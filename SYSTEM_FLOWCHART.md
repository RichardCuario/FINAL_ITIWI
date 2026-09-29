# iTIWI Complete System Flowchart

This flowchart is based on the current Flutter mobile app, `adminside`, backend services, Firebase, and Supabase integration.

## End-to-End System Flow

```mermaid
flowchart TD
    Start([Start]) --> FirstRun{First app launch?}
    FirstRun -->|Yes| Onboarding[Onboarding]
    FirstRun -->|No| AuthState{Firebase session exists?}
    Onboarding --> Auth[Sign in or create account]
    Auth --> AuthState

    AuthState -->|No| Auth
    AuthState -->|Yes| Active{User account active?}
    Active -->|No| Blocked[Show account inactive message]
    Active -->|Yes| MobileHome[Mobile Home]

    MobileHome --> PublicFeatures[Public features]
    MobileHome --> ProtectedFeatures[Protected features]
    MobileHome --> AccountFeatures[Account features]

    subgraph PublicFeatures [Public mobile features]
        Barangay[Barangay information]
        News[Published news and announcements]
        Tourist[Tourist guide and places]
        Hotlines[Emergency hotlines]
        Transparency[Transparency documents]
        FAQ[FAQs]
    end

    subgraph ProtectedFeatures [Identity-gated mobile features]
        Gate[Check identity_verification status]
        Verify[Submit or resubmit identity verification]
        Report[Submit concern or incident report]
        MyReports[View my reports and statuses]
        Services[Online services]
    end

    subgraph AccountFeatures [Account and device features]
        Profile[Edit profile and preferences]
        Notifications[Notifications and local cache]
        SignOut[Sign out]
    end

    ProtectedFeatures --> Gate
    Gate -->|Not verified| Verify
    Gate -->|Verified| Report
    Gate -->|Verified| MyReports
    Gate -->|Verified| Services
    Verify --> VerificationPending[Verification status: pending]
    VerificationPending --> AdminReview

    Report --> ReportForm[Enter message and optional images]
    ReportForm --> ReportInsert[Insert report with status pending]
    ReportInsert --> ReportImages[Upload report images to Supabase Storage]
    ReportImages --> ReportRecord[Update report with image URLs]
    ReportRecord --> AdminReview

    Services --> ServiceChoice{Choose service}
    ServiceChoice --> Birth[Birth certificate appointment]
    ServiceChoice --> Marriage[Marriage certificate appointment]
    ServiceChoice --> Death[Death certificate appointment]
    ServiceChoice --> CENODEATH[CENODEATH appointment]
    ServiceChoice --> CENOMAR[CENOMAR appointment]
    ServiceChoice --> Facility[Facility borrow request]
    Birth --> ServicePending[Request inserted with status pending]
    Marriage --> ServicePending
    Death --> ServicePending
    CENODEATH --> ServicePending
    CENOMAR --> ServicePending
    Facility --> ServicePending
    ServicePending --> AdminReview

    subgraph AdminSide [Admin web dashboard]
        AdminLogin[Admin login]
        AdminSession{Valid Supabase session?}
        RoleCheck[Resolve role and permissions]
        Dashboard[Dashboard and analytics]
        ManageContent[Manage Barangay, News, Tourist Guide, Transparency, Hotlines]
        ManageRequests[Review Reports and Online Services]
        ManageVerification[Review identity verification]
        ManageUsers[Manage Users]
        ManageAdmins[Manage Admin roles and permissions]
        AdminProfile[Edit admin profile]
        AdminLogout[Logout]
    end

    AdminLogin --> AdminSession
    AdminSession -->|No| AdminLogin
    AdminSession -->|Yes| RoleCheck
    RoleCheck -->|Super Admin| AllPages[All dashboard sections]
    RoleCheck -->|Assigned permissions| AllowedPages[Permitted dashboard sections]
    AllPages --> Dashboard
    AllowedPages --> Dashboard
    Dashboard --> ManageContent
    Dashboard --> ManageRequests
    Dashboard --> ManageVerification
    Dashboard --> ManageUsers
    Dashboard --> ManageAdmins
    Dashboard --> AdminProfile
    ManageContent --> ContentUpdate[Create, update, schedule, or delete records]
    ContentUpdate --> Supabase[(Supabase database)]
    ManageRequests --> RequestDecision{Review request}
    ManageVerification --> VerificationDecision{Review identity data and photos}
    ManageUsers --> UserData[Read, sync, or remove user records]
    ManageAdmins --> RoleData[Store local admin roles and permissions]
    AdminProfile --> Supabase
    AdminLogout --> AdminLogin

    AdminReview --> ManageRequests
    AdminReview --> ManageVerification
    RequestDecision -->|Pending| ServicePending
    RequestDecision -->|Processing| ServiceProcessing[Request status processing]
    RequestDecision -->|Approved or completed| ServiceApproved[Request status approved or completed]
    RequestDecision -->|Rejected| ServiceRejected[Request status rejected]
    VerificationDecision -->|Verified| Verified[Identity status verified]
    VerificationDecision -->|Rejected with reason| Rejected[Identity status rejected]
    VerificationDecision -->|Needs review| VerificationPending
    Rejected --> Verify
    Verified --> Gate

    ServiceProcessing --> Notify
    ServiceApproved --> Notify
    ServiceRejected --> Notify
    ReportRecord --> Notify
    Verified --> Notify
    Rejected --> Notify

    subgraph Notify [Feedback and notification loop]
        DatabaseChange[Supabase record/status change]
        FCM[Firebase Cloud Messaging topic]
        Push[Push notification]
        LocalCache[Local notification cache]
        MobileRefresh[Refresh mobile status on next load]
    end

    DatabaseChange --> FCM --> Push --> LocalCache --> Notifications
    DatabaseChange --> MobileRefresh --> MyReports
    DatabaseChange --> MobileRefresh --> Services

    subgraph Backend [Supporting services]
        FirebaseAuth[Firebase Authentication]
        FirebaseAdmin[Firebase Admin SDK]
        BackendAPI[Node/Express or admin API]
        UserSync[Sync Firebase users to Supabase users]
    end

    Auth -.-> FirebaseAuth
    AdminLogin -.-> Supabase
    Dashboard -.-> BackendAPI
    BackendAPI -.-> FirebaseAdmin
    FirebaseAdmin -.-> UserSync -.-> Supabase
    FirebaseAuth -.-> UserSync

    Supabase --> DataAccess[Supabase queries, RLS, storage, RPCs]
    DataAccess --> Barangay
    DataAccess --> News
    DataAccess --> Tourist
    DataAccess --> Hotlines
    DataAccess --> Transparency
    DataAccess --> ReportRecord
    DataAccess --> MyReports
    DataAccess --> ServicePending
    DataAccess --> Gate
```

