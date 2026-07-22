import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import nodemailer from "npm:nodemailer@6.9.13";

const GMAIL_USER = "lucawookamooka@gmail.com";
const GMAIL_PASS = "hzbcicpyslsu lqcs".replace(/\s+/g, ''); // Ensure no spaces

serve(async (req) => {
  try {
    const { type, payload } = await req.json();
    console.log(`Processing notification type: ${type} for email: ${payload.email}`);

    let subject = "";
    let content = "";
    let to = payload.email;

    if (type === "reminder") {
      subject = "Faith Hours: Daily Report Reminder";
      content = `Hi ${payload.name},\n\nPlease remember to fill your daily work report for today.`;
    } else if (type === "approval") {
      subject = `Report ${payload.status}: ${payload.date}`;
      content = `Hi ${payload.name},\n\nYour report for ${payload.date} has been ${payload.status}.\n\nComments: ${payload.comments || "None"}`;
    } else if (type === "alert") {
      subject = "Compliance Alert: Consecutive Missed Reports";
      content = `Alert: ${payload.emp_name} (${payload.emp_code}) has not submitted reports for 2 consecutive days.`;
    } else {
      console.error("Invalid notification type");
      return new Response(JSON.stringify({ error: "Invalid type" }), { status: 400 });
    }

    console.log("Connecting to Gmail SMTP via nodemailer...");
    
    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: GMAIL_USER,
        pass: GMAIL_PASS,
      },
    });

    console.log(`Sending email to ${to}...`);
    
    const info = await transporter.sendMail({
      from: `"Faith Hours" <${GMAIL_USER}>`,
      to: to,
      subject: subject,
      text: content, // Plain text body
    });

    console.log("Email sent successfully:", info.messageId);

    return new Response(JSON.stringify({ success: true, messageId: info.messageId }), { headers: { "Content-Type": "application/json" } });
  } catch (err) {
    console.error("SMTP error:", err.message);
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
});
