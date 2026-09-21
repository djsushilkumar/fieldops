# FieldOps Operational User Guide & Manual

This user guide provides step-by-step instructions for all three organizational personas: **Field Technicians (Employees)**, **Dispatch Managers**, and **System Administrators**.

---

## 👷 1. Field Technician / Employee Guide

### 1.1 Daily GPS Attendance Clock-In & Clock-Out
1. Open the **FieldOps** mobile app.
2. On your **Home Screen**, tap the green **"Check In"** button.
3. The app automatically locks your GPS fix and verifies your coordinates.
4. Throughout the day, your elapsed shift duration is displayed on your home dashboard.
5. At shift conclusion, tap **"Check Out"** to finalize your timesheet.

### 1.2 Accessing Assigned Tasks
1. Navigate to the **Tasks** tab in the bottom bar.
2. Switch between **All**, **To Do**, **In Progress**, and **Completed** filters.
3. Tap any task card to open the **Task Detail Screen**:
   - Customer contact name and 1-tap dial/navigate actions.
   - Job site address and geofence perimeter.
   - Required proof items (Photo, Digital Signature, Custom Checklist).

### 1.3 Executing a Job Site Visit (GPS Geofence)
1. When you arrive at the customer location, tap **"Start Field Task"**.
2. If GPS indicates you are within the designated geofence radius (e.g. 100m), check-in is confirmed immediately.
3. If you are outside the radius, a warning banner will notify you of the distance remaining.

### 1.4 Completing Proof of Work & Checklists
1. **Dynamic Checklists**: Tap **"Fill Inspection Form"**, complete the dynamic fields, and tap **"Submit Inspection"**.
2. **Photo Proof**: Tap the camera icon to capture before/after photos with automatic timestamp overlays.
3. **Customer Signature**: Tap **"Collect Signature"**, hand the phone to the customer for their digital touch-screen sign-off.
4. Tap **"Complete Task & Submit Proof"** to conclude the work order.

### 1.5 Working in Offline Areas
* You do not need to worry about cell signal or WiFi. All actions (check-in, photo capture, form fills, status transitions) save directly to local SQLite storage.
* As soon as network connectivity is restored, the built-in **Sync Queue** automatically synchronizes all pending items with cloud servers.

---

## 👨‍💼 2. Operations & Dispatch Manager Guide

### 2.1 Task Dispatch & Technician Scheduling
1. Open the **Manager Dashboard** on mobile or web.
2. Tap the floating **"+"** button or **"Create Task"**:
   - Select Customer and Site Location.
   - Set Priority (`Low`, `Medium`, `High`, `Urgent`).
   - Assign to a specific Field Technician or Dispatch Unit.
   - Configure proof requirements (Require GPS, Require Photo, Require Checklist).
3. Tap **"Dispatch Task"** — an in-app alert is routed to the technician immediately.

### 2.2 Real-Time Field Radar & GPS Tracking
1. Open the **Command Center** dashboard.
2. View the **Field Radar**:
   - Live location of all active technicians.
   - Color-coded pins indicating shift status (Green: On-site / In-Progress, Amber: Traveling, Grey: Clocked-out).
   - Real-time activity stream of arrivals, departures, and photo uploads.

### 2.3 Analytics & RFC-4180 CSV Export Center
1. Navigate to the **Reports** section.
2. Filter by date range, team, or specific technician.
3. View operational KPIs:
   - Task Completion Rate (%)
   - On-Time Delivery Rate (%)
   - Average Visit Duration
   - Total Logged Working Hours
4. Tap **"Export CSV"** to generate RFC-4180 compliant CSV files for:
   - `Tasks_Export.csv`
   - `Visits_Audit.csv`
   - `Attendance_Payroll.csv`

---

## 👑 3. System Administrator Guide

### 3.1 Organization Settings & Business Rules
1. Open **Admin Shell → Organization Settings**:
   - Company Name, Industry, Timezone, and Operating Currency.
   - **Default Geofence Radius**: Adjust default tolerance in meters (e.g. 50m to 500m).
   - **Auto-Checkout Policy**: Set maximum continuous shift duration before automated checkout.
   - Enforce mandatory camera proof or GPS check-in rules across the entire company.

### 3.2 Dispatch Teams Management
1. Open **Admin Shell → Teams Management**.
2. Tap **"Create Team"**:
   - Enter team title (e.g. "HVAC Commercial Squad").
   - Designate a Lead Dispatch Manager.
   - Assign team badge color hex for map radar visualization.
   - Add field technicians to the team roster.

### 3.3 Staff Directory & Role-Based Access Control (RBAC)
1. Open **Staff Directory** to view active employees, managers, and admins.
2. Tap **"Invite User"** to add new field technicians or office dispatchers.
3. Open **Role Permissions Matrix** to customize granular capabilities:
   - `can_create_tasks`
   - `can_manage_customers`
   - `can_view_all_teams`
   - `can_export_reports`
   - `can_manage_forms`
   - `can_manage_users`
