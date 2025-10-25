/**
 * Vector Search Accuracy Tests
 * Verify RAG pipeline search quality and relevance
 *
 * Prerequisites:
 * 1. Firebase Admin SDK credentials:
 *    - Option A: Set GOOGLE_APPLICATION_CREDENTIALS env variable
 *      export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
 *    - Option B: Use gcloud CLI authentication
 *      gcloud auth application-default login
 * 2. Valid OPENAI_API_KEY in .env.local
 * 3. Valid PINECONE_API_KEY in .env.local
 * 4. Pinecone index "messageai-messages" must exist
 *
 * Run with: node src/__tests__/vectorSearch.test.js
 */

const admin = require("firebase-admin");
const { generateEmbedding, prepareMessageForEmbedding } = require("../ai/embeddings");
const { getMessageIndex } = require("../ai/pinecone");
const { searchMessages } = require("../features/vectorSearch");

// Load environment variables for local execution
if (process.env.NODE_ENV !== "production") {
  require("dotenv").config({ path: ".env.local" });
}

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  try {
    admin.initializeApp({
      projectId: "messagingai-75f21",
    });
  } catch (error) {
    console.error("❌ Failed to initialize Firebase Admin:", error.message);
    console.error("\nTo run this test:");
    console.error("1. Set GOOGLE_APPLICATION_CREDENTIALS env variable, OR");
    console.error("2. Run: firebase login");
    console.error("3. Ensure you have access to project: messagingai-75f21");
    process.exit(1);
  }
}

/**
 * Test dataset: 20 messages across different topics
 */
const TEST_MESSAGES = [
  // Project Management (5 messages)
  { id: "msg1", text: "We need to update the project timeline for Q4 deliverables", topic: "project" },
  { id: "msg2", text: "The sprint planning meeting is scheduled for next Monday at 2 PM", topic: "project" },
  { id: "msg3", text: "Can someone review the product roadmap before the stakeholder meeting?", topic: "project" },
  { id: "msg4", text: "Let's prioritize the bug fixes before adding new features", topic: "project" },
  { id: "msg5", text: "The project deadline has been extended by two weeks", topic: "project" },

  // Technical Discussions (5 messages)
  { id: "msg6", text: "We should migrate the database to PostgreSQL for better performance", topic: "technical" },
  { id: "msg7", text: "The API response time is too slow, we need to add caching", topic: "technical" },
  { id: "msg8", text: "Let's implement Firebase Cloud Functions for the backend logic", topic: "technical" },
  { id: "msg9", text: "The authentication flow needs OAuth2 integration", topic: "technical" },
  { id: "msg10", text: "We have a memory leak in the iOS app that needs fixing", topic: "technical" },

  // Meeting Coordination (5 messages)
  { id: "msg11", text: "Are you free for a call tomorrow at 3 PM to discuss the budget?", topic: "meeting" },
  { id: "msg12", text: "Let's schedule a team sync next week to align on priorities", topic: "meeting" },
  { id: "msg13", text: "Can we reschedule the client demo to Friday afternoon?", topic: "meeting" },
  { id: "msg14", text: "I'm available for the design review meeting on Wednesday", topic: "meeting" },
  { id: "msg15", text: "Please send calendar invites for the quarterly business review", topic: "meeting" },

  // Casual Conversation (5 messages)
  { id: "msg16", text: "Did you watch the game last night? It was amazing!", topic: "casual" },
  { id: "msg17", text: "I'm grabbing lunch at the new Italian restaurant, anyone want to join?", topic: "casual" },
  { id: "msg18", text: "Happy birthday! Hope you have a wonderful day!", topic: "casual" },
  { id: "msg19", text: "The weather is perfect for hiking this weekend", topic: "casual" },
  { id: "msg20", text: "Thanks for helping me move yesterday, I really appreciate it!", topic: "casual" },
];

/**
 * Test queries with expected relevant message IDs
 */
const TEST_QUERIES = [
  {
    query: "project timeline and deadlines",
    expectedTopics: ["project"],
    expectedIds: ["msg1", "msg5", "msg4"],
    minRecall: 0.6, // At least 60% recall
  },
  {
    query: "database performance and API optimization",
    expectedTopics: ["technical"],
    expectedIds: ["msg6", "msg7", "msg8"],
    minRecall: 0.6,
  },
  {
    query: "scheduling meetings and availability",
    expectedTopics: ["meeting"],
    expectedIds: ["msg11", "msg12", "msg13"],
    minRecall: 0.6,
  },
  {
    query: "Firebase backend implementation",
    expectedTopics: ["technical"],
    expectedIds: ["msg8", "msg9", "msg7"],
    minRecall: 0.4, // Lower threshold for more specific query
  },
];

/**
 * Run vector search accuracy tests
 */
