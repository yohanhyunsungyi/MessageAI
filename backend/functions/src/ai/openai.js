/**
 * OpenAI API Configuration
 * Initializes and exports OpenAI client for use across AI features
 */

const OpenAI = require("openai");
const functions = require("firebase-functions");

// Load environment variables from .env.local for local development
if (process.env.NODE_ENV !== "production") {
  require("dotenv").config({ path: ".env.local" });
}

/**
 * Initialize OpenAI client with API key
 * Priority: .env.local > Firebase config > environment variable
 */
const openaiConfig = functions.config().openai || {};
const apiKey = process.env.OPENAI_API_KEY || openaiConfig.api_key;

// Only initialize OpenAI if API key is available
// This prevents crashes in functions that don't need OpenAI
let openai = null;
if (apiKey) {
  openai = new OpenAI({ apiKey });
}

/**
 * Default model configuration
 * Using gpt-4o-mini for faster responses and lower cost
 * - 2-5x faster than gpt-4-turbo
 * - 60x cheaper
 * - Excellent for summarization, extraction, and chat tasks
 */
const DEFAULT_MODEL = "gpt-4o-mini";
const EMBEDDING_MODEL = "text-embedding-3-small";

/**
 * Default parameters for chat completions
 */
const DEFAULT_PARAMS = {
  temperature: 0.7,
  max_tokens: 1000,
};

/**
 * Get OpenAI client instance
 * Throws error if API key is not configured
 */
function getOpenAIClient() {
  if (!openai) {
    throw new Error(
        "OpenAI API key not configured. " +
      "Set OPENAI_API_KEY environment variable or configure via Firebase.",
    );
  }
  return openai;
}

module.exports = {
  openai,
  getOpenAIClient,
  DEFAULT_MODEL,
  EMBEDDING_MODEL,
  DEFAULT_PARAMS,
};