## Admin Decision Flows

```mermaid
flowchart LR
    Admin[Authenticated admin] --> Permission{Has permission?}
    Permission -->|No| DashboardOnly[Dashboard only]
    Permission -->|Yes| Section[Open permitted section]

    Section --> Content[Content management]
    Section --> ReportReview[Reports]
    Section --> ServiceReview[Online services]
    Section --> IdentityReview[Identity verification]
    Section --> Users[Users]
    Section --> AdminRoles[Manage admin]

    Content --> ContentAction{Action}
    ContentAction --> Create[Create]
    ContentAction --> Edit[Edit]
    ContentAction --> Schedule[Schedule news]
    ContentAction --> Delete[Delete after confirmation]
    Create --> ContentSaved[Supabase record saved]
    Edit --> ContentSaved
    Schedule --> ContentSaved
    Delete --> ContentSaved
    ContentSaved --> MobileContent[Mobile app reads published content]

    ReportReview --> ReportStatus{Set report status}
    ReportStatus --> Pending[Pending]
    ReportStatus --> Reviewing[Reviewing]
    ReportStatus --> Resolved[Resolved or approved]
    ReportStatus --> RejectedReport[Rejected with reason]
    Pending --> ReportSaved[Supabase report update]
    Reviewing --> ReportSaved
    Resolved --> ReportSaved
    RejectedReport --> ReportSaved
    ReportSaved --> ReportNotification[Report status notification]

    ServiceReview --> ServiceStatus{Set request status}
    ServiceStatus --> Processing[Processing]
    ServiceStatus --> Completed[Completed or approved]
    ServiceStatus --> RejectedService[Rejected]
    Processing --> ServiceSaved[Supabase service-table update]
    Completed --> ServiceSaved
    RejectedService --> ServiceSaved
    ServiceSaved --> ServiceNotification[Online service notification]

    IdentityReview --> IdentityStatus{Set verification status}
    IdentityStatus --> VerifiedStatus[Verified]
    IdentityStatus --> RejectedIdentity[Rejected with reason]
    VerifiedStatus --> VerificationSaved[Update verification and user access]
    RejectedIdentity --> VerificationSaved
    VerificationSaved --> IdentityNotification[Identity status notification]
```

