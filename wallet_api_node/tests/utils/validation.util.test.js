const assert = require('assert');
const {
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
    isValidUrl
} = require('../../src/modules/admin/_shared/validation.util');

// Test normalizeFullName
assert.strictEqual(normalizeFullName('   Nguyễn    Văn   An   '), 'Nguyễn Văn An');
assert.strictEqual(normalizeFullName('Jean-Pierre  Dupont'), 'Jean-Pierre Dupont');

// Test normalizeUsername
assert.strictEqual(normalizeUsername('  ADMIN_User123  '), 'admin_user123');

// Test normalizeVietnamPhone
assert.strictEqual(normalizeVietnamPhone('0912 345 678'), '+84912345678');
assert.strictEqual(normalizeVietnamPhone('84 912-345-678'), '+84912345678');
assert.strictEqual(normalizeVietnamPhone('+84(912)345678'), '+84912345678');
assert.strictEqual(normalizeVietnamPhone('912345678'), '+84912345678');

// Test isValidFullName
assert.strictEqual(isValidFullName('Nguyễn Văn An'), true);
assert.strictEqual(isValidFullName('Nguyen Van An'), true);
assert.strictEqual(isValidFullName('Jean-Pierre Dupont'), true);
assert.strictEqual(isValidFullName("O'Connor James"), true);
assert.strictEqual(isValidFullName('Nguyễn'), false); // Only 1 word
assert.strictEqual(isValidFullName('Nguyễn Văn An 123'), false); // Contains numbers
assert.strictEqual(isValidFullName('Nguyễn Văn An @'), false); // Contains special chars

// Test isValidVietnamMobilePhone
assert.strictEqual(isValidVietnamMobilePhone('0912345678'), true); // 09x
assert.strictEqual(isValidVietnamMobilePhone('0312345678'), true); // 03x
assert.strictEqual(isValidVietnamMobilePhone('0812345678'), true); // 08x
assert.strictEqual(isValidVietnamMobilePhone('0512345678'), true); // 05x
assert.strictEqual(isValidVietnamMobilePhone('0712345678'), true); // 07x
assert.strictEqual(isValidVietnamMobilePhone('0212345678'), false); // 02x is landline/invalid mobile prefix
assert.strictEqual(isValidVietnamMobilePhone('091234567'), false); // too short
assert.strictEqual(isValidVietnamMobilePhone('09123456789'), false); // too long

// Test isValidUsername
assert.strictEqual(isValidUsername('admin_user123'), true);
assert.strictEqual(isValidUsername('user.name'), true);
assert.strictEqual(isValidUsername('u'), false); // too short
assert.strictEqual(isValidUsername('admin-user'), false); // invalid char -

console.log('All backend validation tests passed!');
