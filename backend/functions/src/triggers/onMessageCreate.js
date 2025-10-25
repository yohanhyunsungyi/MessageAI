/**
 * Message Indexing Trigger
 * Automatically indexes new messages to Pinecone for semantic search
 */

const { generateEmbedding, prepareMessageForEmbedding } = require("../ai/embeddings");
const { upsertMessageEmbedding } = require("../ai/pinecone");

/**
 * Index message in Pinecone when created
 * Runs in background, does not block message creation
 * @param {Object} messageData - Message document data
 * @param {Object} context - Function context with params
 * @return {Promise<void>}
 */
async function indexMessageInPinecone(messageData, context) {
  const { conversationId, messageId } = context.params;

  try {
    console.log(`🔍 Indexing message: ${messageId}`);

    // Prepare text for embedding
    const textForEmbedding = prepareMessageForEmbedding(messageData);

    if (!textForEmbedding || textForEmbedding.trim().length === 0) {
      console.log(`⚠️ Skipping empty message: ${messageId}`);
      return;
    }

    // Generate embedding
    console.log(`   Generating embedding...`);
    const embedding = await generateEmbedding(textForEmbedding);

    // Store in Pinecone with metadata
    const metadata = {
      conversationId: conversationId,
      senderId: messageData.senderId || "",
      senderName: messageData.senderName || "",
      text: messageData.text || "",
      timestamp: (messageData.timestamp && messageData.timestamp.toMillis) ?
        messageData.timestamp.toMillis() : Date.now(),
    };

    await upsertMessageEmbedding(messageId, embedding, metadata);

    console.log(`✅ Successfully indexed message: ${messageId}`);
  } catch (error) {
    // Log error but don't throw - indexing is best-effort
    // Message should still be created even if indexing fails
    console.error(`❌ Failed to index message ${messageId}:`, error);
    console.error(`   Error: ${error.message}`);
  }
}

module.exports = {
  indexMessageInPinecone,
};
