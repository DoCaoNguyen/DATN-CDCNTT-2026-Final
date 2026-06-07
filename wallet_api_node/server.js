require('dotenv').config();
BigInt.prototype.toJSON = function () {
    return this.toString();
};
const express = require('express');
const cors = require('cors');
const masterRouter = require('./src/routes');
const app = express();
const swaggerUi = require('swagger-ui-express');
const swaggerSpec = require('./src/config/swagger');

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
app.use(cors());
app.use(express.json());
app.use('/api/v1', masterRouter);

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => {
    console.log(`Server Node.js đang chạy tại cổng ${PORT}`);
});