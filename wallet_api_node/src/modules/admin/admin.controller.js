const adminService = require('./admin.service');

function getRequestMeta(req) {
    return {
        ipAddress: req.ip || req.connection?.remoteAddress || null,
        userAgent: req.headers['user-agent'] || null
    };
}

function success(res, data, message = 'OK', status = 200) {
    return res.status(status).json({
        success: true,
        code: 'OK',
        message,
        data
    });
}

function error(res, status, code, message) {
    return res.status(status).json({
        success: false,
        code,
        error: message
    });
}

function handleAdminError(res, err, logPrefix) {
    const mapping = {
        Validation_Error: [400, 'VALIDATION_ERROR', 'Thieu thong tin bat buoc'],
        Invalid_Id: [400, 'VALIDATION_ERROR', 'ID khong hop le'],
        Invalid_User_Id: [400, 'VALIDATION_ERROR', 'User ID khong hop le'],
        Invalid_Wallet_Id: [400, 'VALIDATION_ERROR', 'Wallet ID khong hop le'],
        Password_Policy_Invalid: [400, 'VALIDATION_ERROR', 'Mat khau phai co toi thieu 8 ky tu'],
        Invalid_User_Type: [400, 'VALIDATION_ERROR', 'Loai user khong hop le'],
        Invalid_User_Status: [400, 'VALIDATION_ERROR', 'Trang thai user khong hop le'],
        User_Conflict: [409, 'CONFLICT', 'Username, email hoac so dien thoai da ton tai'],
        Role_Not_Found: [400, 'VALIDATION_ERROR', 'Role khong ton tai hoac khong hoat dong'],
        User_Not_Found: [404, 'USER_NOT_FOUND', 'Khong tim thay user'],
        Wallet_Not_Found: [404, 'WALLET_NOT_FOUND', 'Khong tim thay vi'],
        Admin_Write_Forbidden: [403, 'FORBIDDEN', 'Tai khoan admin hien tai khong co quyen ghi'],
        Super_Admin_Required: [403, 'FORBIDDEN', 'Chi Super Admin duoc thuc hien thao tac nay'],
        Cannot_Lock_Self: [400, 'VALIDATION_ERROR', 'Khong the khoa chinh tai khoan dang dang nhap'],
        Reason_Required: [400, 'VALIDATION_ERROR', 'Bat buoc nhap ly do thao tac'],
        No_Update_Field: [400, 'VALIDATION_ERROR', 'Khong co truong cap nhat hop le']
    };

    if (mapping[err.message]) {
        const [status, code, message] = mapping[err.message];
        return error(res, status, code, message);
    }

    console.error(logPrefix, err);
    return error(res, 500, 'INTERNAL_SERVER_ERROR', 'Loi he thong');
}

const adminController = {
    listUsers: async (req, res) => {
        try {
            const result = await adminService.listUsers(req.query);
            return success(res, result, 'Lay danh sach user thanh cong');
        } catch (err) {
            return handleAdminError(res, err, 'Loi admin list users:');
        }
    },

    createUser: async (req, res) => {
        try {
            const result = await adminService.createUser({
                actor: req.user,
                payload: req.body,
                ...getRequestMeta(req)
            });
            return success(res, result, 'Tao user thanh cong', 201);
        } catch (err) {
            return handleAdminError(res, err, 'Loi admin create user:');
        }
    },

    getUserDetail: async (req, res) => {
        try {
            const result = await adminService.getUserDetail(req.params.id);
            return success(res, result, 'Lay chi tiet user thanh cong');
        } catch (err) {
            return handleAdminError(res, err, 'Loi admin get user detail:');
        }
    },

    updateUser: async (req, res) => {
        try {
            const result = await adminService.updateUser({
                actor: req.user,
                userId: req.params.id,
                payload: req.body,
                ...getRequestMeta(req)
            });
            return success(res, result, 'Cap nhat user thanh cong');
        } catch (err) {
            return handleAdminError(res, err, 'Loi admin update user:');
        }
    },

    getUserWallet: async (req, res) => {
        try {
            const result = await adminService.getUserWallet(req.params.id);
            return success(res, result, 'Lay vi cua user thanh cong');
        } catch (err) {
            return handleAdminError(res, err, 'Loi admin get user wallet:');
        }
    },

    lockUser: async (req, res) => {
        try {
            const result = await adminService.lockUser({
                actor: req.user,
                userId: req.params.id,
                reason: req.body.reason,
                ...getRequestMeta(req)
            });
            return success(res, result, 'Khoa user thanh cong');
        } catch (err) {
            return handleAdminError(res, err, 'Loi admin lock user:');
        }
    },

    unlockUser: async (req, res) => {
        try {
            const result = await adminService.unlockUser({
                actor: req.user,
                userId: req.params.id,
                reason: req.body.reason,
                ...getRequestMeta(req)
            });
            return success(res, result, 'Mo khoa user thanh cong');
        } catch (err) {
            return handleAdminError(res, err, 'Loi admin unlock user:');
        }
    },

    listWallets: async (req, res) => {
        try {
            const result = await adminService.listWallets(req.query);
            return success(res, result, 'Lay danh sach vi thanh cong');
        } catch (err) {
            return handleAdminError(res, err, 'Loi admin list wallets:');
        }
    },

    getWalletDetail: async (req, res) => {
        try {
            const result = await adminService.getWalletDetail(req.params.wallet_id || req.params.id);
            return success(res, result, 'Lay chi tiet vi thanh cong');
        } catch (err) {
            return handleAdminError(res, err, 'Loi admin get wallet detail:');
        }
    },

    getWalletSummary: async (req, res) => {
        try {
            const result = await adminService.getWalletSummary(req.params.wallet_id || req.params.id);
            return success(res, result, 'Lay tong quan vi thanh cong');
        } catch (err) {
            return handleAdminError(res, err, 'Loi admin get wallet summary:');
        }
    },

    getWalletLedger: async (req, res) => {
        try {
            const result = await adminService.getWalletLedger({
                walletId: req.params.wallet_id || req.params.id,
                query: req.query
            });
            return success(res, result, 'Lay ledger vi thanh cong');
        } catch (err) {
            return handleAdminError(res, err, 'Loi admin get wallet ledger:');
        }
    }
};

module.exports = adminController;
