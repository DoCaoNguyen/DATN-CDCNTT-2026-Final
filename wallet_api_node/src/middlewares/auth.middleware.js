const jwt = require('jsonwebtoken');
const pool = require('../config/db');

const verifyToken = async (req, res, next) => {
    const authHeader = req.headers['authorization'];
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Không tìm thấy Access Token' });
    }

    const token = authHeader.split(' ')[1];

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        
        // Truy vấn database để so sánh token_version hiện tại của người dùng
        const query = 'SELECT token_version FROM users WHERE id = $1';
        const result = await pool.query(query, [decoded.userId]);
        
        if (result.rows.length === 0) {
            return res.status(401).json({ error: 'Người dùng không tồn tại' });
        }
        
        const currentVersion = result.rows[0].token_version;
        if (decoded.tokenVersion === undefined || decoded.tokenVersion !== currentVersion) {
            return res.status(401).json({ error: 'Tài khoản đã được đăng nhập ở thiết bị khác' });
        }

        req.user = decoded;
        next();
    } catch (error) {
        return res.status(401).json({ error: 'Token không hợp lệ hoặc đã hết hạn' });
    }
};

module.exports = verifyToken;