const db = require('./src/config/database');
db.all("SELECT * FROM reports WHERE employeeCode = 'EMP001'", (err, rows) => {
  if (err) {
    console.error(err);
  } else {
    console.log(JSON.stringify(rows, null, 2));
  }
  db.close();
});
