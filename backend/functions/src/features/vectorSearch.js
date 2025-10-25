/**
 * Vector Search Feature
 * Semantic search across all messages using RAG pipeline
 */

const { generateEmbedding } = require("../ai/embeddings");
const { searchSimilarMessages } = require("../ai/pinecone");
const admin = require("firebase-admin");

/**
 * Search messages using semantic similarity
 * @param {string} query - User's search query
 * @param {Object} options - Search options
 * @param {number} options.topK - Number of results (default: 5)
 * @param {string} options.conversationId - Optional conversation filter
 * @param {string} options.userId - User ID for permission check
 * @return {Promise<Array>} Matching messages with scores
 */
async function searchMessages(query, options = {}) {
  const { topK = 5, conversationId, userId } = options;

  try {
    console.log(`🔍 Searching for: "${query}"`);
    if (conversationId) {
      console.log(`   Filtering by conversation: ${conversationId}`);
    }

    // Generate embedding for search query
    const queryEmbedding = await generateEmbedding(query);

    // Search in Pinecone
    const pineconeResults = await searchSimilarMessages(queryEmbedding, {
      topK: topK * 2, // Get more results for filtering
      conversationId,
    });

    if (pineconeResults.length === 0) {
      console.log(`   No results found`);
      return [];
    }

    console.log(`   Found ${pineconeResults.length} potential matches`);

    // Filter results by user permissions (check conversation access)
    const accessibleResults = await filterByUserPermissions(
        pineconeResults,
        userId,
    );

    // Filter to only show results with 50%+ relevance (score >= 0.5)
    const relevantResults = accessibleResults.filter((result) => result.score >= 0.5);

    console.log(`   Filtered by relevance (>=50%): ${accessibleResults.length} → ${relevantResults.length}`);

    // Return top K results with formatted data
    const formattedResults = relevantResults.slice(0, topK).map((result) => ({
      messageId: result.id,
      score: result.score,
      conversationId: result.metadata.conversationId,
      senderId: result.metadata.senderId,
      senderName: result.metadata.senderName,
      text: result.metadata.text,
      timestamp: result.metadata.timestamp,
    }));

    console.log(`✅ Returning ${formattedResults.length} results`);
    return formattedResults;
  } catch (error) {
    console.error("❌ Search failed:", error);
    throw new Error(`Search failed: ${error.message}`);
  }
}

/**
 * Filter search results by user's conversation access
 * @param {Array} results - Pinecone search results
 * @param {string} userId - User ID
 * @return {Promise<Array>} Filtered results
 */
async function filterByUserPermissions(results, userId) {
  if (!results || results.length === 0) {
    return [];
  }

  // Fetch user's accessible conversations
  const conversationsSnap = await admin
      .firestore()
      .collection("conversations")
      .where("participantIds", "array-contains", userId)
      .get();

  const accessibleConversationIds = new Set(
      conversationsSnap.docs.map((doc) => doc.id),
  );

  // Filter results to only accessible conversations
  const filtered = results.filter((result) =>
    accessibleConversationIds.has(result.metadata.conversationId),
  );

  console.log(`   Filtered ${results.length} → ${filtered.length} (user access)`);
  return filtered;
}

module.exports = {
  searchMessages,
  filterByUserPermissions,
};
