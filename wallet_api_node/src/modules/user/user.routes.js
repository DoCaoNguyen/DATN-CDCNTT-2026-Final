const express = require('express');
const router = express.Router();
const userController = require('./user.controller');
const verifyToken = require('../../middlewares/auth.middleware');

router.use(verifyToken);
router.get('/', userController.getAllUsers);
router.get('/search', userController.search);
router.get('/me', userController.getProfile);
router.get('/:id', userController.getUserById);

module.exports = router;