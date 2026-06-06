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
    }
};

module.exports = userController;