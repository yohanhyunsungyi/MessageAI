# MessageAI Final - Product Requirements Document (AI Features)

**Project Name:** MessageAI Final (Post-MVP)  
**Target Persona:** Remote Team Professional  
**Timeline:** 4-5 days (after MVP completion)  
**Objective:** Build production-quality AI features that solve real pain points for distributed software teams

---

## Executive Summary

Building on the completed MVP messaging infrastructure, this PRD defines the AI-powered features that transform MessageAI into an intelligent collaboration tool for remote software teams. The focus is on reducing cognitive load, surfacing critical information, and automating routine scheduling tasks.

**Target Grade:** A (90-100 points)

---

## 1. Persona Deep Dive: Remote Team Professional

### Who They Are
- Software Engineers, Designers, Product Managers
- Work in distributed teams across multiple time zones
- Handle 50-200+ messages daily across multiple channels
- Participate in 3-5 ongoing projects simultaneously
- Mix of synchronous (video calls) and asynchronous (chat) communication

### Core Pain Points (from rubric)
1. **Drowning in threads** - Can't keep track of multiple conversation threads across projects
2. **Missing important messages** - Critical info gets buried in high-volume channels
3. **Context switching** - Mental overhead of switching between projects/conversations
4. **Time zone coordination** - Scheduling meetings across PST, EST, GMT, IST is painful
5. **Decision tracking** - Hard to remember what was decided and when

### Success Metrics
- Reduce time finding information by 60%
- Catch 95% of action items automatically
- Schedule meetings 3x faster
- Never miss a critical decision

---

## 2. AI Features Architecture

### 2.1 Technology Stack

**LLM Provider:** OpenAI GPT-4 Turbo (primary) or Anthropic Claude Sonnet 4.5
- Function calling support
- Fast response times (<2s for simple queries)
- High accuracy for structured extraction

**Backend:** Firebase Cloud Functions (Node.js)
- Secure API key management (never exposed to client)
- Serverless scaling
- Integration with Firestore

**AI Framework:** Vercel AI SDK or LangChain
- Structured function calling
- Streaming responses
- Tool use orchestration

**Vector Database:** Pinecone or Firebase Vector Search (for RAG)
- Store conversation embeddings
- Semantic search across chat history
- Fast retrieval (<100ms)

### 2.2 System Architecture

```
iOS App (Swift)
    ↓
Firebase Cloud Functions (Secure Layer)
    ↓
OpenAI API / Claude API
    ↓
Structured Responses
    ↓
Firebase Cloud Functions (Processing)
    ↓
Update Firestore + Client
```

**Key Principle:** All AI API calls go through Firebase Cloud Functions to keep keys secure.

---

## 3. Required AI Features (15 points from rubric)

### Feature 1: Thread Summarization

**User Story:** As a remote developer, I want to quickly understand what happened in a long conversation thread without reading every message.

**Implementation:**
- **Trigger:** User taps "Summarize" button on any conversation
- **Input:** Last 50-200 messages from conversation
- **Processing:** 
  - Send messages to LLM via Firebase Function
  - Prompt: "Summarize this team conversation. Focus on: key decisions, technical discussions, blockers, and action items."
  - Return structured summary (3-5 bullet points)
- **Output:** Display summary card with:
  - Key points (3-5 bullets)
  - Mentioned people (@mentions)
  - Timestamp range
  - "View Full Thread" button

**Performance Target:** <3 seconds for 100-message summary

**Prompt Template:**
```
You are summarizing a team chat for software professionals. 
Analyze the conversation and provide:
1. Key technical decisions made
2. Blockers or issues discussed
3. Action items identified
4. Important updates shared

Keep it concise (3-5 bullets). Focus on what matters for an engineer who missed the discussion.

Conversation:
{messages}
```

### Feature 2: Action Item Extraction

**User Story:** As a PM, I want to automatically extract action items from team conversations so nothing falls through the cracks.

**Implementation:**
- **Trigger:** Automatic (runs on conversation close) or manual "Extract Actions"
- **Input:** Conversation messages
- **Processing:**
  - LLM extracts structured action items
  - Each item: description, assignee (if mentioned), deadline (if mentioned), priority
- **Output:** 
  - List view of action items
  - Tap to create reminder
  - Export to calendar/task app
  - Notification if assigned to you

