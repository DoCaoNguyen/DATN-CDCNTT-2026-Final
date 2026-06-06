require('dotenv').config();
const express = require('express');
const cors = require('cors');
const masterRouter = require('./src/routes');
const app = express();

app.use(cors());
app.use(express.json());

app.use('/api/v1', masterRouter);

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => {
    console.log(`Server Node.js đang chạy tại cổng ${PORT}`);
});