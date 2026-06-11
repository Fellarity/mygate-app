const cron = require('node-cron');
const nodemailer = require('nodemailer');
const supabase = require('../config/database');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});

function initCron(io) {
  cron.schedule('0 19 * * *', async () => {
    console.log('Running daily report compliance check...');
    const today = new Date().toISOString().split('T')[0];

    // 1. Get all employees
    const { data: employees, error: empError } = await supabase
      .from('users')
      .select('employee_code, email, name, team_leader')
      .eq('role', 'Employee');

    if (empError) return console.error(empError);

    for (const employee of employees) {
      // 2. Check if report exists for today
      const { data: report, error: repError } = await supabase
        .from('reports')
        .select('id')
        .eq('employee_code', employee.employee_code)
        .eq('date', today)
        .maybeSingle();

      if (!report) {
        sendReminder(employee, io);

        // 3. Check if they missed yesterday too
        const yesterday = new Date();
        yesterday.setDate(yesterday.getDate() - 1);
        const yesterdayStr = yesterday.toISOString().split('T')[0];

        const { data: yReport } = await supabase
          .from('reports')
          .select('id')
          .eq('employee_code', employee.employee_code)
          .eq('date', yesterdayStr)
          .maybeSingle();

        if (!yReport) {
          notifyTL(employee, io);
        }
      }
    }
  });
}

function sendReminder(employee, io) {
  const msg = `Hi ${employee.name}, please remember to fill your daily work report for today.`;
  io.to(employee.employee_code).emit('notification', { message: msg, type: 'reminder' });

  const mailOptions = {
    from: process.env.EMAIL_USER,
    to: employee.email,
    subject: 'OfficeGate: Daily Report Reminder',
    text: msg
  };

  transporter.sendMail(mailOptions, (error) => {
    if (error) console.log('Email error:', error);
  });
}

async function notifyTL(employee, io) {
  const msg = `Alert: ${employee.name} (${employee.employee_code}) has not submitted reports for 2 consecutive days.`;
  
  io.to(employee.team_leader).emit('notification', { 
    message: msg, 
    type: 'alert' 
  });

  const { data: tl } = await supabase
    .from('users')
    .select('email')
    .eq('employee_code', employee.team_leader)
    .maybeSingle();

  if (tl) {
    transporter.sendMail({
      from: process.env.EMAIL_USER,
      to: tl.email,
      subject: 'Compliance Alert: Consecutive Missed Reports',
      text: msg
    });
  }
}

module.exports = { initCron };