**Data Model:**
```typescript
interface ActionItem {
  id: string;
  description: string;
  assignee?: string; // userId
  deadline?: Date;
  priority: 'high' | 'medium' | 'low';
  conversationId: string;
  extractedAt: Date;
  status: 'pending' | 'completed';
}
```

**Performance Target:** <2 seconds for extraction

**Function Calling Schema:**
```typescript
{
  name: "extract_action_items",
  description: "Extract action items from conversation",
  parameters: {
    type: "object",
    properties: {
      action_items: {
        type: "array",
        items: {
          type: "object",
          properties: {
            description: { type: "string" },
            assignee: { type: "string" },
            deadline: { type: "string" },
            priority: { type: "string", enum: ["high", "medium", "low"] }
          }
        }
      }
    }
  }
}
```

### Feature 3: Smart Search

**User Story:** As a developer, I want to search for "that discussion about Redis caching" without knowing exact keywords.

**Implementation:**
- **Trigger:** User types in search bar
- **Type:** Semantic search (not just keyword matching)
- **Processing:**
  - Generate embedding for search query
  - Vector search against conversation embeddings
  - Rank by relevance
  - LLM re-ranks top results with context
- **Output:**
  - Ranked search results
  - Show context (surrounding messages)
  - Highlight relevant sections
  - "Jump to message" button

**RAG Pipeline:**
1. **Indexing** (background):
   - Every message → generate embedding
   - Store in Pinecone: `{messageId, embedding, text, metadata}`
2. **Search** (real-time):
   - Query → generate embedding
   - Vector search → top 20 results
   - LLM re-ranks with context → top 5
   - Return to user

**Performance Target:** <1 second for search results

**Prompt for Re-ranking:**
```
Given the user's search query and these message results, rank them by relevance.
Consider: semantic meaning, recency, participants, context.

Query: {searchQuery}
Results: {messages}

Return the top 5 most relevant messages with brief explanations.
```

### Feature 4: Priority Message Detection

**User Story:** As an engineer in multiple time zones, I want urgent messages to be highlighted so I don't miss critical blockers.

**Implementation:**
- **Trigger:** Automatic (real-time as messages arrive)
- **Input:** New message content
- **Processing:**
  - Fast LLM call (<500ms) to classify priority
  - Factors: urgency words, @mentions, keywords (BLOCKED, URGENT, ASAP), sender, time
- **Output:**
  - High-priority badge on message
  - Push notification (even if app open)
  - Move to top of conversation list
  - Option to snooze/dismiss

**Priority Levels:**
- 🔴 **Critical:** Production down, security issue, blocking deployment
- 🟡 **High:** Review needed, deadline today, direct request
- 🟢 **Normal:** Everything else

**Performance Target:** <500ms classification (must be real-time)

**Function Calling:**
```typescript
{
  name: "classify_message_priority",
  parameters: {
    message: string,
    sender: string,
    timestamp: string,
    mentions: string[]
  },
  returns: {
    priority: "critical" | "high" | "normal",
    reason: string,
    confidence: number
  }
}
```

### Feature 5: Decision Tracking

**User Story:** As a PM, I want to track what decisions were made and when, without manually taking notes.

**Implementation:**
- **Trigger:** Automatic (background processing) or manual "Track Decision"
- **Input:** Conversation messages
- **Processing:**
  - LLM identifies decision points
  - Extracts: decision, context, participants, timestamp
  - Stores in decisions collection
- **Output:**
  - Decisions timeline view
  - Filter by project/person/date
  - Link back to original conversation
  - Export capabilities

**Data Model:**
```typescript
interface Decision {
  id: string;
  summary: string; // "Decided to use PostgreSQL for analytics DB"
  context: string; // Background/reasoning
  participants: string[]; // userIds
  conversationId: string;
  timestamp: Date;
  tags: string[]; // ["technical", "architecture"]
  relatedDecisions?: string[]; // IDs of related decisions
}
```

**Performance Target:** <4 seconds to extract decisions from 100-message thread

---

## 4. Advanced AI Feature: Proactive Assistant (10 points from rubric)

### Overview
A background AI agent that monitors conversations and proactively suggests meeting times when it detects scheduling needs, eliminating the "when are you free?" back-and-forth.

