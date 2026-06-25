/**
 * Admin Merchants Routes
 * 
 * Endpoints:
 * - GET    /                          → listMerchants
 * - GET    /:id                       → getMerchantDetail
 * - POST   /:id/actions/approve       → approveMerchant
 * - POST   /:id/actions/reject        → rejectMerchant
 * - POST   /:id/actions/suspend       → suspendMerchant
 * - POST   /:id/actions/activate      → activateMerchant
 * - GET    /:id/api-keys              → getMerchantApiKeys
 */
/**
 * Admin Merchants Routes
 * 
 * Endpoints:
 * - GET    /                          → listMerchants
 * - GET    /:id                       → getMerchantDetail
 * - POST   /:id/actions/approve       → approveMerchant
 * - POST   /:id/actions/reject        → rejectMerchant
 * - POST   /:id/actions/suspend       → suspendMerchant
 * - POST   /:id/actions/activate      → activateMerchant
 * - GET    /:id/api-keys              → getMerchantApiKeys
 */
const express = require('express');
const router = express.Router();
const { requirePermission } = require('../../../middlewares/auth.middleware');
const merchantsController = require('./merchants.controller');
const merchantsValidator = require('./merchants.validator');

/**
 * @swagger
 * /api/v1/admin/merchants:
 *   get:
 *     summary: Admin xem danh sach merchant
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Merchants
 * /api/v1/admin/merchants/{id}:
 *   get:
 *     summary: Admin xem chi tiet merchant
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Merchant detail
 * /api/v1/admin/merchants/{id}/actions/approve:
 *   post:
 *     summary: Admin duyet merchant
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Merchant approved
 * /api/v1/admin/merchants/{id}/actions/reject:
 *   post:
 *     summary: Admin tu choi merchant
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Merchant rejected
 * /api/v1/admin/merchants/{id}/actions/suspend:
 *   post:
 *     summary: Admin tam ngung merchant
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Merchant suspended
 * /api/v1/admin/merchants/{id}/actions/activate:
 *   post:
 *     summary: Admin kich hoat lai merchant
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Merchant activated
 * /api/v1/admin/merchants/{id}/api-keys:
 *   get:
 *     summary: Admin xem API keys cua merchant
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Merchant API keys
 */


// Validation middleware chaining for actions
const validateAction = [merchantsValidator.validateIdParam, merchantsValidator.validateActionReason];
const validateKeyAction = [merchantsValidator.validateIdParam, merchantsValidator.validateKeyIdParam, merchantsValidator.validateActionReason];

router.post('/', requirePermission('admin.merchants.manage'), merchantsValidator.validateCreateMerchant, merchantsController.createMerchant);
router.get('/', requirePermission('admin.merchants.read'), merchantsController.listMerchants);

router.get('/:id', requirePermission('admin.merchants.read'), merchantsValidator.validateIdParam, merchantsController.getMerchantDetail);
router.patch('/:id', requirePermission('admin.merchants.manage'), merchantsValidator.validateIdParam, merchantsController.updateMerchant);

router.post('/:id/actions/approve', requirePermission('admin.merchants.manage'), validateAction, merchantsController.approveMerchant);
router.post('/:id/actions/reject', requirePermission('admin.merchants.manage'), validateAction, merchantsController.rejectMerchant);
router.post('/:id/actions/suspend', requirePermission('admin.merchants.manage'), validateAction, merchantsController.suspendMerchant);
router.post('/:id/actions/activate', requirePermission('admin.merchants.manage'), validateAction, merchantsController.activateMerchant);

router.get('/:id/api-keys', requirePermission('admin.merchants.read'), merchantsValidator.validateIdParam, merchantsController.getMerchantApiKeys);
router.post('/:id/api-keys', requirePermission('admin.merchants.manage'), merchantsValidator.validateIdParam, merchantsValidator.validateCreateApiKey, merchantsController.createApiKey);

router.post('/:id/api-keys/:keyId/actions/rotate', requirePermission('admin.merchants.manage'), validateKeyAction, merchantsController.rotateApiKey);
router.post('/:id/api-keys/:keyId/actions/revoke', requirePermission('admin.merchants.manage'), validateKeyAction, merchantsController.revokeApiKey);

module.exports = router;
