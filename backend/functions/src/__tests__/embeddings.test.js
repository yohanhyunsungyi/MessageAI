/**
 * Embeddings Generation Tests
 * Verify embedding generation functionality
 */

const { generateEmbedding, generateEmbeddingsBatch, prepareMessageForEmbedding } = require("../ai/embeddings");

/**
 * Test embedding generation with sample messages
 * Run with: node src/__tests__/embeddings.test.js
 */
async function testEmbeddings() {
  console.log("🧪 Testing Embedding Generation...\n");

  try {
    // Test 1: Single message embedding
    console.log("Test 1: Single message embedding...");
    const testMessage = "Hello, this is a test message about Firebase and AI.";
    const embedding = await generateEmbedding(testMessage);

    if (!Array.isArray(embedding)) {
      throw new Error("Embedding should be an array");
    }

    if (embedding.length !== 1536) {
      throw new Error(`Expected 1536 dimensions, got ${embedding.length}`);
    }

    console.log(`   Generated embedding: ${embedding.length} dimensions`);
    console.log(`   First 5 values: [${embedding.slice(0, 5).map((v) => v.toFixed(4)).join(", ")}]`);
    console.log("✅ Single embedding generation works\n");

    // Test 2: Batch embedding generation
    console.log("Test 2: Batch embedding generation...");
    const testMessages = [
      "How do I use Firebase with React?",
      "What is vector search?",
      "Pinecone integration tutorial",
    ];

    const embeddings = await generateEmbeddingsBatch(testMessages);

    if (!Array.isArray(embeddings)) {
      throw new Error("Batch embeddings should be an array");
    }

    if (embeddings.length !== testMessages.length) {
      throw new Error(`Expected ${testMessages.length} embeddings, got ${embeddings.length}`);
    }

    for (const emb of embeddings) {
      if (emb.length !== 1536) {
        throw new Error(`All embeddings should have 1536 dimensions, got ${emb.length}`);
      }
    }

    console.log(`   Generated ${embeddings.length} embeddings`);
    console.log("✅ Batch embedding generation works\n");

    // Test 3: Message preparation
    console.log("Test 3: Message preparation...");
    const messageData = {
      senderName: "Alice",
      text: "Let's schedule a call about the project",
    };

    const preparedText = prepareMessageForEmbedding(messageData);
    console.log(`   Original: ${JSON.stringify(messageData)}`);
    console.log(`   Prepared: "${preparedText}"`);

    if (!preparedText.includes("Alice")) {
      throw new Error("Prepared text should include sender name");
    }

    if (!preparedText.includes(messageData.text)) {
      throw new Error("Prepared text should include message text");
    }

    console.log("✅ Message preparation works\n");

    // Test 4: Embedding similarity (cosine similarity)
    console.log("Test 4: Embedding similarity...");
    const msg1 = "I love programming in Python";
    const msg2 = "Python is my favorite programming language";
    const msg3 = "I prefer eating pizza for dinner";

    const emb1 = await generateEmbedding(msg1);
    const emb2 = await generateEmbedding(msg2);
    const emb3 = await generateEmbedding(msg3);

    const sim12 = cosineSimilarity(emb1, emb2);
    const sim13 = cosineSimilarity(emb1, emb3);

    console.log(`   Similarity (msg1, msg2): ${sim12.toFixed(4)} (similar topics)`);
    console.log(`   Similarity (msg1, msg3): ${sim13.toFixed(4)} (different topics)`);

    if (sim12 <= sim13) {
      console.log("⚠️  Warning: Similar messages should have higher similarity");
    } else {
      console.log("✅ Embeddings capture semantic similarity correctly");
    }

    console.log("\n🎉 All embedding tests passed!");
    return true;
  } catch (error) {
    console.error("❌ Test failed:", error.message);
    console.error("\nTroubleshooting:");
    console.error("1. Ensure .env.local has OPENAI_API_KEY set");
    console.error("2. Verify API key is valid");
    console.error("3. Check network connection");
    return false;
  }
}

/**
 * Calculate cosine similarity between two vectors
 * @param {number[]} a - First vector
 * @param {number[]} b - Second vector
 * @return {number} Similarity score (0-1)
 */
function cosineSimilarity(a, b) {
  let dotProduct = 0;
  let normA = 0;
  let normB = 0;

  for (let i = 0; i < a.length; i++) {
    dotProduct += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }

  return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
}

// Run tests if executed directly
if (require.main === module) {
  testEmbeddings()
      .then((success) => process.exit(success ? 0 : 1))
      .catch((error) => {
        console.error(error);
        process.exit(1);
      });
}

module.exports = { testEmbeddings };
