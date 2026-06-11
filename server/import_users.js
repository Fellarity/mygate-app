const fs = require('fs');
const path = require('path');
const csv = require('csv-parser');
const supabase = require('./src/config/database');

const csvFilePath = path.join(__dirname, '../csv/Daily Working(Sheet1).csv');

async function importUsers() {
  const users = new Map();
  console.log('Scanning CSV for unique users...');

  return new Promise((resolve) => {
    fs.createReadStream(csvFilePath)
      .pipe(csv())
      .on('data', (row) => {
        const code = row['Emp Code'];
        if (code && !users.has(code)) {
          users.set(code, {
            employee_code: code,
            name: row['Emp Name'],
            contact_no: row['Contact No.'],
            department: row['Department'],
            team_leader: row['Team Leader'],
            password: 'pass123', // Default password
            email: `${code.toLowerCase()}@officegate.com`, // Generated email
            role: 'Employee'
          });
        }
      })
      .on('end', async () => {
        console.log(`Found ${users.size} unique users.`);
        const userList = Array.from(users.values());
        
        // Batch insert users
        const batchSize = 100;
        for (let i = 0; i < userList.length; i += batchSize) {
          const batch = userList.slice(i, i + batchSize);
          const { error } = await supabase.from('users').upsert(batch, { onConflict: 'employee_code' });
          if (error) console.error('Error importing user batch:', error.message);
          else console.log(`Imported users ${i} to ${Math.min(i + batchSize, userList.length)}`);
        }
        resolve();
      });
  });
}

importUsers().then(() => console.log('User import complete!'));
