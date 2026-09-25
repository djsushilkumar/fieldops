# FieldOps - Enterprise Field Operations & Task Management Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL%2015-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Tests](https://img.shields.io/badge/Tests-324%20Passed-brightgreen)](test/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-blueviolet)]()

**FieldOps** is a production-grade, offline-first Field Operations, Task Dispatch, and Team Monitoring platform designed for field service businesses and field sales forces (HVAC, maintenance, FMCG, retail distribution, inspections).

Integrating the best-in-class capabilities of **TaskOPad** (Kanban tasks, Face biometrics, Timesheets) and **Unolo** (Odometer ML OCR, Beat Planning / PJP, Secondary SKU order booking, GPS anti-fraud).

It delivers real-time job dispatch, Haversine GPS geofence arrival verification, automated timesheet attendance, dynamic checklist forms, proof of work attachments, and role-based multi-tenant security.

---

## 📚 Complete Project Documentation Suite

For detailed engineering, database, API, and operations specifications, consult the documentation in [`docs/`](docs/):

| Document | Description |
| :--- | :--- |
| 📋 **[Product Requirements (PRD)](docs/PRD.md)** | Full business goals, user personas, functional specifications across all 10 slices, NFRs, and edge cases. |
| 🛠️ **[Tech Stack & ADRs](docs/TECH_STACK.md)** | Technical stack breakdown, library dependencies, architecture decision records, and benchmarks. |
| 🏛️ **[System Architecture](docs/ARCHITECTURE.md)** | Clean Architecture layers, Riverpod state management, offline SQLite sync engine, Haversine GPS engine, and multi-tenant security model. |
| 🗄️ **[Database Schema & Dictionary](docs/DATABASE_SCHEMA.md)** | Complete Entity-Relationship (ER) mermaid diagram, 19 tables & views specifications, composite indexes, audit triggers, and Row-Level Security (RLS) policies. |
| 🌐 **[REST API Integration Guide](docs/API_DOCUMENTATION.md)** | Full specification for Gotrue Authentication, PostgREST queries, joins, mutations, and curl examples. |
| 📖 **[Operational User Guide](docs/USER_GUIDE.md)** | Step-by-step role-based manual for Field Technicians, Dispatch Managers, and System Administrators. |
| 🔒 **[Security & Compliance](docs/SECURITY_AND_COMPLIANCE.md)** | PostgreSQL Row-Level Security (RLS), OAuth2 PKCE flow, data encryption, and ethical GPS privacy. |
| 🧪 **[Testing Strategy & CI/CD](docs/TESTING_STRATEGY.md)** | Automated test pyramid (313 passing tests), mock architecture, and GitHub Actions CI workflow. |
| 🚀 **[Production Deployment Guide](docs/DEPLOYMENT_GUIDE.md)** | Building & releasing for Android (APK / AAB), Flutter Web (Vercel / Firebase / Cloudflare), iOS, and automated Supabase database deployment. |
| 🏢 **[Competitive Audit & Next-Gen Blueprint](docs/COMPETITIVE_AUDIT_AND_NEXTGEN_BLUEPRINT.md)** | Deep comparative audit of TaskOPad vs Unolo and architectural blueprint for the unified platform. |

---

## ✨ Core Feature Highlights

### 1. 👷 Field Technician Experience
* **GPS Attendance Check-In / Check-Out**: 1-tap clock-in with automated coordinates capture and daily shift duration tracking.
* **Smart Task Dispatch**: Filter by *All*, *To Do*, *In Progress*, and *Completed* work orders.
* **Geofenced Arrival Verification**: Haversine distance engine validates arrival within the customer site radius (e.g. 100m).
* **Proof of Work & Digital Signatures**: Mandatory before/after camera photos, notes, and on-screen customer touch signature pad.
* **Dynamic Inspection Checklists**: In-app execution of custom company forms with automatic GPS tagging.
* **100% Offline Resilience**: Complete functionality without internet; operations queue locally in SQLite and auto-sync when online.

### 2. 👨‍💼 Dispatch & Operations Manager Command Center
* **Live Field Radar**: Map-based GPS tracker displaying real-time locations and operational statuses of all field technicians.
* **Task Scheduling & Assignment**: Create and dispatch emergency or planned work orders with custom proof requirements.
* **Team Monitoring**: Shift attendance overview, arrival logs, and completed job checklist reviews.
* **Operations Analytics & RFC-4180 CSV Export**: One-click export of `Tasks_Export.csv`, `Visits_Audit.csv`, and `Attendance_Payroll.csv`.

### 3. 👑 Multi-Tenant Administrator Portal
* **Organization Settings**: Configure default geofence radii, auto-checkout shift limits, and company-wide proof policies.
* **Dispatch Units**: Organize technicians into squads with designated lead managers and color-coded map pins.
* **Staff Directory**: Manage team members, invite new technicians, and manage account statuses.
* **Role-Based Access Control (RBAC)**: Granular permission toggles (`can_create_tasks`, `can_manage_customers`, `can_export_reports`, `can_manage_forms`).

### 4. 🚀 Next-Gen Enterprise Capabilities (TaskOPad + Unolo Synergy)
* **Conveyance & Odometer OCR Fraud Engine**: Camera OCR digit extraction with letter-to-digit disambiguation ('O'->0, 'l'->1, 'S'->5, 'B'->8), Haversine GPS vs claimed distance discrepancy formula, and manager audit badges.
* **On-Device Face Biometrics Attendance**: FaceNet cosine similarity matcher (<150ms inference, $\ge 0.80$ threshold) with selfie liveness detection and geofence verification.
* **Interactive Task Kanban Board**: Visual 3-stage board (To Do, In Progress, Completed) with direct drag-and-drop progression.
* **Permanent Journey Plan (PJP) & Beat Planning**: Store visit route planning, Traveling Salesperson (TSP) nearest-neighbor route optimizer (reporting km and % saved), and real-time compliance tracking gauge.
* **Field Sales CRM & Secondary SKU Order Booking**: Product catalogue management, real-time cart and multi-tier GST/tax calculations, credit line & instant payment terms, and offline-first SQLite order queueing.

