const jwt = require('jsonwebtoken');
const pool = require('../config/db');

function unauthorized(res, code, message) {
    return res.status(401).json({
        success: false,
        code,
        error: message
    });
}

function forbidden(res, message) {
    return res.status(403).json({
        success: false,
        code: 'FORBIDDEN',
        error: message
    });
}

const authenticateJwt = async (req, res, next) => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return unauthorized(res, 'UNAUTHORIZED', 'Không tìm thấy Access Token');
    }

    let token = authHeader.replace(/^Bearer\s+/i, '').trim();
    token = token.replace(/^Bearer\s+/i, '').trim();

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        if (decoded.token_type && decoded.token_type !== 'ACCESS') {
            return unauthorized(res, 'UNAUTHORIZED', 'Token không đúng loại');
        }

        const userId = decoded.sub || decoded.userId || decoded.id;
        const query = `
            SELECT id, user_type, status, token_version
            FROM users
            WHERE id = $1
        `;
        const result = await pool.query(query, [userId]);

        if (result.rows.length === 0) {
            return unauthorized(res, 'UNAUTHORIZED', 'Người dùng không tồn tại');
        }

        const user = result.rows[0];
        if (['LOCKED', 'BLOCKED', 'INACTIVE'].includes(user.status)) {
            return forbidden(res, 'Tài khoản đã bị khóa hoặc chưa kích hoạt');
        }

        const roles = Array.isArray(decoded.roles)
            ? decoded.roles
            : [decoded.role || user.user_type].filter(Boolean);

        req.user = {
            ...decoded,
            id: userId,
            userId,
            sub: userId,
            user_type: decoded.user_type || user.user_type,
            role: decoded.role || roles[0],
            roles,
            permissions: Array.isArray(decoded.permissions) ? decoded.permissions : [],
            merchant_context: decoded.merchant_context || null
        };

        return next();
    } catch (err) {
        if (err.name === 'TokenExpiredError') {
            return unauthorized(res, 'TOKEN_EXPIRED', 'Token đã hết hạn');
        }
        return unauthorized(res, 'UNAUTHORIZED', 'Token không hợp lệ');
    }
};

const requireRole = (...allowedRoles) => (req, res, next) => {
    const roles = req.user?.roles || [];
    const hasRole = allowedRoles.some(role => roles.includes(role));
    if (!hasRole) {
        return forbidden(res, 'Không có vai trò phù hợp để truy cập tài nguyên này');
    }
    return next();
};

const requirePermission = (...requiredPermissions) => (req, res, next) => {
    const permissions = req.user?.permissions || [];
    const hasPermission = requiredPermissions.every(permission => permissions.includes(permission));
    if (!hasPermission) {
        return forbidden(res, 'Không có quyền truy cập tài nguyên này');
    }
    return next();
};

const requireAdmin = requireRole('ADMIN', 'SUPER_ADMIN', 'SUPPORT_STAFF');
const requireMerchant = requireRole('MERCHANT_OWNER', 'MERCHANT_STAFF');
const requireMerchantOwner = (req, res, next) => {
    const roles = req.user?.roles || [];
    const merchantContext = req.user?.merchant_context;
    if (roles.includes('MERCHANT_OWNER') || merchantContext?.is_owner) {
        return next();
    }
    return forbidden(res, 'Chỉ merchant owner được thực hiện thao tác này');
};

module.exports = authenticateJwt;
module.exports.authenticateJwt = authenticateJwt;
module.exports.requireRole = requireRole;
module.exports.requirePermission = requirePermission;
module.exports.requireAdmin = requireAdmin;
module.exports.requireMerchant = requireMerchant;
module.exports.requireMerchantOwner = requireMerchantOwner;
