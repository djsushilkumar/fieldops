# FieldOps Production Deployment & Release Guide

This guide covers end-to-end production deployment for the FieldOps mobile app (Android & iOS), Web command center, and backend PostgreSQL database.

---

## 📱 1. Android Packaging & Release

### 1.1 Android Permissions & Capabilities
FieldOps includes production configurations in `android/app/src/main/AndroidManifest.xml`:
* `ACCESS_FINE_LOCATION` & `ACCESS_COARSE_LOCATION` (GPS geofencing & tracking)
* `ACCESS_BACKGROUND_LOCATION` (Optional background field radar)
* `CAMERA` (Proof of work photo capture)
* `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` (Photo caching & CSV report downloads)
* `INTERNET` & `ACCESS_NETWORK_STATE` (Two-way cloud synchronization)

### 1.2 Proguard Obfuscation Rules
Pre-configured in `android/app/proguard-rules.pro` to protect business logic while preserving Flutter and Supabase reflection classes:
```proguard
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep public class * extends io.flutter.embedding.engine.FlutterEngine
```

### 1.3 Building Android Binaries
```bash
# Debug APK (for internal QA & testing)
flutter build apk --debug

# Production Release APK
flutter build apk --release

# Google Play Store App Bundle (AAB)
flutter build appbundle --release
```
* The compiled APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`
* The Google Play App Bundle will be located at: `build/app/outputs/bundle/release/app-release.aab`

---

## 🌐 2. Flutter Web Deployment (Admin & Manager Command Center)

The Flutter Web application serves as the desktop command center for dispatch managers and system administrators.

### 2.1 Compile Web Release Bundle
```bash
flutter build web --release --web-renderer canvaskit
```
Output directory: `build/web/`

### 2.2 100% Free Hosting with Easy Auto-Upgrades

#### 🚀 Recommended Platform 1: GitHub Pages via GitHub Actions (Zero External Accounts, 100% Free)
FieldOps includes a fully configured continuous deployment pipeline in [`.github/workflows/deploy.yml`](file:///workspace/calm-turing/.github/workflows/deploy.yml).

**How it works:**
1. You make changes to your code or add new features.
2. Push your code to GitHub:
   ```bash
   git push origin main
   ```
3. GitHub Actions automatically checks out your code, runs static analysis (`flutter analyze`), executes all 287 automated tests (`flutter test`), compiles the production Web application (`flutter build web --release`), and deploys it live to GitHub Pages in ~2 minutes!
4. **Zero manual intervention required for upgrades.**

> [!NOTE]
> Ensure **Settings -> Pages -> Build and deployment -> Source** is set to **GitHub Actions** in your GitHub repository settings.

#### ⚡ Recommended Platform 2: Vercel (Fastest Global CDN & Custom Domains)
FieldOps includes [`vercel.json`](file:///workspace/calm-turing/vercel.json) and [`scripts/vercel_build.sh`](file:///workspace/calm-turing/scripts/vercel_build.sh) for instant, zero-config deployment on Vercel's free Hobby plan.

1. Go to [vercel.com](https://vercel.com) and click **"Add New Project"**.
2. Select your GitHub repository (`djsushilkumar/fieldops`).
3. Click **"Deploy"**.
4. Every future `git push` to `main` will automatically build and update your production site with zero downtime!

#### 📦 Alternative: Netlify & Cloudflare Pages
* **Netlify**: Configured via [`netlify.toml`](file:///workspace/calm-turing/netlify.toml). Simply import the repository in [netlify.com](https://netlify.com).
* **Cloudflare Pages**: Connect your GitHub repository, specify build command `bash scripts/vercel_build.sh`, and output folder `build/web`.

---

## 🍏 3. iOS Deployment

### 3.1 Permissions Configured in `ios/Runner/Info.plist`
* `NSLocationWhenInUseUsageDescription`: "FieldOps requires your location for attendance check-in and task arrival verification."
* `NSLocationAlwaysAndWhenInUseUsageDescription`: "FieldOps uses your location to update dispatch managers on job progress."
* `NSCameraUsageDescription`: "FieldOps requires camera access to attach proof of work photos."
* `NSPhotoLibraryUsageDescription`: "FieldOps requires photo library access to upload site inspection images."

### 3.2 Building iOS Archive
```bash
# Install CocoaPods dependencies
cd ios && pod install && cd ..

# Build iOS release
flutter build ipa --release
```

---

## 🗄️ 4. Supabase Backend Production Setup

### 4.1 Automated Migration Execution
You can deploy all 19 database tables, triggers, views, and RLS policies using our automated migration runner:
```bash
python3 supabase/apply_migrations.py <YOUR_SUPABASE_DB_PASSWORD>
```

### 4.2 Manual Execution via Supabase Dashboard
1. Open your **[Supabase Dashboard](https://supabase.com/dashboard)**.
2. Go to **SQL Editor** -> **New query**.
3. Copy and paste the consolidated script from `supabase/complete_schema.sql`.
4. Click **Run**.
