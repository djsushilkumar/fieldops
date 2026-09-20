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

---

## 📁 Project Directory Structure

```
/workspace/quiet-lovelace
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── config/             # SupabaseConfig (with fallback demo mode)
│   │   ├── constants/          # AppConstants, AppColors
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
│       └── navigation/         # GoRouter, AdminShellScreen, ManagerShellScreen, EmployeeShellScreen, AdminSettingsScreen
├── supabase/
│   └── migrations/
│       ├── 20260920000001_auth_org_user_role_rls.sql
│       ├── 20260920000002_core_v1_tables.sql
│       ├── 20260920000003_tasks_activity_and_indexes.sql
│       ├── 20260920000004_customers_locations_visits.sql
│       ├── 20260920000005_attendance_indexes_and_triggers.sql
│       └── 20260920000006_forms_indexes_and_triggers.sql
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
    │   └── forms_controller_test.dart
    └── widget/
        ├── login_screen_test.dart
        ├── role_navigation_test.dart
        ├── task_list_screen_test.dart
        ├── task_detail_screen_test.dart
        ├── create_task_screen_test.dart
        ├── customer_screens_test.dart
        ├── visit_screens_test.dart
        ├── attendance_widgets_test.dart
        └── forms_screens_test.dart
```

---

## 🧪 Verification & Testing

To run static analysis:
```bash
flutter analyze
```

To execute the full test suite:
```bash
flutter test
```

### Pre-configured Demo Accounts
For rapid manual verification on the Login screen, click any of the 1-tap quick buttons:
- **Admin**: `admin@fieldops.com` / `password123` -> routes to `/admin/tasks`, `/admin/customers` & `/admin/settings` (Custom Forms launcher)
- **Manager**: `manager@fieldops.com` / `password123` -> routes to `/manager/tasks`, `/manager/visits` & `/manager/attendance`
- **Field Employee**: `employee@fieldops.com` / `password123` -> routes to `/employee/home`, `/employee/tasks` & `/employee/visits`

---

## 🗺️ Next Vertical Slices

1. **Slice 6**: Offline Local SQLite Database & Sync Queue Engine (PRD Sections 14, 24, 25)
2. **Slice 7**: Proof of Work Attachments & Digital Signatures (PRD Sections 11, 24, 25)
3. **Slice 8**: Push Notifications & Background Location Updates (PRD Sections 12, 13, 24, 25)



