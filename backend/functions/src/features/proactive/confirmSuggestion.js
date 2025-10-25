/**
 * Proactive Assistant - Confirm Suggestion
 * Creates calendar event when user accepts a scheduling suggestion
 */

const admin = require("firebase-admin");

/**
 * Confirm a proactive scheduling suggestion
 * Creates calendar event and sends to participants
 * @param {Object} data - Request data
 * @param {Object} context - Function context
 * @return {Promise<Object>} Success response
 */
async function confirmSuggestion(data, context) {
  try {
    // Verify authentication
    if (!context.auth) {
      throw new Error("Unauthenticated");
    }

    const { suggestionId, timeSlot } = data;

    if (!suggestionId || !timeSlot) {
      throw new Error("Missing required fields: suggestionId, timeSlot");
    }

    console.log(`📅 Confirming suggestion: ${suggestionId}`);

    // Get suggestion document
    const suggestionRef = admin.firestore()
        .collection("proactiveSuggestions")
        .doc(suggestionId);

    const suggestionDoc = await suggestionRef.get();

    if (!suggestionDoc.exists) {
      throw new Error(`Suggestion not found: ${suggestionId}`);
    }

    const suggestionData = suggestionDoc.data();

    // Verify user is a participant
    if (!suggestionData.participantIds.includes(context.auth.uid)) {
      throw new Error("User is not a participant in this suggestion");
    }

    // Create calendar event message
    const calendarMessage = await createCalendarEventMessage(
        suggestionData,
        timeSlot,
    );

    // Send calendar event to conversation as a message
    await sendCalendarEventToConversation(
        suggestionData.conversationId,
        calendarMessage,
        context.auth.uid,
    );

    // Update suggestion status to accepted (already done by client, but ensure it)
    await suggestionRef.update({
      status: "accepted",
      acceptedTimeSlot: timeSlot,
      acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
      acceptedBy: context.auth.uid,
    });

    console.log(`   ✅ Suggestion confirmed and calendar event created`);

    return {
      success: true,
      message: "Meeting scheduled successfully",
      calendarMessage,
    };
  } catch (error) {
    console.error(`❌ Failed to confirm suggestion:`, error);
    throw error;
  }
}

/**
 * Create calendar event message
 * Formats the meeting details into a message
 * @param {Object} suggestionData - The suggestion data
 * @param {Object} timeSlot - The selected time slot
 * @return {Promise<string>} Formatted calendar message
 */
async function createCalendarEventMessage(suggestionData, timeSlot) {
  const startTime = new Date(timeSlot.startTime);
  const duration = timeSlot.duration;

  // Format date and time
  const dateStr = startTime.toLocaleDateString("en-US", {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
  });

  const timeStr = startTime.toLocaleTimeString("en-US", {
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
    timeZone: "UTC",
  });

  // Build message
  let message = `📅 **Meeting Scheduled**\n\n`;
  message += `**Purpose:** ${suggestionData.purpose}\n`;
  message += `**When:** ${dateStr} at ${timeStr} UTC\n`;
  message += `**Duration:** ${duration} minutes\n`;
  message += `**Participants:** ${Object.values(suggestionData.participantNames).join(", ")}\n\n`;

  // Add timezone displays
  if (timeSlot.timezoneDisplays && Object.keys(timeSlot.timezoneDisplays).length > 0) {
    message += `**Times by timezone:**\n`;
    const displays = Object.values(timeSlot.timezoneDisplays);
    // Remove duplicates
    const uniqueDisplays = [...new Set(displays)];
    for (const display of uniqueDisplays) {
      message += `• ${display}\n`;
    }
  }

  message += `\nAdd this to your calendar!`;

  return message;
}

/**
 * Send calendar event as a message to the conversation
 * @param {string} conversationId - The conversation ID
 * @param {string} calendarMessage - The formatted calendar message
 * @param {string} senderId - The user who confirmed the meeting
 * @return {Promise<void>}
 */
async function sendCalendarEventToConversation(
    conversationId,
    calendarMessage,
    senderId,
) {
  try {
    console.log(`📨 Sending calendar event to conversation: ${conversationId}`);

    // Get sender's name
    const senderDoc = await admin.firestore()
        .collection("users")
        .doc(senderId)
        .get();

    const senderName = senderDoc.exists ?
      (senderDoc.data().displayName || "AI Assistant") :
      "AI Assistant";

    // Create message document
    const messageData = {
      senderId,
      senderName,
      text: calendarMessage,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: "sent",
      readBy: [senderId], // Mark as read by sender
    };

    // Add to conversation's messages subcollection
    await admin.firestore()
        .collection("conversations")
        .doc(conversationId)
        .collection("messages")
        .add(messageData);

    // Update conversation's last message
    await admin.firestore()
        .collection("conversations")
        .doc(conversationId)
        .update({
          lastMessage: "📅 Meeting scheduled",
          lastMessageTimestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

    console.log(`   ✅ Calendar event message sent to conversation`);
  } catch (error) {
    console.error(`❌ Failed to send calendar event message:`, error);
    throw error;
  }
}

module.exports = {
  confirmSuggestion,
};
