# FieldOps REST API & Backend Integration Guide

The FieldOps backend exposes RESTful endpoints via **Supabase PostgREST** and **Gotrue Authentication**. All requests require the project's publishable API key in the `apikey` header and a valid JWT bearer token in the `Authorization` header for authenticated endpoints.

---

## 🌐 Base URL & Common Headers

* **Base URL**: `https://<PROJECT_REF>.supabase.co`
* **Common Request Headers**:
  ```http
  apikey: <SUPABASE_ANON_KEY>
  Authorization: Bearer <ACCESS_TOKEN>
  Content-Type: application/json
  Prefer: return=representation
  ```

---

## 🔐 1. Authentication Endpoints (Gotrue)

### User Sign In with Email & Password
Authenticates a field technician or administrator and returns access + refresh tokens.

* **Endpoint**: `POST /auth/v1/token?grant_type=password`
* **Request Body**:
  ```json
  {
    "email": "employee@fieldops.com",
    "password": "password123"
  }
  ```
* **Response (200 OK)**:
  ```json
  {
    "access_token": "eyJhbGciOiJFUzI1Ni...",
    "token_type": "bearer",
    "expires_in": 3600,
    "refresh_token": "...",
    "user": {
      "id": "33333333-3333-3333-3333-333333333333",
      "email": "employee@fieldops.com",
      "user_metadata": {
        "name": "David Miller (Technician)"
      }
    }
  }
  ```

### Refresh User Access Token
* **Endpoint**: `POST /auth/v1/token?grant_type=refresh_token`
* **Request Body**:
  ```json
  {
    "refresh_token": "..."
  }
  ```

---

## 📋 2. Tasks & Work Orders API

### Get Assigned Tasks (Technician View)
Fetches tasks assigned to the authenticated user with customer and location joins.

* **Endpoint**: `GET /rest/v1/tasks?select=*,customers(*),locations(*)&order=scheduled_start.asc`
* **Response (200 OK)**:
  ```json
  [
    {
      "id": "00000000-0000-0000-0000-000000000031",
      "organization_id": "00000000-0000-0000-0000-000000000001",
      "title": "Emergency HVAC System Diagnostic",
      "description": "Inspect high-voltage cooling unit #4 and verify pressure levels.",
      "priority": "HIGH",
      "status": "ASSIGNED",
      "requires_gps": true,
      "requires_photo": true,
      "customers": {
        "id": "00000000-0000-0000-0000-000000000011",
        "name": "Metro Logistics Center",
        "phone": "+1 (555) 123-4567"
      },
      "locations": {
        "id": "00000000-0000-0000-0000-000000000021",
        "name": "Main Warehouse - Hub A",
        "latitude": 40.7128,
        "longitude": -74.0060,
        "radius_meters": 150
      }
    }
  ]
  ```

### Update Task Status
Transitions task state (e.g. from `ASSIGNED` -> `IN_PROGRESS` or `COMPLETED`).

* **Endpoint**: `PATCH /rest/v1/tasks?id=eq.<TASK_ID>`
* **Request Body**:
  ```json
  {
    "status": "IN_PROGRESS",
    "actual_start": "2026-09-21T06:00:00Z"
  }
  ```

---

## 📍 3. GPS Attendance & Timesheets API

### Clock-In (Daily Attendance)
Records the technician's morning check-in fix with GPS verification.

* **Endpoint**: `POST /rest/v1/attendance`
* **Request Body**:
  ```json
  {
    "organization_id": "00000000-0000-0000-0000-000000000001",
    "user_id": "33333333-3333-3333-3333-333333333333",
    "date": "2026-09-21",
    "check_in_at": "2026-09-21T06:00:00Z",
    "check_in_latitude": 40.7128,
    "check_in_longitude": -74.0060,
    "status": "PRESENT"
  }
  ```

### Clock-Out & Duration Computation
* **Endpoint**: `PATCH /rest/v1/attendance?id=eq.<ATTENDANCE_ID>`
* **Request Body**:
  ```json
  {
    "check_out_at": "2026-09-21T08:00:00Z",
    "check_out_latitude": 40.7128,
    "check_out_longitude": -74.0060,
    "total_minutes": 120
  }
  ```

---

## 📝 4. Dynamic Forms & Checklist Submissions API

### Fetch Form Templates
* **Endpoint**: `GET /rest/v1/forms?select=*`

### Submit Completed Field Inspection
* **Endpoint**: `POST /rest/v1/form_submissions`
* **Request Body**:
  ```json
  {
    "form_id": "00000000-0000-0000-0000-000000000051",
    "task_id": "00000000-0000-0000-0000-000000000031",
    "user_id": "33333333-3333-3333-3333-333333333333",
    "latitude": 40.7128,
    "longitude": -74.0060,
    "data": {
      "f1": "Passed",
      "f2": 118.0,
      "f3": true,
      "f4": "Compressor running smoothly. Pressure certified normal."
    }
  }
  ```

---

## 👥 5. Teams & Dispatch Units API

### List Dispatch Units with Team Members
* **Endpoint**: `GET /rest/v1/teams?select=*,team_members(*,users(*))`
* **Response (200 OK)**:
  ```json
  [
    {
      "id": "00000000-0000-0000-0000-000000000041",
      "name": "Rapid Response Alpha",
      "description": "Primary emergency response and maintenance unit",
      "color_hex": "#0288D1",
      "team_members": [
        {
          "team_id": "00000000-0000-0000-0000-000000000041",
          "user_id": "33333333-3333-3333-3333-333333333333",
          "users": {
            "name": "David Miller (Technician)",
            "role": "employee"
          }
        }
      ]
    }
  ]
  ```
