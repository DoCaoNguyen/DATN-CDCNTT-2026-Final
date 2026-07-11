const { ensureUuid, handleAdminError } = require('../_shared');
const { 
    normalizeMerchantName, 
    normalizeTaxCode, 
    normalizeVietnamPhone, 
    normalizeEmail, 
    normalizeFullName, 
    normalizeUsername,
    isValidFullName, 
    isValidUsername, 
    isValidVietnamMobilePhone,
    URL_REGEX
} = require('../_shared/validation.util');

const merchantsValidator = {
    validateIdParam: (req, res, next) => {
        try {
            ensureUuid(req.params.id, 'Invalid_Merchant_Id');
            next();
        } catch (error) {
            return handleAdminError(res, error, 'Validation Error:');
        }
    },

    validateActionReason: (req, res, next) => {
        // reason is required for reject and suspend
        const action = req.path.split('/').pop(); // "approve", "reject", "suspend", "activate", "rotate", "revoke"
        const reason = (req.body || {}).reason;

        if (['reject', 'suspend', 'revoke'].includes(action)) {
            if (!reason || typeof reason !== 'string' || reason.trim() === '') {
                return res.status(400).json({
                    success: false,
                    message: 'Reason is required for this action',
                    error_code: 'Reason_Required'
                });
            }
        }
        next();
    },

    validateKeyIdParam: (req, res, next) => {
        try {
            ensureUuid(req.params.keyId, 'Invalid_Key_Id');
            next();
        } catch (error) {
            return handleAdminError(res, error, 'Validation Error:');
        }
    },

    validateCreateMerchant: (req, res, next) => {
        const { merchant_name, business_type, tax_code, representative_name, address, email, phone, owner_info, callback } = req.body;
        const errors = [];

        // Validate Merchant Name
        if (!merchant_name || !String(merchant_name).trim()) {
            errors.push({ field: 'merchant_name', code: 'MERCHANT_NAME_REQUIRED', message: 'Tên Merchant là bắt buộc.' });
        } else if (String(merchant_name).trim().length > 255) {
            errors.push({ field: 'merchant_name', code: 'MERCHANT_NAME_TOO_LONG', message: 'Tên Merchant không được vượt quá 255 ký tự.' });
        }

        // Validate Business Type
        if (!business_type || !['ONLINE', 'OFFLINE', 'BOTH'].includes(business_type)) {
            errors.push({ field: 'business_type', code: 'BUSINESS_TYPE_INVALID', message: 'Loại hình kinh doanh không hợp lệ.' });
        }

        // Validate Tax Code
        if (!tax_code || !String(tax_code).trim()) {
            errors.push({ field: 'tax_code', code: 'TAX_CODE_REQUIRED', message: 'Mã số thuế là bắt buộc.' });
        }

        // Validate Representative Name
        if (!representative_name || !String(representative_name).trim()) {
            errors.push({ field: 'representative_name', code: 'REPRESENTATIVE_NAME_REQUIRED', message: 'Người đại diện là bắt buộc.' });
        }

        // Validate Address
        if (!address || !String(address).trim()) {
            errors.push({ field: 'address', code: 'ADDRESS_REQUIRED', message: 'Địa chỉ doanh nghiệp là bắt buộc.' });
        }

        // Validate Email (Optional for Merchant)
        if (email) {
            const normalizedEmail = normalizeEmail(email);
            if (normalizedEmail.length > 255) {
                errors.push({ field: 'email', code: 'EMAIL_TOO_LONG', message: 'Email không được vượt quá 255 ký tự.' });
            } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizedEmail)) {
                errors.push({ field: 'email', code: 'EMAIL_INVALID_FORMAT', message: 'Email không hợp lệ.' });
            }
        }

        // Validate Phone (Optional)
        if (phone) {
            if (!isValidVietnamMobilePhone(phone)) {
                errors.push({ field: 'phone', code: 'PHONE_INVALID_FORMAT', message: 'Số điện thoại không đúng định dạng (VD: 0912345678 hoặc +84912345678).' });
            }
        }

        // Validate Tax Code (Optional)
        if (tax_code && String(tax_code).trim().length > 50) {
            errors.push({ field: 'tax_code', code: 'TAX_CODE_TOO_LONG', message: 'Mã số thuế không được vượt quá 50 ký tự.' });
        }

        // Validate Callback
        if (callback) {
            const hasCallbackUrl = !!(callback.default_callback_url && String(callback.default_callback_url).trim());
            const hasRedirectUrl = !!(callback.default_redirect_url && String(callback.default_redirect_url).trim());
            
            if (hasRedirectUrl && !hasCallbackUrl) {
                errors.push({ field: 'callback.default_callback_url', code: 'CALLBACK_URL_REQUIRED', message: 'Bắt buộc nhập Callback URL khi có Redirect URL.' });
            }

            if (hasCallbackUrl && !URL_REGEX.test(callback.default_callback_url)) {
                errors.push({ field: 'callback.default_callback_url', code: 'URL_INVALID', message: 'Callback URL không hợp lệ.' });
            }
            if (hasRedirectUrl && !URL_REGEX.test(callback.default_redirect_url)) {
                errors.push({ field: 'callback.default_redirect_url', code: 'URL_INVALID', message: 'Redirect URL không hợp lệ.' });
            }
        }

        // Validate Owner Info
        if (owner_info) {
            if (!owner_info.full_name || !String(owner_info.full_name).trim()) {
                errors.push({ field: 'owner_info.full_name', code: 'FULL_NAME_REQUIRED', message: 'Họ tên chủ sở hữu là bắt buộc.' });
            } else if (!isValidFullName(owner_info.full_name)) {
                errors.push({ field: 'owner_info.full_name', code: 'FULL_NAME_INVALID', message: 'Họ tên không hợp lệ.' });
            }

            if (!owner_info.username) {
                errors.push({ field: 'owner_info.username', code: 'USERNAME_REQUIRED', message: 'Tên đăng nhập là bắt buộc.' });
            } else if (!isValidUsername(owner_info.username)) {
                errors.push({ field: 'owner_info.username', code: 'USERNAME_INVALID', message: 'Username không hợp lệ.' });
            }

            if (!owner_info.email) {
                errors.push({ field: 'owner_info.email', code: 'EMAIL_REQUIRED', message: 'Email chủ sở hữu là bắt buộc.' });
            } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizeEmail(owner_info.email))) {
                errors.push({ field: 'owner_info.email', code: 'EMAIL_INVALID_FORMAT', message: 'Email chủ sở hữu không hợp lệ.' });
            }

            if (owner_info.phone && !isValidVietnamMobilePhone(owner_info.phone)) {
                errors.push({ field: 'owner_info.phone', code: 'PHONE_INVALID_FORMAT', message: 'Số điện thoại chủ sở hữu không đúng định dạng.' });
            }
        }

        if (errors.length > 0) {
            return res.status(409).json({
                success: false,
                code: 'RESOURCE_CONFLICT',
                message: 'Dữ liệu không hợp lệ.',
                errors
            });
        }

        next();
    },

    validateCreateApiKey: (req, res, next) => {
        const body = req.body || {};
        let { key_name, environment } = body;

        if (!key_name || !environment) {
            return res.status(400).json({
                success: false,
                message: 'key_name, environment are required',
                error_code: 'Validation_Error'
            });
        }

        key_name = String(key_name).trim();
        if (key_name.length < 3 || key_name.length > 100) {
            return res.status(400).json({
                success: false,
                message: 'Tên API Key phải từ 3 đến 100 ký tự.',
                error_code: 'Validation_Error'
            });
        }
        req.body.key_name = key_name;

        if (!['SANDBOX', 'LIVE'].includes(environment)) {
            return res.status(400).json({
                success: false,
                message: 'environment must be SANDBOX or LIVE',
                error_code: 'Validation_Error'
            });
        }
        next();
    }
};

module.exports = merchantsValidator;
