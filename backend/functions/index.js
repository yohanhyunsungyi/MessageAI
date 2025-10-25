/**
 * Firebase Cloud Functions for MessageAI
 * Handles push notifications and AI features
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize Firebase Admin SDK
admin.initializeApp();

// Import AI infrastructure
const { indexMessageInPinecone, classifyPriority } = require("./src/triggers/onMessageCreate");
const { searchMessages } = require("./src/features/vectorSearch");
const { summarizeConversation } = require("./src/features/summarization");
const { extractActionItems } = require("./src/features/actionItems");
const { extractDecisions } = require("./src/features/decisions");
const { parseAndExecuteCommand } = require("./src/features/nlCommands");
const { withRateLimit } = require("./src/middleware/rateLimit");

/**
 * Send push notification when a new message is created
 * Triggers on: /conversations/{conversationId}/messages/{messageId}
 */
exports.sendMessageNotification = functions.firestore
    .document("conversations/{conversationId}/messages/{messageId}")
    .onCreate(async (snap, context) => {
      try {
        const message = snap.data();
        const conversationId = context.params.conversationId;
        const messageId = context.params.messageId;

        console.log(`📬 New message created in conversation: ${conversationId}`);
        console.log(`   Message ID: ${messageId}`);
        console.log(`   Sender: ${message.senderName}`);

        // Index message in Pinecone (non-blocking, best-effort)
        indexMessageInPinecone(message, context).catch((error) => {
          console.error(`⚠️ Background indexing failed: ${error.message}`);
        });

        // Classify message priority and extract action items (await to ensure completion)
        // This must complete before function ends so action items are created
        await classifyPriority(message, context, snap.ref).catch((error) => {
          console.error(`⚠️ Priority classification failed: ${error.message}`);
        });

        // Get conversation to find recipients
        const conversationSnap = await admin.firestore()
            .collection("conversations")
            .doc(conversationId)
            .get();

        if (!conversationSnap.exists) {
          console.error(`❌ Conversation ${conversationId} not found`);
          return null;
        }

        const conversation = conversationSnap.data();
        const recipientIds = conversation.participantIds.filter(
            (id) => id !== message.senderId,
        );

        if (recipientIds.length === 0) {
          console.log("⚠️ No recipients to notify");
          return null;
        }

        console.log(`👥 Notifying ${recipientIds.length} recipient(s)`);

        // Get recipient FCM tokens
        const usersSnap = await admin.firestore()
            .collection("users")
            .where(admin.firestore.FieldPath.documentId(), "in", recipientIds)
            .get();

        const tokens = [];
        usersSnap.forEach((doc) => {
          const fcmToken = doc.data().fcmToken;
          if (fcmToken && fcmToken.trim() !== "") {
            tokens.push(fcmToken);
            console.log(`   ✓ Token found for user: ${doc.id}`);
          }
        });

        if (tokens.length === 0) {
          console.log("⚠️ No valid FCM tokens found for recipients");
          return null;
        }

        // Determine notification priority (will be set by AI classification)
        const messagePriority = message.priority || "normal";
        const isPriorityMessage = messagePriority === "critical" || messagePriority === "high";

        // Prepare notification payload
        const payload = {
          notification: {
            title: isPriorityMessage ?
              `${messagePriority === "critical" ? "🔴" : "🟡"} ${message.senderName}` :
              message.senderName,
            body: message.text,
            sound: isPriorityMessage ? "default" : "default", // Can use different sound for priority
          },
          data: {
            conversationId: conversationId,
            messageId: messageId,
            type: "new_message",
            senderId: message.senderId,
            senderName: message.senderName,
            senderPhotoURL: message.senderPhotoURL || "",
            priority: messagePriority,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          apns: {
            payload: {
              "aps": {
                "badge": 1,
                "sound": "default",
                "content-available": 1,
                "category": "MESSAGE_CATEGORY",
                "alert": isPriorityMessage ? {
                  "title": `${messagePriority === "critical" ? "🔴" : "🟡"} ${message.senderName}`,
                  "body": message.text,
                } : undefined,
              },
              // Add sender image URL for iOS notification attachment
              "sender-image": message.senderPhotoURL || "",
            },
          },
        };

        // Send notification to all recipient tokens
        console.log(`📤 Sending ${isPriorityMessage ? "PRIORITY " : ""}notifications to ${tokens.length} device(s)`);
        if (isPriorityMessage) {
          console.log(`   Priority: ${messagePriority.toUpperCase()}`);
        }

        const response = await admin.messaging().sendToDevice(tokens, payload, {
          priority: isPriorityMessage ? "high" : "normal",
          timeToLive: 60 * 60 * 24, // 24 hours
        });

        // Log results
        console.log(`✅ Notification sent successfully`);
        console.log(`   Success count: ${response.successCount}`);
        console.log(`   Failure count: ${response.failureCount}`);

        // Handle failed tokens (remove invalid tokens)
        if (response.failureCount > 0) {
          const tokensToRemove = [];

          response.results.forEach((result, index) => {
            const error = result.error;
            if (error) {
              console.error(`   ❌ Failed to send to token ${index}: ${error.code}`);

              // Remove invalid tokens
              if (error.code === "messaging/invalid-registration-token" ||
                error.code === "messaging/registration-token-not-registered") {
                tokensToRemove.push(tokens[index]);
              }
            }
          });

          // Clean up invalid tokens from Firestore
          if (tokensToRemove.length > 0) {
            console.log(`🧹 Removing ${tokensToRemove.length} invalid token(s)`);
            const batch = admin.firestore().batch();

            usersSnap.forEach((doc) => {
              const userToken = doc.data().fcmToken;
              if (tokensToRemove.includes(userToken)) {
                batch.update(doc.ref, { fcmToken: "" });
                console.log(`   Removed token for user: ${doc.id}`);
              }
            });

            await batch.commit();
          }
        }

        return response;
      } catch (error) {
        console.error("❌ Error sending notification:", error);
        return null;
      }
    });

/**
 * Clean up typing indicators (optional)
 * Remove typing indicators older than 5 seconds
 */
exports.cleanupTypingIndicators = functions.pubsub
    .schedule("every 5 minutes")
    .onRun(async (context) => {
      const fiveSecondsAgo = Date.now() - 5000;

      try {
        const conversationsSnap = await admin.firestore()
            .collection("conversations")
            .get();

        const batch = admin.firestore().batch();
        let deleteCount = 0;

        for (const convDoc of conversationsSnap.docs) {
          const typingSnap = await convDoc.ref
              .collection("typing")
              .get();

          for (const typingDoc of typingSnap.docs) {
            const timestamp = typingDoc.data().timestamp;
            if (timestamp && timestamp.toMillis() < fiveSecondsAgo) {
              batch.delete(typingDoc.ref);
              deleteCount++;
            }
          }
        }

        if (deleteCount > 0) {
          await batch.commit();
          console.log(`🧹 Cleaned up ${deleteCount} stale typing indicators`);
        }

        return null;
      } catch (error) {
        console.error("❌ Error cleaning typing indicators:", error);
        return null;
      }
    });

/**
 * Update conversation participant count when user joins/leaves (optional)
 */
exports.updateConversationMetadata = functions.firestore
    .document("conversations/{conversationId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();

      // Check if participantIds changed
      if (JSON.stringify(before.participantIds) !== JSON.stringify(after.participantIds)) {
        console.log(`👥 Participant list changed for conversation: ${context.params.conversationId}`);

      // Could add logic here to notify users about participant changes
      // For example: "User X joined the group"
      }

      return null;
    });

