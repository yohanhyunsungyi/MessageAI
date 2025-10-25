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
    console.error(`❌ Command parsing failed after ${duration}ms:`, error);
    throw error;
  }
}

/**
 * Handle summarization request
 */
async function handleSummarization(intent, userId) {
  const { conversationId, messageLimit } = intent.parameters;

  if (!conversationId) {
    throw new Error("No conversation ID specified. Please specify which conversation to summarize.");
  }

  return await summarizeConversation(conversationId, userId, messageLimit || 200);
}

/**
 * Handle action items extraction
 */
async function handleActionItems(intent, userId) {
  const { conversationId, messageLimit } = intent.parameters;

  if (!conversationId) {
    throw new Error("No conversation ID specified. Please specify which conversation to analyze.");
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
  const { conversationId, messageLimit } = intent.parameters;

  if (!conversationId) {
    throw new Error("No conversation ID specified. Please specify which conversation to analyze.");
  }

  return await extractDecisions(conversationId, userId, messageLimit || 200);
}

/**
 * List user's action items
 */
async function listUserActionItems(userId) {
  const admin = require("firebase-admin");

  const actionItemsSnap = await admin.firestore()
      .collection("actionItems")
      .where("assignee", "==", userId)
      .where("status", "==", "pending")
      .orderBy("priority", "desc")
      .limit(10)
      .get();

  const actionItems = [];
  actionItemsSnap.forEach((doc) => {
    actionItems.push({ id: doc.id, ...doc.data() });
  });

  return actionItems;
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
