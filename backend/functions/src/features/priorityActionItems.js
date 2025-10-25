/**
 * Automatic Action Item Creation for Priority Messages
 * Extracts action items from high/critical priority messages
 */

const admin = require("firebase-admin");
const { openai, DEFAULT_MODEL } = require("../ai/openai");
const { EXTRACT_ACTION_ITEMS_SCHEMA } = require("../ai/tools");

/**
 * Extract action items from a single priority message
 * @param {Object} message - The priority message
 * @param {string} conversationId - Conversation ID
 * @return {Promise<Array>} Extracted action items
 */
async function extractActionItemsFromPriorityMessage(message, conversationId) {
  try {
    console.log(`📋 Extracting action items from priority message: ${message.text.substring(0, 50)}...`);

    // Quick check: does the message contain actionable language?
    const actionKeywords = ["need", "must", "should", "todo", "task", "fix", "urgent", "asap", "please"];
    const textLower = message.text.toLowerCase();
    const hasActionKeyword = actionKeywords.some((keyword) => textLower.includes(keyword));

    if (!hasActionKeyword) {
      console.log(`   ⚠️ No action keywords found - skipping extraction`);
      return [];
    }

    // Call OpenAI to extract action items from this single message
    const prompt = `Extract action items from this urgent message.

Message from ${message.senderName}:
"${message.text}"

Identify any tasks, TODOs, or action items that need to be done.`;

    const completion = await openai.chat.completions.create({
      model: DEFAULT_MODEL,
      messages: [
        {
          role: "system",
          content: "You are a task extraction assistant. Extract concrete action items from urgent messages.",
        },
        {
          role: "user",
          content: prompt,
        },
      ],
      functions: [EXTRACT_ACTION_ITEMS_SCHEMA],
      function_call: { name: "extract_action_items" },
      temperature: 0.3,
      max_tokens: 500,
    });

    // Parse function call response
    const functionCall = completion.choices[0].message.function_call;
    if (!functionCall || !functionCall.arguments) {
      console.log(`   ⚠️ No action items extracted`);
      return [];
    }

    const result = JSON.parse(functionCall.arguments);
    const actionItems = result.action_items || [];

    if (actionItems.length === 0) {
      console.log(`   ℹ️ No action items found in message`);
      return [];
    }

    console.log(`   ✅ Extracted ${actionItems.length} action item(s)`);

    // Save action items to Firestore
    const batch = admin.firestore().batch();
    const savedItems = [];

    for (const item of actionItems) {
      const actionItemRef = admin.firestore()
          .collection("conversations")
          .doc(conversationId)
          .collection("actionItems")
          .doc();

      const actionItemData = {
        id: actionItemRef.id,
        conversationId: conversationId,
        description: item.description || "",
        assignee: item.assignee || null,
        deadline: item.deadline || null,
        priority: item.priority || "medium",
        status: "pending",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdFrom: "priority-message",
        sourceMessageId: message.id || null,
        extractedBy: "ai",
      };

      batch.set(actionItemRef, actionItemData);
      savedItems.push(actionItemData);

      console.log(`   📝 Action item: ${item.description}`);
    }

    await batch.commit();
    console.log(`   ✅ Saved ${savedItems.length} action items to Firestore`);

    return savedItems;
  } catch (error) {
    console.error(`❌ Failed to extract action items from priority message:`, error);
    console.error(`   Error: ${error.message}`);
    return []; // Don't block the message flow
  }
}

module.exports = {
  extractActionItemsFromPriorityMessage,
};
