const pool = require('./src/config/db');
const { v7: uuidv7 } = require('uuid');

async function fixPermissions() {
  const permissions = [
    { code: 'admin.roles.read', name: 'View Roles', description: 'Can view roles and permissions' },
    { code: 'admin.roles.create', name: 'Create Role', description: 'Can create roles' },
    { code: 'admin.roles.update', name: 'Update Role', description: 'Can update roles' },
    { code: 'admin.roles.delete', name: 'Delete Role', description: 'Can delete roles' }
  ];

  for (const p of permissions) {
    const existing = await pool.query('SELECT id FROM permissions WHERE code = $1', [p.code]);
    if (existing.rows.length === 0) {
      await pool.query('INSERT INTO permissions (id, code, name, description) VALUES ($1, $2, $3, $4)', [uuidv7(), p.code, p.name, p.description]);
      console.log('Inserted', p.code);
    }
  }

  // Assign to SUPER_ADMIN and ADMIN
  const roles = await pool.query("SELECT id, code FROM roles WHERE code IN ('SUPER_ADMIN', 'ADMIN')");
  const newPerms = await pool.query("SELECT id FROM permissions WHERE code LIKE 'admin.roles.%'");

  for (const role of roles.rows) {
    for (const perm of newPerms.rows) {
      const existingLink = await pool.query('SELECT 1 FROM role_permissions WHERE role_id = $1 AND permission_id = $2', [role.id, perm.id]);
      if (existingLink.rows.length === 0) {
        await pool.query('INSERT INTO role_permissions (role_id, permission_id) VALUES ($1, $2)', [role.id, perm.id]);
        console.log(`Assigned to ${role.code}`);
      }
    }
  }

  console.log('Done');
  process.exit(0);
}

fixPermissions().catch(console.error);
