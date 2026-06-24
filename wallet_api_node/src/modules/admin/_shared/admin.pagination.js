/**
 * Admin Shared Pagination
 * 
 * Di chuyển từ admin.repository.js:
 * - buildPagination(page, limit)
 */

function buildPagination(page = 1, limit = 20) {
    const safePage = Math.max(Number(page) || 1, 1);
    const safeLimit = Math.min(Math.max(Number(limit) || 20, 1), 100);
    return {
        page: safePage,
        limit: safeLimit,
        offset: (safePage - 1) * safeLimit
    };
}

module.exports = { buildPagination };
