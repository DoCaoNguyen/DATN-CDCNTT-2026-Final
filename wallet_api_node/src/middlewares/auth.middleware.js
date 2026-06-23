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

const requireAdmin = async (req, res, next) => {
    try {
        const userId = req.user.userId || req.user.id;
        const query = `
            SELECT r.code 
            FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = $1
        `;
        const result = await pool.query(query, [userId]);
        const roles = result.rows.map(row => row.code);

        if (roles.includes('ADMIN') || roles.includes('SUPER_ADMIN')) {
            req.user.roles = roles;
            return next();
        }

        return res.status(403).json({ error: 'Không có quyền truy cập tài nguyên này' });
    } catch (error) {
        console.error('requireAdmin error:', error);
        return res.status(500).json({ error: 'Lỗi kiểm tra quyền hạn' });
    }
};

const requirePermission = (...permissions) => {
    return async (req, res, next) => {
        try {
            if (req.user && req.user.roles && req.user.roles.includes('SUPER_ADMIN')) {
                return next();
            }

            if (req.user && req.user.roles && req.user.roles.includes('ADMIN')) {
                return next();
            }

            return res.status(403).json({ error: 'Không có quyền thực hiện thao tác này' });
        } catch (error) {
            console.error('requirePermission error:', error);
            return res.status(500).json({ error: 'Lỗi kiểm tra quyền hạn' });
        }
    };
};

module.exports = verifyToken;
module.exports.verifyToken = verifyToken;
module.exports.requireAdmin = requireAdmin;
module.exports.requirePermission = requirePermission;
module.exports.authenticateJwt = verifyToken;