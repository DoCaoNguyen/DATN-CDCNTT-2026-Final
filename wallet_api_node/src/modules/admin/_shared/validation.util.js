const normalizeFullName = (fullName) => {
    if (!fullName) return '';
    return String(fullName)
        .normalize('NFC')
        .trim()
        .replace(/\s+/g, ' ');
};

const normalizeUsername = (username) => {
    if (!username) return '';
    return String(username).trim().toLowerCase();
};

const normalizeEmail = (email) => {
    if (!email) return '';
    return String(email).trim().toLowerCase();
};

const normalizeVietnamPhone = (phone) => {
    if (!phone) return '';
    let cleaned = String(phone).replace(/[\s\-\(\)]/g, '');
    if (cleaned.startsWith('+84')) {
        cleaned = '0' + cleaned.slice(3);
    } else if (cleaned.startsWith('84') && cleaned.length > 9) {
        cleaned = '0' + cleaned.slice(2);
    }
    return cleaned;
};

const normalizeMerchantName = (merchantName) => {
    if (!merchantName) return '';
    return String(merchantName)
        .normalize('NFC')
        .trim()
        .replace(/\s+/g, ' ');
};

const normalizeTaxCode = (taxCode) => {
    if (!taxCode) return '';
    return String(taxCode).trim().replace(/\s+/g, '');
};

// Regex patterns
const FULL_NAME_REGEX = /^[\p{L}\p{M}\s\-']+$/u;
const VIETNAM_MOBILE_PHONE_REGEX = /^0[35789]\d{8}$/;
const USERNAME_REGEX = /^[a-zA-Z0-9_\.]+$/;
const URL_REGEX = /^https?:\/\/.+$/;

const isValidFullName = (fullName) => {
    if (!fullName) return false;
    const normalized = normalizeFullName(fullName);
    if (normalized.length === 0 || normalized.length > 25) return false;
    // Check if it has at least 2 words
    if (normalized.split(' ').length < 2) return false;
    // Check characters (letters, marks, spaces, hyphens, apostrophes only)
    return FULL_NAME_REGEX.test(normalized);
};

const isValidVietnamMobilePhone = (phone) => {
    if (!phone) return false;
    const normalized = normalizeVietnamPhone(phone);
    return VIETNAM_MOBILE_PHONE_REGEX.test(normalized);
};

const isValidUsername = (username) => {
    if (!username) return false;
    const normalized = normalizeUsername(username);
    if (normalized.length < 3 || normalized.length > 50) return false;
    return USERNAME_REGEX.test(normalized);
};

const isValidMerchantName = (merchantName) => {
    if (!merchantName) return false;
    const normalized = normalizeMerchantName(merchantName);
    return normalized.length > 0 && normalized.length <= 150;
};

const isValidUrl = (url) => {
    if (!url) return false;
    const strUrl = String(url).trim();
    return URL_REGEX.test(strUrl);
};

const formatValidationError = (field, code, message) => {
    return {
        field,
        code,
        message
    };
};

const buildErrorResponse = (errors) => {
    return {
        success: false,
        code: 'VALIDATION_ERROR',
        message: 'Dữ liệu chưa hợp lệ.',
        errors: errors
    };
};

module.exports = {
    normalizeFullName,
    normalizeUsername,
    normalizeEmail,
    normalizeVietnamPhone,
    normalizeMerchantName,
    normalizeTaxCode,
    isValidFullName,
    isValidVietnamMobilePhone,
    isValidUsername,
    isValidMerchantName,
    isValidUrl,
    formatValidationError,
    buildErrorResponse
};
