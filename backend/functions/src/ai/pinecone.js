/**
 * Pinecone Vector Database Configuration
 * Handles vector storage and semantic search for messages
 */

const { Pinecone } = require("@pinecone-database/pinecone");
const functions = require("firebase-functions");

/**
 * Initialize Pinecone client with API key from Firebase config
 * Set API key using: firebase functions:config:set pinecone.api_key="..."
 */
const pineconeConfig = functions.config().pinecone || {};
const pinecone = new Pinecone({
  apiKey: pineconeConfig.api_key || process.env.PINECONE_API_KEY,
});

/**
 * Index name for message embeddings
 * Must be created in Pinecone dashboard before use
 */
const INDEX_NAME = "messageai-messages";

/**
 * Vector dimensions for OpenAI text-embedding-3-small model
 */
const VECTOR_DIMENSIONS = 1536;

/**
 * Get Pinecone index for message embeddings
 * @return {Object} Pinecone index instance
 */
function getMessageIndex() {
  return pinecone.index(INDEX_NAME);
}

/**
 * Upsert message embedding to Pinecone
 * @param {string} messageId - Unique message ID
 * @param {number[]} embedding - Vector embedding (1536 dimensions)
 * @param {Object} metadata - Metadata for filtering
 * @return {Promise<void>}
 */
async function upsertMessageEmbedding(messageId, embedding, metadata) {
  try {
    const index = getMessageIndex();

    await index.upsert([
      {
        id: messageId,
        values: embedding,
        metadata: {
          conversationId: metadata.conversationId || "",
          senderId: metadata.senderId || "",
          senderName: metadata.senderName || "",
          text: metadata.text || "",
          timestamp: metadata.timestamp || Date.now(),
        },
      },
    ]);

    console.log(`✓ Upserted embedding for message: ${messageId}`);
  } catch (error) {
    console.error("❌ Error upserting to Pinecone:", error);
    throw new Error(`Failed to upsert embedding: ${error.message}`);
  }
}

/**
 * Search for similar messages using vector similarity
 * @param {number[]} queryEmbedding - Query vector (1536 dimensions)
 * @param {Object} options - Search options
 * @param {number} options.topK - Number of results to return (default: 5)
 * @param {string} options.conversationId - Filter by conversation (optional)
 * @return {Promise<Array>} Array of matching messages with scores
 */
async function searchSimilarMessages(queryEmbedding, options = {}) {
  try {
    const index = getMessageIndex();
    const { topK = 5, conversationId } = options;

    const filter = conversationId ? { conversationId: { $eq: conversationId } } : {};

    const queryResponse = await index.query({
      vector: queryEmbedding,
      topK: topK,
      includeMetadata: true,
      filter: filter,
    });

    return queryResponse.matches || [];
  } catch (error) {
    console.error("❌ Error searching Pinecone:", error);
    throw new Error(`Failed to search embeddings: ${error.message}`);
  }
}

/**
 * Delete message embedding from Pinecone
 * @param {string} messageId - Message ID to delete
 * @return {Promise<void>}
 */
async function deleteMessageEmbedding(messageId) {
  try {
    const index = getMessageIndex();
    await index.deleteOne(messageId);
    console.log(`✓ Deleted embedding for message: ${messageId}`);
  } catch (error) {
    console.error("❌ Error deleting from Pinecone:", error);
    throw new Error(`Failed to delete embedding: ${error.message}`);
  }
}

module.exports = {
  pinecone,
  INDEX_NAME,
  VECTOR_DIMENSIONS,
  getMessageIndex,
  upsertMessageEmbedding,
  searchSimilarMessages,
  deleteMessageEmbedding,
};
