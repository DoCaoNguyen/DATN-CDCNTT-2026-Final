const { createClient } = require('@supabase/supabase-js');
const { GoogleGenerativeAI } = require('@google/generative-ai');

// Khởi tạo Supabase & Gemini
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

// API xử lý Chatbot
const askQuestion = async (req, res) => {
  try {
    const { question } = req.body;
    if (!question) {
      return res.status(400).json({ error: "Thiếu câu hỏi (question)" });
    }

    // 1. Biến câu hỏi thành Vector (Embedding)
    const embeddingModel = genAI.getGenerativeModel({ model: "embedding-001" });
    const embedResult = await embeddingModel.embedContent(question);
    const queryVector = embedResult.embedding.values;

    // 2. Tìm kiếm các tài liệu liên quan trong Supabase
    // match_documents là hàm chúng ta đã tạo bằng SQL ở bước trước
    const { data: documents, error: searchError } = await supabase.rpc('match_documents', {
      query_embedding: queryVector,
      match_threshold: 0.7, // Mức độ giống nhau tối thiểu (0.0 đến 1.0)
      match_count: 3 // Lấy 3 tài liệu gần nhất
    });

    if (searchError) {
      console.error("Lỗi tìm kiếm Supabase:", searchError);
      return res.status(500).json({ error: "Lỗi khi tìm kiếm dữ liệu" });
    }

    // Nếu không tìm thấy tài liệu nào phù hợp
    if (!documents || documents.length === 0) {
      return res.json({ 
        answer: "Xin lỗi, hiện tại mình chưa có thông tin về vấn đề này. Bạn vui lòng liên hệ tổng đài CSKH nhé." 
      });
    }

    // 3. Gộp các tài liệu tìm được thành một chuỗi Context
    const contextText = documents.map(doc => doc.content).join('\n\n---\n\n');

    // 4. Gửi Prompt (Câu lệnh) cho Gemini để sinh câu trả lời
    const chatModel = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
    
    const prompt = `
Bạn là Trợ thủ AI thông minh của ứng dụng ví điện tử Mio247.
Nhiệm vụ của bạn là giải đáp thắc mắc của người dùng một cách ngắn gọn, súc tích và thân thiện.
Bạn CHỈ ĐƯỢC PHÉP sử dụng thông tin trong phần DỮ LIỆU CUNG CẤP dưới đây để trả lời.
Nếu thông tin trong DỮ LIỆU CUNG CẤP không đủ để trả lời, hãy nói: "Xin lỗi, hiện tại mình chưa có thông tin về vấn đề này. Bạn vui lòng liên hệ tổng đài CSKH nhé." - TUYỆT ĐỐI KHÔNG được tự bịa ra thông tin.

=== DỮ LIỆU CUNG CẤP ===
${contextText}
=========================

Câu hỏi của người dùng: "${question}"
Câu trả lời của bạn:
    `;

    const chatResult = await chatModel.generateContent(prompt);
    const answer = chatResult.response.text();

    // 5. Trả kết quả về cho App
    return res.json({ 
      answer: answer,
      // Trả thêm metadata để debug (App không cần hiển thị)
      sources: documents.map(d => d.metadata?.source)
    });

  } catch (error) {
    console.error("Lỗi xử lý AI Chatbot:", error);
    res.status(500).json({ error: "Đã có lỗi xảy ra trong quá trình xử lý" });
  }
};

module.exports = {
  askQuestion
};
