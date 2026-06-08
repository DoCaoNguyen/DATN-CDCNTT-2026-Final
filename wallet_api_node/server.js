require('dotenv').config();
require('./src/config/firebase');
BigInt.prototype.toJSON = function () {
    return this.toString();
};
const express = require('express');
const http = require('http');
const cors = require('cors');
const masterRouter = require('./src/routes');
const app = express();
const server = http.createServer(app);
const { initSocket } = require('./src/utils/socket');
const swaggerUi = require('swagger-ui-express');
const swaggerSpec = require('./src/config/swagger');

initSocket(server);

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
app.use(cors());
app.use(express.json());
app.use('/api/v1', masterRouter);

const PORT = process.env.PORT || 8000;
server.listen(PORT, () => {
    console.log(`Server Node.js đang chạy tại cổng ${PORT}`);
});