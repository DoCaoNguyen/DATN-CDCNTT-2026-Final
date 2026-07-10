const fs = require('fs');
const path = require('path');

const txRepoPath = path.join(__dirname, 'src', 'modules', 'transaction', 'transaction.repository.js');
let txRepo = fs.readFileSync(txRepoPath, 'utf8');

// 1. txRepo: createLedgerTransaction
txRepo = txRepo.replace(
    /createLedgerTransaction: async \(client, type, sourceId, sourceType, description, amount, currency = 'VND', metadata = null\) => {/g,
    "createLedgerTransaction: async (client, type, sourceId, sourceType, description, amount, currency = 'VND', metadata = null, idempotencyKey = null) => {"
);
txRepo = txRepo.replace(
    /INSERT INTO ledger_transactions \(id, transaction_no, transaction_type, source_id, source_type, status, description, amount, currency, completed_at, metadata\)\s*VALUES \(\$1, \$2, \$3, \$4, \$5, 'SUCCESS', \$6, \$7, \$8, CURRENT_TIMESTAMP, \$9\) RETURNING id;/g,
    "INSERT INTO ledger_transactions (id, transaction_no, transaction_type, source_id, source_type, status, description, amount, currency, completed_at, metadata, idempotency_key)\n            VALUES ($1, $2, $3, $4, $5, 'SUCCESS', $6, $7, $8, CURRENT_TIMESTAMP, $9, $10) RETURNING id;"
);
txRepo = txRepo.replace(
    /const result = await client.query\(query, \[newId, transactionNo, type, sourceId, sourceType, description, amount\.toString\(\), currency, metadata\]\);/g,
    "const result = await client.query(query, [newId, transactionNo, type, sourceId, sourceType, description, amount.toString(), currency, metadata, idempotencyKey]);"
);

// 2. txRepo: recordDeposit
txRepo = txRepo.replace(
    /recordDeposit: async \(client, id, depositNo, userId, walletId, amount, ledgerId, depositMethod = 'LINKED_BANK', externalReference = null\) => {/g,
    "recordDeposit: async (client, id, depositNo, userId, walletId, amount, ledgerId, depositMethod = 'LINKED_BANK', externalReference = null, idempotencyKey = null) => {"
);
txRepo = txRepo.replace(
    /const idempotencyKey = id; \/\/ Fallback idempotency key/g,
    "idempotencyKey = idempotencyKey || id; // Fallback idempotency key"
);

// 3. txRepo: recordBankTransfer
txRepo = txRepo.replace(
    /recordBankTransfer: async \(client, id, transferNo, userId, walletId, amount, ledgerId, bankCode, accountNo, externalRef = null\) => {/g,
    "recordBankTransfer: async (client, id, transferNo, userId, walletId, amount, ledgerId, bankCode, accountNo, externalRef = null, idempotencyKey = null) => {"
);

// 4. txRepo: recordWalletTransfer
txRepo = txRepo.replace(
    /recordWalletTransfer: async \(client, id, transferNo, senderUserId, senderWalletId, receiverUserId, receiverWalletId, amount, ledgerId, description = null\) => {/g,
    "recordWalletTransfer: async (client, id, transferNo, senderUserId, senderWalletId, receiverUserId, receiverWalletId, amount, ledgerId, description = null, idempotencyKey = null) => {"
);

// 5. txRepo: recordWithdrawal
txRepo = txRepo.replace(
    /recordWithdrawal: async \(client, id, withdrawalNo, userId, walletId, linkedBankId, amount, ledgerId, method = 'LINKED_BANK', externalRef = null\) => {/g,
    "recordWithdrawal: async (client, id, withdrawalNo, userId, walletId, linkedBankId, amount, ledgerId, method = 'LINKED_BANK', externalRef = null, idempotencyKey = null) => {"
);

fs.writeFileSync(txRepoPath, txRepo);


const txSvcPath = path.join(__dirname, 'src', 'modules', 'transaction', 'transaction.service.js');
let txSvc = fs.readFileSync(txSvcPath, 'utf8');

// 1. txSvc: deposit
txSvc = txSvc.replace(
    /deposit: async \(userId, amount, pin, faceImagePath, externalReference\) => {/g,
    "deposit: async (userId, amount, pin, faceImagePath, externalReference, idempotencyKey = null) => {"
);
txSvc = txSvc.replace(
    /const ledgerTxId = await repo.createLedgerTransaction\(client, 'DEPOSIT', depositId, 'DEPOSIT', 'Nạp tiền từ ngân hàng liên kết', amount\);/g,
    "const ledgerTxId = await repo.createLedgerTransaction(client, 'DEPOSIT', depositId, 'DEPOSIT', 'Nạp tiền từ ngân hàng liên kết', amount, 'VND', null, idempotencyKey);"
);
txSvc = txSvc.replace(
    /await repo.recordDeposit\(client, depositId, 'DEP-' \+ extRef, userId, wallet\.id, amount, ledgerTxId, 'LINKED_BANK', extRef\);/g,
    "await repo.recordDeposit(client, depositId, 'DEP-' + extRef, userId, wallet.id, amount, ledgerTxId, 'LINKED_BANK', extRef, idempotencyKey);"
);

// 2. txSvc: withdraw
txSvc = txSvc.replace(
    /withdraw: async \(userId, amount, pin, faceImagePath, linkedBankId, externalReference\) => {/g,
    "withdraw: async (userId, amount, pin, faceImagePath, linkedBankId, externalReference, idempotencyKey = null) => {"
);
txSvc = txSvc.replace(
    /const ledgerTxId = await repo.createLedgerTransaction\(client, 'WITHDRAW', withdrawalId, 'WITHDRAW', 'Rút tiền về ngân hàng liên kết', amount\);/g,
    "const ledgerTxId = await repo.createLedgerTransaction(client, 'WITHDRAW', withdrawalId, 'WITHDRAW', 'Rút tiền về ngân hàng liên kết', amount, 'VND', null, idempotencyKey);"
);
txSvc = txSvc.replace(
    /await repo.recordWithdrawal\(client, withdrawalId, 'WDR-' \+ extRef, userId, wallet\.id, linkedBankId, amount, ledgerTxId, 'LINKED_BANK', extRef\);/g,
    "await repo.recordWithdrawal(client, withdrawalId, 'WDR-' + extRef, userId, wallet.id, linkedBankId, amount, ledgerTxId, 'LINKED_BANK', extRef, idempotencyKey);"
);

// 3. txSvc: bankTransfer
txSvc = txSvc.replace(
    /bankTransfer: async \(userId, amount, pin, faceImagePath, bankCode, accountNumber, externalReference\) => {/g,
    "bankTransfer: async (userId, amount, pin, faceImagePath, bankCode, accountNumber, externalReference, idempotencyKey = null) => {"
);
txSvc = txSvc.replace(
    /const ledgerTxId = await repo.createLedgerTransaction\(client, 'BANK_TRANSFER', transferId, 'BANK_TRANSFER', `Chuyển tiền đến tài khoản \${accountNumber} - \${bankName}`, amount\);/g,
    "const ledgerTxId = await repo.createLedgerTransaction(client, 'BANK_TRANSFER', transferId, 'BANK_TRANSFER', `Chuyển tiền đến tài khoản ${accountNumber} - ${bankName}`, amount, 'VND', null, idempotencyKey);"
);
txSvc = txSvc.replace(
    /await repo.recordBankTransfer\(client, transferId, 'BNK-' \+ extRef, userId, wallet\.id, amount, ledgerTxId, bankCode, accountNumber, extRef\);/g,
    "await repo.recordBankTransfer(client, transferId, 'BNK-' + extRef, userId, wallet.id, amount, ledgerTxId, bankCode, accountNumber, extRef, idempotencyKey);"
);

// 4. txSvc: transfer
txSvc = txSvc.replace(
    /transfer: async \(senderId, amount, pin, faceImagePath, receiverIdentifier, message\) => {/g,
    "transfer: async (senderId, amount, pin, faceImagePath, receiverIdentifier, message, idempotencyKey = null) => {"
);
txSvc = txSvc.replace(
    /const ledgerTxId = await repo.createLedgerTransaction\(client, 'TRANSFER', transferId, 'TRANSFER', message, amount\);/g,
    "const ledgerTxId = await repo.createLedgerTransaction(client, 'TRANSFER', transferId, 'TRANSFER', message, amount, 'VND', null, idempotencyKey);"
);
txSvc = txSvc.replace(
    /await repo.recordWalletTransfer\(client, transferId, 'TRF-' \+ hex, senderId, senderWallet\.id, receiverWallet\.user_id, receiverWallet\.id, amount, ledgerTxId, message\);/g,
    "await repo.recordWalletTransfer(client, transferId, 'TRF-' + hex, senderId, senderWallet.id, receiverWallet.user_id, receiverWallet.id, amount, ledgerTxId, message, idempotencyKey);"
);

fs.writeFileSync(txSvcPath, txSvc);


const txCtrlPath = path.join(__dirname, 'src', 'modules', 'transaction', 'transaction.controller.js');
let txCtrl = fs.readFileSync(txCtrlPath, 'utf8');

txCtrl = txCtrl.replace(
    /const result = await txService\.bankTransfer\(userId, bigAmount, pin, faceImagePath, bank_code, account_number, external_reference\);/g,
    "const result = await txService.bankTransfer(userId, bigAmount, pin, faceImagePath, bank_code, account_number, external_reference, idempotencyKey);"
);
txCtrl = txCtrl.replace(
    /const result = await txService\.transfer\(userId, bigAmount, pin, faceImagePath, receiver_identifier, message\);/g,
    "const result = await txService.transfer(userId, bigAmount, pin, faceImagePath, receiver_identifier, message, idempotencyKey);"
);

fs.writeFileSync(txCtrlPath, txCtrl);

console.log("Updated idempotency keys successfully.");
