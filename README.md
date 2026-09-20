# FieldOps - Field Operations + Task Management

Lightweight SMB field operations and task management platform combining task dispatch, field visits, attendance, GPS verification, proof of work, and team monitoring.

---

## 🚀 Implementation Slices

### ✅ Slice 1: Architecture & Authentication Core
In accordance with PRD Sections 24 & 25:
- **Authentication**: Email & Password sign-in, session caching, password reset, sign-out
- **Organization & Multi-Tenancy**: Organization models, user profiles, tenant isolation
- **Role-Based Access Control (RBAC)**:
  - **Owner / Admin** (`admin@fieldops.com` / `password123`)
  - **Manager** (`manager@fieldops.com` / `password123`)
  - **Field Employee** (`employee@fieldops.com` / `password123`)
- **Backend & Database Migrations**:
  - `supabase/migrations/20260920000001_auth_org_user_role_rls.sql`: Core tables, helper functions, and Row-Level Security (RLS) policies
  - `supabase/migrations/20260920000002_core_v1_tables.sql`: Full V1 schema (Teams, Tasks, Visits, Attendance, Forms, Attachments, Sync Queue) with RLS
- **State Handling**: Content, Loading (`LoadingView`), Empty (`EmptyStateView`), Error (`ErrorStateView`)

### ✅ Slice 2: Task Engine, Lifecycle & Offline Caching
In accordance with PRD Sections 24, 25 & 26:
- **Domain Layer**:
  - `TaskEntity`, `TaskPriority` (`low`, `medium`, `high`, `urgent`), `TaskStatus` (`draft`, `assigned`, `accepted`, `inProgress`, `completed`, `cancelled`, `overdue`)
  - Status transition machine (`canTransitionTo`) enforcing valid status workflows
  - Operational guards (`canStart`, `canComplete`, `isOverdue`)
  - `TaskFilter` supporting status filtering, priority filtering, assigned user filtering, and text search
  - 7 Use Cases: `GetTasksUseCase`, `GetTaskDetailUseCase`, `CreateTaskUseCase`, `AssignTaskUseCase`, `UpdateTaskStatusUseCase`, `StartTaskUseCase`, `CompleteTaskUseCase`
- **Data Layer & Offline Fallback**:
  - `TaskModel` with JSON serialization and Supabase joins
  - `TaskLocalDataSource` (SharedPreferences + memory cache) providing resilient offline task caching and local status updates
  - `TaskRepositoryImpl` with automatic offline fallback when network is unavailable
- **Presentation Layer**:
  - `TaskListNotifier` and `TaskDetailNotifier` Riverpod controllers
  - `TaskListScreen`: Status tabs (All, To Do, In Progress, Completed), search filter, pull-to-refresh, status chips, role-guarded FAB
  - `CreateTaskScreen`: Form validation, priority selector, due date picker, mandatory proof switches (photo, signature, notes)
  - `TaskDetailScreen`: Customer & location details, proof requirement checklist, action buttons (`Start Task`, `Complete Task`)
- **Backend Migrations**:
### ✅ Slice 3: Customers, Locations, GPS Radius Verification & Field Visits
In accordance with PRD Sections 6, 8, 10, 24, 25 & 27:
- **Core GPS & Geofencing Engine (`lib/core/location/`)**:
  - `LocationCoordinates`: Standardized coordinates entity with latitude, longitude, accuracy, and timestamp.
  - `GpsDistanceEngine`: Haversine formula calculation, geofence radius verification (`checkRadius`), delta distance calculation, and human-readable formatting (`km`/`m`).
  - `LocationService`: Service abstraction with `GeolocatorLocationService` implementation and `MockLocationService` for unit/widget testing.
- **Customers & Locations (`lib/features/customers/`)**:
  - `CustomerEntity`, `LocationEntity`, `CustomerModel`, `LocationModel`.
  - Data sources (`CustomerLocalDataSourceImpl` with in-memory & SharedPreferences caching, `CustomerRemoteDataSource`, `MockCustomerRemoteDataSource`).
  - `CustomerRepositoryImpl` with offline fallback.
  - Use cases: `GetCustomersUseCase`, `GetCustomerDetailUseCase`, `CreateCustomerUseCase`, `CreateLocationUseCase`, `GetLocationsUseCase`.
  - UI: `CustomerListScreen` (search, customer card list, add customer FAB), `CustomerDetailScreen` (profile, contact info, site list, add site dialog), `CreateCustomerScreen`, `CreateLocationDialog`.
