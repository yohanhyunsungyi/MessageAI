/**
 * OpenAI API Configuration
 * Initializes and exports OpenAI client for use across AI features
 */

const OpenAI = require("openai");
const functions = require("firebase-functions");

/**
 * Initialize OpenAI client with API key from Firebase config
 * Set API key using: firebase functions:config:set openai.api_key="sk-..."
 */
const openaiConfig = functions.config().openai || {};
const openai = new OpenAI({
  apiKey: openaiConfig.api_key || process.env.OPENAI_API_KEY,
});

/**
 * Default model configuration
 */
const DEFAULT_MODEL = "gpt-4-turbo-preview";
const EMBEDDING_MODEL = "text-embedding-3-small";

/**
 * Default parameters for chat completions
 */
const DEFAULT_PARAMS = {
  temperature: 0.7,
  max_tokens: 1000,
};

module.exports = {
  openai,
  DEFAULT_MODEL,
  EMBEDDING_MODEL,
  DEFAULT_PARAMS,
};
