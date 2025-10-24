# AI Infrastructure Setup Guide

This document explains how to configure and use the AI features in MessageAI.

## Prerequisites

1. OpenAI API key from https://platform.openai.com/api-keys
2. Pinecone API key and index from https://www.pinecone.io/

## Setup Steps

### 1. Configure API Keys

Set the API keys using Firebase Functions configuration:

```bash
# Set OpenAI API key
firebase functions:config:set openai.api_key="sk-..."

# Set Pinecone API key
firebase functions:config:set pinecone.api_key="..."
```

### 2. Create Pinecone Index

1. Go to https://www.pinecone.io/
2. Create a new account or sign in
3. Create a new index with the following settings:
   - **Index Name**: `messageai-messages`
   - **Dimensions**: `1536` (for OpenAI text-embedding-3-small)
   - **Metric**: `cosine`
   - **Cloud**: AWS (free tier)
   - **Region**: us-east-1 (or your preferred region)

### 3. Deploy Cloud Functions

```bash
# From the project root
firebase deploy --only functions
```

### 4. Test the Setup

#### Option 1: Run the test script

```bash
cd backend/functions
export OPENAI_API_KEY="sk-..."
node src/__tests__/openai.test.js
```

#### Option 2: Test from iOS app

```swift
let aiService = AIService()
try await aiService.testConnection()
```

## Architecture Overview

### File Structure

```
backend/functions/src/
├── ai/
│   ├── openai.js          # OpenAI client configuration
│   ├── pinecone.js        # Pinecone vector DB configuration
│   ├── embeddings.js      # Text-to-vector conversion
│   ├── prompts.js         # All AI prompts
│   └── tools.js           # Function calling schemas
├── middleware/
│   └── rateLimit.js       # Rate limiting (10/min, 100/day)
└── __tests__/
    └── openai.test.js     # OpenAI connection tests
```

### Models Used

- **Chat**: `gpt-4-turbo-preview` - Fast responses, function calling support
- **Embeddings**: `text-embedding-3-small` - 1536 dimensions, cost-effective

### Rate Limits

- **Per Minute**: 10 AI calls
- **Per Day**: 100 AI calls
- Tracked in Firestore at `/users/{userId}/aiUsage/`

## AI Features (to be implemented in future PRs)

1. **Thread Summarization** (PR #24) - Summarize conversation threads
2. **Action Item Extraction** (PR #25) - Extract tasks from conversations
3. **Smart Search** (PR #26) - Semantic search with RAG
4. **Priority Detection** (PR #27) - Real-time message priority classification
5. **Decision Tracking** (PR #28) - Extract and track key decisions
6. **Proactive Assistant** (PRs #30-32) - Multi-step scheduling agent

## Environment Variables (for local development)

```bash
# .env file (do not commit!)
OPENAI_API_KEY=sk-...
PINECONE_API_KEY=...
```

## Troubleshooting

### OpenAI API errors

- **401 Unauthorized**: Check your API key is valid
- **429 Rate Limit**: Wait a moment, then retry
- **Model not found**: Verify model names in `src/ai/openai.js`

### Pinecone errors

- **Index not found**: Create index with name `messageai-messages`
- **Dimension mismatch**: Ensure index uses 1536 dimensions
- **Connection timeout**: Check your API key and network

### Firebase Functions errors

- **Config not set**: Run `firebase functions:config:get` to verify
- **Deploy fails**: Check Node.js version (18 required)
- **Functions timeout**: Increase timeout in firebase.json

## Cost Estimates

### Development/Testing

- OpenAI: ~$20-30 for testing all features
- Pinecone: Free tier (sufficient for development)
- Firebase: Free tier (sufficient for development)

### Per-Call Costs

- Embedding (1 message): $0.0001
- Summarization: $0.01-0.05
- Search query: $0.002-0.01
- Priority detection: $0.001

## Security Notes

- ✅ API keys stored in Cloud Functions config (not in iOS app)
- ✅ Rate limiting enforced per user
- ✅ Authentication required for all AI calls
- ✅ User data scoped properly in Firestore

## Next Steps

After infrastructure is set up:

1. PR #23: Implement RAG pipeline for message indexing
2. PR #24: Build thread summarization feature
3. Continue with remaining AI features

---

**Created**: October 24, 2025
**PR**: #22 - AI Infrastructure Setup