async function testVectorSearch() {
  console.log("🧪 Testing Vector Search Accuracy...\n");

  const testConversationId = `test-conv-${Date.now()}`;
  const testUserId = `test-user-${Date.now()}`;

  try {
    // Setup: Index test messages
    console.log("📊 Setting up test dataset...");
    await setupTestData(testConversationId, testUserId);
    console.log(`   ✓ Indexed ${TEST_MESSAGES.length} test messages\n`);

    // Wait for indexing to propagate
    console.log("⏳ Waiting for index propagation (5 seconds)...");
    await new Promise((resolve) => setTimeout(resolve, 5000));

    // Run test queries
    const results = [];
    for (const testQuery of TEST_QUERIES) {
      console.log(`\n🔍 Testing query: "${testQuery.query}"`);
      const queryResult = await runQueryTest(testQuery, testConversationId, testUserId);
      results.push(queryResult);
    }

    // Calculate overall metrics
    console.log("\n" + "=".repeat(60));
    console.log("📊 Overall Results:");
    const avgRecall = results.reduce((sum, r) => sum + r.recall, 0) / results.length;
    const avgPrecision = results.reduce((sum, r) => sum + r.precision, 0) / results.length;
    const avgTopicAccuracy = results.reduce((sum, r) => sum + r.topicAccuracy, 0) / results.length;

    console.log(`   Average Recall@5: ${(avgRecall * 100).toFixed(1)}%`);
    console.log(`   Average Precision@5: ${(avgPrecision * 100).toFixed(1)}%`);
    console.log(`   Average Topic Accuracy: ${(avgTopicAccuracy * 100).toFixed(1)}%`);

    const allPassed = results.every((r) => r.passed);
    if (allPassed) {
      console.log("\n✅ All vector search tests passed!");
    } else {
      console.log("\n⚠️  Some tests did not meet minimum thresholds");
    }

    // Cleanup
    console.log("\n🧹 Cleaning up test data...");
    await cleanupTestData(testConversationId, testUserId);
    console.log("   ✓ Cleanup complete\n");

    return allPassed;
  } catch (error) {
    console.error("❌ Test failed:", error.message);
    console.error("\nTroubleshooting:");
    console.error("1. Ensure Pinecone index exists and is accessible");
    console.error("2. Verify OPENAI_API_KEY and PINECONE_API_KEY in .env.local");
    console.error("3. Check network connection");
    console.error("4. Wait longer for index propagation if tests fail initially");
    return false;
  }
}

/**
 * Setup test data in Firestore and Pinecone
 */
async function setupTestData(conversationId, userId) {
  const db = admin.firestore();
  const index = getMessageIndex();

  // Create test conversation
  await db.collection("conversations").doc(conversationId).set({
    type: "group",
    participantIds: [userId],
    participantNames: ["Test User"],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Index messages in batches
  const vectors = [];
  for (const msg of TEST_MESSAGES) {
    const messageData = {
      id: msg.id,
      conversationId: conversationId,
      senderId: userId,
      senderName: "Test User",
      text: msg.text,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Save to Firestore
    await db
        .collection("conversations")
        .doc(conversationId)
        .collection("messages")
        .doc(msg.id)
        .set(messageData);

    // Prepare for Pinecone
    const textForEmbedding = prepareMessageForEmbedding(messageData);
    const embedding = await generateEmbedding(textForEmbedding);

    vectors.push({
      id: msg.id,
      values: embedding,
      metadata: {
        conversationId: conversationId,
        senderId: userId,
        senderName: "Test User",
        text: msg.text,
        timestamp: Date.now(),
        topic: msg.topic, // Store topic for accuracy testing
      },
    });
  }

  // Upsert to Pinecone in batches
  const batchSize = 10;
  for (let i = 0; i < vectors.length; i += batchSize) {
    const batch = vectors.slice(i, i + batchSize);
    await index.upsert(batch);
  }
}

/**
 * Run a single query test and calculate metrics
 */
async function runQueryTest(testQuery, conversationId, userId) {
  const { query, expectedTopics, expectedIds, minRecall } = testQuery;

  // Execute search
  const searchResults = await searchMessages(query, {
    topK: 5,
    conversationId: conversationId,
    userId: userId,
  });

  // Calculate metrics
  const retrievedIds = searchResults.map((r) => r.messageId);
  const retrievedTopics = searchResults.map((r) => {
    const msg = TEST_MESSAGES.find((m) => m.id === r.messageId);
    return msg ? msg.topic : null;
  });

  // Recall: How many expected IDs were retrieved?
  const relevantRetrieved = expectedIds.filter((id) => retrievedIds.includes(id)).length;
  const recall = relevantRetrieved / expectedIds.length;

  // Precision: How many retrieved are relevant?
  const precision = relevantRetrieved / Math.max(retrievedIds.length, 1);

  // Topic Accuracy: Are retrieved messages from expected topics?
  const correctTopics = retrievedTopics.filter((t) => expectedTopics.includes(t)).length;
  const topicAccuracy = correctTopics / Math.max(retrievedTopics.length, 1);

  // Display results
  console.log(`   Retrieved IDs: [${retrievedIds.join(", ")}]`);
  console.log(`   Expected IDs: [${expectedIds.join(", ")}]`);
  console.log(`   Recall@5: ${(recall * 100).toFixed(1)}% (${relevantRetrieved}/${expectedIds.length})`);
  console.log(`   Precision@5: ${(precision * 100).toFixed(1)}%`);
  console.log(`   Topic Accuracy: ${(topicAccuracy * 100).toFixed(1)}%`);

  const passed = recall >= minRecall;
  console.log(`   Result: ${passed ? "✅ PASS" : "❌ FAIL"} (threshold: ${minRecall * 100}%)`);

  return {
    query,
    recall,
    precision,
    topicAccuracy,
    passed,
  };
}

/**
 * Cleanup test data from Firestore and Pinecone
 */
async function cleanupTestData(conversationId, userId) {
  const db = admin.firestore();
  const index = getMessageIndex();

  // Delete messages from Firestore
  const messagesSnap = await db
      .collection("conversations")
      .doc(conversationId)
      .collection("messages")
      .get();

  const deletePromises = messagesSnap.docs.map((doc) => doc.ref.delete());
  await Promise.all(deletePromises);

  // Delete conversation
  await db.collection("conversations").doc(conversationId).delete();

  // Delete from Pinecone
  const messageIds = TEST_MESSAGES.map((m) => m.id);
  await index.deleteMany(messageIds);
}

// Run tests if executed directly
if (require.main === module) {
  testVectorSearch()
      .then((success) => process.exit(success ? 0 : 1))
      .catch((error) => {
        console.error(error);
        process.exit(1);
      });
}

module.exports = { testVectorSearch };
