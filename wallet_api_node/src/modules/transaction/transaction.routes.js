const express = require('express');
const router = express.Router();
const transactionController = require('./transaction.controller');
const verifyToken = require('../../middlewares/auth.middleware');
const multer = require('multer');

// Configure Multer to store uploaded temp files in uploads/
const upload = multer({ dest: 'uploads/' });

const withIdempotency = require('../../middlewares/idempotency.middleware');

router.use(verifyToken);

router.post('/deposit', upload.single('face_image'), withIdempotency, transactionController.deposit);
router.post('/withdraw', upload.single('face_image'), withIdempotency, transactionController.withdraw);
router.post('/transfer', withIdempotency, transactionController.transfer);
router.get('/history', transactionController.getHistory);

module.exports = router;