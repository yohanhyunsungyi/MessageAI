# ⚡ Quick Start: Get AI Working in 5 Minutes

## Step 1: Setup Environment (2 minutes)

```bash
cd backend/functions

# Copy the template
cp .env.example .env.local

# Edit .env.local and add your keys
# OPENAI_API_KEY=sk-...
# PINECONE_API_KEY=...
```

**Get API Keys:**
- OpenAI: https://platform.openai.com/api-keys
- Pinecone: https://www.pinecone.io/

## Step 2: Create Pinecone Index (2 minutes)

1. Go to https://www.pinecone.io/
2. Create new index:
   - Name: `messageai-messages`
   - Dimensions: `1536`
   - Metric: `cosine`
   - Cloud: AWS (free tier)

## Step 3: Test Connection (1 minute)

```bash
# Test OpenAI connection
node src/__tests__/openai.test.js

# Expected output:
# ✅ API key is configured
# ✅ Chat completion works
# ✅ Embedding generation works
# 🎉 All tests passed!
```

## ✅ You're Ready!

Your AI infrastructure is now set up and tested.

## Next Steps

- **Deploy**: `firebase deploy --only functions`
- **Start PR #23**: RAG Pipeline Implementation
- **See Full Guide**: `AI_SETUP.md`

---

**Security Note:** `.env.local` is in `.gitignore` and will NEVER be committed to git. ✅
