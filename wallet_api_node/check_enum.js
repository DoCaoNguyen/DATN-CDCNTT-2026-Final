const pool = require('./src/config/db');
pool.query("SELECT enumlabel FROM pg_enum WHERE enumtypid = 'ledger_transaction_type'::regtype")
  .then(r => console.log(r.rows))
  .catch(console.error)
  .finally(() => process.exit(0));