**User Story:** As a distributed team member, I want the AI to detect when we need to schedule a meeting and automatically suggest times that work for everyone.

### 4.1 Detection Phase

**Triggers (monitored in real-time):**
- Keywords: "let's meet", "schedule a call", "find time", "when are you free"
- Meeting-related questions
- Calendar event mentions
- Multiple people discussing availability
- Follow-ups on action items that need sync discussion

**Detection Logic:**
```typescript
// Firebase Function listens to new messages
function detectSchedulingNeed(message: Message, conversation: Conversation) {
  // LLM classification
  const needsMeeting = await classifyMessage(message, {
    type: "scheduling_detection",
    context: getRecentMessages(conversation, 10)
  });
  
  if (needsMeeting.probability > 0.7) {
    triggerProactiveAssistant(conversation, needsMeeting);
  }
}
```

### 4.2 Data Collection Phase

When scheduling need detected:
1. **Identify participants** - From @mentions and conversation context
2. **Fetch availability** - Get calendar data (if integrated) or ask users
3. **Determine meeting purpose** - Extract from context
4. **Estimate duration** - Default 30min, or extract from conversation

**Calendar Integration Options:**
- **Simple:** Users share "typical availability" in profile (9am-5pm PST)
- **Advanced:** OAuth to Google Calendar/Outlook (bonus feature)

### 4.3 Suggestion Phase

**LLM Agent Flow:**
1. Analyze conversation context
2. Identify optimal time slots (consider time zones!)
3. Generate natural language suggestion
4. Present to users

**Output Example:**
```
🤖 Assistant: I noticed you're trying to schedule a meeting about the API redesign.

Suggested times (all zones):
• Tomorrow 2pm PST / 5pm EST / 10pm GMT (60 min)
• Friday 10am PST / 1pm EST / 6pm GMT (60 min)

Participants: @alice @bob @charlie
Should I send calendar invites?

[Confirm] [Suggest Different Times] [Dismiss]
```

### 4.4 Execution Phase (Optional)

If user confirms:
- Generate calendar event
- Send to all participants
- Add event link to conversation
- Track RSVP status

### 4.5 Learning Phase

Over time, learn:
- Preferred meeting times by person
- Meeting duration patterns by type
- Who typically needs to be included

**Performance Targets:**
- Detection: <500ms
- Suggestion generation: <5s
- Accuracy: 80%+ suggestions accepted

### 4.6 Implementation Details

**Multi-Step Agent Architecture:**
```typescript
// Agent orchestration
class ProactiveSchedulingAgent {
  async execute(conversation: Conversation) {
    // Step 1: Analyze need
    const analysis = await this.analyzeSchedulingNeed(conversation);
    
    // Step 2: Gather data
    const participants = await this.identifyParticipants(conversation);
    const availability = await this.getAvailability(participants);
    
    // Step 3: Find time slots
    const slots = await this.findOptimalSlots(availability, analysis);
    
    // Step 4: Generate suggestion
    const suggestion = await this.generateSuggestion(slots, analysis);
    
    // Step 5: Present to users
    await this.presentSuggestion(conversation, suggestion);
  }
}
```

**Tool Use/Function Calling:**
```typescript
const tools = [
  {
    name: "get_user_timezone",
    description: "Get timezone for a user",
    parameters: { userId: "string" }
  },
  {
    name: "check_availability",
    description: "Check if time slot works for users",
    parameters: { 
      userIds: "string[]",
      startTime: "datetime",
      duration: "number"
    }
  },
  {
    name: "create_calendar_event",
    description: "Create calendar event",
    parameters: {
      title: "string",
      startTime: "datetime",
      duration: "number",
      participants: "string[]"
    }
  }
];
```

---

## 5. AI Chat Interface Options

### Option A: Dedicated AI Assistant (Recommended)

**Implementation:**
- Special "AI Assistant" chat in conversation list
- Always available
- Chat-based interaction for all AI features
- Can ask questions naturally

**Pros:**
- Natural interaction
- Centralized AI experience
- Easy to discover features

**UI Example:**
```
Conversations
├── AI Assistant ⚡
├── #engineering-team
├── #design-sync
└── @alice
```

### Option B: Contextual Menus

