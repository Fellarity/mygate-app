const db = require('./src/config/database');
db.all("SELECT * FROM reports", (err, rows) => {
  if (err) {
    console.error(err);
  } else {
    console.log('--- ALL REPORTS ---');
    console.log(JSON.stringify(rows, null, 2));
    console.log('-------------------');
  }
  db.close();
});
