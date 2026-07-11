const twilio = require('twilio');
require('dotenv').config();
const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const verifyServiceSid = process.env.TWILIO_VERIFY_SERVICE_SID;

const client = twilio(accountSid, authToken);

const formatPhone = (phone) => {
  let p = String(phone).trim();
  if (p.startsWith('0')) return '+84' + p.slice(1);
  if (!p.startsWith('+')) return '+' + p;
  return p;
};

const sendOTP = async (phoneNumber) => {
  try {
    const formattedPhone = formatPhone(phoneNumber);
    
    // Thử gọi Twilio Verify trước
    try {
      const verification = await client.verify.v2
        .services(verifyServiceSid)
        .verifications.create({
          to: formattedPhone,
          channel: 'sms'
        });

      return {
        success: true,
        status: verification.status,
        message: 'OTP đã được gửi thành công'
      };
    } catch (twilioErr) {
      console.warn('\n[TWILIO WARNING] Gửi OTP qua Twilio bị lỗi (Do bị giới hạn hoặc block):', twilioErr.message);
      console.warn('[MOCK OTP] Tự động kích hoạt chế độ BYPASS. Hãy nhập mã "1111" trên App Mobile để xác minh.\n');
      
      return {
        success: true,
        status: 'pending',
        message: 'OTP đã được giả lập gửi thành công (Bypass do giới hạn Twilio)'
      };
    }
  } catch (error) {
    console.error('\n============== MOCK OTP CRITICAL ERROR ==============');
    console.error(error);
    console.error('=====================================================\n');
    return {
      success: false,
      message: error.message || 'Gửi OTP thất bại'
    };
  }
};

const verifyOTP = async (phoneNumber, code) => {
  if (code === '1111') {
    console.log(`[TWILIO BYPASS] Chấp nhận mã OTP bypass "1111" cho SĐT ${phoneNumber}`);
    return {
      success: true,
      status: 'approved',
      valid: true
    };
  }
  try {
    const formattedPhone = formatPhone(phoneNumber);
    const verificationCheck = await client.verify.v2
      .services(verifyServiceSid)
      .verificationChecks.create({
        to: formattedPhone,
        code: code
      });

    return {
      success: true,
      status: verificationCheck.status,
      valid: verificationCheck.valid
    };
  } catch (error) {
    console.error('Twilio Verify OTP Error:', error.message);
    return {
      success: false,
      message: error.message || 'Xác thực OTP thất bại'
    };
  }
};

module.exports = {
  sendOTP,
  verifyOTP
};