# Software Design Specification (SDS)

## Project: Todo Backend API

---

## 1. Architecture

### 1.1 Tech Stack

* Node.js
* Express.js
* MongoDB
* Mongoose
* JWT (authentication)
* bcrypt (password hashing)

---

## 2. Project Structure

```id="1qaz2w"
todo-backend/
├── src/
│   ├── config/
│   │    └── db.js
│   ├── models/
│   │    └── User.js
│   ├── controllers/
│   │    └── authController.js
│   ├── routes/
│   │    └── authRoutes.js
│   ├── middleware/
│   │    └── authMiddleware.js
│   ├── utils/
│   │    └── generateToken.js
│   └── app.js
├── server.js
├── package.json
└── .env
```

---

## 3. Database Design

### 3.1 User Schema

```js id="schema1"
{
  name: String,
  email: {
    type: String,
    unique: true
  },
  password: String,
  createdAt: Date
}
```

---

## 4. API Design

### 4.1 Register API

**Route:** `POST /api/auth/register`

**Flow:**

1. Validate input
2. Check if user exists
3. Hash password (bcrypt)
4. Save user
5. Return response

---

### 4.2 Login API

**Route:** `POST /api/auth/login`

**Flow:**

1. Validate input
2. Find user by email
3. Compare password (bcrypt)
4. Generate JWT
5. Return token + user

---

## 5. Middleware Design

### 5.1 Auth Middleware

**Steps:**

1. Extract token from header:
   `Authorization: Bearer <token>`
2. Verify JWT
3. Attach user ID to request
4. Call next()

---

## 6. Utility Functions

### 6.1 Token Generator

```js id="tok123"
jwt.sign({ id: user._id }, process.env.JWT_SECRET, {
  expiresIn: "7d"
});
```

---

## 7. Error Handling

Standard response format:

```json
{
  "success": false,
  "message": "Error message"
}
```

---

## 8. Security Design

* Store secrets in `.env`
* Hash passwords using bcrypt
* Validate all inputs
* Avoid exposing sensitive fields

---

## 9. Environment Variables

```env id="env1"
PORT=5000
MONGO_URI=your_mongodb_connection
JWT_SECRET=your_secret_key
```

---

## 10. Request Lifecycle

1. Client sends request
2. Route receives request
3. Controller processes logic
4. Model interacts with DB
5. Response returned

---

## 11. Future Enhancements

* Add Todo model and APIs
* Add refresh tokens
* Add rate limiting