- **Field Visits (`lib/features/visits/`)**:
  - `VisitEntity`, `VisitModel` with duration calculation, completion status, and coordinate tracking.
  - Use cases: `GetVisitsUseCase`, `GetActiveVisitUseCase`, `VisitCheckInUseCase` (enforcing geofence radius validation via `GpsDistanceEngine`), `VisitCheckOutUseCase`.
  - UI: `VisitListScreen` (All, Active, Completed tabs), `VisitDetailScreen` (GPS execution audit, check-in/out timestamps, coordinates), `GpsVisitExecutionCard` (embedded in task detail).
- **Backend Migrations**:
  - `supabase/migrations/20260920000004_customers_locations_visits.sql`: Composite indexes on `customers`, `locations`, `visits`, notes column support, and `log_visit_activity()` trigger.

### ✅ Slice 4: Custom Forms & Dynamic Form Builder
In accordance with PRD Sections 9, 24, 25 & 27:
- **Domain Layer (`lib/features/forms/domain/`)**:
  - `FormFieldType` (`text`, `multiline`, `number`, `date`, `select`, `checkbox`) with icons, display titles, and validation logic.
  - `FormFieldDefinition`: Field schema with ID, label, type, required flag, placeholder, options list, default value, and help text.
  - `FormSchemaEntity`: Schema container with comprehensive field-level validation (`validate(data)` returning map of field errors).
  - `CustomFormEntity`: Custom form definition with field count and submission counts.
  - `FormSubmissionEntity`: Form submission entity with GPS location audit, submitted timestamp, form and task metadata, and dynamic response data map.
  - Use cases: `GetFormsUseCase`, `GetFormDetailUseCase`, `CreateFormUseCase`, `UpdateFormUseCase`, `DeleteFormUseCase`, `GetFormSubmissionsUseCase`, `SubmitFormUseCase` (with automatic GPS capture).
- **Data Layer & Offline Caching (`lib/features/forms/data/`)**:
  - `CustomFormModel`: JSON serialization with flexible JSON/String schema parsing and `copyWith`.
  - `FormSubmissionModel`: JSON serialization with joined user and task information.
  - `FormsLocalDataSource`: Memory and SharedPreferences caching with draft auto-save and clear support.
  - `FormsRemoteDataSource` & `MockFormsRemoteDataSource`: Pre-seeded real-world forms ("HVAC & Mechanical Maintenance Checklist", "Site Safety & PPE Audit", "Customer Service Acceptance Sign-Off") and submissions.
  - `FormsRepositoryImpl`: Remote execution with offline cache fallback and draft clearance on submission.
- **Presentation Layer (`lib/features/forms/presentation/`)**:
  - `FormsListNotifier`: Forms catalogue search, loading, and deletion.
  - `FormBuilderNotifier`: Visual form builder with interactive field addition, modification, reordering, and saving.
  - `FormFillerNotifier`: Form execution controller with auto-loaded form definitions, draft auto-restore, input validation, and automatic GPS capture.
  - `TaskFormSubmissionsNotifier`: Task-specific form submission history and status tracking.
  - UI Components:
    - `FormsManagementScreen`: Admin/Manager catalogue with search, card list, and form creation launcher.
    - `FormBuilderScreen`: Dynamic form designer with field type selector, properties modal, and field card reordering.
    - `FillFormScreen`: Dynamic field renderer for all 6 input types with validation error feedback and auto-GPS submission.
    - `FormSubmissionsScreen`: Submission history viewer with expandable cards and GPS audit coordinates.
    - `TaskFormExecutionCard`: Embedded task checklist card displaying PENDING/COMPLETED status badges and navigation to fill/view submissions.
