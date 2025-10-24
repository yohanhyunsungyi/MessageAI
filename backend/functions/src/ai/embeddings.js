/**
 * Embeddings Generation Service
 * Handles text-to-vector conversion for semantic search
 */

const { openai, EMBEDDING_MODEL } = require("./openai");

/**
 * Generate embedding for a single text
 * @param {string} text - Text to embed
 * @return {Promise<number[]>} Vector embedding (1536 dimensions)
 */
async function generateEmbedding(text) {
  try {
    const response = await openai.embeddings.create({
      model: EMBEDDING_MODEL,
      input: text.trim(),
    });

    return response.data[0].embedding;
  } catch (error) {
    console.error("❌ Error generating embedding:", error);
    throw new Error(`Failed to generate embedding: ${error.message}`);
  }
}

/**
 * Generate embeddings for multiple texts in batch
 * More efficient than generating one at a time
 * @param {string[]} texts - Array of texts to embed (max 100)
 * @return {Promise<number[][]>} Array of vector embeddings
 */
async function generateEmbeddingsBatch(texts) {
  if (texts.length === 0) {
    return [];
  }

  if (texts.length > 100) {
    throw new Error("Batch size must be 100 or less");
  }

  try {
    const cleanTexts = texts.map((t) => t.trim());

    const response = await openai.embeddings.create({
      model: EMBEDDING_MODEL,
      input: cleanTexts,
    });

    return response.data.map((item) => item.embedding);
  } catch (error) {
    console.error("❌ Error generating batch embeddings:", error);
    throw new Error(`Failed to generate batch embeddings: ${error.message}`);
  }
}

/**
 * Prepare message text for embedding
 * Combines sender name and message text for better context
 * @param {Object} message - Message object from Firestore
 * @return {string} Formatted text for embedding
 */
function prepareMessageForEmbedding(message) {
  const parts = [];

  if (message.senderName) {
    parts.push(`From ${message.senderName}`);
  }

  if (message.text) {
    parts.push(message.text);
  }

  return parts.join(": ");
}

module.exports = {
  generateEmbedding,
  generateEmbeddingsBatch,
  prepareMessageForEmbedding,
};
