# FieldOps - Field Operations + Task Management

Lightweight SMB field operations and task management platform combining task dispatch, field visits, attendance, GPS verification, proof of work, and team monitoring.

---

## 🚀 First Implementation Slice: Architecture & Authentication Core

In accordance with the PRD specification (Section 24 & 25), Slice 1 implements:
- **Authentication**: Email & Password sign-in, session caching, password reset, sign-out
- **Organization & Multi-Tenancy**: Organization models, user profiles, tenant isolation
- **Role-Based Access Control (RBAC)**:
  - **Owner / Admin** (`admin@fieldops.com` / `password123`)
  - **Manager** (`manager@fieldops.com` / `password123`)
  - **Field Employee** (`employee@fieldops.com` / `password123`)
- **Backend & Database Migrations**:
  - `supabase/migrations/20260920000001_auth_org_user_role_rls.sql`: Core tables, helper functions, and Row-Level Security (RLS) policies
  - `supabase/migrations/20260920000002_core_v1_tables.sql`: Full V1 schema (Teams, Tasks, Visits, Attendance, Forms, Attachments, Sync Queue) with RLS
- **Clean Architecture**:
  - `core/`: Constants, Theme, Errors/Failures, Network/Supabase config, Reusable UI widgets
  - `features/auth/`: Domain entities, repositories, use cases, data sources, Riverpod controllers, UI screens
  - `features/organization/`: Domain & Data layer for organization settings
  - `features/navigation/`: GoRouter configuration with reactive redirect guards and dedicated Shells for each role (Admin, Manager, Employee)
- **State Handling**:
  - ✅ Content State
  - ✅ Loading State (`LoadingView`)
  - ✅ Empty State (`EmptyStateView`)
  - ✅ Error State (`ErrorStateView`)
- **Testing & Quality Assurance**:
  - 100% passing tests (22/22 tests pass)
  - 0 static analysis issues (`flutter analyze` clean)

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
│   │   ├── theme/              # AppTheme (Material 3, typography, buttons)
│   │   └── widgets/            # AppButton, AppTextField, LoadingView, EmptyStateView, ErrorStateView, RoleBadge
│   └── features/
│       ├── auth/
│       │   ├── data/           # Models, Local & Remote (Supabase + Mock) DataSources, RepositoryImpl
│       │   ├── domain/         # Entities (UserEntity, UserRole, AuthSession), Repository Interfaces, UseCases
│       │   └── presentation/   # Riverpod AuthNotifier, LoginScreen, ForgotPasswordScreen, SplashScreen
│       ├── organization/       # Organization domain & data layers
│       └── navigation/         # GoRouter, AdminShellScreen, ManagerShellScreen, EmployeeShellScreen, SlicePlaceholderScreen
├── supabase/
│   └── migrations/
│       ├── 20260920000001_auth_org_user_role_rls.sql
│       └── 20260920000002_core_v1_tables.sql
└── test/
    ├── unit/
    │   ├── user_role_test.dart
    │   ├── user_model_test.dart
    │   ├── auth_repository_test.dart
    │   └── auth_controller_test.dart
    └── widget/
        ├── login_screen_test.dart
        └── role_navigation_test.dart
```

---

## 🧪 Verification & Testing

To run static analysis:
```bash
flutter analyze
```

To execute the test suite:
```bash
flutter test
```

### Pre-configured Demo Accounts
For rapid manual verification on the Login screen, click any of the 1-tap quick buttons:
- **Admin**: `admin@fieldops.com` / `password123` -> routes to `/admin/dashboard`
- **Manager**: `manager@fieldops.com` / `password123` -> routes to `/manager/dashboard`
- **Field Employee**: `employee@fieldops.com` / `password123` -> routes to `/employee/home`

---

## 🗺️ Next Vertical Slices

1. **Slice 2**: Task Engine (Task Creation, Assignment, Employee Task List, Status Lifecycle)
2. **Slice 3**: Customers, Locations, GPS Radius Verification, Field Visits
3. **Slice 4**: Forms & Custom Form Builder
4. **Slice 5**: Attendance Logging (Check-in, Check-out, GPS, Working Duration)
5. **Slice 6**: Offline Local SQLite Database & Sync Queue
