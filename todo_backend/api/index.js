require('../src/config/config');
const app = require('../src/app');
const connectDB = require('../src/config/db');

let dbConnected = false;

module.exports = async (req, res) => {
  if (!dbConnected) {
    await connectDB();
    dbConnected = true;
  }
  app(req, res);
};