/**
 * Test AI Infrastructure
 * Simple callable function to test Cloud Functions and AI setup
 * Call from iOS: functions.httpsCallable("testAI").call()
 */
exports.testAI = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be authenticated to test AI features",
    );
  }

  console.log("🧪 Testing AI infrastructure");
  console.log(`   User ID: ${context.auth.uid}`);

  return {
    success: true,
    message: "AI infrastructure is ready!",
    timestamp: Date.now(),
    userId: context.auth.uid,
  };
});

/**
 * Smart Search - Vector Search with RAG
 * Semantic search across all user's messages
 * Call from iOS: functions.httpsCallable("smartSearch").call({ query: "...", topK: 5 })
 */
exports.smartSearch = functions.https.onCall(
    withRateLimit(async (data, context) => {
      const { query, topK, conversationId } = data;

      if (!query || typeof query !== "string") {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "query is required and must be a string",
        );
      }

      console.log(`🔍 Smart search request from user: ${context.auth.uid}`);
      console.log(`   Query: "${query}"`);

      const results = await searchMessages(query, {
        topK: topK || 5,
        conversationId,
        userId: context.auth.uid,
      });

      return {
        query,
        resultCount: results.length,
        results,
      };
    }, "smart-search"),
);

/**
 * Thread Summarization
 * Summarize conversation threads into key points
 * Call from iOS: functions.httpsCallable("summarizeConversation").call({ conversationId: "...", messageLimit: 200 })
 */
