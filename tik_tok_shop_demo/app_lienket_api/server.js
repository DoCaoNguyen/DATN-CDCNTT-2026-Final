require('dotenv').config();
const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 4000;

app.use(cors());
app.use(express.json());

// Routes
const walletRoutes = require('./src/routes/wallet.routes');
const orderRoutes = require('./src/routes/order.routes');
app.use('/api/v1/wallets', walletRoutes);
app.use('/api/v1/orders', orderRoutes);

app.get('/', (req, res) => {
    res.send('App Liên kết API is running');
});

app.listen(PORT, () => {
    console.log(`🚀 Server đang chạy tại http://localhost:${PORT}`);
});
