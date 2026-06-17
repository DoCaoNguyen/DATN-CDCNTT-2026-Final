const pool = require('../../config/db');

const logRepository = {
    
    writeSystemLog: async (serviceName, logLevel, message, metadata) => {
        const query = `
            INSERT INTO system_logs (module, level, event, message, context)
            VALUES ($1, UPPER($2)::log_level, 'SYSTEM_LOG', $3, $4)
        `;
        await pool.query(query, [serviceName, logLevel || 'INFO', message, JSON.stringify(metadata || {})]);
    }
};

module.exports = logRepository;