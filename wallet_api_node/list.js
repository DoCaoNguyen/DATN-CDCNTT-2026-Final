require('dotenv').config();
const axios = require('axios');

async function listAvailableModels() {
    const apiKey = process.env.GEMINI_API_KEY;
    
    if (!apiKey) {
        console.log("Không tìm thấy API Key trong file .env!");
        return;
    }

    try {
        console.log("Đang kết nối tới Google AI để lấy danh sách...");
        const response = await axios.get(`https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey}`);
        
        console.log("\n=== DANH SÁCH MODEL BẠN ĐƯỢC PHÉP DÙNG ===");
        
        response.data.models.forEach(model => {
            // Chỉ lọc ra những model hỗ trợ hàm generateContent (hàm mà chúng ta đang dùng để OCR)
            if (model.supportedGenerationMethods.includes('generateContent')) {
                // Google trả về tên có chữ 'models/' ở đầu, ta cắt đi cho dễ nhìn
                const modelName = model.name.replace('models/', '');
                console.log(`👉 Tên model chèn vào code: "${modelName}"`);
                console.log(`   Mô tả: ${model.displayName}`);
                console.log('---');
            }
        });

    } catch (error) {
        console.error("Lỗi khi lấy danh sách:", error.response ? JSON.stringify(error.response.data, null, 2) : error.message);
    }
}

listAvailableModels();