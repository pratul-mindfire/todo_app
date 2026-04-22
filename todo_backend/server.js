const config = require('./src/config/config');
const app = require('./src/app');
const connectDB = require('./src/config/db');

connectDB()
  .then(() => {
    app.listen(config.PORT, () => console.log(`Server running on port ${config.PORT}`));
  })
  .catch((err) => {
    console.error('DB connection failed:', err.message);
    process.exit(1);
  });
