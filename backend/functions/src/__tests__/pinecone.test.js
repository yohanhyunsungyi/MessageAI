/**
 * Pinecone Connection Tests
 * Verify Pinecone API is properly configured
 */

const { pinecone, INDEX_NAME } = require("../ai/pinecone");

/**
 * Test Pinecone configuration and index availability
 * Run with: node src/__tests__/pinecone.test.js
 */
async function testPineconeConfiguration() {
  console.log("🧪 Testing Pinecone Configuration...\n");

  try {
    // Test 1: Check if API key is configured
    console.log("Test 1: Checking API key configuration...");
    if (!pinecone) {
      throw new Error("Pinecone client not initialized");
    }
    console.log("✅ Pinecone client is initialized\n");

    // Test 2: List available indexes
    console.log("Test 2: Listing available indexes...");
    const indexes = await pinecone.listIndexes();
    console.log(`Found ${indexes.indexes.length} index(es):`);
    indexes.indexes.forEach((index) => {
      console.log(`  - ${index.name} (${index.dimension} dimensions)`);
    });
    console.log("✅ Successfully connected to Pinecone\n");

    // Test 3: Check if required index exists
    console.log(`Test 3: Checking for index '${INDEX_NAME}'...`);
    const indexExists = indexes.indexes.some(
        (index) => index.name === INDEX_NAME,
    );

    if (indexExists) {
      console.log(`✅ Index '${INDEX_NAME}' exists\n`);

      // Test 4: Get index stats
      console.log("Test 4: Getting index statistics...");
      const index = pinecone.index(INDEX_NAME);
      const stats = await index.describeIndexStats();
      console.log(`  Total vectors: ${stats.totalRecordCount || 0}`);
      console.log(`  Dimensions: ${stats.dimension}`);
      console.log("✅ Index is ready to use\n");
    } else {
      console.log(`⚠️  Index '${INDEX_NAME}' does not exist yet\n`);
      console.log("📋 To create the index:");
      console.log("1. Go to https://www.pinecone.io/");
      console.log("2. Click 'Create Index'");
      console.log(`3. Name: ${INDEX_NAME}`);
      console.log("4. Dimensions: 1536");
      console.log("5. Metric: cosine");
      console.log("6. Cloud: AWS");
      console.log("7. Region: us-east-1 (or your preferred region)\n");
      console.log("⚠️  Some features will not work until index is created");
    }

    console.log("🎉 Pinecone configuration test complete!");
    return indexExists;
  } catch (error) {
    console.error("❌ Test failed:", error.message);
    console.error("\nTroubleshooting:");
    console.error("1. Verify API key in .env.local");
    console.error("2. Check your Pinecone dashboard: https://www.pinecone.io/");
    console.error("3. Ensure your API key has proper permissions");
    return false;
  }
}

// Run tests if executed directly
if (require.main === module) {
  testPineconeConfiguration()
      .then((indexExists) => process.exit(indexExists ? 0 : 1))
      .catch((error) => {
        console.error(error);
        process.exit(1);
      });
}

module.exports = { testPineconeConfiguration };
