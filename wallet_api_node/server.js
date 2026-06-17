require('dotenv').config();
BigInt.prototype.toJSON = function () {
    return this.toString();
};
const express = require('express');
const morgan = require('morgan');
const http = require('http');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const masterRouter = require('./src/routes');
const app = express();
app.set('trust proxy', true);
const server = http.createServer(app);
const { initSocket } = require('./src/utils/socket');
const swaggerUi = require('swagger-ui-express');
const swaggerSpec = require('./src/config/swagger');
require('./src/cron/token_cleanup.cron');
require('./src/cron/loyaltySyncRetry.cron');
require('./src/modules/webhook/webhook.consumer');


initSocket(server);

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// Bảo mật với Helmet
app.use(helmet());

// Cấu hình CORS an toàn
app.use(cors({
    origin: [
        'http://localhost:3000', 
        'https://admin.yourdomain.com', 
        'https://merchant.yourdomain.com',
        'https://nonoily-overinfluential-deegan.ngrok-free.dev'
    ],
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Webhook-Signature', 'Idempotency-Key']
}));

// Giới hạn số lượng request
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    limit: 100, // Tối đa 100 requests mỗi 15 phút cho 1 IP
    message: { error: 'Bạn đã gửi quá nhiều yêu cầu, vui lòng thử lại sau 15 phút.' },
    standardHeaders: 'draft-7',
    legacyHeaders: false,
});
app.use(limiter);

app.use(morgan('dev'));
app.use(express.json());
app.use('/api/v1', masterRouter);

const PORT = process.env.PORT || 8000;
server.listen(PORT, () => {
    console.log(`Server Node.js đang chạy tại cổng ${PORT}`);
});