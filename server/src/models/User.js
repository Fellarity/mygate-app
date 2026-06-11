const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  employeeCode: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { 
    type: String, 
    enum: ['Employee', 'Team Leader', 'Admin'], 
    default: 'Employee' 
  },
  department: { type: String },
  teamLeader: { type: String } // Stores the employeeCode of their TL
});

module.exports = mongoose.model('User', UserSchema);
