/**
 * Thread Summarization Feature
 * Summarizes conversation threads into concise key points
 * Target: <2 seconds response time
 */

const admin = require("firebase-admin");
const { openai, DEFAULT_MODEL } = require("../ai/openai");
const { SUMMARIZATION_PROMPT } = require("../ai/prompts");

/**
 * Summarize a conversation thread
 * @param {string} conversationId - The conversation to summarize
 * @param {string} userId - The requesting user ID
 * @param {number} messageLimit - Max messages to include (default: 200)
 * @returns {Object} Summary with key points, timeRange, and participants
 */
async function summarizeConversation(conversationId, userId, messageLimit = 200) {
  console.log(`📝 Starting summarization for conversation: ${conversationId}`);
  console.log(`   User: ${userId}, Message limit: ${messageLimit}`);

  const startTime = Date.now();

  try {
    // Verify user has access to this conversation
    const conversationRef = admin.firestore()
        .collection("conversations")
        .doc(conversationId);

    const conversationSnap = await conversationRef.get();

    if (!conversationSnap.exists) {
      throw new Error(`Conversation ${conversationId} not found`);
    }

    const conversation = conversationSnap.data();

    // Check if user is a participant
    if (!conversation.participantIds.includes(userId)) {
      throw new Error("User is not a participant in this conversation");
    }

    // Fetch messages from the conversation (most recent first, then reverse)
    const messagesSnap = await conversationRef
        .collection("messages")
        .orderBy("timestamp", "desc")
        .limit(messageLimit)
        .get();

    if (messagesSnap.empty) {
      return {
        summary: "No messages to summarize.",
        keyPoints: [],
        messageCount: 0,
        timeRange: null,
        participants: conversation.participantNames || [],
      };
    }

    // Convert messages to array and reverse to chronological order
    const messages = [];
    messagesSnap.forEach((doc) => {
      const msg = doc.data();
      messages.push({
        senderName: msg.senderName,
        text: msg.text,
        timestamp: msg.timestamp,
      });
    });

    // Reverse to get chronological order
    messages.reverse();

    console.log(`   Found ${messages.length} messages to summarize`);

    // Format messages for the LLM
    const formattedMessages = messages.map((msg) => {
      return `${msg.senderName}: ${msg.text}`;
    }).join("\n");

    // Get time range
    const firstMessage = messages[0];
    const lastMessage = messages[messages.length - 1];
    const timeRange = {
      start: firstMessage.timestamp,
      end: lastMessage.timestamp,
    };

    // Call OpenAI to generate summary
    console.log(`   Calling OpenAI for summarization...`);

    const completion = await openai.chat.completions.create({
      model: DEFAULT_MODEL,
      messages: [
        {
          role: "system",
          content: SUMMARIZATION_PROMPT,
        },
        {
          role: "user",
          content: `Summarize this conversation:\n\n${formattedMessages}`,
        },
      ],
      temperature: 0.7,
      max_tokens: 500,
    });

    const summaryText = completion.choices[0].message.content;

    // Parse key points from summary (extract bullet points)
    const keyPoints = summaryText
        .split("\n")
        .filter((line) => line.trim().startsWith("•"))
        .map((line) => line.trim().substring(1).trim());

    const duration = Date.now() - startTime;
    console.log(`✅ Summarization completed in ${duration}ms`);
    console.log(`   Generated ${keyPoints.length} key points`);

    return {
      summary: summaryText,
      keyPoints,
      messageCount: messages.length,
      timeRange,
      participants: conversation.participantNames || [],
      duration,
    };
  } catch (error) {
    const duration = Date.now() - startTime;
    console.error(`❌ Summarization failed after ${duration}ms:`, error);
    throw error;
  }
}

module.exports = {
  summarizeConversation,
};
