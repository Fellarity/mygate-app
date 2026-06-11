const mongoose = require('mongoose');

const ReportSchema = new mongoose.Schema({
  employeeCode: { type: String, required: true },
  date: { type: Date, default: Date.now },
  department: { type: String, required: true },
  report1: { type: String, required: true },
  report2: { type: String },
  report3: { type: String },
  startTime: { type: String, required: true },
  endTime: { type: String, required: true },
  teamLeader: { type: String, required: true },
  projectNumber: { type: String, required: true },
  status: { 
    type: String, 
    enum: ['Pending', 'Approved', 'Rejected'], 
    default: 'Pending' 
  },
  tlComments: { type: String },
  submittedAt: { type: Date, default: Date.now },
  reviewedAt: { type: Date }
});

module.exports = mongoose.model('Report', ReportSchema);