**Implementation:**
- Long-press message → "Ask AI"
- Conversation header → AI actions dropdown
- Inline AI suggestions

**Pros:**
- Context-aware
- Less intrusive
- Faster access

### Option C: Hybrid (Best)

Combine both:
- Dedicated AI chat for general queries
- Contextual actions for specific tasks
- Proactive suggestions appear inline

---

## 6. AI Service Architecture

### 6.1 Firebase Cloud Functions Structure

```
functions/
├── src/
│   ├── ai/
│   │   ├── openai.ts           # OpenAI client
│   │   ├── embeddings.ts       # Generate embeddings
│   │   ├── prompts.ts          # Prompt templates
│   │   └── tools.ts            # Function calling schemas
│   ├── features/
│   │   ├── summarization.ts    # Feature 1
│   │   ├── actionItems.ts      # Feature 2
│   │   ├── smartSearch.ts      # Feature 3
│   │   ├── priority.ts         # Feature 4
│   │   ├── decisions.ts        # Feature 5
│   │   └── proactive.ts        # Advanced feature
│   ├── triggers/
│   │   ├── onMessageCreate.ts  # Real-time triggers
│   │   └── scheduled.ts        # Batch processing
│   └── index.ts
├── package.json
└── tsconfig.json
```

### 6.2 Key Cloud Functions

**1. Summarize Conversation**
```typescript
exports.summarizeConversation = functions.https.onCall(async (data, context) => {
  const { conversationId, messageLimit } = data;
  
  // Auth check
  if (!context.auth) throw new Error('Unauthorized');
  
  // Fetch messages
  const messages = await getMessages(conversationId, messageLimit);
  
  // Call OpenAI
  const summary = await openai.chat.completions.create({
    model: "gpt-4-turbo",
    messages: [
      { role: "system", content: SUMMARIZATION_PROMPT },
      { role: "user", content: JSON.stringify(messages) }
    ]
  });
  
  return { summary: summary.choices[0].message.content };
});
```

**2. Extract Action Items**
```typescript
exports.extractActionItems = functions.https.onCall(async (data, context) => {
  // Similar structure but use function calling
  const completion = await openai.chat.completions.create({
    model: "gpt-4-turbo",
    messages: [...],
    functions: [ACTION_ITEM_FUNCTION],
    function_call: { name: "extract_action_items" }
  });
  
  const actionItems = JSON.parse(
    completion.choices[0].message.function_call.arguments
  );
  
  // Store in Firestore
  await storeActionItems(conversationId, actionItems);
  
  return actionItems;
});
```

**3. Priority Classification (Real-time)**
```typescript
exports.onMessageCreated = functions.firestore
  .document('conversations/{convId}/messages/{msgId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    
    // Fast priority check
    const priority = await classifyPriority(message);
    
    if (priority === 'critical' || priority === 'high') {
      // Update message with priority
      await snap.ref.update({ priority, aiClassified: true });
      
      // Send push notification
      await sendPriorityNotification(message);
    }
  });
```

### 6.3 RAG Pipeline Implementation

**Indexing Pipeline:**
```typescript
// Background job - index messages for search
exports.indexMessage = functions.firestore
  .document('conversations/{convId}/messages/{msgId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    
    // Generate embedding
    const embedding = await openai.embeddings.create({
      model: "text-embedding-3-small",
      input: message.text
    });
    
    // Store in Pinecone
    await pinecone.upsert({
      id: snap.id,
      values: embedding.data[0].embedding,
      metadata: {
        conversationId: context.params.convId,
        senderId: message.senderId,
        timestamp: message.timestamp,
        text: message.text
      }
    });
  });
```

**Search Pipeline:**
```typescript
exports.smartSearch = functions.https.onCall(async (data, context) => {
  const { query, conversationId } = data;
  
  // 1. Generate query embedding
  const queryEmbedding = await openai.embeddings.create({
    model: "text-embedding-3-small",
    input: query
  });
  
  // 2. Vector search
  const results = await pinecone.query({
    vector: queryEmbedding.data[0].embedding,
    topK: 20,
    filter: { conversationId }
  });
  
  // 3. LLM re-ranking
  const reranked = await openai.chat.completions.create({
    model: "gpt-4-turbo",
    messages: [
      { role: "system", content: RERANK_PROMPT },
      { role: "user", content: JSON.stringify({ query, results }) }
    ]
  });
  
  return JSON.parse(reranked.choices[0].message.content);
});
```