---

## 🏗️ Technology Stack

* **Framework**: Flutter 3.x (Dart 3.x)
* **Architecture**: Clean Architecture (Domain, Data, Presentation)
* **State Management**: Flutter Riverpod (`StateNotifierProvider`, `Provider`)
* **Navigation**: GoRouter with role-based auth guards and splash safety timers
* **Local Persistence & Cache**: SQLite (`sqflite`), `shared_preferences`
* **Geofencing & Location**: `geolocator`, custom Haversine distance engine
* **Backend Database**: Supabase PostgreSQL 15+ with Row-Level Security (RLS)
* **Authentication**: Supabase Gotrue (JWT, PKCE)
* **Testing**: Flutter Test framework (Unit, Widget, and End-to-End integration journeys)

---

## ⚡ Quick Start & Local Setup

### 1. Prerequisites
* Flutter SDK (version >= 3.3.0)
* Android SDK / Android Studio (for Android build)
* Git

### 2. Clone & Install Dependencies
```bash
git clone https://github.com/djsushilkumar/fieldops.git
cd fieldops
flutter pub get
```

### 3. Verify Code Quality & Tests
```bash
# Run static analysis (0 issues)
flutter analyze

# Run all 324 unit, widget, and integration tests
flutter test
```

### 4. Run the Application
```bash
# Run on connected device or emulator
flutter run

# Run on Web (Chrome)
flutter run -d chrome
```

---

## 🚀 Production Deployment & CI/CD

FieldOps is architected to run seamlessly on modern cloud platforms and mobile ecosystems:

| Component | Platform | Configuration & Deployment |
| :--- | :--- | :--- |
| **Backend & DB** | **[Supabase](https://supabase.com)** | PostgreSQL 15+ with Row-Level Security (RLS) and hardened `SECURITY DEFINER` functions. Managed via SQL migrations in [`supabase/migrations/`](supabase/migrations/). |
| **CI/CD Pipeline** | **GitHub Actions** | Automated workflow template in [`ci/ci.yml`](ci/ci.yml) (or `.github/workflows/ci.yml`). Automatically validates code formatting, static analysis (`flutter analyze`), unit and widget tests (`flutter test`), and web builds. |
| **Web Console** | **Web / CDN (Vercel / Firebase / Cloudflare)** | Deployable via standard Flutter Web build (`flutter build web --release`). Pre-configured for Edge CDN hosting with [`vercel.json`](vercel.json). |
| **Mobile App (Android)** | **Android APK / AAB** | Build debug with `flutter build apk --debug`. For production release, configure signing keys in `android/key.properties` (see [`android/key.properties.example`](android/key.properties.example)) or CI environment variables. |

---

## ⚙️ Environment Configuration & Release Setup

### 1. Supabase Environment Variables
Configure your Supabase endpoint and anonymous key via compile-time `--dart-define` flags or a `.env` file (see [`.env.example`](.env.example)):
```bash
# Production Run/Build with Supabase
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your_anon_key

# Release Build for Web
flutter build web --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

### 2. Demo Mode vs Production Mode
- **Production Mode (Default)**: Requires a valid Supabase backend. The login screen renders standard empty input fields without demo personas, and authenticates via real Gotrue credentials.
- **Demo Mode**: Explicitly activated using `--dart-define=FIELDOPS_DEMO_MODE=true`. This enables 1-tap quick persona sign-in (`admin@fieldops.com`, `manager@fieldops.com`, `employee@fieldops.com`) and local mock authentication for offline QA and demos:
```bash
flutter run --dart-define=FIELDOPS_DEMO_MODE=true
```

### 3. Android Production Release Signing
Release builds require a keystore. Never use debug signing keys in production.
1. Copy `android/key.properties.example` to `android/key.properties`.
2. Populate `storeFile`, `storePassword`, `keyAlias`, and `keyPassword` (or export environment variables `KEYSTORE_PATH`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`).
3. Build the production App Bundle or APK:
```bash
flutter build appbundle --release
# or
flutter build apk --release
```
If signing credentials are not provided, release builds will fail safely rather than falling back to debug signing.

---

## 🔑 Demo Personas (When FIELDOPS_DEMO_MODE=true)

When running in demo mode, the login screen features quick persona buttons for testing across all roles:

| Role | Email | Password | Primary Capabilities |
| :--- | :--- | :--- | :--- |
| **Owner / Admin** | `admin@fieldops.com` | `password123` | Full admin portal, staff directory, dispatch teams, RBAC matrix, organization settings |
| **Field Manager** | `manager@fieldops.com` | `password123` | Command center, live GPS radar, task dispatch, team attendance, analytics, CSV reports |
| **Field Technician** | `employee@fieldops.com` | `password123` | Mobile field home, GPS clock-in/out, task execution, geofence visits, proof of work checklists |

---

## 🧪 Automated Test Suite (313 Tests Passing)

FieldOps includes rigorous automated test coverage across all features:

* **Unit Tests (35 test suites)**: Entity validation, status state machines, use case execution, Haversine distance calculation, repository caching, and sync queue conflict resolution.
* **Widget Tests (15 test suites)**: Role navigation shells, login screen validation, task detail checklists, GPS radar cards, and dynamic form renderers.
* **Integration Journeys**: End-to-end user workflows for Employee, Manager, and Admin personas.

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
