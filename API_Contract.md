# Child Care Center Management System - API Contract

## Base URL
```
Development: http://localhost:3001/api
Production: https://api.ccms.com/api
```

## Authentication
All API requests (except login) require a valid JWT token in the Authorization header:
```
Authorization: Bearer <token>
```

---

## Authentication Endpoints

### POST /auth/login
Authenticate user and receive JWT token.

**Request:**
```json
{
  "email": "admin@example.com",
  "password": "securepassword"
}
```

**Response (200):**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "admin@example.com",
    "role": "center_admin",
    "center_id": 2
  }
}
```

**Response (401):**
```json
{
  "success": false,
  "message": "Invalid credentials"
}
```

### POST /auth/logout
Invalidate current token (client-side removal).

**Response (200):**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

### GET /auth/me
Get current user information.

**Response (200):**
```json
{
  "success": true,
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "admin@example.com",
    "role": "center_admin",
    "center_id": 2,
    "center": {
      "id": 2,
      "name": "Sunshine Daycare"
    }
  }
}
```

---

## Center Management (SuperAdmin Only)

### GET /centers
List all child care centers.

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20)
- `is_active` (optional): Filter by status

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Sunshine Daycare",
      "address": "123 Main Street, Cityville",
      "phone": "555-0101",
      "email": "sunshine@ccms.com",
      "opening_time": "07:00:00",
      "closing_time": "18:00:00",
      "is_active": true,
      "created_at": "2024-01-15T08:00:00Z",
      "child_count": 45,
      "admin_count": 2
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 5,
    "total_pages": 1
  }
}
```

### POST /centers
Create a new child care center.

**Request:**
```json
{
  "name": "New Daycare Center",
  "address": "789 New Street, Cityville",
  "phone": "555-0200",
  "email": "newcenter@ccms.com",
  "opening_time": "07:00",
  "closing_time": "18:00"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Center created successfully",
  "data": {
    "id": 6,
    "name": "New Daycare Center",
    ...
  }
}
```

### GET /centers/:id
Get center details.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Sunshine Daycare",
    "address": "123 Main Street, Cityville",
    "phone": "555-0101",
    "email": "sunshine@ccms.com",
    "opening_time": "07:00:00",
    "closing_time": "18:00:00",
    "is_active": true,
    "stats": {
      "total_children": 45,
      "active_children": 42,
      "total_admins": 2,
      "monthly_revenue": 32500.00
    }
  }
}
```

### PUT /centers/:id
Update center information.

**Request:**
```json
{
  "name": "Updated Center Name",
  "phone": "555-0102",
  "opening_time": "06:30"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Center updated successfully",
  "data": { ... }
}
```

### DELETE /centers/:id
Soft delete (deactivate) a center.

**Response (200):**
```json
{
  "success": true,
  "message": "Center deactivated successfully"
}
```

---

## User Management (SuperAdmin)

### GET /users
List all users.

**Query Parameters:**
- `role` (optional): Filter by role
- `center_id` (optional): Filter by center
- `is_active` (optional): Filter by status

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "admin@sunshine.com",
      "role": "center_admin",
      "center_id": 1,
      "center_name": "Sunshine Daycare",
      "is_active": true,
      "last_login": "2024-02-01T09:30:00Z"
    }
  ]
}
```

### POST /users
Create a new user (center admin).

**Request:**
```json
{
  "name": "Jane Smith",
  "email": "jane@sunshine.com",
  "password": "securepassword123",
  "role": "center_admin",
  "center_id": 1
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "User created successfully",
  "data": { ... }
}
```

### PUT /users/:id
Update user information.

### DELETE /users/:id
Deactivate user account.

---

## Child Management

