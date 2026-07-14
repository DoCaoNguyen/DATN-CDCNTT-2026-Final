const fs = require('fs');
const path = require('path');

function fixString(str) {
    // Find sequences of characters that are in the range \x80-\xFF.
    // We also include ASCII chars if they are mixed within the sequence, 
    // but the safest regex is matching words containing at least one \x80-\xFF char.
    
    return str.replace(/([^\x00-\x7F]+)/g, (match) => {
        try {
            // Convert the matched ISO-8859-1 string back to bytes, then to UTF-8
            const decoded = Buffer.from(match, 'latin1').toString('utf8');
            // If the decoded string doesn't contain replacement characters (FFFD)
            // and actually makes sense (doesn't have non-printable characters), keep it.
            if (!decoded.includes('\uFFFD') && decoded.length > 0) {
                return decoded;
            }
        } catch(e) {}
        return match;
    });
}

function processFile(filePath) {
    const content = fs.readFileSync(filePath, 'utf8');
    
    // We don't want to accidentally convert files that are already correct.
    // If the file has valid Vietnamese characters (like 'ă', 'đ', 'ĩ', 'ơ', 'ư'), 
    // it means it's ALREADY in UTF-8 and was NOT fully mojibaked.
    // Wait, the file could have a mix. Let's just run fixString on it.
    
    const fixedContent = fixString(content);
    
    if (fixedContent !== content) {
        console.log('Fixed:', filePath);
        fs.writeFileSync(filePath, fixedContent, 'utf8');
    }
}

function walkDir(dir) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const fullPath = path.join(dir, file);
        const stat = fs.statSync(fullPath);
        if (stat.isDirectory() && file !== 'node_modules' && file !== '.git') {
            walkDir(fullPath);
        } else if (stat.isFile() && (fullPath.endsWith('.jsx') || fullPath.endsWith('.js') || fullPath.endsWith('.ts') || fullPath.endsWith('.tsx'))) {
            processFile(fullPath);
        }
    }
}

walkDir(path.join(__dirname, 'src'));
console.log('Done');
