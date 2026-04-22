# Functional Requirements Specification (FRS)

## Project: Todo Backend API

---

## 1. Overview

This document defines the functional requirements for a Todo backend service built using Node.js, Express, and MongoDB.

The system provides:

* User registration
* User login
* Authentication for protected routes (future scope: Todo APIs)

---

## 2. Actors

* **User**: End user interacting with the API

---

## 3. Functional Requirements

### 3.1 User Registration

**Description:**
Allows a new user to create an account.

**Endpoint:**
`POST /api/auth/register`

**Input:**

* name (string, required)
* email (string, required, unique)
* password (string, required, min 6 chars)

**Validation Rules:**

* Email must be valid format
* Password must be at least 6 characters
* Email must be unique

**Behavior:**

* Hash password before storing
* Save user in database
* Return success response with user info (excluding password)

**Output:**

```json
{
  "success": true,
  "user": {
    "id": "string",
    "name": "string",
    "email": "string"
  }
}
```

---

### 3.2 User Login

**Description:**
Allows an existing user to log in.

**Endpoint:**
`POST /api/auth/login`

**Input:**

* email (string, required)
* password (string, required)

**Validation Rules:**

* Email must exist
* Password must match stored hash

**Behavior:**

* Verify credentials
* Generate JWT token

**Output:**

```json
{
  "success": true,
  "token": "jwt_token",
  "user": {
    "id": "string",
    "name": "string",
    "email": "string"
  }
}
```

---

### 3.3 Authentication Middleware

**Description:**
Protect routes using JWT.

**Behavior:**

* Read token from Authorization header
* Validate token
* Attach user to request

---

## 4. Non-Functional Requirements

### 4.1 Performance

* API response time < 500ms under normal load

### 4.2 Security

* Password hashing using bcrypt
* JWT-based authentication
* Input validation

### 4.3 Scalability

* Modular architecture
* Separation of concerns

---

## 5. Constraints

* Must use MongoDB
* Must use Mongoose ODM
* No SQL databases

---

## 6. Future Scope

* Todo CRUD APIs
* Refresh tokens
* Role-based access
