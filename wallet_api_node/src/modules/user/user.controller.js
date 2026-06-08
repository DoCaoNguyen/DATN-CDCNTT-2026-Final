const userService = require('./user.service'); 

const userController = {
    search: async (req, res) => {
        try {
            const currentUserId = req.user.userId; 
            const { q } = req.query; 

            
            if (!q || q.trim() === '') {
                return res.status(200).json({ data: [] });
            }

            
            const users = await userService.searchUsers(q, currentUserId);
            
            
            res.status(200).json({ data: users });

        } catch (error) {
            console.error("Lỗi tìm kiếm user:", error);
            res.status(500).json({ error: 'Lỗi hệ thống khi tìm kiếm' });
        }
    },

    getProfile: async (req, res) => {
        try {
            const userId = req.user.userId; 
            const user = await userService.getUserProfile(userId);
            if (!user) {
                return res.status(404).json({ error: 'Không tìm thấy người dùng' });
            }
            res.status(200).json({ data: user });
        } catch (error) {
            console.error("Lỗi lấy thông tin profile:", error);
            res.status(500).json({ error: 'Lỗi hệ thống' });
        }
    },

    getAllUsers: async (req, res) => {
        try {
            const users = await userService.getAllUsers();
            res.status(200).json({ data: users });
        } catch (error) {
            console.error("Lỗi lấy danh sách user:", error);
            res.status(500).json({ error: 'Lỗi hệ thống' });
        }
    },

    getUserById: async (req, res) => {
        try {
            const { id } = req.params;
            const user = await userService.getUserById(id);
            if (!user) {
                return res.status(404).json({ error: 'Không tìm thấy người dùng' });
            }
            res.status(200).json({ data: user });
        } catch (error) {
            console.error("Lỗi lấy thông tin user theo ID:", error);
            res.status(500).json({ error: 'Lỗi hệ thống' });
        }
    }
};

module.exports = userController;