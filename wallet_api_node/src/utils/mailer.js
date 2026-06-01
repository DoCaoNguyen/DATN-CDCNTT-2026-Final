const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS
    }
});

const sendOTP = async (email, otp) => {
    const mailOptions = {
        from: process.env.SMTP_USER,
        to: email,
        subject: 'Mã OTP Xác Nhận Đăng Ký Ví',
        text: `Mã OTP của bạn là: ${otp}. Mã này có hiệu lực trong 5 phút.`
    };
    return transporter.sendMail(mailOptions);
};

module.exports = { sendOTP };