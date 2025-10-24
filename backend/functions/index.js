/**
 * Firebase Cloud Functions for MessageAI
 * Handles push notifications and AI features
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize Firebase Admin SDK
admin.initializeApp();

// Import AI infrastructure (for future use)
// const {openai} = require("./src/ai/openai");
// const {pinecone} = require("./src/ai/pinecone");

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

        // Prepare notification payload
        const payload = {
          notification: {
            title: message.senderName,
            body: message.text,
            sound: "default",
          },
          data: {
            conversationId: conversationId,
            messageId: messageId,
            type: "new_message",
            senderId: message.senderId,
            senderName: message.senderName,
            senderPhotoURL: message.senderPhotoURL || "",
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          apns: {
            payload: {
              "aps": {
                "badge": 1,
                "sound": "default",
                "content-available": 1,
                "category": "MESSAGE_CATEGORY",
              },
              // Add sender image URL for iOS notification attachment
              "sender-image": message.senderPhotoURL || "",
            },
          },
        };

        // Send notification to all recipient tokens
        console.log(`📤 Sending notifications to ${tokens.length} device(s)`);

        const response = await admin.messaging().sendToDevice(tokens, payload, {
          priority: "high",
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

