require('dotenv').config();
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const bodyParser = require('body-parser');
const db = require('./config/database');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: { origin: "*" }
});

app.use(cors());
app.use(bodyParser.json());

// Socket.io for notifications
io.on('connection', (socket) => {
  console.log('New client connected');
  socket.on('join', (userId) => {
    socket.join(userId);
    console.log(`User ${userId} joined room`);
  });
});

app.use((req, res, next) => {
  req.io = io;
  req.db = db;
  next();
});

const reportRoutes = require('./routes/reports');
const { initCron } = require('./services/notificationService');

app.use('/api/reports', reportRoutes);

// Start Compliance Cron Jobs
initCron(io);

app.get('/', (req, res) => res.send('OfficeGate API Running (SQLite)'));

const PORT = process.env.PORT || 5000;
server.listen(PORT, '0.0.0.0', () => console.log(`Server running on port ${PORT}`));
