const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');
const request = require('supertest');
const jwt = require('jsonwebtoken');
const app = require('../app');
const User = require('../models/User');

let mongod;

beforeAll(async () => {
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri());
  process.env.JWT_SECRET = 'test-secret-key';
});

afterAll(async () => {
  await mongoose.disconnect();
  await mongod.stop();
});

afterEach(async () => {
  await User.deleteMany({});
});

const validUser = { name: 'Test User', email: 'test@example.com', password: 'secret123' };

// ---------------------------------------------------------------------------
// Registration scenarios
// ---------------------------------------------------------------------------

describe('POST /api/auth/register', () => {
  it('4.1 returns 200 with token and user on successful registration', async () => {
    const res = await request(app).post('/api/auth/register').send(validUser);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.token).toBeDefined();
    expect(res.body.user).toMatchObject({ name: validUser.name, email: validUser.email });
    expect(res.body.user.id).toBeDefined();
    expect(res.body.user.password).toBeUndefined();
  });

  it('4.2 returns 409 when email is already registered', async () => {
    await request(app).post('/api/auth/register').send(validUser);
    const res = await request(app).post('/api/auth/register').send(validUser);

    expect(res.status).toBe(409);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toBe('Email already registered');
  });

  it('4.3 returns 400 when name is missing', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ email: validUser.email, password: validUser.password });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/required/i);
  });

  it('4.4 returns 400 when email is missing', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ name: validUser.name, password: validUser.password });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it('4.5 returns 400 when password is missing', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ name: validUser.name, email: validUser.email });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it('4.6 returns 400 when email format is invalid', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ ...validUser, email: 'not-an-email' });

    expect(res.status).toBe(400);
    expect(res.body.message).toBe('Valid email is required');
  });

  it('4.7 returns 400 when password is shorter than 6 characters', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ ...validUser, password: 'abc' });

    expect(res.status).toBe(400);
    expect(res.body.message).toBe('Password must be at least 6 characters');
  });
});

// ---------------------------------------------------------------------------
// Login scenarios
// ---------------------------------------------------------------------------

describe('POST /api/auth/login', () => {
  beforeEach(async () => {
    await request(app).post('/api/auth/register').send(validUser);
  });

  it('4.8 returns 200 with token and user on successful login', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: validUser.email, password: validUser.password });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.token).toBeDefined();
    expect(res.body.user).toMatchObject({ name: validUser.name, email: validUser.email });
    expect(res.body.user.password).toBeUndefined();
  });

  it('4.9 returns 401 when email does not exist', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'nobody@example.com', password: validUser.password });

    expect(res.status).toBe(401);
    expect(res.body.message).toBe('Invalid credentials');
  });

  it('4.10 returns 401 when password is wrong', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: validUser.email, password: 'wrongpassword' });

    expect(res.status).toBe(401);
    expect(res.body.message).toBe('Invalid credentials');
  });

  it('4.11 returns 400 when credentials are missing', async () => {
    const res = await request(app).post('/api/auth/login').send({});

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// Profile scenarios
// ---------------------------------------------------------------------------

describe('GET /api/auth/me', () => {
  it('4.12 returns user profile for authenticated request', async () => {
    const regRes = await request(app).post('/api/auth/register').send(validUser);
    const token = regRes.body.token;

    const res = await request(app)
      .get('/api/auth/me')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.user).toMatchObject({ name: validUser.name, email: validUser.email });
    expect(res.body.user.password).toBeUndefined();
  });

  it('4.13 returns 401 when no Authorization header is provided', async () => {
    const res = await request(app).get('/api/auth/me');

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// Auth middleware scenarios
// ---------------------------------------------------------------------------

describe('Auth middleware — JWT verification', () => {
  it('4.14 returns 401 for a malformed Bearer token', async () => {
    const res = await request(app)
      .get('/api/auth/me')
      .set('Authorization', 'Bearer THIS_IS_NOT_A_VALID_JWT');

    expect(res.status).toBe(401);
    expect(res.body.message).toBe('Not authorized, token failed');
  });

  it('4.15 returns 401 for an expired token', async () => {
    const expiredToken = jwt.sign(
      { id: new mongoose.Types.ObjectId().toString() },
      process.env.JWT_SECRET,
      { expiresIn: '1ms' },
    );

    await new Promise((resolve) => setTimeout(resolve, 10));

    const res = await request(app)
      .get('/api/auth/me')
      .set('Authorization', `Bearer ${expiredToken}`);

    expect(res.status).toBe(401);
    expect(res.body.message).toBe('Not authorized, token failed');
  });
});
