const { Pool } = require('pg');
const bcrypt = require('bcrypt');
const p = new Pool({ user: 'postgres', password: '123', database: 'wallet_db' });
const hash = bcrypt.hashSync('000000', 10);
p.query('UPDATE users SET pin_hash = $1', [hash])
  .then(r => console.log('Updated ' + r.rowCount + ' users'))
  .catch(e => console.log(e))
  .finally(() => p.end());
