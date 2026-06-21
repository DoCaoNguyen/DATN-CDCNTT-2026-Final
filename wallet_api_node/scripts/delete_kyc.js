const pool = require('../src/config/db');

async function run() {
  try {
    const phone = '0855313437';
    // Find user
    const res1 = await pool.query('SELECT id FROM users WHERE phone = $1', [phone]);
    if (res1.rows.length === 0) {
      console.log('User not found with phone', phone);
      process.exit(0);
    }
    const userId = res1.rows[0].id;
    console.log('Found user ID:', userId);

    // Delete KYC
    const res2 = await pool.query('DELETE FROM user_kyc WHERE user_id = $1', [userId]);
    console.log('Deleted rows from user_kyc:', res2.rowCount);
    
    // Update users table
    const res3 = await pool.query("UPDATE users SET is_kyc_verified = FALSE WHERE id = $1", [userId]);
    console.log('Updated users table, rows:', res3.rowCount);
    
    console.log('Successfully cleared KYC for', phone);
  } catch (err) {
    console.error(err);
  } finally {
    pool.end();
  }
}
run();
