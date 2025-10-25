# Quick Start: Environment Setup

## 🚀 Get Started in 3 Steps

### 1. Copy the environment template
```bash
cp .env.example .env.local
```

### 2. Get your API keys

#### OpenAI
1. Go to https://platform.openai.com/api-keys
2. Click "Create new secret key"
3. Copy the key (starts with `sk-...`)

#### Pinecone
1. Go to https://www.pinecone.io/
2. Sign up or log in
3. Go to "API Keys" section
4. Copy your API key

### 3. Edit `.env.local`

Open `.env.local` and paste your keys:

```bash
OPENAI_API_KEY=sk-your_actual_key_here
PINECONE_API_KEY=your_actual_key_here
```

## ✅ You're Ready!

Test your setup:
```bash
node src/__tests__/openai.test.js
```

## 📝 Important Notes

- ✅ `.env.local` is in `.gitignore` - safe from commits
- ❌ NEVER commit API keys to git
- 🔒 Keep your `.env.local` file private
- 📋 `.env.example` is the template (commit this)

## 🔄 Priority Order

The code checks for API keys in this order:
1. `.env.local` file (local development)
2. Firebase config (production)
3. Environment variables (CI/CD)

## 💰 Free Tiers

Both services have free tiers for testing:
- **OpenAI**: $5 free credit for new accounts
- **Pinecone**: Free tier with 1 index (sufficient for testing)

## 🆘 Need Help?

See `AI_SETUP.md` for detailed setup instructions and troubleshooting.
