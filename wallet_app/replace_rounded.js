const fs = require('fs');

function getFiles(dir, files = []) {
    const list = fs.readdirSync(dir);
    for (const f of list) {
        const n = dir + '/' + f;
        if (fs.statSync(n).isDirectory()) getFiles(n, files);
        else if (n.endsWith('.dart')) files.push(n);
    }
    return files;
}

const files = getFiles('lib');
let modifiedCount = 0;

files.forEach(f => {
    let c = fs.readFileSync(f, 'utf8');
    let d = c.replace(/Icons\.([a-zA-Z0-9_]+)/g, (match, p1) => {
        if (p1.endsWith('_rounded')) return match;
        if (p1.endsWith('_outlined')) return `Icons.${p1.replace('_outlined', '_rounded')}`;
        return `Icons.${p1}_rounded`;
    });
    
    if (c !== d) {
        fs.writeFileSync(f, d, 'utf8');
        modifiedCount++;
    }
});

console.log(`Replaced icons in ${modifiedCount} files.`);
