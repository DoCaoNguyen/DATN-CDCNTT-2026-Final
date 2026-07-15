const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');

let io;

const initSocket = (server) => {
    io = new Server(server, {
        cors: {
            origin: [
                'http://localhost:3000',
                'http://localhost:5173',
                'https://admin.yourdomain.com',
                'https://merchant.yourdomain.com'
            ],
            methods: ["GET", "POST"]
        }
    });

    io.use((socket, next) => {
        const token = socket.handshake.auth.token || socket.handshake.query.token;

        if (!token) {
            return next(new Error('Authentication error: No token provided'));
        }

        try {
            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            socket.user = decoded;
            next();
        } catch (err) {
            next(new Error('Authentication error: Invalid token'));
        }
    });

    io.on('connection', (socket) => {
        const userId = socket.user.userId || socket.user.id;
        console.log(`User connected: ${userId} (Socket ID: ${socket.id})`);

        socket.join(`user_${userId}`);
        
        const isAdmin = 
            socket.user.role === 'ADMIN' || socket.user.role === 'SUPER_ADMIN' ||
            socket.user.role_code === 'ADMIN' || socket.user.role_code === 'SUPER_ADMIN' ||
            socket.user.userType === 'ADMIN' || socket.user.userType === 'SUPER_ADMIN' ||
            socket.user.user_type === 'ADMIN' || socket.user.user_type === 'SUPER_ADMIN' ||
            (Array.isArray(socket.user.roles) && (socket.user.roles.includes('ADMIN') || socket.user.roles.includes('SUPER_ADMIN')));

        if (isAdmin) {
            socket.join('admin_dashboard');
            console.log(`User ${userId} joined admin_dashboard`);
        }

        socket.on('disconnect', () => {
            console.log(`User disconnected: ${userId}`);
        });
    });

    return io;
};

const getIo = () => {
    if (!io) {
        throw new Error('Socket.io not initialized!');
    }
    return io;
};

const emitToUser = (userId, event, data) => {
    if (io) {
        io.to(`user_${userId}`).emit(event, data);
    }
};

const broadcastToAdminDashboard = (event, data) => {
    if (io) {
        io.to('admin_dashboard').emit(event, data);
    }
};

module.exports = { initSocket, getIo, emitToUser, broadcastToAdminDashboard };
