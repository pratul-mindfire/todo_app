const jwt = require('jsonwebtoken');
const config = require('../config/config');

const generateToken = (userId) =>
  jwt.sign({ id: userId }, config.JWT_SECRET, { expiresIn: '7d' });

module.exports = generateToken;
