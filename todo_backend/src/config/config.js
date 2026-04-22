require('dotenv').config();

module.exports = {
  get PORT() { return process.env.PORT || 5000; },
  get MONGO_URI() { return process.env.MONGO_URI; },
  get JWT_SECRET() { return process.env.JWT_SECRET; },
  get API_VERSION() { return process.env.API_VERSION || 'v1'; },
};