- **Navigation & Shell Integration**:
  - `AdminSettingsScreen`: Dedicated administrative settings screen hosting the Custom Forms builder launcher.
  - `AdminShellScreen`: Updated Tab 3 to render `AdminSettingsScreen`.
  - `AppRouter`: Added `/forms`, `/forms/builder`, `/forms/:id/fill`, `/forms/:id/submissions`, and `/tasks/:id/submissions`.
  - `TaskDetailScreen`: Embedded `TaskFormExecutionCard` for tasks requiring forms.
- **Backend Migrations**:
  - `supabase/migrations/20260920000006_forms_indexes_and_triggers.sql`: Composite indexes on `forms` and `form_submissions`, and audit activity logging trigger `log_form_submission_activity()`.

### ✅ Slice 5: Attendance Logging, GPS Verification & Team Attendance
In accordance with PRD Sections 7, 24, 25 & 27:
- **Domain Layer (`lib/features/attendance/domain/`)**:
  - `AttendanceEntity` & `AttendanceStatus` (`PRESENT`, `ABSENT`, `HALF_DAY`, `ON_LEAVE`).
  - Automated working duration calculation (`workingDuration`, `formattedDuration`, `formattedCheckInTime`, `formattedCheckOutTime`).
  - Use cases: `GetTodayAttendanceUseCase`, `GetAttendanceHistoryUseCase`, `GetTeamAttendanceUseCase`, `AttendanceCheckInUseCase` (GPS auto-capture, duplicate prevention), `AttendanceCheckOutUseCase` (GPS auto-capture, total duration calculation).
- **Data Layer & Offline Fallback (`lib/features/attendance/data/`)**:
  - `AttendanceModel` with Supabase joined user profiles and JSON serialization.
  - `AttendanceLocalDataSource` with in-memory & SharedPreferences caching.
  - `AttendanceRepositoryImpl` supporting seamless offline check-in/out and cached history.
- **Presentation Layer (`lib/features/attendance/presentation/`)**:
  - `TodayAttendanceNotifier`: Tracks current shift status, live working time counter, GPS coordinates, check-in/out lifecycle.
  - `AttendanceHistoryNotifier`: Individual monthly/weekly logs with total days present and hours worked.
  - `TeamAttendanceNotifier`: Manager/Admin view with date navigation, status statistics (Present, Half Day, On Leave, Total), and filter chips.
  - UI Components:
    - `FieldHomeScreen`: Employee hub embedding `AttendanceQuickActionCard`, operations overview, and quick history navigation.
    - `AttendanceQuickActionCard`: One-tap check-in, live elapsed shift timer, check-out confirmation dialog.
    - `TeamAttendanceScreen`: Manager team cockpit with day selector, metrics cards, status filter chips, and employee attendance cards.
    - `MyAttendanceHistoryScreen`: Summary metric cards and list of previous shift logs.
- **Backend Migrations**:
  - `supabase/migrations/20260920000005_attendance_indexes_and_triggers.sql`: Composite indexes, `compute_attendance_duration()` trigger, and audit activity logging trigger `log_attendance_activity()`.

### ✅ Slice 6: Offline Local SQLite Database & Sync Queue Engine
In accordance with PRD Sections 14, 24 & 25:
- **Core Database Engine (`lib/core/database/`)**:
  - `ColumnType` (`text`, `integer`, `real`, `blob`), `ColumnDefinition`, and `DatabaseTable` DDL generator.
  - `SqliteDatabase`: SQL persistence engine supporting `insert`, `query`, `update`, `delete`, `count`, `clearTable`, `clearAll`, and transactional rollback (`transaction<T>`) backed by persistent storage.
  - `AppDatabase`: Pre-configured schema definitions matching Supabase V1 relational schema (`tasks`, `customers`, `locations`, `visits`, `attendance`, `forms`, `form_submissions`, `sync_queue`).
- **Sync Queue Domain Layer (`lib/features/sync/domain/`)**:
  - `SyncOperation` (`create`, `update`, `delete`, `statusChange`), `SyncEntityType` (`task`, `visit`, `attendance`, `form`, `formSubmission`, `customer`, `location`), and `SyncStatus` (`pending`, `syncing`, `synced`, `failed`).
  - `ConflictResolutionStrategy` (`clientWins`, `serverWins`, `merge`).
  - `SyncQueueItem`: Mutation queue item with payload serialization and exponential backoff calculator (`nextBackoffDuration` based on `2^attempts`).
  - `SyncQueueRepository`: Enqueue, peek, mark synced/failed, retry, and clear operations contract.
