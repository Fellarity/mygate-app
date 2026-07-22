const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '/home/ashutosh/Desktop/mygate app/server/.env' });

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_KEY);

async function createAuthUser() {
  const { data, error } = await supabase.auth.signUp({
    email: 'testuser@example.com',
    password: 'password123',
  });
  if (error) {
    console.error('Error creating auth user:', error.message);
  } else {
    console.log('Successfully created auth user:', data.user.email);
  }
}

createAuthUser();
