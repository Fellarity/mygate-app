import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { SmtpClient } from "https://deno.land/x/smtp@v0.7.0/mod.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { to, subject, body } = await req.json()

    // Retrieve environment variables or use hardcoded fallbacks
    const gmailUser = Deno.env.get('GMAIL_USER') || 'lucawookamooka@gmail.com'
    const gmailPassword = Deno.env.get('GMAIL_PASSWORD') || 'fcqbspbpebguzfko'

    if (!gmailUser || !gmailPassword) {
      throw new Error("SMTP credentials not configured. Please set GMAIL_USER and GMAIL_PASSWORD secrets.")
    }

    if (!to || !subject || !body) {
      throw new Error("Missing required fields: to, subject, body")
    }

    // Initialize SMTP client
    const client = new SmtpClient()

    await client.connectTLS({
      hostname: "smtp.gmail.com",
      port: 465,
      username: gmailUser,
      password: gmailPassword,
    })

    await client.send({
      from: gmailUser,
      to: to,
      subject: subject,
      content: body,
      html: body,
    })

    await client.close()

    return new Response(
      JSON.stringify({ message: "Email sent successfully" }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})
