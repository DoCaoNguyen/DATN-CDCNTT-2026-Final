const fs = require('fs');
const txt = fs.readFileSync('db.txt', 'utf8');
const tables = [...txt.matchAll(/CREATE TABLE public\.([\"\w]+)/g)];
console.log('Tables in db.txt:', tables.length);

const copyBlocks = [...txt.matchAll(/COPY public\.(\w+) \((.*?)\) FROM stdin;/g)];
console.log('COPY blocks in db.txt:', copyBlocks.length);
