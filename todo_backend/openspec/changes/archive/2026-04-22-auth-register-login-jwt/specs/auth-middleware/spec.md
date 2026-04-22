## ADDED Requirements

### Requirement: JWT Verification Middleware
The system SHALL provide Express middleware that extracts, verifies, and decodes a JWT from the `Authorization: Bearer <token>` request header. On success it SHALL attach `{ _id }` to `req.user` and call `next()`. On failure it SHALL respond immediately with 401 and not call `next()`.

#### Scenario: Valid token on protected route
- **WHEN** a request reaches a protected route with a valid, non-expired `Authorization: Bearer <token>` header
- **THEN** middleware decodes the token, sets `req.user = { _id: <userId> }`, and calls `next()` to pass control to the controller

#### Scenario: Missing Authorization header
- **WHEN** a request reaches a protected route with no `Authorization` header
- **THEN** middleware returns HTTP 401 with `{ success: false, message: "Not authorized, no token" }` and does NOT call `next()`

#### Scenario: Malformed Bearer token
- **WHEN** a request reaches a protected route with an `Authorization` header that is not in `Bearer <token>` format, or whose token fails JWT verification
- **THEN** middleware returns HTTP 401 with `{ success: false, message: "Not authorized, token failed" }` and does NOT call `next()`

#### Scenario: Expired token
- **WHEN** a request reaches a protected route with a syntactically valid JWT whose `exp` claim is in the past
- **THEN** middleware returns HTTP 401 with `{ success: false, message: "Not authorized, token failed" }` and does NOT call `next()`
