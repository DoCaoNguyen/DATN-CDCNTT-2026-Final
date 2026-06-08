const admin = require('firebase-admin');

const serviceAccount = require('./firebase-service-account.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

console.log(" Firebase Admin kết nối thành công!");

module.exports = admin;