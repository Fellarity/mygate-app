const fs = require('fs');
const path = require('path');
const xlsx = require('xlsx');
const supabase = require('./src/config/database');

const jsonFilePath = path.join(__dirname, '../csv/hierarchy_structure.json');
const excelFilePath = path.join(__dirname, '../csv/EMPLOYEE EMAIL MASTER_18-06-2026_UPDATED.xlsx');

async function importHierarchy() {
  console.log('Loading Excel data...');
  const workbook = xlsx.readFile(excelFilePath);
  const sheetName = workbook.SheetNames[0];
  const excelData = xlsx.utils.sheet_to_json(workbook.Sheets[sheetName]);

  const excelMap = new Map();
  for (const row of excelData) {
    const email = (row['Emplyoee Email id.'] || '').toString().trim().toLowerCase();
    if (email) {
      excelMap.set(email, {
        employee_code: (row['EmpNo'] || '').toString().trim(),
        name: (row['Name'] || '').toString().trim(),
        department: (row['CostCentre'] || '').toString().trim() || (row['Sub Department'] || '').toString().trim(),
      });
    }
  }
  
  console.log(`Loaded ${excelMap.size} valid email entries from Excel.`);

  console.log('Loading JSON hierarchy...');
  const hierarchy = JSON.parse(fs.readFileSync(jsonFilePath, 'utf8'));

  const usersToInsert = [];
  let generatedCodeCounter = 1;

  function traverse(node, managerCode) {
    const email = (node.email || '').toString().trim().toLowerCase();
    if (!email) return;

    let empCode = '';
    let department = '';
    let contact_no = '';

    const excelInfo = excelMap.get(email);
    if (excelInfo && excelInfo.employee_code) {
      empCode = excelInfo.employee_code;
      department = excelInfo.department;
    } else {
      empCode = `FA-GEN-${String(generatedCodeCounter++).padStart(3, '0')}`;
    }

    const hasReports = Array.isArray(node.reports) && node.reports.length > 0;
    const role = hasReports ? 'Team Leader' : 'Employee';

    usersToInsert.push({
      employee_code: empCode,
      name: node.name || 'Unknown',
      email: email,
      password: 'pass123',
      role: role,
      designation: node.designation || '',
      department: department,
      team_leader: managerCode || null,
      is_blocked: false,
    });

    if (hasReports) {
      for (const report of node.reports) {
        traverse(report, empCode);
      }
    }
  }

  for (const rootNode of hierarchy) {
    traverse(rootNode, null); // Top level users have no manager
  }

  console.log(`Found ${usersToInsert.length} total users in hierarchy.`);

  // Insert in batches
  const batchSize = 100;
  for (let i = 0; i < usersToInsert.length; i += batchSize) {
    const batch = usersToInsert.slice(i, i + batchSize);
    const { error } = await supabase.from('users').upsert(batch, { onConflict: 'employee_code' });
    if (error) {
      console.error('Error inserting batch:', error);
    } else {
      console.log(`Imported users ${i} to ${Math.min(i + batchSize, usersToInsert.length)}`);
    }
  }
}

importHierarchy().then(() => {
  console.log('Hierarchy import complete!');
  process.exit(0);
}).catch(e => {
  console.error('Fatal error:', e);
  process.exit(1);
});
