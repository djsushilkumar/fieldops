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
│       └── navigation/         # GoRouter, AdminShellScreen, ManagerShellScreen, EmployeeShellScreen
├── supabase/
│   └── migrations/
│       ├── 20260920000001_auth_org_user_role_rls.sql
│       ├── 20260920000002_core_v1_tables.sql
│       ├── 20260920000003_tasks_activity_and_indexes.sql
│       └── 20260920000004_customers_locations_visits.sql
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
    │   └── customer_and_visit_controller_test.dart
    └── widget/
        ├── login_screen_test.dart
        ├── role_navigation_test.dart
        ├── task_list_screen_test.dart
        ├── task_detail_screen_test.dart
        ├── create_task_screen_test.dart
        ├── customer_screens_test.dart
        └── visit_screens_test.dart
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
- **Admin**: `admin@fieldops.com` / `password123` -> routes to `/admin/tasks`, `/admin/customers` & `/admin/dashboard`
- **Manager**: `manager@fieldops.com` / `password123` -> routes to `/manager/tasks`, `/manager/visits` & `/manager/dashboard`
- **Field Employee**: `employee@fieldops.com` / `password123` -> routes to `/employee/tasks`, `/employee/visits` & `/employee/home`

---

## 🗺️ Next Vertical Slices

1. **Slice 4**: Forms & Custom Form Builder (PRD Sections 9, 24, 25, 27)
2. **Slice 5**: Attendance Logging (Check-in, Check-out, GPS, Working Duration)
3. **Slice 6**: Offline Local SQLite Database & Sync Queue

