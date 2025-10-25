graph TB
    subgraph User["👤 User Devices"]
        Device1[Device A - Alice<br/>iOS iPhone]
        Device2[Device B - Bob<br/>iOS iPhone]
    end
    
    subgraph iOSApp["📱 iOS App - Swift + SwiftUI"]
        subgraph Views["UI Layer"]
            AuthUI[Auth Views<br/>Email + Google SignIn]
            ChatUI[Chat View<br/>Messages + Input]
            ConvList[Conversations List]
            UsersList[Users List]
            AIAssistant[⚡ AI Assistant Chat]
            ActionItemsUI[Action Items View]
            DecisionsUI[Decisions Timeline]
            SearchUI[Smart Search]
        end
        
        subgraph ViewModels["ViewModels"]
            ChatVM[Chat ViewModel]
            AIVM[AI ViewModel]
        end
        
        subgraph Services["Services Layer"]
            AuthSvc[Auth Service]
            MsgSvc[Message Service<br/>LOCAL-FIRST]
            ConvSvc[Conversation Service]
            UserSvc[User Service]
            AISvc[AI Service<br/>API Wrapper]
            PresenceSvc[Presence Service]
            NotifSvc[Notification Service]
        end
        
        subgraph LocalStorage["Local Storage"]
            SwiftData[(SwiftData<br/>Offline Database<br/>Messages + Conversations)]
        end
    end
    
    subgraph Firebase["🔥 Firebase Cloud Platform"]
        subgraph RealtimeDB["Real-time Services"]
            Firestore[(Cloud Firestore<br/>Collections:<br/>users, conversations,<br/>messages, actionItems,<br/>decisions, suggestions)]
            FBAuth[Firebase Auth<br/>Email + Google OAuth]
            FCM[Cloud Messaging<br/>Push Notifications]
        end
        
        subgraph CloudFunctions["☁️ Cloud Functions - Node.js"]
            subgraph CoreAI["5 Core AI Features"]
                F1[1. Thread Summarization<br/>Target: 2s]
                F2[2. Action Item Extraction<br/>Target: 2s]
                F3[3. Smart Search + RAG<br/>Target: 1s]
                F4[4. Priority Detection<br/>Target: 500ms]
                F5[5. Decision Tracking<br/>Target: 4s]
            end
            
            subgraph AdvancedAI["Advanced Feature"]
                ProactiveDetect[Proactive Detection<br/>Monitors for scheduling]
                ProactiveAgent[Multi-Step Agent<br/>1. Get participants<br/>2. Get timezones<br/>3. Check availability<br/>4. Generate time slots<br/>5. Format suggestion<br/>Target: 15s]
            end
            
            subgraph AIInfra["AI Infrastructure"]
                RAGIndex[RAG Indexing<br/>Message → Embedding]
                RAGSearch[RAG Search<br/>Query → Results]
                NLCommands[Natural Language<br/>Command Parser]
            end
        end
    end
    
    subgraph ExternalServices["🌐 External Services"]
        subgraph GoogleServices["Google"]
            GoogleAuth[Google Sign-In SDK<br/>OAuth 2.0]
        end
        
        subgraph AIServices["AI Services"]
            OpenAI[OpenAI GPT-4 Turbo<br/>- Chat Completions<br/>- Function Calling<br/>- Embeddings API]
            Pinecone[Pinecone Vector DB<br/>Semantic Search<br/>1536 dimensions]
        end
    end
    
    %% User Interactions
    Device1 --> iOSApp
    Device2 --> iOSApp
    
    %% UI Layer Connections
    AuthUI --> AuthSvc
    ChatUI --> ChatVM
    ConvList --> ConvSvc
    UsersList --> UserSvc
    AIAssistant --> AIVM
    ActionItemsUI --> AISvc
    DecisionsUI --> AISvc
    SearchUI --> AISvc
    
    %% ViewModel Connections
    ChatVM --> MsgSvc
    ChatVM --> AISvc
    AIVM --> AISvc
    
    %% Service Layer - MVP Features
    AuthSvc --> FBAuth
    AuthSvc --> GoogleAuth
    MsgSvc --> SwiftData
    MsgSvc --> Firestore
    ConvSvc --> Firestore
    UserSvc --> Firestore
    PresenceSvc --> Firestore
    NotifSvc --> FCM
    
    %% Service Layer - AI Features
    AISvc --> CloudFunctions
    
    %% Local-First Architecture
    SwiftData -.Save Local First.-> ChatUI
    MsgSvc -.Then Sync.-> Firestore
    
    %% Real-time Sync
    Firestore -.WebSocket<br/>Real-time.-> MsgSvc
    Firestore -.WebSocket<br/>Real-time.-> ConvSvc
    
    %% Cloud Functions - AI Processing
    F1 --> OpenAI
    F2 --> OpenAI
    F3 --> OpenAI
    F3 --> Pinecone
    F4 --> OpenAI
    F5 --> OpenAI
    ProactiveDetect --> OpenAI
    ProactiveAgent --> OpenAI
    
    %% RAG Pipeline
    RAGIndex --> OpenAI
    RAGIndex --> Pinecone
    RAGSearch --> Pinecone
    RAGSearch --> OpenAI
    
    %% AI Results Storage
    F2 -.Store.-> Firestore
    F5 -.Store.-> Firestore
    ProactiveAgent -.Store.-> Firestore
    
    %% Firestore Triggers
    Firestore -.Trigger<br/>onMessageCreate.-> F4
    Firestore -.Trigger<br/>onMessageCreate.-> ProactiveDetect
    Firestore -.Trigger<br/>onMessageCreate.-> RAGIndex
    
    %% Google OAuth Flow
    GoogleAuth -.OAuth Token.-> FBAuth
    
    %% Push Notifications
    FCM --> Device1
    FCM --> Device2
    
    %% Data Flow Labels
    MsgSvc -.Priority<br/>Messages.-> NotifSvc
    ProactiveAgent -.Scheduling<br/>Suggestions.-> ChatUI
    
    %% Styling
    style SwiftData fill:#e1f5ff,stroke:#0066cc,stroke-width:3px
    style Firestore fill:#ffd700,stroke:#ff9800,stroke-width:3px
    style OpenAI fill:#10a37f,stroke:#059669,stroke-width:3px
    style Pinecone fill:#6366f1,stroke:#4f46e5,stroke-width:3px
    style MsgSvc fill:#90ee90,stroke:#22c55e,stroke-width:3px
    style AISvc fill:#4285f4,stroke:#1976d2,stroke-width:3px
    style F1 fill:#dceefb,stroke:#3b82f6
    style F2 fill:#dceefb,stroke:#3b82f6
    style F3 fill:#dceefb,stroke:#3b82f6
    style F4 fill:#dceefb,stroke:#3b82f6
    style F5 fill:#dceefb,stroke:#3b82f6
    style ProactiveAgent fill:#ffd6cc,stroke:#ef4444,stroke-width:3px
    style GoogleAuth fill:#4285f4,stroke:#1976d2
    style FCM fill:#ffa000,stroke:#f57c00
    style RAGIndex fill:#f3e8ff,stroke:#9333ea
    style RAGSearch fill:#f3e8ff,stroke:#9333ea