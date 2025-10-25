/**
 * Natural Language Command Parser
 * Parses user intent from chat messages to AI Assistant
 * Maps queries to specific AI features
 */

const { openai, DEFAULT_MODEL } = require("../ai/openai");
const { NL_COMMAND_PARSER_PROMPT } = require("../ai/prompts");
const { summarizeConversation } = require("./summarization");
const { extractActionItems } = require("./actionItems");
const { searchMessages } = require("./vectorSearch");
const { extractDecisions } = require("./decisions");

/**
 * Parse natural language command and execute appropriate action
 * @param {string} userMessage - The user's natural language query
 * @param {string} userId - The requesting user ID
 * @param {Object} context - Additional context (optional)
 * @returns {Object} Response with intent and result
 */
async function parseAndExecuteCommand(userMessage, userId, context = {}) {
  console.log(`🤖 Parsing command from user: ${userId}`);
  console.log(`   Message: "${userMessage}"`);

  const startTime = Date.now();

  try {
    // Check if OpenAI is configured
    if (!openai) {
      throw new Error("OpenAI client not initialized. Please configure API key.");
    }

    // Step 1: Parse intent using LLM
    const intentResponse = await openai.chat.completions.create({
      model: DEFAULT_MODEL,
      messages: [
        {
          role: "system",
          content: NL_COMMAND_PARSER_PROMPT,
        },
        {
          role: "user",
          content: userMessage,
        },
      ],
      temperature: 0.3, // Lower temperature for more consistent parsing
      max_tokens: 200,
    });

    const intentText = intentResponse.choices[0].message.content;
    console.log(`   Intent parsed: ${intentText}`);

    // Parse the JSON response
    let intent;
    try {
      intent = JSON.parse(intentText);
    } catch (parseError) {
      console.error(`⚠️ Failed to parse intent JSON: ${parseError.message}`);
      // Fallback: treat as general query
      intent = { action: "general_query", parameters: {} };
    }

    // Step 2: Execute the appropriate action
    let result;
    let responseMessage;

    switch (intent.action) {
      case "summarize_conversation":
        result = await handleSummarization(intent, userId);
        responseMessage = formatSummarizationResponse(result);
        break;

      case "extract_action_items":
        result = await handleActionItems(intent, userId);
        responseMessage = formatActionItemsResponse(result);
        break;

      case "search_messages":
        result = await handleSearch(intent, userId);
        responseMessage = formatSearchResponse(result, intent.parameters.query);
        break;

      case "extract_decisions":
        result = await handleDecisions(intent, userId);
        responseMessage = formatDecisionsResponse(result);
        break;

      case "list_action_items":
        result = await listUserActionItems(userId);
        responseMessage = formatActionItemsListResponse(result);
        break;

      case "general_query":
      default:
        responseMessage = await handleGeneralQuery(userMessage, userId);
        result = { type: "general_response" };
        break;
    }

    const duration = Date.now() - startTime;
    console.log(`✅ Command executed in ${duration}ms`);
    console.log(`   Action: ${intent.action}`);

    return {
      success: true,
      intent: intent.action,
      parameters: intent.parameters,
      response: responseMessage,
      result,
      duration,
    };
  } catch (error) {
    const duration = Date.now() - startTime;
    console.error(`❌ Command parsing failed after ${duration}ms`);
    console.error(`   Error name: ${error.name}`);
    console.error(`   Error message: ${error.message}`);
    console.error(`   Error stack:`, error.stack);

    // Re-throw with more context
    const enhancedError = new Error(`AI Assistant error: ${error.message}`);
    enhancedError.originalError = error;
    throw enhancedError;
  }
}

/**
 * Handle summarization request
 */
async function handleSummarization(intent, userId) {
  const admin = require("firebase-admin");
  let { conversationId, messageLimit } = intent.parameters;

  // If no conversation ID specified, try to get the user's latest conversation
  if (!conversationId) {
    console.log(`   No conversation ID specified, fetching latest conversation for user`);

    const conversationsSnap = await admin.firestore()
        .collection("conversations")
        .where("participantIds", "array-contains", userId)
        .orderBy("lastMessageTimestamp", "desc")
        .limit(1)
        .get();

    if (conversationsSnap.empty) {
      throw new Error("No conversations found. Please send some messages first!");
    }

    conversationId = conversationsSnap.docs[0].id;
    console.log(`   Using latest conversation: ${conversationId}`);
  }

  return await summarizeConversation(conversationId, userId, messageLimit || 200);
}

