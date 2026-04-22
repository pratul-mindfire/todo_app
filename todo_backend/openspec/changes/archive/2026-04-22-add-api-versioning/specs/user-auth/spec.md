## MODIFIED Requirements

### Requirement: User Registration
The system SHALL allow a new user to register by providing name, email, and password. On success it SHALL persist the user with a bcrypt-hashed password and return a JWT token alongside the user object (excluding password). Email SHALL be treated as case-insensitive for uniqueness checks.

#### Scenario: Successful registration
- **WHEN** a POST request is sent to `/api/v1/auth/register` with valid `name`, `email`, and `password` (≥ 6 chars)
- **THEN** the system returns HTTP 200 with `{ success: true, token: "<jwt>", user: { id, name, email } }` and the user is persisted in the database

#### Scenario: Duplicate email
- **WHEN** a POST request is sent to `/api/v1/auth/register` with an email that already exists in the database
- **THEN** the system returns HTTP 409 with `{ success: false, message: "Email already registered" }`

#### Scenario: Missing required field
- **WHEN** a POST request is sent to `/api/v1/auth/register` with `name`, `email`, or `password` absent
- **THEN** the system returns HTTP 400 with `{ success: false, message: "<field> is required" }`

#### Scenario: Invalid email format
- **WHEN** a POST request is sent to `/api/v1/auth/register` with a malformed email string
- **THEN** the system returns HTTP 400 with `{ success: false, message: "Valid email is required" }`

#### Scenario: Password too short
- **WHEN** a POST request is sent to `/api/v1/auth/register` with a password shorter than 6 characters
- **THEN** the system returns HTTP 400 with `{ success: false, message: "Password must be at least 6 characters" }`

---

### Requirement: User Login
The system SHALL authenticate an existing user by verifying the provided password against the stored bcrypt hash. On success it SHALL return a JWT token and the user object (excluding password).

#### Scenario: Successful login
- **WHEN** a POST request is sent to `/api/v1/auth/login` with a valid `email` and matching `password`
- **THEN** the system returns HTTP 200 with `{ success: true, token: "<jwt>", user: { id, name, email } }`

#### Scenario: Unknown email
- **WHEN** a POST request is sent to `/api/v1/auth/login` with an email that does not exist in the database
- **THEN** the system returns HTTP 401 with `{ success: false, message: "Invalid credentials" }`

#### Scenario: Wrong password
- **WHEN** a POST request is sent to `/api/v1/auth/login` with a valid email but an incorrect password
- **THEN** the system returns HTTP 401 with `{ success: false, message: "Invalid credentials" }`

#### Scenario: Missing credentials
- **WHEN** a POST request is sent to `/api/v1/auth/login` with `email` or `password` absent
- **THEN** the system returns HTTP 400 with `{ success: false, message: "<field> is required" }`

---

### Requirement: Get Current User Profile
The system SHALL provide a protected endpoint that returns the authenticated user's profile. This endpoint MUST be gated by the JWT auth middleware.

#### Scenario: Authenticated request
- **WHEN** a GET request is sent to `/api/v1/auth/me` with a valid `Authorization: Bearer <token>` header
- **THEN** the system returns HTTP 200 with `{ success: true, user: { id, name, email } }`

#### Scenario: Unauthenticated request
- **WHEN** a GET request is sent to `/api/v1/auth/me` without an Authorization header or with an invalid token
- **THEN** the system returns HTTP 401 with `{ success: false, message: "Not authorized" }`
