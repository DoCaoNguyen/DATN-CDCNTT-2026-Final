const logRepo = require('../repositories/log.repository');

const apiLogger = (req, res, next) => {
    const startTime = Date.now();

    // Lắng nghe sự kiện khi response được gửi đi thành công
    res.on('finish', () => {
        const duration = Date.now() - startTime;
        const logData = {
            method: req.method,
            url: req.originalUrl,
            status: res.statusCode,
            ip: req.ip || req.connection.remoteAddress,
            duration: `${duration}ms`,
            user_agent: req.headers['user-agent'],
            // Lấy userId nếu có đi qua middleware xác thực JWT
            actor_id: req.user ? req.user.userId : null 
        };

        // Quyết định Log Level dựa trên Status Code
        let logLevel = 'INFO';
        if (res.statusCode >= 400 && res.statusCode < 500) logLevel = 'WARN';
        if (res.statusCode >= 500) logLevel = 'ERROR';

        // Ghi xuống DB chạy ngầm
        logRepo.writeSystemLog('API_GATEWAY', logLevel, `API Call: ${req.method} ${req.originalUrl}`, logData)
            .catch(err => console.error('Lỗi ghi System Log:', err));
    });

    next();
};

module.exports = apiLogger;