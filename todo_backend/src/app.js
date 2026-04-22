const express = require('express');
const authRoutes = require('./routes/authRoutes');
const config = require('./config/config');

const app = express();
const API_VERSION = config.API_VERSION;

app.use(express.json());
app.use(`/api/${API_VERSION}/auth`, authRoutes);
app.use('/api/auth', authRoutes);

module.exports = app;
