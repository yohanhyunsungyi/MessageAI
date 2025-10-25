/**
 * Priority Message Classification
 * Analyzes message urgency in real-time
 */

const { openai, DEFAULT_MODEL } = require("../ai/openai");
const { PRIORITY_CLASSIFICATION_PROMPT } = require("../ai/prompts");

/**
 * Classify message priority using LLM
 * Fast classification (<500ms target) for real-time processing
 * @param {Object} message - Message data from Firestore
 * @param {Object} context - Additional context (conversation, sender)
 * @return {Promise<Object>} Classification result
 */
async function classifyMessagePriority(message, context = {}) {
  try {
    const messagePreview = message.text ? message.text.substring(0, 50) : "";
    console.log(`🎯 Classifying priority for message: ${messagePreview}...`);

    // Prepare message content for classification
    const conversationInfo = context.conversationName ?
      `Conversation: ${context.conversationName}` : "";
    const messageContent = `
Message: "${message.text}"
Sender: ${message.senderName || "Unknown"}
Timestamp: ${new Date().toISOString()}
${conversationInfo}
`;

    // Call OpenAI for fast classification
    const completion = await openai.chat.completions.create({
      model: DEFAULT_MODEL,
      messages: [
        { role: "system", content: PRIORITY_CLASSIFICATION_PROMPT },
        { role: "user", content: messageContent },
      ],
      temperature: 0.3, // Lower temperature for consistent classification
      max_tokens: 50, // We only need one word: critical, high, or normal
    });

    const classification = completion.choices[0].message.content.trim().toLowerCase();

    // Validate classification
    const validPriorities = ["critical", "high", "normal"];
    let priority = "normal"; // Default
    let confidence = 0.7;

    if (validPriorities.includes(classification)) {
      priority = classification;
      confidence = 0.9;
    } else {
      // Try to extract priority from response
      for (const p of validPriorities) {
        if (classification.includes(p)) {
          priority = p;
          confidence = 0.8;
          break;
        }
      }
    }

    // Additional rule-based checks for higher confidence
    const textLower = message.text ? message.text.toLowerCase() : "";
    const urgencyKeywords = {
      critical: ["production down", "system failure", "critical bug", "urgent fix", "emergency"],
      high: ["urgent", "asap", "blocked", "blocker", "immediately", "critical", "important"],
    };

    // Boost priority if urgent keywords found
    if (urgencyKeywords.critical.some((kw) => textLower.includes(kw))) {
      priority = "critical";
      confidence = 0.95;
    } else if (priority === "normal" && urgencyKeywords.high.some((kw) => textLower.includes(kw))) {
      priority = "high";
      confidence = 0.85;
    }

    console.log(`   ✓ Priority: ${priority} (confidence: ${confidence})`);

    return {
      priority,
      confidence,
      classifiedAt: new Date().toISOString(),
      aiClassified: true,
    };
  } catch (error) {
    console.error(`❌ Priority classification error:`, error);
    // Return default on error - don't block message flow
    return {
      priority: "normal",
      confidence: 0.5,
      classifiedAt: new Date().toISOString(),
      aiClassified: false,
      error: error.message,
    };
  }
}

module.exports = {
  classifyMessagePriority,
};
