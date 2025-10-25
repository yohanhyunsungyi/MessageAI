/**
 * Rate Limiting Middleware
 * Tracks and enforces AI usage limits per user
 */

const admin = require("firebase-admin");
const functions = require("firebase-functions");

/**
 * Rate limit configuration
 */
const RATE_LIMITS = {
  PER_MINUTE: 10, // Max 10 AI calls per minute
  PER_DAY: 100, // Max 100 AI calls per day
};

/**
 * Check if user has exceeded rate limits
 * @param {string} userId - User ID to check
 * @param {string} feature - AI feature name (for tracking)
 * @return {Promise<{allowed: boolean, reason: string}>}
 */
async function checkRateLimit(userId, feature = "ai") {
  try {
    const now = Date.now();
    const oneMinuteAgo = now - 60 * 1000;
    const oneDayAgo = now - 24 * 60 * 60 * 1000;

    // Get user's AI usage from Firestore
    const usageRef = admin.firestore()
        .collection("users")
        .doc(userId)
        .collection("aiUsage");

    // Count calls in last minute
    const minuteSnapshot = await usageRef
        .where("timestamp", ">", oneMinuteAgo)
        .count()
        .get();

    const callsPerMinute = minuteSnapshot.data().count;

    if (callsPerMinute >= RATE_LIMITS.PER_MINUTE) {
      return {
        allowed: false,
        reason: `Rate limit exceeded: ${RATE_LIMITS.PER_MINUTE} calls per minute. Please try again in a moment.`,
      };
    }

    // Count calls in last day
    const daySnapshot = await usageRef
        .where("timestamp", ">", oneDayAgo)
        .count()
        .get();

    const callsPerDay = daySnapshot.data().count;

    if (callsPerDay >= RATE_LIMITS.PER_DAY) {
      return {
        allowed: false,
        reason: `Daily limit exceeded: ${RATE_LIMITS.PER_DAY} calls per day. Limit resets in 24 hours.`,
      };
    }

    return { allowed: true, reason: "" };
  } catch (error) {
    console.error("❌ Error checking rate limit:", error);
    // On error, allow the request (fail open)
    return { allowed: true, reason: "" };
  }
}

/**
 * Record an AI usage event
 * @param {string} userId - User ID
 * @param {string} feature - AI feature used
 * @param {Object} metadata - Additional tracking data
 * @return {Promise<void>}
 */
async function recordUsage(userId, feature, metadata = {}) {
  try {
    const usageRef = admin.firestore()
        .collection("users")
        .doc(userId)
        .collection("aiUsage");

    await usageRef.add({
      feature: feature,
      timestamp: Date.now(),
      ...metadata,
    });

    console.log(`📊 Recorded AI usage: ${userId} - ${feature}`);
  } catch (error) {
    console.error("❌ Error recording usage:", error);
    // Don't throw - usage tracking is not critical
  }
}

/**
 * Middleware wrapper for Cloud Functions
 * Enforces rate limits before executing function
 * @param {Function} handler - The actual function handler
 * @param {string} feature - Feature name for tracking
 * @return {Function} Wrapped handler with rate limiting
 */
function withRateLimit(handler, feature = "ai") {
  return async (data, context) => {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
          "unauthenticated",
          "Must be authenticated to use AI features",
      );
    }

    const userId = context.auth.uid;

    // Check rate limit
    const { allowed, reason } = await checkRateLimit(userId, feature);

    if (!allowed) {
      throw new functions.https.HttpsError(
          "resource-exhausted",
          reason,
      );
    }

    // Execute the handler
    const startTime = Date.now();
    const result = await handler(data, context);
    const duration = Date.now() - startTime;

    // Record usage
    await recordUsage(userId, feature, {
      duration,
      success: true,
    });

    return result;
  };
}

module.exports = {
  checkRateLimit,
  recordUsage,
  withRateLimit,
  RATE_LIMITS,
};
