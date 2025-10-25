/**
 * OpenAI Function Calling Schemas
 * Defines structured output formats for AI features
 */

/**
 * Action Item Extraction Function Schema
 * Used with OpenAI function calling to extract structured action items
 */
const EXTRACT_ACTION_ITEMS_SCHEMA = {
  name: "extract_action_items",
  description: "Extract action items and tasks from conversation",
  parameters: {
    type: "object",
    properties: {
      actionItems: {
        type: "array",
        description: "List of action items found in the conversation",
        items: {
          type: "object",
          properties: {
            description: {
              type: "string",
              description: "What needs to be done",
            },
            assignee: {
              type: "string",
              description: "Person assigned (name or 'unassigned')",
            },
            deadline: {
              type: "string",
              description: "When it's due (specific date or 'none')",
            },
            priority: {
              type: "string",
              enum: ["high", "medium", "low"],
              description: "Priority level based on urgency",
            },
          },
          required: ["description", "assignee", "priority"],
        },
      },
    },
    required: ["actionItems"],
  },
};

/**
 * Decision Extraction Function Schema
 * Used to extract structured decisions from conversations
 */
const EXTRACT_DECISIONS_SCHEMA = {
  name: "extract_decisions",
  description: "Extract key decisions from team conversation",
  parameters: {
    type: "object",
    properties: {
      decisions: {
        type: "array",
        description: "List of decisions made in the conversation",
        items: {
          type: "object",
          properties: {
            summary: {
              type: "string",
              description: "Brief description of what was decided",
            },
            context: {
              type: "string",
              description: "Why this decision was made, background info",
            },
            participants: {
              type: "array",
              items: { type: "string" },
              description: "Names of people involved in the decision",
            },
            tags: {
              type: "array",
              items: { type: "string" },
              description: "Categories like 'technical', 'product', 'timeline'",
            },
          },
          required: ["summary", "context", "participants", "tags"],
        },
      },
    },
    required: ["decisions"],
  },
};

/**
 * Scheduling Detection Function Schema
 * Used to detect and structure scheduling needs
 */
const DETECT_SCHEDULING_NEED_SCHEMA = {
  name: "detect_scheduling_need",
  description: "Detect if message indicates a need to schedule a meeting",
  parameters: {
    type: "object",
    properties: {
      needsMeeting: {
        type: "boolean",
        description: "Whether the message indicates a scheduling need",
      },
      confidence: {
        type: "number",
        description: "Confidence level from 0.0 to 1.0",
      },
      purpose: {
        type: "string",
        description: "What the meeting would be about",
      },
      urgency: {
        type: "string",
        enum: ["urgent", "this-week", "flexible"],
        description: "How soon the meeting should happen",
      },
    },
    required: ["needsMeeting", "confidence"],
  },
};

/**
 * Priority Classification Function Schema
 * Used to classify message priority
 */
const CLASSIFY_PRIORITY_SCHEMA = {
  name: "classify_priority",
  description: "Classify message urgency and priority",
  parameters: {
    type: "object",
    properties: {
      priority: {
        type: "string",
        enum: ["critical", "high", "normal"],
        description: "Priority level of the message",
      },
      reason: {
        type: "string",
        description: "Brief explanation of why this priority was assigned",
      },
      confidence: {
        type: "number",
        description: "Confidence level from 0.0 to 1.0",
      },
    },
    required: ["priority", "confidence"],
  },
};

/**
 * Get User Timezone Tool Schema
 * Used by proactive assistant to get user's timezone
 */
const GET_USER_TIMEZONE_SCHEMA = {
  name: "get_user_timezone",
  description: "Get the timezone identifier for a user",
  parameters: {
    type: "object",
    properties: {
      userId: {
        type: "string",
        description: "The user's ID",
      },
    },
    required: ["userId"],
  },
};

/**
 * Check Availability Tool Schema
 * Used to check if a time slot works for given users
 */
const CHECK_AVAILABILITY_SCHEMA = {
  name: "check_availability",
  description: "Check if a time slot is available for given users",
  parameters: {
    type: "object",
    properties: {
      userIds: {
        type: "array",
        items: { type: "string" },
        description: "Array of user IDs to check",
      },
      startTime: {
        type: "string",
        description: "Start time in ISO 8601 format",
      },
      duration: {
        type: "number",
        description: "Duration in minutes",
      },
    },
    required: ["userIds", "startTime", "duration"],
  },
};

/**
 * Generate Time Slots Tool Schema
 * Used to generate meeting time suggestions
 */
const GENERATE_TIME_SLOTS_SCHEMA = {
  name: "generate_time_slots",
  description: "Generate optimal meeting time suggestions for users",
  parameters: {
    type: "object",
    properties: {
      userIds: {
        type: "array",
        items: { type: "string" },
        description: "Array of participant user IDs",
      },
      duration: {
        type: "number",
        description: "Meeting duration in minutes (default: 60)",
      },
      daysOut: {
        type: "number",
        description: "Days in future to start suggestions (default: 2)",
      },
    },
    required: ["userIds"],
  },
};

module.exports = {
  EXTRACT_ACTION_ITEMS_SCHEMA,
  EXTRACT_DECISIONS_SCHEMA,
  DETECT_SCHEDULING_NEED_SCHEMA,
  CLASSIFY_PRIORITY_SCHEMA,
  GET_USER_TIMEZONE_SCHEMA,
  CHECK_AVAILABILITY_SCHEMA,
  GENERATE_TIME_SLOTS_SCHEMA,
};
