const pool = require('../../config/db');

const logRepository = {
    
    writeSystemLog: async (serviceName, logLevel, message, metadata) => {
        const query = `
            INSERT INTO system_logs (service_name, log_level, message, metadata)
            VALUES ($1, $2, $3, $4)
        `;
        await pool.query(query, [serviceName, logLevel, message, JSON.stringify(metadata)]);
    }
};

module.exports = logRepository;