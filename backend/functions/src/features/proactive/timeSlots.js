/**
 * Proactive Assistant - Time Slot Generation
 * Generates optimal meeting time suggestions across multiple time zones
 */

const admin = require("firebase-admin");

/**
 * Get user's timezone from their profile
 * @param {string} userId - The user ID
 * @return {Promise<string>} User's timezone identifier or default
 */
async function getUserTimezone(userId) {
  try {
    const userDoc = await admin.firestore()
        .collection("users")
        .doc(userId)
        .get();

    if (!userDoc.exists) {
      console.warn(`⚠️ User not found: ${userId}, using default timezone`);
      return "America/Los_Angeles"; // Default to PST
    }

    const userData = userDoc.data();
    return userData.timezone || "America/Los_Angeles"; // Default to PST if not set
  } catch (error) {
    console.error(`❌ Failed to get timezone for user ${userId}:`, error.message);
    return "America/Los_Angeles";
  }
}

/**
 * Get timezones for all participants
 * @param {Array<string>} participantIds - Array of user IDs
 * @return {Promise<Object>} Map of userId to timezone
 */
async function getParticipantTimezones(participantIds) {
  try {
    console.log(`🌍 Fetching timezones for ${participantIds.length} participants`);

    const timezones = {};
    for (const userId of participantIds) {
      timezones[userId] = await getUserTimezone(userId);
    }

    console.log(`   ✅ Timezones fetched:`, timezones);
    return timezones;
  } catch (error) {
    console.error(`❌ Failed to fetch participant timezones:`, error);
    throw error;
  }
}

/**
 * Check if a time is within typical working hours for a timezone
 * @param {Date} time - The time to check
 * @param {string} timezone - The timezone identifier
 * @return {boolean} True if within working hours
 */
function isWorkingHours(time, timezone) {
  try {
    // Convert to timezone-specific time
    const timeStr = time.toLocaleString("en-US", { timeZone: timezone, hour12: false });
    const hour = parseInt(timeStr.split(",")[1].trim().split(":")[0]);

    // Working hours: 9 AM - 6 PM
    return hour >= 9 && hour < 18;
  } catch (error) {
    console.error(`⚠️ Error checking working hours:`, error.message);
    return false;
  }
}

/**
 * Generate candidate time slots
 * @param {number} daysOut - How many days in the future to start
 * @param {number} duration - Meeting duration in minutes
 * @return {Array<Date>} Array of candidate start times
 */
function generateCandidateSlots(daysOut = 2, duration = 60) {
  const slots = [];
  const now = new Date();

  // Generate slots for next 7 days, starting from daysOut
  for (let day = daysOut; day < daysOut + 7; day++) {
    const date = new Date(now);
    date.setDate(date.getDate() + day);

    // Try times: 9am, 10am, 11am, 1pm, 2pm, 3pm, 4pm (UTC)
    const hours = [9, 10, 11, 13, 14, 15, 16];

    for (const hour of hours) {
      const slot = new Date(date);
      slot.setHours(hour, 0, 0, 0);
      slots.push(slot);
    }
  }

  return slots;
}

/**
 * Filter slots that work for all participants
 * @param {Array<Date>} candidateSlots - Candidate time slots
 * @param {Object} participantTimezones - Map of userId to timezone
 * @return {Array<Date>} Filtered slots that work for everyone
 */
function filterSlotsForAllTimezones(candidateSlots, participantTimezones) {
  const validSlots = [];

  for (const slot of candidateSlots) {
    let worksForAll = true;

    // Check if slot is during working hours for all participants
    for (const timezone of Object.values(participantTimezones)) {
      if (!isWorkingHours(slot, timezone)) {
        worksForAll = false;
        break;
      }
    }

    if (worksForAll) {
      validSlots.push(slot);
    }
  }

  return validSlots;
}

/**
 * Format time slot for display in all timezones
 * @param {Date} startTime - The start time
 * @param {number} duration - Duration in minutes
 * @param {Object} participantTimezones - Map of userId to timezone
 * @return {Object} Formatted time slot with timezone displays
 */
