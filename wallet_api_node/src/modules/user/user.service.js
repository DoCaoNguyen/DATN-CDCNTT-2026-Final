const userRepository = require('./user.repository');

const userService = {
    searchUsers: async (searchQuery, currentUserId) => {
        const cleanQuery = searchQuery.trim();
        const users = await userRepository.searchUsers(cleanQuery, currentUserId);
        return users;
    },

    getUserProfile: async (userId) => {
        const user = await userRepository.getUserProfile(userId);
        return user;
    },

    getAllUsers: async () => {
        return await userRepository.getAllUsers();
    },

    getUserById: async (userId) => {
        return await userRepository.getUserById(userId);
    }
};

module.exports = userService;