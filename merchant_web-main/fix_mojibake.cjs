const fs = require('fs');
const path = require('path');
const windows1252ToBytes = {
    '\u20AC': 0x80, '\u201A': 0x82, '\u0192': 0x83, '\u201E': 0x84,
    '\u2026': 0x85, '\u2020': 0x86, '\u2021': 0x87, '\u02C6': 0x88,
    '\u2030': 0x89, '\u0160': 0x8A, '\u2039': 0x8B, '\u0152': 0x8C,
    '\u017D': 0x8E, '\u2018': 0x91, '\u2019': 0x92, '\u201C': 0x93,
    '\u201D': 0x94, '\u2022': 0x95, '\u2013': 0x96, '\u2014': 0x97,
    '\u02DC': 0x98, '\u2122': 0x99, '\u0161': 0x9A, '\u203A': 0x9B,
    '\u0153': 0x9C, '\u017E': 0x9E, '\u0178': 0x9F
};
function fixString(str) {
    return str.replace(/([^\x00-\x7F]+)/g, (match) => {
        const bytes = [];
        for (let i = 0; i < match.length; i++) {
            const code = match.charCodeAt(i);
            if (code <= 0xFF) bytes.push(code);
            else if (windows1252ToBytes[match[i]]) bytes.push(windows1252ToBytes[match[i]]);
            else return match; // skip if unmappable
        }
        try {
            const decoded = Buffer.from(bytes).toString('utf8');
            if (!decoded.includes('\uFFFD') && decoded.length > 0) return decoded;
        } catch(e) {}
        return match;
    });
}
function processFile(filePath) {
    let content = fs.readFileSync(filePath, 'utf8');
    let fixedContent = fixString(content);
    if (fixedContent !== content) {
        console.log('Fixed:', filePath);
        fs.writeFileSync(filePath, fixedContent, 'utf8');
    }
}
function walkDir(dir) {
    for (const file of fs.readdirSync(dir)) {
        const fullPath = path.join(dir, file);
        if (fs.statSync(fullPath).isDirectory() && file !== 'node_modules') walkDir(fullPath);
        else if (fullPath.endsWith('.jsx')) processFile(fullPath);
    }
}
walkDir(path.join(__dirname, 'src'));
console.log('Done');
