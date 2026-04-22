## ADDED Requirements

### Requirement: Versioned Route Prefix
The system SHALL expose all API routes under a versioned path segment derived from the `API_VERSION` environment variable (e.g. `API_VERSION=v1` → `/api/v1/`). If `API_VERSION` is not set, the system SHALL default to `v1`.

#### Scenario: Versioned path is reachable
- **WHEN** `API_VERSION=v1` is set and a request is sent to `/api/v1/auth/register`
- **THEN** the system processes the request identically to a request on the unversioned path and returns the same response shape

#### Scenario: Missing API_VERSION defaults to v1
- **WHEN** `API_VERSION` is not present in the environment and the server starts
- **THEN** the system mounts routes at `/api/v1/` and starts without error

---

### Requirement: Backward-Compatible Unversioned Routes
The system SHALL continue to serve all existing routes at their unversioned paths (`/api/auth/*`) to avoid breaking clients that have not yet adopted the versioned URLs. The unversioned paths SHALL be functionally identical to their versioned counterparts.

#### Scenario: Unversioned register path still works
- **WHEN** a POST request is sent to `/api/auth/register` with valid body
- **THEN** the system returns HTTP 200 with `{ success: true, token, user }` — same as the versioned path

#### Scenario: Unversioned login path still works
- **WHEN** a POST request is sent to `/api/auth/login` with valid credentials
- **THEN** the system returns HTTP 200 with `{ success: true, token, user }` — same as the versioned path

#### Scenario: Unversioned me path still works
- **WHEN** a GET request is sent to `/api/auth/me` with a valid Bearer token
- **THEN** the system returns HTTP 200 with `{ success: true, user }` — same as the versioned path
