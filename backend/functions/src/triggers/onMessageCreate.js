/**
 * Message Indexing Trigger
 * Automatically indexes new messages to Pinecone for semantic search
 * Also classifies message priority in real-time
 */

const { generateEmbedding, prepareMessageForEmbedding } = require("../ai/embeddings");
const { upsertMessageEmbedding } = require("../ai/pinecone");
const { classifyMessagePriority } = require("../features/priority");

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

/**
 * Classify message priority in real-time
 * Updates message document with priority field
 * @param {Object} messageData - Message document data
 * @param {Object} context - Function context with params
 * @param {Object} messageRef - Firestore reference to message
 * @return {Promise<void>}
 */
async function classifyPriority(messageData, context, messageRef) {
  try {
    console.log(`🎯 Classifying priority for message: ${context.params.messageId}`);

    // Get conversation context for better classification
    const admin = require("firebase-admin");
    let conversationName = "";
    try {
      const convSnap = await admin.firestore()
          .collection("conversations")
          .doc(context.params.conversationId)
          .get();
      if (convSnap.exists) {
        const convData = convSnap.data();
        const participants = convData.participantNames;
        conversationName = convData.name ||
          (participants ? participants.join(", ") : "") ||
          "";
      }
    } catch (err) {
      console.log(`   ⚠️ Could not fetch conversation: ${err.message}`);
    }

    // Classify priority
    const classification = await classifyMessagePriority(messageData, { conversationName });

    // Update message with priority
    if (classification.priority && (classification.priority === "critical" || classification.priority === "high")) {
      console.log(`   🚨 High priority message detected: ${classification.priority}`);

      await messageRef.update({
        priority: classification.priority,
        aiClassified: classification.aiClassified,
      });

      console.log(`   ✅ Priority updated in Firestore`);
    } else {
      // For normal priority, still mark as classified but don't trigger notifications
      await messageRef.update({
        priority: "normal",
        aiClassified: classification.aiClassified,
      });
    }
  } catch (error) {
    // Log error but don't throw - priority classification is best-effort
    console.error(`❌ Failed to classify priority:`, error);
    console.error(`   Error: ${error.message}`);
  }
}

module.exports = {
  indexMessageInPinecone,
  classifyPriority,
};