/**
 * Handle action items extraction
 */
async function handleActionItems(intent, userId) {
  const admin = require("firebase-admin");
  let { conversationId, messageLimit } = intent.parameters;

  // If no conversation ID specified, try to get the user's latest conversation
  if (!conversationId) {
    console.log(`   No conversation ID specified, fetching latest conversation for user`);

    const conversationsSnap = await admin.firestore()
        .collection("conversations")
        .where("participantIds", "array-contains", userId)
        .orderBy("lastMessageTimestamp", "desc")
        .limit(1)
        .get();

    if (conversationsSnap.empty) {
      throw new Error("No conversations found. Please send some messages first!");
    }

    conversationId = conversationsSnap.docs[0].id;
    console.log(`   Using latest conversation: ${conversationId}`);
  }

  return await extractActionItems(conversationId, userId, messageLimit || 200);
}

/**
 * Handle search request
 */
async function handleSearch(intent, userId) {
  const { query, conversationId, topK } = intent.parameters;

  if (!query) {
    throw new Error("No search query provided.");
  }

  return await searchMessages(query, {
    topK: topK || 5,
    conversationId,
    userId,
  });
}

/**
 * Handle decisions extraction
 */
async function handleDecisions(intent, userId) {
  const admin = require("firebase-admin");
  let { conversationId, messageLimit } = intent.parameters;

  // If no conversation ID specified, try to get the user's latest conversation
  if (!conversationId) {
    console.log(`   No conversation ID specified, fetching latest conversation for user`);

    const conversationsSnap = await admin.firestore()
        .collection("conversations")
        .where("participantIds", "array-contains", userId)
        .orderBy("lastMessageTimestamp", "desc")
        .limit(1)
        .get();

    if (conversationsSnap.empty) {
      throw new Error("No conversations found. Please send some messages first!");
    }

    conversationId = conversationsSnap.docs[0].id;
    console.log(`   Using latest conversation: ${conversationId}`);
  }

  return await extractDecisions(conversationId, userId, messageLimit || 200);
}

/**
 * List user's action items
 * NOTE: Currently assignee is stored as a display name (string), not userId
 * So we fetch all pending items and let the client filter by user
 * TODO: Update action item extraction to store assignee as userId for proper filtering
 */
async function listUserActionItems(userId) {
  const admin = require("firebase-admin");

  console.log(`   Fetching action items for user: ${userId}`);

  // Get user's display name to match against assignee field
  let userDisplayName = null;
  try {
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    if (userDoc.exists) {
      userDisplayName = userDoc.data().displayName;
      console.log(`   User display name: ${userDisplayName}`);
    }
  } catch (error) {
    console.warn(`   Could not fetch user display name: ${error.message}`);
  }

  // Fetch all pending action items (can't filter by assignee since it's a name, not userId)
  const actionItemsSnap = await admin.firestore()
      .collection("actionItems")
      .where("status", "==", "pending")
      .limit(50)
      .get();

  console.log(`   Found ${actionItemsSnap.size} pending action items total`);

  const actionItems = [];
  actionItemsSnap.forEach((doc) => {
    const data = doc.data();
    // If we have the user's display name, try to filter by it
    // Otherwise, include all items (better to show too many than none)
    if (!userDisplayName || data.assignee === userDisplayName || data.assignee === "unassigned") {
      actionItems.push({ id: doc.id, ...data });
    }
  });

  console.log(`   Filtered to ${actionItems.length} items for this user`);

  // Sort by priority in-memory (high > medium > low)
  const priorityOrder = { high: 3, medium: 2, low: 1 };
  actionItems.sort((a, b) => {
    const aPriority = priorityOrder[a.priority] || 0;
    const bPriority = priorityOrder[b.priority] || 0;
    return bPriority - aPriority;
  });

  // Return top 10
  return actionItems.slice(0, 10);
}

