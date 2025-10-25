/**
 * Conversation Context Retrieval
 * Fetches surrounding messages for LLM context
 */

const admin = require("firebase-admin");

/**
 * Get conversation context around a specific message
 * @param {string} conversationId - Conversation ID
 * @param {string} messageId - Target message ID
 * @param {Object} options - Retrieval options
 * @param {number} options.before - Messages before target (default: 10)
 * @param {number} options.after - Messages after target (default: 10)
 * @return {Promise<Object>} Context with messages
 */
async function getConversationContext(conversationId, messageId, options = {}) {
  const { before = 10, after = 10 } = options;

  try {
    // Get target message first
    const targetMessageDoc = await admin
        .firestore()
        .collection("conversations")
        .doc(conversationId)
        .collection("messages")
        .doc(messageId)
        .get();

    if (!targetMessageDoc.exists) {
      throw new Error(`Message ${messageId} not found`);
    }

    const targetMessage = targetMessageDoc.data();
    const targetTimestamp = targetMessage.timestamp;

    // Get messages before
    const messagesBefore = await admin
        .firestore()
        .collection("conversations")
        .doc(conversationId)
        .collection("messages")
        .where("timestamp", "<", targetTimestamp)
        .orderBy("timestamp", "desc")
        .limit(before)
        .get();

    // Get messages after
    const messagesAfter = await admin
        .firestore()
        .collection("conversations")
        .doc(conversationId)
        .collection("messages")
        .where("timestamp", ">", targetTimestamp)
        .orderBy("timestamp", "asc")
        .limit(after)
        .get();

    // Combine and sort all messages
    const allMessages = [
      ...messagesBefore.docs.reverse().map((doc) => ({ id: doc.id, ...doc.data() })),
      { id: messageId, ...targetMessage },
      ...messagesAfter.docs.map((doc) => ({ id: doc.id, ...doc.data() })),
    ];

    return {
      conversationId,
      targetMessageId: messageId,
      messageCount: allMessages.length,
      messages: allMessages,
    };
  } catch (error) {
    console.error(`❌ Failed to retrieve context: ${error}`);
    throw error;
  }
}

/**
 * Format conversation context for LLM input
 * @param {Array} messages - Array of message objects
 * @param {Object} options - Formatting options
 * @param {boolean} options.includeTimestamps - Include timestamps (default: false)
 * @return {string} Formatted conversation text
 */
function formatContextForLLM(messages, options = {}) {
  const { includeTimestamps = false } = options;

  if (!messages || messages.length === 0) {
    return "";
  }

  return messages
      .map((msg) => {
        const parts = [];

        if (includeTimestamps && msg.timestamp) {
          const timestamp = (msg.timestamp && msg.timestamp.toMillis) ?
            msg.timestamp.toMillis() : msg.timestamp;
          const date = new Date(timestamp);
          parts.push(`[${date.toISOString()}]`);
        }

        if (msg.senderName) {
          parts.push(`${msg.senderName}:`);
        }

        if (msg.text) {
          parts.push(msg.text);
        }

        return parts.join(" ");
      })
      .join("\n");
}

/**
 * Get recent conversation history for summarization
 * @param {string} conversationId - Conversation ID
 * @param {Object} options - Options
 * @param {number} options.limit - Max messages (default: 50)
 * @return {Promise<Array>} Recent messages
 */
async function getRecentMessages(conversationId, options = {}) {
  const { limit = 50 } = options;

  try {
    const messagesSnap = await admin
        .firestore()
        .collection("conversations")
        .doc(conversationId)
        .collection("messages")
        .orderBy("timestamp", "desc")
        .limit(limit)
        .get();

    const messages = messagesSnap.docs
        .reverse()
        .map((doc) => ({ id: doc.id, ...doc.data() }));

    return messages;
  } catch (error) {
    console.error(`❌ Failed to retrieve recent messages: ${error}`);
    throw error;
  }
}

module.exports = {
  getConversationContext,
  formatContextForLLM,
  getRecentMessages,
};