- **Sync Queue Data Layer (`lib/features/sync/data/`)**:
  - `SyncQueueModel`: Full JSON and SQL row mapping.
  - `SyncQueueLocalDataSourceImpl`: Direct persistence to SQLite `sync_queue` table.
  - `SyncRemoteDataSource` & `MockSyncRemoteDataSource`: Push and pull two-way delta sync operations.
  - `SyncQueueRepositoryImpl`: SQLite-backed sync queue implementation.
- **Sync Engine & Services (`lib/features/sync/services/`)**:
  - `NetworkConnectivityService`: Reactive connectivity stream with simulation controls (`isOnline`, `toggleSimulation`, `setOnline`).
  - `SyncQueueEngine`: Delta synchronization orchestrator with automatic reconnect sync trigger, exponential retry backoff, and conflict resolution execution.
- **Presentation Layer (`lib/features/sync/presentation/`)**:
  - `SyncNotifier`: State management for pending counts, online state, syncing progress, conflict resolution strategy, and manual sync triggers.
  - `SyncStatusBar`: Reusable app-wide sync status widget displaying online/offline status, pending items count, and sync progress.
  - `SyncScreen`: Complete offline cockpit with metrics grid (Pending, In-Flight, Failed, Total), connectivity simulation switch, conflict resolution strategy selector, manual "Sync Now" trigger, and live queue mutation cards.
- **Navigation & Shell Integration**:
  - `AppTopNavBar`: Live sync status icon with pending queue badge and navigation to `/sync`.
  - `AdminSettingsScreen`: "Offline Database & Sync Queue" cockpit launcher tile.
  - `AppRouter`: Registered `/sync` route.
- **Backend Migrations**:
  - `supabase/migrations/20260920000007_sync_queue_indexes_and_conflict_triggers.sql`: Composite indexes on `sync_queue`, batch execution stored procedure `process_sync_queue_batch()`, and audit logging trigger `log_sync_queue_activity()`.

---

### ✅ Slice 7: Proof of Work Attachments & Digital Signatures
In accordance with PRD Sections 11, 24 & 25:
- **Domain Layer (`lib/features/attachments/domain/`)**:
  - `AttachmentType` (`photo`, `signature`, `document`, `notes`).
  - `AttachmentMetadata` with GPS coordinates, accuracy, capture timestamp, device model, signer name/role/email, category (`before`, `after`, `site`, `hazard`, `general`, `customer_signoff`), and tamper-proof watermark text.
  - `DigitalSignatureData`: Stroke vectors (`DigitalSignatureStroke`, `DigitalSignaturePoint`), signer name, role, email, timestamp, and GPS audit.
  - `AttachmentEntity`: Domain entity with formatted size, photo/signature predicates, and inline vector data.
  - `TaskProofStatus`: Evaluates comprehensive proof requirement satisfaction across GPS geofence, mandatory photos, customer sign-off signature, and service checklist forms.
  - Use cases: `GetTaskAttachmentsUseCase`, `UploadAttachmentUseCase`, `SaveSignatureUseCase`, `DeleteAttachmentUseCase`.
- **Data Layer & SQLite Caching (`lib/features/attachments/data/`)**:
  - `AttachmentModel`: JSON and SQL row mapping for SQLite `attachments` table.
  - `AttachmentLocalDataSource`: Memory caching + persistent SQLite `attachments` table + SharedPreferences cache fallback.
  - `AttachmentRemoteDataSource`: Supabase table integration + `MockAttachmentRemoteDataSource` pre-seeded with sample photo proof and supervisor signatures.
  - `AttachmentRepositoryImpl`: Remote execution with SQLite local cache and automatic mutation queuing into `SyncQueueRepository` (`SyncEntityType.attachment`) when offline.
