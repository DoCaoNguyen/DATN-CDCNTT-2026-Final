const userRepository = require('./user.repository');

const userService = {
    searchUsers: async (searchQuery, currentUserId) => {
        const cleanQuery = searchQuery.trim();
        const users = await userRepository.searchUsers(cleanQuery, currentUserId);
        return users;
    }
};

module.exports = userService;