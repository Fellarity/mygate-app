const fs = require('fs');
const path = require('path');
const csv = require('csv-parser');
const supabase = require('./src/config/database');

const csvFilePath = path.join(__dirname, '../csv/Daily Working(Sheet1).csv');

// Helper to convert DD-MM-YYYY to YYYY-MM-DD
function formatDate(dateStr) {
  if (!dateStr) return null;
  const parts = dateStr.split('-');
  if (parts.length === 3) {
    return `${parts[2]}-${parts[1]}-${parts[0]}`;
  }
  return dateStr;
}

async function importData() {
  const records = [];
  console.log('Reading CSV...');

  fs.createReadStream(csvFilePath)
    .pipe(csv())
    .on('data', (row) => {
      // Map CSV columns to Supabase columns
      records.push({
        date: formatDate(row['Date']),
        start_time: row['Start Time'],
        end_time: row['End Time'],
        emp_name: row['Emp Name'],
        contact_no: row['Contact No.'],
        employee_code: row['Emp Code'],
        department: row['Department'],
        subtitle: row['Subtitle'],
        project_number: row['Project no.'],
        working_details: row['Working Details'],
        team_leader: row['Team Leader'],
        status: row['Status'] || 'Pending',
        hours_calculate: row['Hours Calculate']
      });
    })
    .on('end', async () => {
      console.log(`Successfully parsed ${records.length} records.`);
      console.log('Beginning insertion into Supabase (in batches of 1000)...');

      const batchSize = 1000;
      for (let i = 0; i < records.length; i += batchSize) {
        const batch = records.slice(i, i + batchSize);
        const { error } = await supabase.from('reports').insert(batch);
        
        if (error) {
          console.error(`Error inserting batch starting at index ${i}:`, error.message);
          // Optional: break or continue depending on strictness
        } else {
          console.log(`Inserted batch ${i / batchSize + 1} of ${Math.ceil(records.length / batchSize)}`);
        }
      }
      
      console.log('Data import complete!');
    });
}

importData();
