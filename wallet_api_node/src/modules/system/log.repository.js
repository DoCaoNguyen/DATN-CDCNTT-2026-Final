const pool = require('../../config/db');

const logRepository = {
    writeSystemLog: async (moduleName, logLevel, message, metadata) => {
        const query = `
            INSERT INTO system_logs (trace_id, level, module, event, message, context)
            VALUES ($1, $2, $3, $4, $5, $6)
        `;
        await pool.query(query, [
            `trace-system-${Date.now()}`,
            logLevel,
            moduleName,
            'api.request',
            message,
            metadata ? JSON.stringify(metadata) : null
        ]);
    }
};

module.exports = logRepository;
