/**
 * Action Item Extraction Feature
 * Extracts structured action items from conversation threads
 * Target: <2 seconds response time
 */

const admin = require("firebase-admin");
const { openai, DEFAULT_MODEL } = require("../ai/openai");
const { ACTION_ITEMS_PROMPT } = require("../ai/prompts");
const { EXTRACT_ACTION_ITEMS_SCHEMA } = require("../ai/tools");

/**
 * Extract action items from a conversation
 * @param {string} conversationId - The conversation to analyze
 * @param {string} userId - The requesting user ID
 * @param {number} messageLimit - Max messages to include (default: 200)
 * @returns {Object} Action items array with metadata
 */
async function extractActionItems(conversationId, userId, messageLimit = 200) {
  console.log(`✅ Starting action item extraction for conversation: ${conversationId}`);
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
        actionItems: [],
        conversationId,
        conversationName: conversation.participantNames ? conversation.participantNames.join(", ") : "Conversation",
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

    // Call OpenAI with function calling to extract structured action items
    console.log(`   Calling OpenAI for action item extraction...`);

    const completion = await openai.chat.completions.create({
      model: DEFAULT_MODEL,
      messages: [
        {
          role: "system",
          content: ACTION_ITEMS_PROMPT,
        },
        {
          role: "user",
          content: `Extract action items from this conversation:\n\n${formattedMessages}`,
        },
      ],
      functions: [EXTRACT_ACTION_ITEMS_SCHEMA],
      function_call: { name: "extract_action_items" },
      temperature: 0.3, // Lower temperature for more consistent extraction
    });

    const functionCall = completion.choices[0].message.function_call;

    if (!functionCall || !functionCall.arguments) {
      console.log(`   No action items found`);
      return {
        actionItems: [],
        conversationId,
        conversationName: conversation.participantNames ? conversation.participantNames.join(", ") : "Conversation",
        messageCount: messages.length,
        extractedAt: admin.firestore.Timestamp.now(),
      };
    }

    const extracted = JSON.parse(functionCall.arguments);
    const actionItems = extracted.actionItems || [];

    console.log(`   Extracted ${actionItems.length} action items`);

    // Store action items in Firestore
    const batch = admin.firestore().batch();
    const storedActionItems = [];

    for (const item of actionItems) {
      const actionItemRef = admin.firestore().collection("actionItems").doc();
      const actionItemData = {
        id: actionItemRef.id,
        description: item.description,
        assignee: item.assignee || "unassigned",
        deadline: item.deadline || "none",
        priority: item.priority || "medium",
        conversationId,
        conversationName: conversation.participantNames ? conversation.participantNames.join(", ") : "Conversation",
        extractedAt: admin.firestore.Timestamp.now(),
        extractedBy: "ai",
        status: "pending",
      };

      batch.set(actionItemRef, actionItemData);
      storedActionItems.push(actionItemData);
    }

    await batch.commit();
    console.log(`   Stored ${storedActionItems.length} action items in Firestore`);

    const duration = Date.now() - startTime;
    console.log(`✅ Action item extraction completed in ${duration}ms`);

    return {
      actionItems: storedActionItems,
      conversationId,
      conversationName: conversation.participantNames ? conversation.participantNames.join(", ") : "Conversation",
      messageCount: messages.length,
      extractedAt: admin.firestore.Timestamp.now(),
      duration,
    };
  } catch (error) {
    const duration = Date.now() - startTime;
    console.error(`❌ Action item extraction failed after ${duration}ms:`, error);
    throw error;
  }
}

module.exports = {
  extractActionItems,
};
