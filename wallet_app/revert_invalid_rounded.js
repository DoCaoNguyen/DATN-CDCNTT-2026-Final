const fs = require('fs');
const analyzeOut = fs.readFileSync('analyze_out.txt', 'utf8');

// The getter 'xyz_rounded' isn't defined for the type 'Icons'.
const undefinedSet = new Set();
const regex = /The getter '([a-zA-Z0-9_]+)' isn't defined for the type 'Icons'/g;
let match;
while ((match = regex.exec(analyzeOut)) !== null) {
    if (match[1].endsWith('_rounded')) {
        undefinedSet.add(match[1]);
    }
}

console.log('Undefined rounded icons:', Array.from(undefinedSet));

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
let revertedCount = 0;

files.forEach(f => {
    let c = fs.readFileSync(f, 'utf8');
    let d = c;
    for (const icon of undefinedSet) {
        const originalIcon = icon.replace('_rounded', '');
        // We replace Icons.xyz_rounded back to Icons.xyz
        const replaceRegex = new RegExp(`Icons\\.${icon}`, 'g');
        d = d.replace(replaceRegex, `Icons.${originalIcon}`);
    }
    if (c !== d) {
        fs.writeFileSync(f, d, 'utf8');
        revertedCount++;
    }
});

console.log(`Reverted invalid rounded icons in ${revertedCount} files.`);
