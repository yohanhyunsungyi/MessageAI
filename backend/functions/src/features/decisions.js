/**
 * Decision Tracking Feature
 * Extracts key decisions from conversation threads
 * Target: <4 seconds response time
 */

const admin = require("firebase-admin");
const { openai, DEFAULT_MODEL } = require("../ai/openai");
const { DECISION_TRACKING_PROMPT } = require("../ai/prompts");
const { EXTRACT_DECISIONS_SCHEMA } = require("../ai/tools");

/**
 * Extract decisions from a conversation
 * @param {string} conversationId - The conversation to analyze
 * @param {string} userId - The requesting user ID
 * @param {number} messageLimit - Max messages to include (default: 200)
 * @returns {Object} Decisions array with metadata
 */
async function extractDecisions(conversationId, userId, messageLimit = 200) {
  console.log(`🎯 Starting decision extraction for conversation: ${conversationId}`);
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
      // participantNames is an object {userId: name}, convert to array of names
      const participantNamesArray = conversation.participantNames ?
          Object.values(conversation.participantNames) :
          [];
      const conversationName = participantNamesArray.length > 0 ?
          participantNamesArray.join(", ") :
          "Conversation";

      return {
        decisions: [],
        conversationId,
        conversationName,
        messageCount: 0,
        extractedAt: admin.firestore.Timestamp.now(),
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

    console.log(`   Found ${messages.length} messages to analyze`);

    // Format messages for the LLM
    const formattedMessages = messages.map((msg) => {
      return `${msg.senderName}: ${msg.text}`;
    }).join("\n");

    // Call OpenAI with function calling to extract structured decisions
    console.log(`   Calling OpenAI for decision extraction...`);

    const completion = await openai.chat.completions.create({
      model: DEFAULT_MODEL,
      messages: [
        {
          role: "system",
          content: DECISION_TRACKING_PROMPT,
        },
        {
          role: "user",
          content: `Extract decisions from this conversation:\n\n${formattedMessages}`,
        },
      ],
      functions: [EXTRACT_DECISIONS_SCHEMA],
      function_call: { name: "extract_decisions" },
      temperature: 0.3, // Lower temperature for more consistent extraction
    });

    const functionCall = completion.choices[0].message.function_call;

    if (!functionCall || !functionCall.arguments) {
      console.log(`   No decisions found`);

      // participantNames is an object {userId: name}, convert to array of names
      const participantNamesArray = conversation.participantNames ?
          Object.values(conversation.participantNames) :
          [];
      const conversationName = participantNamesArray.length > 0 ?
          participantNamesArray.join(", ") :
          "Conversation";

      return {
        decisions: [],
        conversationId,
        conversationName,
        messageCount: messages.length,
        extractedAt: admin.firestore.Timestamp.now(),
      };
    }

    const extracted = JSON.parse(functionCall.arguments);
    const decisions = extracted.decisions || [];

    console.log(`   Extracted ${decisions.length} decisions`);

    // participantNames is an object {userId: name}, convert to array of names
    const participantNamesArray = conversation.participantNames ?
        Object.values(conversation.participantNames) :
        [];
    const conversationName = participantNamesArray.length > 0 ?
        participantNamesArray.join(", ") :
        "Conversation";

    // Store decisions in Firestore
    const batch = admin.firestore().batch();
    const storedDecisions = [];

    for (const item of decisions) {
      const decisionRef = admin.firestore().collection("decisions").doc();
      const decisionData = {
        id: decisionRef.id,
        summary: item.summary,
        context: item.context,
        participants: item.participants || [],
        tags: item.tags || [],
        conversationId,
        conversationName,
        timestamp: admin.firestore.Timestamp.now(),
        createdBy: "ai",
      };

      batch.set(decisionRef, decisionData);
      storedDecisions.push(decisionData);
    }

    await batch.commit();
    console.log(`   Stored ${storedDecisions.length} decisions in Firestore`);

    const duration = Date.now() - startTime;
    console.log(`✅ Decision extraction completed in ${duration}ms`);

    return {
      decisions: storedDecisions,
      conversationId,
      conversationName,
      messageCount: messages.length,
      extractedAt: admin.firestore.Timestamp.now(),
      duration,
    };
  } catch (error) {
    const duration = Date.now() - startTime;
    console.error(`❌ Decision extraction failed after ${duration}ms:`, error);
    throw error;
  }
}

module.exports = {
  extractDecisions,
};
