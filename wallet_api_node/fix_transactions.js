const fs = require('fs');
const file = 'src/modules/transaction/transaction.service.js';
let content = fs.readFileSync(file, 'utf8');

// Remove extRef random generation
content = content.replace(/const extRef = \(externalReference && \/\^\\d\{12\}\$\/\.test\(externalReference\)\)\n\s*\? externalReference\n\s*: Math\.floor\(100000000000 \+ Math\.random\(\) \* 900000000000\)\.toString\(\);/g, '');

// Deposit
content = content.replace(/const ledgerTxId = await repo\.createLedgerTransaction\(client, 'DEPOSIT', wallet\.id, 'Nạp tiền từ ngân hàng liên kết'\);/g, 
`const ledgerTxId = await repo.createLedgerTransaction(client, 'DEPOSIT', wallet.id, 'Nạp tiền từ ngân hàng liên kết');
            const hex = ledgerTxId.replace(/-/g, '').substring(0, 10);
            const extRef = (externalReference && /^\\d{12}$/.test(externalReference)) ? externalReference : BigInt('0x' + hex).toString().padStart(12, '0').slice(0, 12);`);

// Withdraw
content = content.replace(/const ledgerTxId = await repo\.createLedgerTransaction\(client, 'WITHDRAW', wallet\.id, 'Rút tiền về ngân hàng liên kết'\);/g, 
`const ledgerTxId = await repo.createLedgerTransaction(client, 'WITHDRAW', wallet.id, 'Rút tiền về ngân hàng liên kết');
            const hex = ledgerTxId.replace(/-/g, '').substring(0, 10);
            const extRef = (externalReference && /^\\d{12}$/.test(externalReference)) ? externalReference : BigInt('0x' + hex).toString().padStart(12, '0').slice(0, 12);`);

// Bank Transfer
content = content.replace(/const ledgerTxId = await repo\.createLedgerTransaction\(client, 'WITHDRAW', wallet\.id, \`Chuyển tiền đến tài khoản \$\{accountNumber\} - \$\{bankName\}\`\);/g, 
`const ledgerTxId = await repo.createLedgerTransaction(client, 'WITHDRAW', wallet.id, \`Chuyển tiền đến tài khoản \${accountNumber} - \${bankName}\`);
            const hex = ledgerTxId.replace(/-/g, '').substring(0, 10);
            const extRef = (externalReference && /^\\d{12}$/.test(externalReference)) ? externalReference : BigInt('0x' + hex).toString().padStart(12, '0').slice(0, 12);`);

// Transfer - modify repo.recordTransfer
content = content.replace(/await repo\.recordTransfer\(client, senderWallet\.id, receiverWallet\.id, amount, note, ledgerTxId, referenceCode\);/g,
`const hex = ledgerTxId.replace(/-/g, '').substring(0, 10);
            const finalRef = BigInt('0x' + hex).toString().padStart(12, '0').slice(0, 12);
            await repo.recordTransfer(client, senderWallet.id, receiverWallet.id, amount, note, ledgerTxId, finalRef);`);

// History - ALWAYS use uuid
content = content.replace(/if \(!ref && item\.transaction_id\) \{/g, 'if (item.transaction_id) {');

fs.writeFileSync(file, content, 'utf8');
console.log('Done!');
