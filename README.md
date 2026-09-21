# FieldOps - Enterprise Field Operations & Task Management Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL%2015-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Tests](https://img.shields.io/badge/Tests-287%20Passed-brightgreen)](test/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-blueviolet)]()

**FieldOps** is a production-grade, offline-first Field Operations, Task Dispatch, and Team Monitoring platform designed for field service businesses (HVAC, plumbing, electrical, maintenance, inspections, logistics).

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
| 🧪 **[Testing Strategy & CI/CD](docs/TESTING_STRATEGY.md)** | Automated test pyramid (287 passing tests), mock architecture, and GitHub Actions CI workflow. |
| 🚀 **[Production Deployment Guide](docs/DEPLOYMENT_GUIDE.md)** | Building & releasing for Android (APK / AAB), Flutter Web (Vercel / Firebase / Cloudflare), iOS, and automated Supabase database deployment. |

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

# Run all 287 unit, widget, and integration tests
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

## 🚀 100% Free Cloud Deployment & Easy Upgrades

FieldOps is designed to run completely free without recurring server costs on modern cloud platforms:

| Component | Platform | Free Plan Limits | Deployment & Upgrades |
| :--- | :--- | :--- | :--- |
| **Backend & DB** | **[Supabase Cloud](https://supabase.com)** | 500MB DB, 50k monthly active users, unlimited API requests | Already live at `https://yntpxattrcrshrzptkhs.supabase.co`. Upgraded via migrations in [`supabase/`](supabase/). |
| **Web Console (CI/CD)** | **[GitHub Pages](https://pages.github.com)** | 100GB/mo bandwidth, 100% free | Automated via [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml). Every `git push origin main` auto-builds and updates live site. |
| **Alternative Web Host** | **[Vercel](https://vercel.com)** | 100GB bandwidth, fast global Edge CDN | Import repository at vercel.com. Pre-configured via [`vercel.json`](vercel.json) & [`scripts/vercel_build.sh`](scripts/vercel_build.sh). |
| **Mobile App** | **Android APK** | Self-hosted / Free distribution | Download pre-built [fieldops-apk.zip (89MB)](https://filebin.net/fieldopsrelease/fieldops-apk.zip) or compile with `flutter build apk --release`. |

### Easy Upgrades Workflow
To release a new update to production:
```bash
# 1. Make changes or fixes
git add .
git commit -m "feat: your new feature"

# 2. Push to main branch
git push origin main
```
GitHub Actions automatically runs `flutter analyze`, tests all 287 suites, compiles the web app, and deploys the update with **zero manual downtime**.

---

## 🔑 Quick-Login Demo Personas

The login screen features **1-Tap Quick Persona buttons** for rapid testing across all roles:

| Role | Email | Password | Primary Capabilities |
| :--- | :--- | :--- | :--- |
| **Owner / Admin** | `admin@fieldops.com` | `password123` | Full admin portal, staff directory, dispatch teams, RBAC matrix, organization settings |
| **Field Manager** | `manager@fieldops.com` | `password123` | Command center, live GPS radar, task dispatch, team attendance, analytics, CSV reports |
| **Field Technician** | `employee@fieldops.com` | `password123` | Mobile field home, GPS clock-in/out, task execution, geofence visits, proof of work checklists |

---

## 🧪 Automated Test Suite (287 Tests Passing)

FieldOps includes rigorous automated test coverage across all features:

* **Unit Tests (35 test suites)**: Entity validation, status state machines, use case execution, Haversine distance calculation, repository caching, and sync queue conflict resolution.
* **Widget Tests (15 test suites)**: Role navigation shells, login screen validation, task detail checklists, GPS radar cards, and dynamic form renderers.
* **Integration Journeys**: End-to-end user workflows for Employee, Manager, and Admin personas.

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