/**
 * Handle general queries with conversational AI
 */
async function handleGeneralQuery(userMessage, userId) {
  const completion = await openai.chat.completions.create({
    model: DEFAULT_MODEL,
    messages: [
      {
        role: "system",
        content: `You are a helpful AI assistant for MessageAI, a team messaging app.
You can help users with:
- Summarizing conversations
- Finding action items
- Searching messages
- Tracking decisions

Be concise and helpful. Suggest specific commands when appropriate.`,
      },
      {
        role: "user",
        content: userMessage,
      },
    ],
    temperature: 0.7,
    max_tokens: 300,
  });

  return completion.choices[0].message.content;
}

/**
 * Format responses for the UI
 */
function formatSummarizationResponse(result) {
  const { keyPoints, messageCount } = result;

  let response = `📝 **Conversation Summary** (${messageCount} messages)\n\n`;
  response += `**Key Points:**\n`;

  keyPoints.forEach((point) => {
    response += `• ${point}\n`;
  });

  return response.trim();
}

function formatActionItemsResponse(result) {
  const { actionItems } = result;

  if (!actionItems || actionItems.length === 0) {
    return "✅ No action items found in this conversation.";
  }

  let response = `📋 **Action Items Found** (${actionItems.length})\n\n`;

  actionItems.slice(0, 5).forEach((item, index) => {
    const priorityEmoji = item.priority === "high" ? "🔴" : item.priority === "medium" ? "🟡" : "🟢";
    response += `${index + 1}. ${priorityEmoji} ${item.description}\n`;
    if (item.assignee) {
      response += `   Assignee: ${item.assignee}\n`;
    }
    if (item.deadline) {
      response += `   Due: ${item.deadline}\n`;
    }
    response += `\n`;
  });

  if (actionItems.length > 5) {
    response += `\n_...and ${actionItems.length - 5} more. Check the Action Items tab to see all._`;
  }

  return response.trim();
}

function formatSearchResponse(results, query) {
  if (!results || results.length === 0) {
    return `🔍 No results found for "${query}"`;
  }

  let response = `🔍 **Search Results** for "${query}"\n\n`;

  results.slice(0, 5).forEach((result, index) => {
    response += `${index + 1}. ${result.text.substring(0, 100)}...\n`;
    response += `   From: ${result.senderName} • Relevance: ${Math.round(result.score * 100)}%\n\n`;
  });

  if (results.length > 5) {
    response += `\n_...and ${results.length - 5} more results._`;
  }

  return response.trim();
}

function formatDecisionsResponse(result) {
  const { decisions } = result;

  if (!decisions || decisions.length === 0) {
    return "💡 No decisions found in this conversation.";
  }

  let response = `💡 **Decisions Tracked** (${decisions.length})\n\n`;

  decisions.slice(0, 3).forEach((decision, index) => {
    response += `${index + 1}. **${decision.summary}**\n`;
    response += `   ${decision.context}\n`;
    if (decision.tags && decision.tags.length > 0) {
      response += `   Tags: ${decision.tags.join(", ")}\n`;
    }
    response += `\n`;
  });

  if (decisions.length > 3) {
    response += `\n_...and ${decisions.length - 3} more. Check the Decisions tab to see all._`;
  }

  return response.trim();
}

function formatActionItemsListResponse(actionItems) {
  if (!actionItems || actionItems.length === 0) {
    return "✅ You have no pending action items!";
  }

  let response = `📋 **Your Action Items** (${actionItems.length})\n\n`;

  actionItems.forEach((item, index) => {
    const priorityEmoji = item.priority === "high" ? "🔴" : item.priority === "medium" ? "🟡" : "🟢";
    response += `${index + 1}. ${priorityEmoji} ${item.description}\n`;
    if (item.deadline) {
      response += `   Due: ${item.deadline}\n`;
    }
    response += `\n`;
  });

  return response.trim();
}

module.exports = {
  parseAndExecuteCommand,
};
