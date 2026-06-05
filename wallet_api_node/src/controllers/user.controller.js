const userRepository = require('../repositories/user.repository');

const userController = {
    search: async (req, res) => {
        try {
            const currentUserId = req.user.userId; // Lấy từ token
            const { q } = req.query; // Ví dụ: /api/v1/users/search?q=098

            if (!q || q.trim() === '') {
                return res.status(200).json({ data: [] });
            }

            const users = await userRepository.searchUsers(q.trim(), currentUserId);
            res.status(200).json({ data: users });
        } catch (error) {
            console.error("Lỗi tìm kiếm user:", error);
            res.status(500).json({ error: 'Lỗi hệ thống khi tìm kiếm' });
        }
    }
};

module.exports = userController;