---

## 7. Data Models (AI-specific)

### ActionItems Collection
```typescript
/actionItems/{itemId}
{
  id: string;
  description: string;
  assignee?: string;
  assigneeName?: string;
  deadline?: Timestamp;
  priority: 'high' | 'medium' | 'low';
  conversationId: string;
  conversationName: string;
  extractedAt: Timestamp;
  extractedBy: 'ai' | 'user';
  status: 'pending' | 'completed' | 'dismissed';
  completedAt?: Timestamp;
}
```

### Decisions Collection
```typescript
/decisions/{decisionId}
{
  id: string;
  summary: string;
  context: string;
  participants: string[];
  conversationId: string;
  timestamp: Timestamp;
  tags: string[];
  relatedDecisions: string[];
  createdBy: 'ai' | 'user';
}
```

### Summaries Collection
```typescript
/summaries/{summaryId}
{
  id: string;
  conversationId: string;
  summary: string;
  bulletPoints: string[];
  messageCount: number;
  timeRange: { start: Timestamp, end: Timestamp };
  participants: string[];
  generatedAt: Timestamp;
  accuracy?: number; // user feedback
}
```

### AI Usage Metrics
```typescript
/users/{userId}/aiUsage
{
  summarizationsCount: number;
  actionItemsExtracted: number;
  searchesPerformed: number;
  priorityMessagesReceived: number;
  decisionsTracked: number;
  proactiveSuggestions: number;
  lastUsedAt: Timestamp;
}
```

---

## 8. UI/UX Design

### 8.1 AI Chat Assistant View

```
┌─────────────────────────┐
│  ⚡ AI Assistant        │
├─────────────────────────┤
│                         │
│  🤖 Hi! I can help you: │
│  • Summarize threads    │
│  • Find action items    │
│  • Search conversations │
│  • Track decisions      │
│                         │
│  Try: "Summarize #eng"  │
│  or "Find my tasks"     │
│                         │
├─────────────────────────┤
│ [Type a message...]     │
└─────────────────────────┘
```

### 8.2 Contextual AI Menu

Long-press message:
```
┌─────────────────────────┐
│ ✨ Ask AI               │
│ 📝 Summarize Thread     │
│ ✅ Extract Actions      │
│ 🔍 Find Related         │
│ 🎯 Set Priority         │
│ 📌 Track Decision       │
│ ─────────────────       │
│ Copy                    │
│ Delete                  │
└─────────────────────────┘
```

### 8.3 Action Items View

```
┌─────────────────────────┐
│  📋 Action Items        │
├─────────────────────────┤
│ 🔴 Review PR #234       │
│    @you • Due: Today    │
│    From: #eng-backend   │
│                         │
│ 🟡 Update docs          │
│    @alice • This week   │
│    From: #docs-team     │
│                         │
│ 🟢 Research GraphQL     │
│    Unassigned           │
│    From: DM with Bob    │
└─────────────────────────┘
```

### 8.4 Proactive Assistant Suggestion

```
┌─────────────────────────┐
│ 🤖 I noticed you're     │
│ trying to schedule a    │
│ meeting about the API   │
│ redesign.               │
│                         │
│ 📅 Suggested times:     │
│                         │
│ Tomorrow 2pm PST        │
│ 5pm EST / 10pm GMT      │
│ (60 min)                │
│                         │
│ Friday 10am PST         │
│ 1pm EST / 6pm GMT       │
│ (60 min)                │
│                         │
│ [@alice @bob @charlie]  │
│                         │
│ [✓ Confirm]  [✏️ Edit]  │
└─────────────────────────┘
```

---

## 9. Performance Targets (for A grade)

| Feature | Target | Excellent |
|---------|--------|-----------|
| Summarization | <3s | <2s |
| Action Items | <3s | <2s |
| Smart Search | <1s | <500ms |
| Priority Detection | <1s | <500ms |
| Decision Tracking | <5s | <3s |
| Proactive Suggestions | <5s | <3s |
| Natural language accuracy | 80%+ | 90%+ |

---

## 10. Testing Strategy