### GET /children
List children (scoped to user's center for Center Admin).

**Query Parameters:**
- `center_id` (SuperAdmin only): Filter by center
- `is_active` (optional): Filter by status
- `payment_plan` (optional): Filter by plan
- `search` (optional): Search by name

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "first_name": "Emma",
      "last_name": "Johnson",
      "date_of_birth": "2020-03-15",
      "age": 4,
      "enrollment_date": "2024-01-10",
      "payment_plan": "monthly",
      "rate": 800.00,
      "is_active": true,
      "center_id": 1,
      "center_name": "Sunshine Daycare"
    }
  ],
  "pagination": { ... }
}
```

### POST /children
Enroll a new child.

**Request:**
```json
{
  "first_name": "Sophia",
  "last_name": "Anderson",
  "date_of_birth": "2021-06-20",
  "enrollment_date": "2024-02-01",
  "payment_plan": "daily",
  "rate": 45.00,
  "center_id": 1
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Child enrolled successfully",
  "data": { ... }
}
```

### GET /children/:id
Get child details with attendance and payment history.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "first_name": "Emma",
    "last_name": "Johnson",
    "date_of_birth": "2020-03-15",
    "enrollment_date": "2024-01-10",
    "payment_plan": "monthly",
    "rate": 800.00,
    "is_active": true,
    "attendance_summary": {
      "present_days": 18,
      "absent_days": 2,
      "late_days": 1,
      "total_hours": 162.5
    },
    "payment_summary": {
      "total_paid": 1600.00,
      "total_pending": 800.00,
      "total_overdue": 0
    }
  }
}
```

### PUT /children/:id
Update child information.

### DELETE /children/:id
Deactivate child enrollment.

---

## Attendance Management

### GET /attendance
List attendance records.

**Query Parameters:**
- `child_id` (optional): Filter by child
- `date` (optional): Filter by date
- `start_date` (optional): Date range start
- `end_date` (optional): Date range end
- `status` (optional): Filter by status

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "child_id": 1,
      "child_name": "Emma Johnson",
      "date": "2024-02-01",
      "check_in": "08:30:00",
      "check_out": "17:00:00",
      "total_hours": 8.50,
      "status": "present",
      "notes": null
    }
  ]
}
```

### POST /attendance/checkin
Record child check-in.

**Request:**
```json
{
  "child_id": 1,
  "date": "2024-02-01",
  "check_in": "08:30",
  "notes": "On time"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Check-in recorded",
  "data": { ... }
}
```

### PUT /attendance/checkout
Record child check-out.

**Request:**
```json
{
  "attendance_id": 1,
  "check_out": "17:00",
  "notes": "Picked up by parent"
}
```

### PUT /attendance/:id
Update attendance record (with audit logging).

### GET /attendance/daily
Get daily attendance summary for a center.

**Query Parameters:**
- `date` (required): Date to query
- `center_id` (SuperAdmin only): Center to query

**Response (200):**
```json
{
  "success": true,
  "data": {
    "date": "2024-02-01",
    "center_id": 1,
    "present_count": 42,
    "absent_count": 3,
    "late_count": 2,
    "total_hours": 378.5,
    "attendance_rate": 93.3
  }
}
```

### GET /attendance/child/:id
Get attendance history for a specific child.

---

## Payment Management

### GET /payments
List payment records.

**Query Parameters:**
- `child_id` (optional): Filter by child
- `status` (optional): Filter by status
- `period_start` (optional): Period start date
- `period_end` (optional): Period end date

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "child_id": 1,
      "child_name": "Emma Johnson",
      "period_start": "2024-02-01",
      "period_end": "2024-02-29",
      "amount": 800.00,
      "status": "pending",
      "paid_at": null,
      "notes": null
    }
  ]
}
```

### POST /payments/calculate
Calculate payments for a period.

**Request:**
```json
{
  "center_id": 1,
  "period_start": "2024-02-01",
  "period_end": "2024-02-29"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Payments calculated for 42 children",
  "data": {
    "total_calculated": 33600.00,
    "children_processed": 42
  }
}
```

### PUT /payments/:id/pay
Mark payment as paid.

**Request:**
```json
{
  "payment_method": "cash",
  "notes": "Full payment received"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Payment marked as paid",
  "data": { ... }
}
```

### GET /payments/summary
Get payment summary for a center.

**Query Parameters:**
- `center_id` (SuperAdmin only): Center to query
- `period_start` (optional): Period start
- `period_end` (optional): Period end

