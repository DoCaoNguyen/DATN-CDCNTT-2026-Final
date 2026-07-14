import assert from 'assert';
import {
  fullNameSchema,
  vietnamMobilePhoneSchema,
  optionalVietnamPhoneSchema,
  usernameSchema,
  emailSchema,
  merchantNameSchema,
  taxCodeSchema,
  httpUrlSchema,
  mapRoleToVietnamese,
  mapApiErrorsToState
} from './common-validation';

console.log('Testing fullNameSchema...');
assert.doesNotThrow(() => fullNameSchema.parse('Nguyễn Văn An'));
assert.doesNotThrow(() => fullNameSchema.parse("O'Connor James"));
assert.throws(() => fullNameSchema.parse('Nguyễn'), /Họ tên phải có ít nhất 2 từ/);
assert.throws(() => fullNameSchema.parse('Nguyễn Văn 123'), /Họ tên không được chứa số/);

console.log('Testing vietnamMobilePhoneSchema...');
assert.strictEqual(vietnamMobilePhoneSchema.parse('0912 345 678'), '+84912345678');
assert.strictEqual(vietnamMobilePhoneSchema.parse('84912345678'), '+84912345678');
assert.throws(() => vietnamMobilePhoneSchema.parse('0212345678'), /Số điện thoại không đúng định dạng mạng di động/);

console.log('Testing optionalVietnamPhoneSchema...');
assert.strictEqual(optionalVietnamPhoneSchema.parse(''), undefined);
assert.strictEqual(optionalVietnamPhoneSchema.parse('0912 345 678'), '+84912345678');

console.log('Testing usernameSchema...');
assert.doesNotThrow(() => usernameSchema.parse('admin_user.123'));
assert.throws(() => usernameSchema.parse('admin-user'), /chỉ được chứa chữ cái/);

console.log('Testing emailSchema...');
assert.doesNotThrow(() => emailSchema.parse('test@gmail.com'));
assert.throws(() => emailSchema.parse('testgmail.com'));

console.log('Testing taxCodeSchema...');
assert.doesNotThrow(() => taxCodeSchema.parse('0312-345-678'));
assert.throws(() => taxCodeSchema.parse('ABC'), /Mã số thuế chỉ được chứa số/);

console.log('Testing mapRoleToVietnamese...');
assert.strictEqual(mapRoleToVietnamese('SUPER_ADMIN'), 'Quản trị viên Cấp cao');
assert.strictEqual(mapRoleToVietnamese('UNKNOWN'), 'UNKNOWN');

console.log('Testing mapApiErrorsToState...');
const apiErrors = [{ field: 'phone', code: 'TEST', message: 'Lỗi SĐT' }];
const state = mapApiErrorsToState(apiErrors, 'prefix_');
assert.strictEqual(state['prefix_phone'], 'Lỗi SĐT');

console.log('All frontend validation tests passed!');