- **Presentation Layer (`lib/features/attachments/presentation/`)**:
  - `TaskAttachmentsNotifier`: Riverpod state controller for task attachments, uploading photo proofs, saving handwritten signatures, deleting attachments, and evaluating proof satisfaction.
  - UI Components:
    - `SignaturePadDialog`: Interactive handwritten signature drawing canvas (`CustomPaint` / `SignaturePainter`) with real-time stroke capture, Undo/Clear actions, signer name and role inputs, optional receipt email, and live GPS watermark coordinates.
    - `PhotoProofPickerDialog`: Photo evidence uploader with category chips (Before Work, After Work, Site Condition, Hazard/Defect, General), mock camera viewfinder preview, and tamper-proof GPS watermark overlay.
    - `AttachmentThumbnailWidget`: Visual photo proof thumbnail card with category badges, timestamp, GPS badge, and click-to-preview fullscreen modal.
    - `SignaturePreviewCard`: Visual card rendering saved vector signature strokes, signer name/role, signed timestamp, and verified sign-off watermark badge.
    - `TaskProofAttachmentsCard`: Embedded card in `TaskDetailScreen` displaying proof checklist progress, photo evidence gallery, captured customer signature, and launcher dialog buttons.
- **Task Lifecycle & Enforcement Integration**:
  - `TaskDetailScreen`: Embedded `TaskProofAttachmentsCard`, added Digital Signature row to proof requirements checklist, and enforced proof satisfaction before task completion with `_showMissingProofDialog` confirmation override.
  - `TaskCard`: Added customer signature required badge icon.
  - `CreateTaskScreen`: Added digital signature required switch toggle.
- **Backend Migrations**:
  - `supabase/migrations/20260920000008_attachments_indexes_and_triggers.sql`: Composite indexes on `attachments` (`task_id`, `visit_id`, `organization_id`, `type`, `uploaded_by`) and audit logging trigger `log_attachment_activity()`.

### Slice 8: Push Notifications, Realtime Geo-Tracking & Observability Dashboard (PRD Sections 12, 13, 24, 25)
- **Domain Entities & Types (`lib/features/notifications/domain/`, `lib/features/dashboard/domain/`)**:
  - `NotificationType` enum (`taskAssigned`, `taskStarted`, `taskCompleted`, `overdueWarning`, `visitAlert`, `attendanceReminder`, `proofVerified`, `systemAnnouncement`) with brand colors, icons, and SQL code parsing.
  - `NotificationEntity` with relative `timeAgo`, `isUnread`, `isRead`, and payload extraction for linked `taskId` and `visitId`.
  - `TechnicianDutyStatus` enum (`onDuty`, `inTransit`, `onSite`, `idle`, `offDuty`) with visual badges and icons.
  - `OperationsMetrics` domain entity with executive and manager KPIs (total technicians, on-duty headcount %, task status distribution, overdue count, completed visits today, total proofs uploaded, proof compliance %).
  - `FieldTechnicianLocation` domain entity for live GPS tracking (lat/long coordinates, accuracy, speed, battery level %, charging state, active task title, active customer visit).
  - `ActivityLogEntity` domain entity for real-time audit logs and operations activity feed.
  - Use cases: `GetNotificationsUseCase`, `MarkNotificationReadUseCase`, `MarkAllReadUseCase`, `SendNotificationUseCase`, `GetOperationsMetricsUseCase`, `GetLiveTechniciansUseCase`, `GetRecentActivityLogsUseCase`.
- **Data Layer & SQLite Caching (`lib/features/notifications/data/`, `lib/features/dashboard/data/`)**:
  - `NotificationModel`, `OperationsMetricsModel`, `FieldTechnicianLocationModel`, `ActivityLogModel`.
  - `NotificationLocalDataSource`: In-memory caching + persistent SQLite `notifications` table + SharedPreferences fallback.
  - `NotificationRemoteDataSource` & `DashboardRemoteDataSource`: Supabase table queries with comprehensive mock implementations pre-seeded with realistic technician fleet telemetry, task alerts, and activity audit events.
  - `NotificationRepositoryImpl` & `DashboardRepositoryImpl`: Offline fallback and mutation sync queuing.
