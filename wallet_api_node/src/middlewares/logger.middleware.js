const logRepo = require('../modules/system/log.repository');

const apiLogger = (req, res, next) => {
    const startTime = Date.now();

    res.on('finish', () => {
        const duration = Date.now() - startTime;
        const logData = {
            method: req.method,
            url: req.originalUrl,
            status: res.statusCode,
            ip: req.ip || req.connection.remoteAddress,
            duration: `${duration}ms`,
            user_agent: req.headers['user-agent'],
            actor_id: req.user ? req.user.userId : null 
        };

        let logLevel = 'INFO';
        if (res.statusCode >= 400 && res.statusCode < 500) logLevel = 'WARN';
        if (res.statusCode >= 500) logLevel = 'ERROR';

        logRepo.writeSystemLog('API_GATEWAY', logLevel, `API Call: ${req.method} ${req.originalUrl}`, logData)
            .catch(err => console.error('Lỗi ghi System Log:', err));
    });
    next();
};

module.exports = apiLogger;