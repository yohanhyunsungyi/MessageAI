/**
 * OpenAI Connection Tests
 * Verify OpenAI API is properly configured and accessible
 */

const { openai, DEFAULT_MODEL, EMBEDDING_MODEL } = require("../ai/openai");
const { generateEmbedding } = require("../ai/embeddings");

/**
 * Test OpenAI API key configuration
 * Run with: node src/__tests__/openai.test.js
 */
async function testOpenAIConfiguration() {
  console.log("🧪 Testing OpenAI Configuration...\n");

  try {
    // Test 1: Check if API key is configured
    console.log("Test 1: Checking API key configuration...");
    if (!openai.apiKey) {
      throw new Error("OpenAI API key not configured");
    }
    console.log("✅ API key is configured\n");

    // Test 2: Test basic chat completion
    console.log("Test 2: Testing chat completion...");
    const chatResponse = await openai.chat.completions.create({
      model: DEFAULT_MODEL,
      messages: [{ role: "user", content: "Say 'Hello World'" }],
      max_tokens: 10,
    });

    const responseText = chatResponse.choices[0].message.content;
    console.log(`Response: ${responseText}`);
    console.log("✅ Chat completion works\n");

    // Test 3: Test embedding generation
    console.log("Test 3: Testing embedding generation...");
    const embedding = await generateEmbedding("This is a test message");

    if (!Array.isArray(embedding)) {
      throw new Error("Embedding should be an array");
    }

    if (embedding.length !== 1536) {
      throw new Error(`Expected 1536 dimensions, got ${embedding.length}`);
    }

    console.log(`Generated embedding with ${embedding.length} dimensions`);
    console.log("✅ Embedding generation works\n");

    // Test 4: Verify model availability
    console.log("Test 4: Verifying model availability...");
    console.log(`Chat model: ${DEFAULT_MODEL}`);
    console.log(`Embedding model: ${EMBEDDING_MODEL}`);
    console.log("✅ Models configured\n");

    console.log("🎉 All tests passed!");
    return true;
  } catch (error) {
    console.error("❌ Test failed:", error.message);
    console.error("\nTroubleshooting:");
    console.error("1. Set API key: firebase functions:config:set openai.api_key=\"sk-...\"");
    console.error("2. Or set environment variable: export OPENAI_API_KEY=\"sk-...\"");
    console.error("3. Verify your API key at: https://platform.openai.com/api-keys");
    return false;
  }
}

// Run tests if executed directly
if (require.main === module) {
  testOpenAIConfiguration()
      .then((success) => process.exit(success ? 0 : 1))
      .catch((error) => {
        console.error(error);
        process.exit(1);
      });
}

module.exports = { testOpenAIConfiguration };
