/**
 * Proactive Assistant - Scheduling Detection
 * Detects when users need to schedule meetings from conversation context
 */

const { getOpenAIClient, DEFAULT_MODEL } = require("../../ai/openai");
const { SCHEDULING_DETECTION_PROMPT } = require("../../ai/prompts");
const admin = require("firebase-admin");

/**
 * Detect if a message indicates a scheduling need
 * @param {Object} messageData - The message that was sent
 * @param {Object} context - Function context with conversation info
 * @return {Promise<Object|null>} Detection result or null if no scheduling need
 */
async function detectSchedulingNeed(messageData, context) {
  try {
    console.log(`🔍 Detecting scheduling need for message: ${context.params.messageId}`);

    const messageText = messageData.text || "";
    if (!messageText.trim()) {
      return null;
    }

    // Get recent message context (last 10 messages)
    const recentMessages = await getRecentMessages(
        context.params.conversationId,
        10,
    );

    // Call OpenAI to classify scheduling need
    const openai = getOpenAIClient();
    const completion = await openai.chat.completions.create({
      model: DEFAULT_MODEL,
      messages: [
        { role: "system", content: SCHEDULING_DETECTION_PROMPT },
        {
          role: "user",
          content: JSON.stringify({
            currentMessage: messageText,
            recentMessages: recentMessages.map((m) => ({
              sender: m.senderName,
              text: m.text,
              timestamp: m.timestamp,
            })),
          }),
        },
      ],
      temperature: 0.3, // Lower temperature for more consistent detection
      max_tokens: 300,
      response_format: { type: "json_object" },
    });

    const result = JSON.parse(completion.choices[0].message.content);
    console.log(`   Detection result:`, result);

    // Check if confidence threshold met
    if (result.needsMeeting && result.confidence >= 0.7) {
      console.log(`   ✅ Scheduling need detected (confidence: ${result.confidence})`);
      return {
        needsMeeting: true,
        confidence: result.confidence,
        purpose: result.purpose || "Discussion",
        urgency: result.urgency || "flexible",
        conversationId: context.params.conversationId,
        messageId: context.params.messageId,
        detectedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
    }

    console.log(`   ⏭️ No scheduling need detected (confidence: ${result.confidence})`);
    return null;
  } catch (error) {
    console.error(`❌ Scheduling detection failed:`, error);
    console.error(`   Error: ${error.message}`);
    return null; // Fail silently - detection is best-effort
  }
}

/**
 * Get recent messages from conversation for context
 * @param {string} conversationId - The conversation ID
 * @param {number} limit - Number of messages to fetch
 * @return {Promise<Array>} Array of recent messages
 */
async function getRecentMessages(conversationId, limit = 10) {
  try {
    const messagesSnap = await admin.firestore()
        .collection("conversations")
        .doc(conversationId)
        .collection("messages")
        .orderBy("timestamp", "desc")
        .limit(limit)
        .get();

    const messages = [];
    messagesSnap.forEach((doc) => {
      messages.push({
        id: doc.id,
        ...doc.data(),
      });
    });

    // Reverse to get chronological order
    return messages.reverse();
  } catch (error) {
    console.error(`⚠️ Failed to fetch recent messages:`, error.message);
    return [];
  }
}

/**
 * Create a proactive suggestion in Firestore
 * @param {Object} detection - The detection result
 * @param {Object} conversationData - The conversation data
 * @return {Promise<void>}
 */
async function createProactiveSuggestion(detection, conversationData) {
  try {
    console.log(`💡 Creating proactive suggestion for conversation: ${detection.conversationId}`);

    const suggestionData = {
      type: "scheduling",
      conversationId: detection.conversationId,
      conversationName: conversationData.name || "Conversation",
      participantIds: conversationData.participantIds || [],
      participantNames: conversationData.participantNames || {},
      purpose: detection.purpose,
      urgency: detection.urgency,
      confidence: detection.confidence,
      status: "pending", // pending, accepted, dismissed
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      triggeredByMessageId: detection.messageId,
    };

    // Create suggestion document
    const suggestionRef = await admin.firestore()
        .collection("proactiveSuggestions")
        .add(suggestionData);

    console.log(`   ✅ Proactive suggestion created: ${suggestionRef.id}`);

    return suggestionRef.id;
  } catch (error) {
    console.error(`❌ Failed to create proactive suggestion:`, error);
    throw error;
  }
}

/**
 * Main handler - detect and create suggestion if needed
 * Called from onMessageCreate trigger
 * @param {Object} messageData - The message that was sent
 * @param {Object} context - Function context
 * @return {Promise<void>}
 */
async function handleSchedulingDetection(messageData, context) {
  try {
    // Detect scheduling need
    const detection = await detectSchedulingNeed(messageData, context);

    if (!detection) {
      return; // No scheduling need detected
    }

    // Get conversation data
    const conversationSnap = await admin.firestore()
        .collection("conversations")
        .doc(context.params.conversationId)
        .get();

    if (!conversationSnap.exists) {
      console.error(`⚠️ Conversation not found: ${context.params.conversationId}`);
      return;
    }

    const conversationData = conversationSnap.data();

    // Create proactive suggestion
    await createProactiveSuggestion(detection, conversationData);
  } catch (error) {
    console.error(`❌ Scheduling detection handler failed:`, error);
    // Don't throw - this is a background process
  }
}

module.exports = {
  detectSchedulingNeed,
  createProactiveSuggestion,
  handleSchedulingDetection,
};
