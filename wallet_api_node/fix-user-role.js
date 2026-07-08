const pool = require('./src/config/db');

async function fixUserRole() {
    try {
        const roleId = '01000000-0000-0000-0000-000000000004';
        
        // Fix Name
        await pool.query("UPDATE roles SET name = 'User Wallet' WHERE id = $1", [roleId]);
        
        // Reset permissions
        await pool.query("DELETE FROM role_permissions WHERE role_id = $1", [roleId]);
        
        // Find permission IDs for user role
        const permissions = [
            'auth.me.read',
            'wallets.me.read',
            'wallets.me.statement.read',
            'topups.create',
            'topups.me.read',
            'transfers.create',
            'transfers.me.read',
            'qr-payments.resolve',
            'qr-payments.confirm',
            'transactions.me.read'
        ];
        
        const { rows } = await pool.query("SELECT id FROM permissions WHERE code = ANY($1)", [permissions]);
        const permIds = rows.map(r => r.id);
        
        for (const pId of permIds) {
            await pool.query("INSERT INTO role_permissions (role_id, permission_id) VALUES ($1, $2)", [roleId, pId]);
        }
        
        console.log('Restored User Wallet role and permissions successfully.');
    } catch (err) {
        console.error('Error fixing User Wallet:', err);
    }
    process.exit(0);
}

fixUserRole();
