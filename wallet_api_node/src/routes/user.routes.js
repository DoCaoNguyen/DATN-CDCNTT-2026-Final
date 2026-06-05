const express = require('express');
const router = express.Router();
const userController = require('../controllers/user.controller');
const verifyToken = require('../middlewares/auth.middleware');

router.use(verifyToken);
router.get('/search', userController.search);

module.exports = router;