function formatTimeSlot(startTime, duration, participantTimezones) {
  const timezoneDisplays = {};

  for (const [participantId, timezone] of Object.entries(participantTimezones)) {
    try {
      // Format time for this timezone
      const timeStr = startTime.toLocaleString("en-US", {
        timeZone: timezone,
        hour: "numeric",
        minute: "2-digit",
        hour12: true,
        weekday: "short",
        month: "short",
        day: "numeric",
      });

      // Get timezone abbreviation
      const tzAbbr = startTime.toLocaleString("en-US", {
        timeZone: timezone,
        timeZoneName: "short",
      }).split(" ").pop();

      timezoneDisplays[participantId] = `${timeStr} ${tzAbbr}`;
    } catch (error) {
      console.error(`⚠️ Error formatting time for timezone ${timezone}:`, error.message);
      timezoneDisplays[participantId] = startTime.toISOString();
    }
  }

  return {
    startTime: startTime.toISOString(),
    duration,
    timezoneDisplays,
  };
}

/**
 * Generate optimal time slot suggestions
 * @param {Array<string>} participantIds - Array of user IDs
 * @param {number} duration - Meeting duration in minutes (default: 60)
 * @param {number} daysOut - Days in future to start suggestions (default: 2)
 * @return {Promise<Array<Object>>} Array of time slot suggestions
 */
async function generateTimeSlots(participantIds, duration = 60, daysOut = 2) {
  try {
    console.log(`⏰ Generating time slots for ${participantIds.length} participants`);
    console.log(`   Duration: ${duration} minutes, Starting ${daysOut} days out`);

    // Step 1: Get all participant timezones
    const participantTimezones = await getParticipantTimezones(participantIds);

    // Step 2: Generate candidate slots
    const candidateSlots = generateCandidateSlots(daysOut, duration);
    console.log(`   Generated ${candidateSlots.length} candidate slots`);

    // Step 3: Filter slots that work for all timezones
    const validSlots = filterSlotsForAllTimezones(candidateSlots, participantTimezones);
    console.log(`   Found ${validSlots.length} valid slots for all timezones`);

    if (validSlots.length === 0) {
      console.warn(`⚠️ No valid time slots found for all participants`);
      return [];
    }

    // Step 4: Take top 3 slots
    const topSlots = validSlots.slice(0, 3);

    // Step 5: Format slots for display
    const formattedSlots = topSlots.map((slot) =>
      formatTimeSlot(slot, duration, participantTimezones),
    );

    console.log(`   ✅ Generated ${formattedSlots.length} time slot suggestions`);
    return formattedSlots;
  } catch (error) {
    console.error(`❌ Time slot generation failed:`, error);
    throw error;
  }
}

/**
 * Update proactive suggestion with time slots
 * @param {string} suggestionId - The suggestion document ID
 * @param {Array<Object>} timeSlots - Array of time slot suggestions
 * @return {Promise<void>}
 */
async function updateSuggestionWithTimeSlots(suggestionId, timeSlots) {
  try {
    console.log(`💾 Updating suggestion ${suggestionId} with ${timeSlots.length} time slots`);

    await admin.firestore()
        .collection("proactiveSuggestions")
        .doc(suggestionId)
        .update({
          suggestedTimeSlots: timeSlots,
          timeSlotsGeneratedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

    console.log(`   ✅ Suggestion updated with time slots`);
  } catch (error) {
    console.error(`❌ Failed to update suggestion with time slots:`, error);
    throw error;
  }
}

/**
 * Generate time slots for a proactive suggestion
 * This is the main entry point called after detection
 * @param {string} suggestionId - The suggestion document ID
 * @return {Promise<Array<Object>>} Generated time slots
 */
async function generateTimeSlotsForSuggestion(suggestionId) {
  try {
    console.log(`🔧 Generating time slots for suggestion: ${suggestionId}`);

    // Get suggestion data
    const suggestionDoc = await admin.firestore()
        .collection("proactiveSuggestions")
        .doc(suggestionId)
        .get();

    if (!suggestionDoc.exists) {
      throw new Error(`Suggestion not found: ${suggestionId}`);
    }

    const suggestionData = suggestionDoc.data();

    // Determine duration and urgency
    const duration = 60; // Default 60 minutes
    const daysOut = suggestionData.urgency === "urgent" ? 1 : 2;

    // Generate time slots
    const timeSlots = await generateTimeSlots(
        suggestionData.participantIds,
        duration,
        daysOut,
    );

    // Update suggestion with time slots
    await updateSuggestionWithTimeSlots(suggestionId, timeSlots);

    return timeSlots;
  } catch (error) {
    console.error(`❌ Failed to generate time slots for suggestion:`, error);
    throw error;
  }
}

module.exports = {
  getUserTimezone,
  getParticipantTimezones,
  generateTimeSlots,
  generateTimeSlotsForSuggestion,
  updateSuggestionWithTimeSlots,
};
