const mongoose = require('mongoose');

const connectMongoDB = async () => {
    try {
        let uri = process.env.MONGODB_URI;
        if (!uri) {
            console.warn('[MongoDB] MONGODB_URI is not defined in .env');
            return;
        }

        const dbName = process.env.MONGODB_LOG_DB || 'ewallet_logs';
        if (!uri.endsWith('/')) {
            uri += '/';
        }
        uri += dbName;

        await mongoose.connect(uri, {
            // Mongoose 6+ không cần các tùy chọn useNewUrlParser, useUnifiedTopology nữa
        });

        console.log('[MongoDB] Connected to MongoDB successfully.');
    } catch (error) {
        console.error('[MongoDB] Connection failed:', error);
        // Có thể không cần exit process nếu log chỉ là phụ
        // process.exit(1); 
    }
};

module.exports = connectMongoDB;
