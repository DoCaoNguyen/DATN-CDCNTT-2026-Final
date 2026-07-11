const { ensureUuid } = require('../_shared');
const { 
    normalizeFullName, 
    normalizeVietnamPhone, 
    normalizeEmail, 
    isValidFullName, 
    isValidUsername, 
    isValidVietnamMobilePhone 
} = require('../_shared/validation.util');

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

    validateCreateWalletUser: (req, res, next) => {
        const { full_name, email, phone } = req.body || {};
        
        // Security: Remove password from body if FE sends it
        if (req.body && req.body.password) {
            delete req.body.password;
        }

        const errors = [];

        // Validate Full Name
        if (!full_name || !String(full_name).trim()) {
            errors.push({ field: 'full_name', code: 'FULL_NAME_REQUIRED', message: 'Họ tên là bắt buộc.' });
        } else if (!isValidFullName(full_name)) {
            errors.push({ field: 'full_name', code: 'FULL_NAME_INVALID', message: 'Họ tên phải có ít nhất 2 từ và không chứa số hoặc ký tự đặc biệt.' });
        }

        // Validate Phone
        if (!phone) {
            errors.push({ field: 'phone', code: 'PHONE_REQUIRED', message: 'Số điện thoại là bắt buộc.' });
        } else if (!isValidVietnamMobilePhone(phone)) {
            errors.push({ field: 'phone', code: 'PHONE_INVALID_FORMAT', message: 'Số điện thoại không đúng định dạng (VD: 0912345678 hoặc +84912345678).' });
        }

        // Validate Email
        if (email) {
            const normalizedEmail = normalizeEmail(email);
            if (normalizedEmail.length > 254) {
                errors.push({ field: 'email', code: 'EMAIL_TOO_LONG', message: 'Email không được vượt quá 254 ký tự.' });
            } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizedEmail)) {
                errors.push({ field: 'email', code: 'EMAIL_INVALID_FORMAT', message: 'Email không hợp lệ.' });
            }
        }

        if (errors.length > 0) {
            return res.status(400).json({
                success: false,
                code: 'VALIDATION_ERROR',
                message: 'Dữ liệu chưa hợp lệ.',
                errors
            });
        }
        
        next();
    },

    validateCreateStaff: (req, res, next) => {
        const { full_name, email, phone, username, role_codes } = req.body || {};

        // Security: Remove password from body if FE sends it
        if (req.body && req.body.password) {
            delete req.body.password;
        }

        if (!full_name) {
            return res.status(400).json({
                success: false,
                code: 'VALIDATION_ERROR',
                error: 'Họ tên là bắt buộc.'
            });
        }
        if (!isValidFullName(full_name)) {
            return res.status(400).json({
                success: false,
                code: 'VALIDATION_ERROR',
                error: 'Họ tên phải có ít nhất 2 từ, tối đa 25 ký tự và không chứa số hoặc ký tự đặc biệt.'
            });
        }
        if (!username) {
            return res.status(400).json({
                success: false,
                code: 'VALIDATION_ERROR',
                error: 'Username là bắt buộc.'
            });
        }
        if (!isValidUsername(username)) {
            return res.status(400).json({
                success: false,
                code: 'VALIDATION_ERROR',
                error: 'Username chỉ được chứa chữ cái, số, dấu gạch dưới và từ 3-30 ký tự.'
            });
        }
        if (!email) {
            return res.status(400).json({
                success: false,
                code: 'VALIDATION_ERROR',
                error: 'Email là bắt buộc khi tạo tài khoản nhân viên.'
            });
        }
        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
            return res.status(400).json({
                success: false,
                code: 'VALIDATION_ERROR',
                error: 'Email không hợp lệ.'
            });
        }
        
        if (phone && !isValidVietnamMobilePhone(phone)) {
            return res.status(400).json({
                success: false,
                code: 'VALIDATION_ERROR',
                error: 'Số điện thoại không hợp lệ (Phải là số ĐT Việt Nam hợp lệ).'
            });
        }
        if (!role_codes || !Array.isArray(role_codes) || role_codes.length === 0) {
            return res.status(400).json({
                success: false,
                code: 'VALIDATION_ERROR',
                error: 'role_codes khong hop le hoac bi thieu'
            });
        }
        
        // Kiểm tra xem role_codes có hợp lệ không
        const allowedRoles = ['ADMIN', 'SUPPORT_STAFF', 'SUPER_ADMIN'];
        const isValidRoles = role_codes.every(role => allowedRoles.includes(role));
        if (!isValidRoles) {
            return res.status(400).json({
                success: false,
                code: 'VALIDATION_ERROR',
                error: 'Chỉ được phép tạo tài khoản với role: ADMIN, SUPPORT_STAFF, hoặc SUPER_ADMIN'
            });
        }
        
        next();
    },

    validateUpdateUser: (req, res, next) => {
        const { full_name, username, phone, email } = req.body || {};
        
        if (full_name !== undefined && !/^[\p{L}\.'-]+\s+[\p{L}\s\.'-]+$/u.test(String(full_name).trim())) {
            return res.status(400).json({
                success: false,
                code: 'VALIDATION_ERROR',
                error: 'Họ tên phải có ít nhất 2 từ và không chứa số hoặc ký tự đặc biệt.'
            });
        }
        if (username !== undefined && !/^[a-zA-Z0-9_]{3,30}$/.test(String(username).trim())) {
            return res.status(400).json({
                success: false,
                code: 'VALIDATION_ERROR',
                error: 'Username chỉ được chứa chữ cái, số, dấu gạch dưới và từ 3-30 ký tự.'
            });
        }
        if (phone !== undefined && !/^(0|\+84|84)[3|5|7|8|9]\d{8}$/.test(phone)) {
            return res.status(400).json({
                success: false,
                code: 'VALIDATION_ERROR',
                error: 'Số điện thoại phải gồm 10 chữ số và bắt đầu bằng số 0 (VD: 0912345678).'
            });
        }
        if (email !== undefined && email !== '' && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
            return res.status(400).json({
                success: false,
                code: 'VALIDATION_ERROR',
                error: 'Email không hợp lệ.'
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
        const { reason } = req.body || {};
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
