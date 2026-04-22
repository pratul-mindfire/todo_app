const mongoose = require('mongoose');
const config = require('./config');

const connectDB = async () => {
  const conn = await mongoose.connect(config.MONGO_URI);
  console.log(`MongoDB connected: ${conn.connection.host}`);
};

module.exports = connectDB;
