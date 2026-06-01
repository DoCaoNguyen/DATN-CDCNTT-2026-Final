require('dotenv').config();
const express = require('express');
const cors = require('cors');

// Import Router tổng (Node.js sẽ tự động tìm file index.js trong thư mục src/routes)
const masterRouter = require('./src/routes');

const app = express();

// Middleware xử lý CORS và JSON
app.use(cors());
app.use(express.json());

// Nạp Router tổng (Tất cả API sẽ tự động có tiền tố /api/v1 ở trước)
app.use('/api/v1', masterRouter);

// Khởi chạy server
const PORT = process.env.PORT || 8000;
app.listen(PORT, () => {
    console.log(`Server Node.js đang chạy tại cổng ${PORT}`);
});