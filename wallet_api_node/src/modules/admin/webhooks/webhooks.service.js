const webhooksRepository = require('./webhooks.repository');

const adminWebhooksService = {
    listWebhooks: async (page = 1, limit = 20, status, merchantId) => {
        const { items, total } = await webhooksRepository.listWebhooks(page, limit, status, merchantId);

        return {
            items,
            total,
            page,
            limit,
            total_pages: Math.ceil(total / limit)
        };
    },

    getWebhookDetail: async (id) => {
        return webhooksRepository.getWebhookDetail(id);
    }
};

module.exports = adminWebhooksService;
