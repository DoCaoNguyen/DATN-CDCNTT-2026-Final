const pool = require('./src/config/db');

async function dropUnusedTables() {
    try {
        console.log('Đang xóa 4 bảng không sử dụng...');
        await pool.query('DROP TABLE IF EXISTS user_wealth_bags CASCADE;');
        await pool.query('DROP TABLE IF EXISTS wealth_bag_transactions CASCADE;');
        await pool.query('DROP TABLE IF EXISTS user_checkins CASCADE;');
        await pool.query('DROP TABLE IF EXISTS loyalty_point_batches CASCADE;');
        console.log('Xóa 4 bảng thành công!');
    } catch (err) {
        console.error('Lỗi khi xóa bảng:', err);
    } finally {
        pool.end();
    }
}
dropUnusedTables();