- **Presentation Layer (`lib/features/notifications/presentation/`, `lib/features/dashboard/presentation/`)**:
  - `NotificationsController` Riverpod state notifier managing operational notifications, unread counter badge, filter tabs (All / Unread), optimistic mark as read, and mark all read.
  - `DashboardController` Riverpod state notifier loading organization metrics, live field fleet tracking, and activity audit feed.
  - UI Components:
    - `NotificationBadgeIcon`: Reactive notification bell with live unread counter badge overlay for app bars.
    - `NotificationItemCard`: Notification item card with type branding, unread indicator, contextual task/visit navigation chip, and mark as read action.
    - `NotificationListScreen`: Notifications center with All / Unread filter chips, pull-to-refresh, empty state, and mark all read button.
    - `MetricSummaryCard`: High-impact KPI tile displaying metric value, delta/badge, icon, title, and context subtitle.
    - `TaskDistributionCard`: Visual breakdown of task statuses (Assigned, In Progress, Completed, Overdue) with multi-segment progress bar and legend percentages.
    - `TechnicianGeoRadarCard`: Live fleet radar tracker with flashing "LIVE" badge, technician duty status, battery %, GPS lat/lng, and active assignment.
    - `ActivityStreamCard`: Live operations activity audit feed showing real-time field actions.
    - `AdminDashboardScreen`: Complete executive command center replacing placeholder on AdminShellScreen (Tab 0).
    - `ManagerDashboardScreen`: Team operations cockpit replacing placeholder on ManagerShellScreen (Tab 0).
- **Navigation & Shell Wiring**:
  - Replaced Tab 0 in `AdminShellScreen` with `AdminDashboardScreen`.
  - Replaced Tab 0 in `ManagerShellScreen` with `ManagerDashboardScreen`.
  - Replaced Tab 3 in `EmployeeShellScreen` with `NotificationListScreen`.
  - Added `NotificationBadgeIcon` to universal `AppTopNavBar`.
  - Added `/notifications` route in `AppRouter`.
- **Backend Migrations**:
  - `supabase/migrations/20260920000009_notifications_and_observability.sql`: Composite indexes on `notifications` (`user_id`, `type`, `created_at`, `read_at`), indexes on `activity_logs`, and automated database triggers `notify_task_assigned()` and `notify_task_completed()`.

---

## 📁 Project Directory Structure

