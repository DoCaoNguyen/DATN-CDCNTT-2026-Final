// File: src/utils/sms.js

const sendSMS = async (to, body) => {
    try {
        let formattedPhone = String(to).trim();
        
        console.log("\n=== GỬI OTP QUA TELEGRAM BOT ===");
        console.log(`📱 Số nhận (Để hiển thị): ${formattedPhone}`);
        console.log(`✉️ Nội dung: ${body}`);
        console.log("================================\n");

        const botToken = process.env.TELEGRAM_BOT_TOKEN;
        
        // Vì trong môi trường Đồ án/Dev, ta sẽ ép tất cả OTP gửi về nick Telegram của bạn để test mượt mà
        const chatId = process.env.TELEGRAM_MY_CHAT_ID; 

        // Định dạng nội dung tin nhắn gửi về Telegram cho đẹp mắt, chuyên nghiệp
        const messageText = `🔔 *[E-WALLET AUTH]*\n\nMã OTP của bạn là: *${body}*\n_Vui lòng không chia sẻ mã này với bất kỳ ai để bảo vệ tài khoản._`;

        // Gọi API của Telegram
        const url = `https://api.telegram.org/bot${botToken}/sendMessage`;
        
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                chat_id: chatId,
                text: messageText,
                parse_mode: 'Markdown' // Hỗ trợ in đậm, in nghiêng tin nhắn
            })
        });

        const result = await response.json();

        if (result.ok) {
            console.log(`✅ Gửi OTP thành công qua Telegram Bot!`);
            return result.result;
        } else {
            console.error(`❌ Telegram báo lỗi: ${result.description}`);
            throw new Error(`Telegram Error: ${result.description}`);
        }

    } catch (error) {
        console.error('Lỗi hệ thống khi gửi OTP qua Telegram:', error);
        throw error;
    }
};

module.exports = { sendSMS };