### 10.1 Unit Tests
- Prompt engineering validation
- Function calling schema tests
- Response parsing tests
- Error handling

### 10.2 Integration Tests
- Firebase Functions with mock OpenAI
- Firestore data flow
- RAG pipeline

### 10.3 AI Quality Tests
- Test summarization with sample conversations (10 test cases)
- Validate action item extraction (20 test messages)
- Priority classification accuracy (50 messages with labels)
- Search relevance (10 queries with expected results)

### 10.4 User Testing
- Test with 3-5 remote team members
- Measure time saved
- Track suggestion acceptance rate
- Gather qualitative feedback

---

## 11. Success Criteria (Rubric Alignment)

### Section 3: AI Features (30 points target)

**Required Features (15 points) - Target: 14-15**
- ✅ All 5 features fully implemented
- ✅ 90%+ command accuracy
- ✅ <2s response times
- ✅ Clean UI integration
- ✅ Proper error handling

**Persona Fit (5 points) - Target: 5**
- ✅ Clear mapping to Remote Team Professional pain points
- ✅ Daily usefulness demonstrated
- ✅ Purpose-built experience

**Advanced Feature (10 points) - Target: 9-10**
- ✅ Proactive Assistant fully functional
- ✅ Multi-step workflow (5+ steps)
- ✅ Handles edge cases
- ✅ <15s response time
- ✅ Uses agent framework correctly

### Section 4: Technical Implementation (10 points target)

**Architecture (5 points) - Target: 5**
- ✅ Clean, organized code
- ✅ API keys secured in Cloud Functions
- ✅ Function calling implemented
- ✅ RAG pipeline working
- ✅ Rate limiting

**Auth & Data (5 points) - Target: 5**
- ✅ Already completed in MVP

---

## 12. Known Limitations & Trade-offs

**MVP Scope:**
- No voice message transcription
- No image analysis
- No multi-language support (English only)
- Simple calendar integration (no OAuth)
- No ML model training (all via API)

**Cost Considerations:**
- OpenAI API costs: ~$0.01-0.05 per conversation summarization
- Embedding storage: ~$0.10/GB in Pinecone
- Budget for testing: $50-100

**Rate Limiting:**
- Max 10 AI requests per user per minute
- Max 100 AI requests per day (free tier)
- Implement caching for repeated queries

---

## 13. Deployment Checklist

**Before Demo:**
- [ ] All 5 AI features working in demo environment
- [ ] Proactive Assistant tested with real scheduling scenarios
- [ ] Firebase Functions deployed and tested
- [ ] OpenAI API key secured
- [ ] Test with 2-3 people in different time zones
- [ ] Record demo video (5-7 minutes)
- [ ] Prepare 1-page Persona Brainlift
- [ ] Create social media post

**Technical:**
- [ ] Error handling for all AI calls
- [ ] Loading states in UI
- [ ] Graceful degradation if AI fails
- [ ] Rate limiting enforced
- [ ] Costs monitored

---

## Appendix A: Sample Prompts

### Thread Summarization Prompt
```
You are an AI assistant helping remote software teams stay productive.
Summarize this team conversation for someone who missed it.

Focus on:
1. Key technical decisions made
2. Blockers or issues discussed  
3. Action items identified
4. Important updates shared

Be concise (3-5 bullet points). Use clear, professional language.

Conversation:
{messages}

Format:
**Key Points:**
• Point 1
• Point 2
• Point 3

**Action Items:**
• Item 1 (@person)
• Item 2 (@person)
```

### Proactive Assistant Detection Prompt
```
Analyze this conversation and determine if the team needs to schedule a meeting.

Look for:
- Direct scheduling requests ("let's meet", "find time")
- Multiple people coordinating availability
- Complex topics needing sync discussion
- Follow-ups on action items

Context: {recentMessages}
New Message: {currentMessage}

Return JSON:
{
  "needsMeeting": true/false,
  "confidence": 0.0-1.0,
  "reason": "explanation",
  "suggestedDuration": 30/60,
  "urgency": "high/medium/low",
  "suggestedParticipants": ["@user1", "@user2"]
}
```

---

**Document Version:** 1.0  
**Status:** Ready for Implementation  
**Target Completion:** 4-5 days post-MVP