**Response (200):**
```json
{
  "success": true,
  "data": {
    "total_expected": 33600.00,
    "total_paid": 25600.00,
    "total_pending": 6400.00,
    "total_overdue": 1600.00,
    "collection_rate": 76.2
  }
}
```

### GET /payments/outstanding
Get outstanding balances.

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "child_id": 1,
      "child_name": "Emma Johnson",
      "total_outstanding": 800.00,
      "overdue_amount": 0.00,
      "pending_amount": 800.00
    }
  ]
}
```

---

## Reports

### GET /reports/attendance
Generate attendance report.

**Query Parameters:**
- `center_id` (required for SuperAdmin)
- `start_date` (required)
- `end_date` (required)
- `format` (optional): json, csv, pdf

**Response (200):**
```json
{
  "success": true,
  "data": {
    "period": {
      "start": "2024-02-01",
      "end": "2024-02-29"
    },
    "summary": {
      "total_days": 20,
      "average_attendance": 40.5,
      "total_hours": 3240.5
    },
    "daily_breakdown": [ ... ]
  }
}
```

### GET /reports/financial
Generate financial report.

**Query Parameters:**
- `center_id` (required for SuperAdmin)
- `start_date` (required)
- `end_date` (required)
- `format` (optional): json, csv, pdf

**Response (200):**
```json
{
  "success": true,
  "data": {
    "period": { ... },
    "revenue": {
      "total": 33600.00,
      "collected": 25600.00,
      "outstanding": 8000.00
    },
    "by_payment_plan": {
      "hourly": 5400.00,
      "daily": 8200.00,
      "monthly": 20000.00
    }
  }
}
```

### GET /reports/child/:id
Generate child-level report.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "child": { ... },
    "attendance": { ... },
    "payments": { ... }
  }
}
```

---

## Logs & Auditing (SuperAdmin Only)

### GET /logs
View system activity logs.

**Query Parameters:**
- `center_id` (optional): Filter by center
- `user_id` (optional): Filter by user
- `action` (optional): Filter by action
- `entity_type` (optional): Filter by entity
- `start_date` (optional): Date range start
- `end_date` (optional): Date range end

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "user_id": 2,
      "user_name": "John Doe",
      "center_id": 1,
      "action": "UPDATE",
      "entity_type": "children",
      "entity_id": 5,
      "old_values": { "rate": 40.00 },
      "new_values": { "rate": 45.00 },
      "created_at": "2024-02-01T10:30:00Z"
    }
  ]
}
```

---

## Dashboard

### GET /dashboard/superadmin
SuperAdmin dashboard data.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "stats": {
      "total_centers": 5,
      "active_centers": 4,
      "total_children": 186,
      "total_users": 12,
      "monthly_revenue": 142500.00
    },
    "recent_activity": [ ... ],
    "centers_performance": [ ... ]
  }
}
```

### GET /dashboard/center
Center Admin dashboard data.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "center": { ... },
    "stats": {
      "total_children": 45,
      "active_children": 42,
      "today_attendance": 40,
      "monthly_revenue": 32500.00,
      "outstanding_payments": 6400.00
    },
    "today_checkins": [ ... ],
    "recent_payments": [ ... ],
    "alerts": [ ... ]
  }
}
```

---

## Error Responses

### 400 Bad Request
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    { "field": "email", "message": "Email is required" }
  ]
}
```

### 401 Unauthorized
```json
{
  "success": false,
  "message": "Authentication required"
}
```

### 403 Forbidden
```json
{
  "success": false,
  "message": "Access denied - insufficient permissions"
}
```

### 404 Not Found
```json
{
  "success": false,
  "message": "Resource not found"
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "message": "Internal server error"
}
```

---

## Data Types

### Payment Plan Enum
- `hourly`: Rate per hour attended
- `daily`: Rate per day attended
- `monthly`: Fixed monthly rate

### Attendance Status Enum
- `present`: Child was present
- `absent`: Child was absent
- `late`: Child arrived late

### Payment Status Enum
- `pending`: Payment not yet made
- `paid`: Payment received
- `overdue`: Payment past due

### User Role Enum
- `superadmin`: System administrator with full access
- `center_admin`: Center-specific administrator