exports.summarizeConversation = functions.https.onCall(
    withRateLimit(async (data, context) => {
      // Verify authentication
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Must be authenticated to summarize conversations",
        );
      }

      const { conversationId, messageLimit } = data;

      if (!conversationId || typeof conversationId !== "string") {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "conversationId is required and must be a string",
        );
      }

      console.log(`📝 Summarization request from user: ${context.auth.uid}`);
      console.log(`   Conversation: ${conversationId}`);

      try {
        const result = await summarizeConversation(
            conversationId,
            context.auth.uid,
            messageLimit || 200,
        );

        return {
          success: true,
          ...result,
        };
      } catch (error) {
        console.error(`❌ Summarization error:`, error);
        throw new functions.https.HttpsError(
            "internal",
            error.message || "Failed to summarize conversation",
        );
      }
    }, "summarization"),
);

/**
 * Action Item Extraction
 * Extract structured action items from conversation threads
 * Call from iOS: functions.httpsCallable("extractActionItems").call({ conversationId: "...", messageLimit: 200 })
 */
exports.extractActionItems = functions.https.onCall(
    withRateLimit(async (data, context) => {
      // Verify authentication
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Must be authenticated to extract action items",
        );
      }

      const { conversationId, messageLimit } = data;

      if (!conversationId || typeof conversationId !== "string") {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "conversationId is required and must be a string",
        );
      }

      console.log(`📋 Action item extraction request from user: ${context.auth.uid}`);
      console.log(`   Conversation: ${conversationId}`);

      try {
        const result = await extractActionItems(
            conversationId,
            context.auth.uid,
            messageLimit || 200,
        );

        return {
          success: true,
          ...result,
        };
      } catch (error) {
        console.error(`❌ Action item extraction error:`, error);
        throw new functions.https.HttpsError(
            "internal",
            error.message || "Failed to extract action items",
        );
      }
    }, "action-items"),
);

/**
 * Decision Tracking
 * Extract key decisions from conversation threads
 * Call from iOS: functions.httpsCallable("extractDecisions").call({ conversationId: "...", messageLimit: 200 })
 */
exports.extractDecisions = functions.https.onCall(
    withRateLimit(async (data, context) => {
      // Verify authentication
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Must be authenticated to extract decisions",
        );
      }

      const { conversationId, messageLimit } = data;

      if (!conversationId || typeof conversationId !== "string") {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "conversationId is required and must be a string",
        );
      }

      console.log(`🎯 Decision extraction request from user: ${context.auth.uid}`);
      console.log(`   Conversation: ${conversationId}`);

      try {
        const result = await extractDecisions(
            conversationId,
            context.auth.uid,
            messageLimit || 200,
        );

        return {
          success: true,
          ...result,
        };
      } catch (error) {
        console.error(`❌ Decision extraction error:`, error);
        throw new functions.https.HttpsError(
            "internal",
            error.message || "Failed to extract decisions",
        );
      }
    }, "decision-tracking"),
);

/**
 * AI Assistant - Natural Language Command Interface
 * Parse user's natural language query and execute appropriate AI feature
 * Call from iOS: functions.httpsCallable("aiAssistant").call({ message: "..." })
 */
exports.aiAssistant = functions.https.onCall(
    withRateLimit(async (data, context) => {
      // Verify authentication
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Must be authenticated to use AI assistant",
        );
      }

      const { message, context: userContext } = data;

      if (!message || typeof message !== "string") {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "message is required and must be a string",
        );
      }

      console.log(`🤖 AI Assistant request from user: ${context.auth.uid}`);
      console.log(`   Message: "${message}"`);

      try {
        const result = await parseAndExecuteCommand(
            message,
            context.auth.uid,
            userContext || {},
        );

        return {
          success: true,
          ...result,
        };
      } catch (error) {
        console.error(`❌ AI Assistant error:`, error);
        throw new functions.https.HttpsError(
            "internal",
            error.message || "Failed to process AI assistant request",
        );
      }
    }, "ai-assistant"),
);

