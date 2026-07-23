import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'
import { SmtpClient } from "https://deno.land/x/smtp@v0.7.0/mod.ts"

serve(async (req) => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    
    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error("Missing Supabase environment variables")
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Check if email notifications are enabled
    const { data: settings } = await supabase.from('app_settings').select('setting_value').eq('setting_key', 'notifications').maybeSingle()
    if (!settings || !settings.setting_value || settings.setting_value.email_enabled !== true) {
      return new Response(JSON.stringify({ message: "Email notifications disabled globally" }), { status: 200 })
    }

    // Get all users
    const { data: users, error: userError } = await supabase.from('users').select('*')
    if (userError) throw userError

    // Initialize SMTP
    const gmailUser = Deno.env.get('GMAIL_USER') || 'lucawookamooka@gmail.com'
    const gmailPassword = Deno.env.get('GMAIL_PASSWORD') || 'fcqbspbpebguzfko'
    const client = new SmtpClient()
    await client.connectTLS({
      hostname: "smtp.gmail.com",
      port: 465,
      username: gmailUser,
      password: gmailPassword,
    })

    const today = new Date();
    const todayStr = today.toISOString().split('T')[0];
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    const yesterdayStr = yesterday.toISOString().split('T')[0];

    for (const user of users) {
      if (user.role === 'App Admin') continue; // Skip App Admins

      // Get latest report
      const { data: latestReport } = await supabase
        .from('reports')
        .select('date')
        .eq('employee_code', user.employee_code)
        .order('date', { ascending: false })
        .limit(1)
        .maybeSingle()

      let missingToday = false;
      let missingTwoDays = false;

      if (!latestReport) {
        missingToday = true;
        missingTwoDays = true;
      } else {
        missingToday = latestReport.date < todayStr;
        missingTwoDays = latestReport.date < yesterdayStr;
      }

      // Send to Employee if missing today
      if (missingToday && user.email) {
        try {
          await client.send({
            from: gmailUser,
            to: user.email,
            subject: "Reminder: Timesheet Submission Required",
            content: `Hi ${user.full_name}, you have not submitted a timesheet for today (${todayStr}). Please log into the app and submit it as soon as possible.`,
            html: `<p>Hi ${user.full_name},</p><p>You have not submitted a timesheet for today (<strong>${todayStr}</strong>). Please log into the app and submit it as soon as possible.</p>`
          })
          console.log(`Sent reminder to employee: ${user.email}`)
        } catch (e) {
          console.error(`Failed to send to ${user.email}: ${e}`)
        }
      }

      // Send to TL if missing 2 days
      if (missingTwoDays && user.team_leader_code) {
        const { data: tlUser } = await supabase.from('users').select('email, full_name').eq('employee_code', user.team_leader_code).maybeSingle()
        if (tlUser && tlUser.email) {
          try {
            await client.send({
              from: gmailUser,
              to: tlUser.email,
              subject: `Escalation: Timesheet Missing for ${user.full_name}`,
              content: `Hi ${tlUser.full_name}, your team member ${user.full_name} (${user.employee_code}) has not submitted a timesheet for 2 or more days. Last submission: ${latestReport ? latestReport.date : 'Never'}.`,
              html: `<p>Hi ${tlUser.full_name},</p><p>Your team member <strong>${user.full_name}</strong> (${user.employee_code}) has not submitted a timesheet for 2 or more days.</p><p>Last submission: ${latestReport ? latestReport.date : 'Never'}.</p>`
            })
            console.log(`Sent escalation to TL: ${tlUser.email}`)
          } catch (e) {
            console.error(`Failed to send to TL ${tlUser.email}: ${e}`)
          }
        }
      }
    }

    await client.close()

    return new Response(JSON.stringify({ success: true, message: "Reminders processed" }), { 
      status: 200, 
      headers: { "Content-Type": "application/json" } 
    })

  } catch (error) {
    console.error(error)
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})
