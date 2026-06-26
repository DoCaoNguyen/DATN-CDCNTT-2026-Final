const { ensureUuid } = require('../_shared');

const usersValidator = {
    validateIdParam: (req, res, next) => {
        try {
            ensureUuid(req.params.id, 'Invalid_User_Id');
            next();
        } catch (err) {
            return res.status(400).json({
                success: false,
                code: 'VALIDATION_ERROR',
                error: 'User ID khong hop le'
            });
        }
    },

    // Bắt buộc: full_name + password + ít nhất 1 trong (email|phone|username)
    validateCreateUser: (req, res, next) => {
        const { full_name, password, email, phone, username } = req.body || {};

        if (!full_name || !String(full_name).trim()) {
            return res.status(400).json({
                success: false,
                code: 'VALIDATION_ERROR',
                error: 'Thieu thong tin bat buoc'
            });
        }
        if (!password) {
            return res.status(400).json({
                success: false,
                code: 'VALIDATION_ERROR',
                error: 'Thieu thong tin bat buoc'
            });
        }
        if (!email && !phone && !username) {
            return res.status(400).json({
                success: false,
                code: 'VALIDATION_ERROR',
                error: 'Thieu thong tin bat buoc'
            });
        }
        if (password.length < 8) {
            return res.status(400).json({
                success: false,
                code: 'VALIDATION_ERROR',
                error: 'Mat khau phai co toi thieu 8 ky tu'
            });
        }
        next();
    },

    // Bắt buộc nhập lý do khi khóa/mở khóa
    validateReason: (req, res, next) => {
        const reason = req.body?.reason;
        if (!reason || !String(reason).trim()) {
            return res.status(400).json({
                success: false,
                code: 'VALIDATION_ERROR',
                error: 'Bat buoc nhap ly do thao tac'
            });
        }
        next();
    },

    validateResetPassword: (req, res, next) => {
        const { new_password, confirm_new_password, reason } = req.body || {};

        if (!new_password || new_password.length < 8) {
            return res.status(400).json({
                success: false,
                code: 'VALIDATION_ERROR',
                error: 'Mat khau phai co toi thieu 8 ky tu'
            });
        }
        if (new_password !== confirm_new_password) {
            return res.status(400).json({
                success: false,
                code: 'VALIDATION_ERROR',
                error: 'Mat khau xac nhan khong khop'
            });
        }
        if (!reason || !String(reason).trim()) {
            return res.status(400).json({
                success: false,
                code: 'VALIDATION_ERROR',
                error: 'Bat buoc nhap ly do thao tac'
            });
        }
        next();
    }
};

module.exports = usersValidator;
