const ExcelJS = require('exceljs');
const workbook = new ExcelJS.Workbook();
workbook.xlsx.readFile('C:\\Users\\ADMIN\\Downloads\\0855313437_22899213332094024.xlsx').then(() => {
    const sheet = workbook.getWorksheet(1);
    sheet.eachRow({ includeEmpty: true }, (row, rowNumber) => {
        console.log('Row ' + rowNumber + ' = ' + JSON.stringify(row.values));
    });
}).catch(console.error);
