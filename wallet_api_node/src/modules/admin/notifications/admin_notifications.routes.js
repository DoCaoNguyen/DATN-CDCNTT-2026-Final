const express = require('express');
const router = express.Router();
const adminNotificationController = require('./admin_notifications.controller');
const { requirePermission } = require('../../../middlewares/auth.middleware');

// Các route này yêu cầu quyền đăng nhập Admin (ít nhất là xem dashboard)
router.get('/', requirePermission('admin.dashboard.read'), adminNotificationController.getNotifications);
router.put('/read-all', requirePermission('admin.dashboard.read'), adminNotificationController.markAllAsRead);
router.put('/:id/read', requirePermission('admin.dashboard.read'), adminNotificationController.markAsRead);

module.exports = router;
