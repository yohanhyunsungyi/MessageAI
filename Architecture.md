graph TB
    subgraph iOS["iOS App - Client Side"]
        subgraph Presentation["Presentation Layer"]
            AuthView[Auth Views<br/>SignIn, SignUp, Onboarding]
            MainTab[Main Tab View]
            UsersView[Users List View]
            ConvView[Conversations View]
            ChatView[Chat View<br/>Messages, Input, Bubbles]
            ProfileView[Profile View]
        end
        
        subgraph ViewModels["ViewModel Layer"]
            AuthVM[Auth ViewModel]
            UsersVM[Users ViewModel]
            ConvVM[Conversations ViewModel]
            ChatVM[Chat ViewModel]
        end
        
        subgraph Services["Service Layer"]
            AuthSvc[Auth Service<br/>Email & Google Sign-In]
            UserSvc[User Service<br/>Fetch Users]
            ConvSvc[Conversation Service<br/>Create, Fetch, Update]
            MsgSvc[Message Service<br/>Local-First Send/Receive]
            PresenceSvc[Presence Service<br/>Online/Offline]
            NotifSvc[Notification Service<br/>FCM, Foreground]
            LocalSvc[Local Storage Service<br/>SwiftData]
        end
        
        subgraph Data["Data Layer"]
            Models[Models<br/>User, Message, Conversation]
            LocalModels[Local Models<br/>SwiftData Model]
            LocalDB[(SwiftData<br/>Local Database)]
        end
        
        subgraph SDK["Firebase SDK"]
            FBManager[Firebase Manager<br/>Singleton]
            FBAuth[Firebase Auth SDK]
            FBFirestore[Firestore SDK<br/>Offline Persistence]
            FBFCM[FCM SDK]
        end
    end
    
    subgraph External["External Services"]
        subgraph Google["Google Services"]
            GoogleAuth[Google Sign-In SDK<br/>OAuth 2.0]
        end
        
        subgraph Firebase["Firebase Backend"]
            FirebaseAuth[Firebase Authentication<br/>User Management]
            Firestore[(Cloud Firestore<br/>NoSQL Database)]
            FCM[Firebase Cloud Messaging<br/>Push Notifications]
        end
    end
    
    AuthView --> AuthVM
    UsersView --> UsersVM
    ConvView --> ConvVM
    ChatView --> ChatVM
    
    AuthVM --> AuthSvc
    UsersVM --> UserSvc
    ConvVM --> ConvSvc
    ChatVM --> MsgSvc
    ChatVM --> PresenceSvc
    
    AuthSvc --> FBManager
    UserSvc --> FBManager
    ConvSvc --> FBManager
    MsgSvc --> FBManager
    PresenceSvc --> FBManager
    NotifSvc --> FBManager
    
    MsgSvc --> LocalSvc
    ConvSvc --> LocalSvc
    LocalSvc --> LocalDB
    LocalSvc --> LocalModels
    
    FBManager --> FBAuth
    FBManager --> FBFirestore
    FBManager --> FBFCM
    
    AuthSvc --> GoogleAuth
    GoogleAuth -.OAuth Token.-> FirebaseAuth
    
    FBAuth <-->|REST API| FirebaseAuth
    FBFirestore <-->|WebSocket| Firestore
    FBFCM <-->|HTTP/2| FCM
    
    MsgSvc --> Models
    ConvSvc --> Models
    UserSvc --> Models
    
    MainTab --> UsersView
    MainTab --> ConvView
    MainTab --> ProfileView
    UsersView -.Navigate.-> ChatView
    ConvView -.Navigate.-> ChatView
    
    style LocalDB fill:#e1f5ff
    style Firestore fill:#ffd700
    style FirebaseAuth fill:#ffd700
    style FCM fill:#ffd700
    style LocalSvc fill:#90ee90
    style MsgSvc fill:#90ee90
    style FBFirestore fill:#ff9999
    style GoogleAuth fill:#4285f4