## Main Data Stores and Integrations

```mermaid
flowchart TB
    Mobile[Flutter mobile app] --> Firebase[Firebase Auth]
    Mobile --> SupabaseClient[Supabase client]
    Mobile --> Storage[Supabase Storage]
    Mobile --> FCM[Firebase Cloud Messaging]

    Admin[Adminside web app] --> SupabaseClient
    Admin --> AdminAPI[Admin API endpoints]
    AdminAPI --> FirebaseAdmin[Firebase Admin SDK]
    AdminAPI --> SupabaseService[Supabase users table]
    Backend[Node backend] --> FirebaseAdmin
    Backend --> SupabaseService
    FirebaseFunctions[Firebase Functions] --> SupabaseService

    SupabaseClient --> Tables[(Supabase tables)]
    SupabaseService --> Tables
    Storage --> Files[(Report and identity files)]
    FCM --> Topics[User-specific status topics]

    Tables --> BarangayTable[barangays]
    Tables --> NewsTable[news]
    Tables --> ReportsTable[reports]
    Tables --> IdentityTable[identity_verification]
    Tables --> ServiceTables[Certificate and facility request tables]
    Tables --> UserTable[users]
    Tables --> PublicTables[places, hotlines, transparency]
```

## Status Summary

| Process | Initial state | Admin outcome | Mobile result |
| --- | --- | --- | --- |
| Identity verification | `pending` | `verified` or `rejected` | Protected features unlock, or resubmission is requested |
| Incident report | `pending` | `reviewing`, `resolved`, or `rejected` | User sees updated report status and notification |
| Online service request | `pending` | `processing`, `completed/approved`, or `rejected` | User sees request status and notification |
| News/content | Draft or scheduled | Published, updated, or deleted | Published records appear in the mobile app |

## Figure 9. Architectural Design

```mermaid
flowchart LR
    Resident[Residents<br/>Mobile Devices]
    Internet((Internet))
    Admin[Barangay Admin<br/>Web Dashboard]

    subgraph Cloud[Cloud System]
        Gateway[Application and<br/>Backend Services]
        Security[Authentication,<br/>Roles and Access Policies]
        Database[(Supabase<br/>Database)]
        Storage[(Supabase<br/>Storage)]
        Firebase[Firebase Services<br/>Authentication and Notifications]
    end

    Resident <--> Internet
    Admin <--> Internet
    Internet <--> Gateway
    Gateway <--> Security
    Security <--> Database
    Security <--> Storage
    Gateway <--> Firebase
    Firebase -. Login and session .-> Resident
    Firebase -. Push notifications .-> Resident
    Database -. Content and status updates .-> Resident
    Database -. Records and management .-> Admin
    Admin -. Reports, services and verification .-> Gateway
    Resident -. Reports, requests and verification .-> Gateway
```

The architectural design shows how residents and barangay administrators interact
with the iTIWI system through separate user interfaces. Residents use the iTIWI
mobile application to access barangay information, view announcements, submit
reports, request online services, complete identity verification, and monitor the
status of their submissions. Barangay administrators use the web-based admin
dashboard to manage system content, review reports, process online service
requests, verify resident identities, and manage users and administrator roles.

Both user interfaces communicate with the cloud system through the internet. The
application and backend services receive requests from the mobile application and
the administrator dashboard, process the required operations, and connect the
users to the appropriate data and supporting services. Firebase Authentication
handles resident account registration, login, and authentication sessions, while
Firebase Cloud Messaging delivers announcements and status notifications to
resident devices.

The security layer represents the authentication, role permissions, database
policies, and storage access rules that protect the system’s resources. After a
request passes the required access controls, the system communicates with the
Supabase database and Supabase Storage. The database stores user profiles,
barangay information, news, reports, online service requests, identity
verification records, and other system data. Supabase Storage stores uploaded
files such as report images and identity verification documents.

Information follows a two-way communication process. Residents send reports,
service requests, and verification information to the system, while administrators
review and update these records through the dashboard. The results are stored in
Supabase and returned to the resident through the mobile application. When an
important status change occurs, such as a report resolution, service approval, or
identity verification decision, Firebase Cloud Messaging sends a notification to
the resident’s device.

This architecture provides a centralized structure for managing barangay services
and information. It connects residents, administrators, application interfaces,
backend services, authentication, cloud storage, and database components into a
single system. Through this arrangement, the iTIWI system supports secure data
handling, efficient communication, organized record management, and timely
feedback to residents.