```
/workspace/quiet-lovelace
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── config/             # SupabaseConfig (with fallback demo mode)
│   │   ├── constants/          # AppConstants, AppColors
│   │   ├── database/           # ColumnDefinition, DatabaseTable, SqliteDatabase, AppDatabase
│   │   ├── errors/             # Failures and Exceptions
│   │   ├── location/           # LocationCoordinates, GpsDistanceEngine, LocationService
│   │   ├── theme/              # AppTheme (Material 3, typography, buttons)
│   │   └── widgets/            # AppButton, AppTextField, LoadingView, EmptyStateView, ErrorStateView, RoleBadge
│   └── features/
│       ├── auth/               # Models, DataSources, Repository, UseCases, AuthNotifier, LoginScreen
│       ├── organization/       # Organization domain & data layers
│       ├── tasks/              # TaskModel, TaskLocalDataSource, TaskRemoteDataSource, TaskRepository, UseCases, Screens
│       ├── customers/          # CustomerModel, LocationModel, Repository, UseCases, CustomerList/Detail Screens
│       ├── visits/             # VisitModel, Repository, UseCases, VisitList/Detail Screens, GpsVisitExecutionCard
│       ├── attendance/         # AttendanceModel, Repository, UseCases, FieldHome, TeamAttendance & History Screens
│       ├── forms/              # CustomFormModel, FormSubmissionModel, Repository, Dynamic Form Renderer & Builder
│       ├── sync/               # SyncQueueEngine, NetworkConnectivityService, SyncNotifier, SyncStatusBar, SyncScreen
│       ├── attachments/        # AttachmentModel, SignaturePadDialog, PhotoProofPicker, TaskProofAttachmentsCard, Repository, Controller
│       ├── notifications/      # NotificationModel, Local/Remote DataSources, Repository, Controller, NotificationBadgeIcon, NotificationListScreen
│       ├── dashboard/          # OperationsMetrics, FieldTechnicianLocation, GeoRadarCard, AdminDashboardScreen, ManagerDashboardScreen
│       ├── reports/            # CsvExportService, FieldOperationsReport, TechnicianPerformance, ReportsController, FieldReportsScreen, CSV Export Center
│       └── navigation/         # GoRouter, AdminShellScreen, ManagerShellScreen, EmployeeShellScreen, AdminSettingsScreen, AppTopNavBar
├── supabase/
│   └── migrations/
│       ├── 20260920000001_auth_org_user_role_rls.sql
│       ├── 20260920000002_core_v1_tables.sql
│       ├── 20260920000003_tasks_activity_and_indexes.sql
│       ├── 20260920000004_customers_locations_visits.sql
│       ├── 20260920000005_attendance_indexes_and_triggers.sql
│       ├── 20260920000006_forms_indexes_and_triggers.sql
│       ├── 20260920000007_sync_queue_indexes_and_conflict_triggers.sql
│       ├── 20260920000008_attachments_indexes_and_triggers.sql
│       ├── 20260920000009_notifications_and_observability.sql
│       └── 20260920000010_reports_and_analytics_views.sql
└── test/
    ├── unit/
    │   ├── user_role_test.dart
    │   ├── user_model_test.dart
    │   ├── auth_repository_test.dart
    │   ├── auth_controller_test.dart
    │   ├── task_model_test.dart
    │   ├── task_repository_test.dart
    │   ├── task_controller_test.dart
    │   ├── gps_distance_engine_test.dart
    │   ├── customer_model_test.dart
    │   ├── visit_model_test.dart
    │   ├── customer_repository_test.dart
    │   ├── visit_usecases_test.dart
    │   ├── customer_and_visit_controller_test.dart
    │   ├── attendance_model_test.dart
    │   ├── attendance_repository_test.dart
    │   ├── attendance_usecases_test.dart
    │   ├── attendance_controller_test.dart
    │   ├── form_model_test.dart
    │   ├── forms_repository_test.dart
    │   ├── forms_usecases_test.dart
    │   ├── forms_controller_test.dart
    │   ├── sqlite_database_test.dart
    │   ├── sync_queue_engine_test.dart
    │   ├── sync_controller_test.dart
    │   ├── attachment_model_test.dart
    │   ├── attachment_repository_test.dart
    │   ├── attachment_controller_test.dart
    │   ├── notification_model_test.dart
    │   ├── notification_repository_test.dart
    │   ├── dashboard_controller_test.dart
    │   ├── csv_export_service_test.dart
    │   ├── reports_models_test.dart
    │   ├── reports_repository_test.dart
    │   └── reports_controller_test.dart
    └── widget/
        ├── login_screen_test.dart
        ├── role_navigation_test.dart
        ├── task_list_screen_test.dart
        ├── task_detail_screen_test.dart
        ├── create_task_screen_test.dart
        ├── customer_screens_test.dart
        ├── visit_screens_test.dart
        ├── attendance_widgets_test.dart
        ├── forms_screens_test.dart
        ├── sync_screens_test.dart
        ├── task_proof_attachments_widget_test.dart
        ├── notification_screens_test.dart
        ├── dashboard_screens_test.dart
        └── field_reports_screen_test.dart
```

---

## 🧪 Verification & Testing

To run static analysis:
```bash
flutter analyze
```

To execute the full test suite (257 passing tests):
```bash
flutter test
```

### Pre-configured Demo Accounts
For rapid manual verification on the Login screen, click any of the 1-tap quick buttons:
- **Admin**: `admin@fieldops.com` / `password123` -> routes to Executive Command Center `/admin/dashboard` & Organization Settings (with Field Reports access)
- **Manager**: `manager@fieldops.com` / `password123` -> routes to Team Operations Cockpit `/manager/dashboard` & Tab 4 Field Reports Screen
- **Field Employee**: `employee@fieldops.com` / `password123` -> routes to `/employee/home`, `/employee/tasks`, `/employee/visits` & `/notifications`

---

## 🗺️ Next Vertical Slices

1. **Slice 10**: Multi-tenant Admin Portal, Organization Settings & Role Permission Customization (PRD Sections 14, 15, 26)
