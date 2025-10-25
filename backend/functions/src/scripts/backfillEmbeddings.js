/**
 * Batch Indexing Script
 * Index existing messages into Pinecone (one-time migration)
 * Run with: node src/scripts/backfillEmbeddings.js
 */

const admin = require("firebase-admin");
const { generateEmbeddingsBatch, prepareMessageForEmbedding } = require("../ai/embeddings");
const { getMessageIndex } = require("../ai/pinecone");

// Load environment variables for local execution
if (process.env.NODE_ENV !== "production") {
  require("dotenv").config({ path: ".env.local" });
}

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Backfill embeddings for all existing messages
 * @param {Object} options - Backfill options
 * @param {number} options.batchSize - Messages per batch (default: 50)
 * @param {string} options.conversationId - Optional: specific conversation only
 * @return {Promise<Object>} Stats about indexing
 */
async function backfillEmbeddings(options = {}) {
  const { batchSize = 50, conversationId } = options;

  console.log("🚀 Starting embedding backfill...");
  if (conversationId) {
    console.log(`   Conversation: ${conversationId}`);
  } else {
    console.log("   Scope: All conversations");
  }

  const stats = {
    totalMessages: 0,
    indexed: 0,
    skipped: 0,
    failed: 0,
    startTime: Date.now(),
  };

  try {
    const index = getMessageIndex();

    // Get all conversations or specific one
    let conversationsQuery = admin.firestore().collection("conversations");

    if (conversationId) {
      conversationsQuery = conversationsQuery.where(
          admin.firestore.FieldPath.documentId(),
          "==",
          conversationId,
      );
    }

    const conversationsSnap = await conversationsQuery.get();
    console.log(`📊 Found ${conversationsSnap.size} conversation(s)\n`);

    // Process each conversation
    for (const convDoc of conversationsSnap.docs) {
      const convId = convDoc.id;
      console.log(`📂 Processing conversation: ${convId}`);

      // Get all messages in conversation
      const messagesSnap = await admin
          .firestore()
          .collection("conversations")
          .doc(convId)
          .collection("messages")
          .get();

      console.log(`   Found ${messagesSnap.size} message(s)`);
      stats.totalMessages += messagesSnap.size;

      // Process messages in batches
      const messages = messagesSnap.docs;
      for (let i = 0; i < messages.length; i += batchSize) {
        const batch = messages.slice(i, i + batchSize);
        console.log(`   Processing batch ${Math.floor(i / batchSize) + 1}...`);

        await processBatch(batch, convId, index, stats);
      }

      console.log(`   ✅ Completed conversation: ${convId}\n`);
    }

    // Print final stats
    const duration = ((Date.now() - stats.startTime) / 1000).toFixed(2);
    console.log("=" .repeat(50));
    console.log("📊 Backfill Complete!");
    console.log(`   Total messages: ${stats.totalMessages}`);
    console.log(`   Indexed: ${stats.indexed}`);
    console.log(`   Skipped: ${stats.skipped}`);
    console.log(`   Failed: ${stats.failed}`);
    console.log(`   Duration: ${duration}s`);
    console.log(`   Rate: ${(stats.indexed / duration).toFixed(2)} msg/s`);
    console.log("=" .repeat(50));

    return stats;
  } catch (error) {
    console.error("❌ Backfill failed:", error);
    throw error;
  }
}

/**
 * Process a batch of messages
 * @param {Array} messageDocs - Message documents
 * @param {string} conversationId - Conversation ID
 * @param {Object} index - Pinecone index
 * @param {Object} stats - Stats object to update
 * @return {Promise<void>}
 */
async function processBatch(messageDocs, conversationId, index, stats) {
  const vectors = [];

  for (const messageDoc of messageDocs) {
    const messageData = messageDoc.data();
    const messageId = messageDoc.id;

    // Prepare text
    const text = prepareMessageForEmbedding(messageData);

    if (!text || text.trim().length === 0) {
      stats.skipped++;
      continue;
    }

    vectors.push({
      id: messageId,
      text: text,
      metadata: {
        conversationId: conversationId,
        senderId: messageData.senderId || "",
        senderName: messageData.senderName || "",
        text: messageData.text || "",
        timestamp: (messageData.timestamp && messageData.timestamp.toMillis) ?
          messageData.timestamp.toMillis() : Date.now(),
      },
    });
  }

  if (vectors.length === 0) {
    return;
  }

  try {
    // Generate embeddings for batch
    const texts = vectors.map((v) => v.text);
    const embeddings = await generateEmbeddingsBatch(texts);

    // Upsert to Pinecone
    const upsertData = vectors.map((vector, idx) => ({
      id: vector.id,
      values: embeddings[idx],
      metadata: vector.metadata,
    }));

    await index.upsert(upsertData);

    stats.indexed += vectors.length;
    console.log(`      ✓ Indexed ${vectors.length} messages`);
  } catch (error) {
    console.error(`      ✗ Batch failed: ${error.message}`);
    stats.failed += vectors.length;
  }
}

// Run backfill if executed directly
if (require.main === module) {
  const args = process.argv.slice(2);
  const conversationId = args[0]; // Optional: node script.js <conversationId>

  backfillEmbeddings({ conversationId })
      .then(() => process.exit(0))
      .catch((error) => {
        console.error(error);
        process.exit(1);
      });
}

module.exports = {
  backfillEmbeddings,
};
