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

const fs = require('fs');
const path = require('path');

app.get('/', (req, res) => {
    res.send(`
        <h1>App Liên kết API is running</h1>
        <a href="/settings">Đi tới Cài đặt API Key</a>
    `);
});

app.get('/settings', (req, res) => {
    const apiKey = process.env.MERCHANT_API_KEY || '';
    const secretKey = process.env.MERCHANT_SECRET_KEY || '';
    
    res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>Cài đặt TikTok Shop Demo</title>
            <style>
                body { font-family: Arial, sans-serif; padding: 2rem; background: #f8fafc; }
                .container { max-width: 600px; margin: 0 auto; background: white; padding: 2rem; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
                input { width: 100%; padding: 10px; margin: 10px 0 20px; border: 1px solid #ccc; border-radius: 4px; box-sizing: border-box; }
                button { background: #3b82f6; color: white; padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer; }
                button:hover { background: #2563eb; }
            </style>
        </head>
        <body>
            <div class="container">
                <h2>Cài đặt API Key (TikTok Shop Demo)</h2>
                <form id="settingsForm">
                    <label>MERCHANT_API_KEY</label>
                    <input type="text" id="apiKey" value="${apiKey}" placeholder="pk_test_...">
                    
                    <label>MERCHANT_SECRET_KEY (tuỳ chọn)</label>
                    <input type="text" id="secretKey" value="${secretKey}" placeholder="sk_test_...">
                    
                    <button type="submit">Lưu cấu hình</button>
                </form>
            </div>
            
            <script>
                document.getElementById('settingsForm').addEventListener('submit', async (e) => {
                    e.preventDefault();
                    const apiKey = document.getElementById('apiKey').value;
                    const secretKey = document.getElementById('secretKey').value;
                    
                    const res = await fetch('/api/settings', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ apiKey, secretKey })
                    });
                    
                    if(res.ok) {
                        alert('Lưu thành công! Vui lòng khởi động lại server app_lienket_api.');
                    } else {
                        alert('Lỗi khi lưu.');
                    }
                });
            </script>
        </body>
        </html>
    `);
});

app.post('/api/settings', (req, res) => {
    try {
        const { apiKey, secretKey } = req.body;
        const envPath = path.join(__dirname, '.env');
        let envContent = '';
        
        if (fs.existsSync(envPath)) {
            envContent = fs.readFileSync(envPath, 'utf8');
        }
        
        if (envContent.includes('MERCHANT_API_KEY=')) {
            envContent = envContent.replace(/MERCHANT_API_KEY=.*/g, `MERCHANT_API_KEY=${apiKey}`);
        } else {
            envContent += `\nMERCHANT_API_KEY=${apiKey}`;
        }
        
        if (envContent.includes('MERCHANT_SECRET_KEY=')) {
            envContent = envContent.replace(/MERCHANT_SECRET_KEY=.*/g, `MERCHANT_SECRET_KEY=${secretKey}`);
        } else {
            envContent += `\nMERCHANT_SECRET_KEY=${secretKey}`;
        }
        
        fs.writeFileSync(envPath, envContent);
        
        process.env.MERCHANT_API_KEY = apiKey;
        process.env.MERCHANT_SECRET_KEY = secretKey;
        
        res.json({ success: true });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});


app.listen(PORT, () => {
    console.log(`🚀 Server đang chạy tại http://localhost:${PORT}`);
});
