const express = require('express');
const router = express.Router();
const supabase = require('../config/database');

// Submit a new report
router.post('/submit', async (req, res) => {
  const { employeeCode, date, department, report1, report2, report3, startTime, endTime, teamLeader, projectNumber } = req.body;
  
  const { data, error } = await supabase
    .from('reports')
    .insert([{ 
      employee_code: employeeCode, 
      date, 
      department, 
      report1, 
      report2, 
      report3, 
      start_time: startTime, 
      end_time: endTime, 
      team_leader: teamLeader, 
      project_number: projectNumber 
    }])
    .select();

  if (error) return res.status(400).json({ error: error.message });

  const reportId = data[0].id;

  // Notify Team Leader
  req.io.to(teamLeader).emit('new_report', {
    message: `New report submitted by ${employeeCode}`,
    reportId: reportId
  });

  res.status(201).json({ 
    message: 'Report submitted and pending approval', 
    id: reportId 
  });
});

// Review (Approve/Reject) a report
router.post('/review/:id', async (req, res) => {
  const { status, tlComments } = req.body;
  const id = req.params.id;

  const { data, error } = await supabase
    .from('reports')
    .update({ 
      status, 
      tl_comments: tlComments, 
      reviewed_at: new Date().toISOString() 
    })
    .eq('id', id)
    .select();

  if (error) return res.status(400).json({ error: error.message });

  const report = data[0];
  // Notify employee of the decision
  req.io.to(report.employee_code).emit('report_update', {
    status,
    message: `Your report for ${report.date} has been ${status}`
  });

  res.json({ message: `Report ${status}` });
});

// Helper to map DB columns back to camelCase for Flutter
const mapReport = (r) => ({
  id: r.id,
  employeeCode: r.employee_code,
  date: r.date,
  department: r.department,
  report1: r.report1,
  report2: r.report2,
  report3: r.report3,
  startTime: r.start_time,
  endTime: r.end_time,
  teamLeader: r.team_leader,
  projectNumber: r.project_number,
  status: r.status,
  tlComments: r.tl_comments,
  submittedAt: r.submitted_at,
  reviewedAt: r.reviewed_at
});

// Get reports for a specific employee
router.get('/employee/:code', async (req, res) => {
  const { data, error } = await supabase
    .from('reports')
    .select('*')
    .eq('employee_code', req.params.code)
    .order('submitted_at', { ascending: false });

  if (error) return res.status(500).json({ error: error.message });
  res.json(data.map(mapReport));
});

// Get pending reports for a TL
router.get('/pending/:tlName', async (req, res) => {
  const { data, error } = await supabase
    .from('reports')
    .select('*')
    .eq('team_leader', req.params.tlName)
    .eq('status', 'Pending');

  if (error) return res.status(500).json({ error: error.message });
  res.json(data.map(mapReport));
});

module.exports = router;
