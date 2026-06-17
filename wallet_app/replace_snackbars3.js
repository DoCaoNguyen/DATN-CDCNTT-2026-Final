const fs = require('fs');
const path = require('path');

function walk(dir, fileList = []) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const filePath = path.join(dir, file);
        if (fs.statSync(filePath).isDirectory()) {
            walk(filePath, fileList);
        } else if (file.endsWith('.dart')) {
            fileList.push(filePath);
        }
    }
    return fileList;
}

const dartFiles = walk(path.join(__dirname, 'lib'));
let modifiedCount = 0;

for (const file of dartFiles) {
    let content = fs.readFileSync(file, 'utf8');
    let original = content;

    let index = 0;
    while ((index = content.indexOf('ScaffoldMessenger.of(context).showSnackBar(', index)) !== -1) {
        let openParen = index + 'ScaffoldMessenger.of(context).showSnackBar'.length;
        let pCount = 0;
        let endIndex = -1;
        for (let i = openParen; i < content.length; i++) {
            if (content[i] === '(') pCount++;
            else if (content[i] === ')') {
                pCount--;
                if (pCount === 0) {
                    endIndex = i;
                    break;
                }
            }
        }
        
        if (endIndex !== -1) {
            let block = content.substring(index, endIndex + 1);
            if (block.includes('Colors.green')) {
                // Find the Text('...') or Text("...")
                let textMatch = block.match(/Text\(\s*(['"])([\s\S]*?)\1/);
                if (textMatch) {
                    let quote = textMatch[1];
                    let msg = textMatch[2];
                    
                    let replacement = `SnackbarUtils.showSuccess(context, ${quote}${msg}${quote})`;
                    // Also replace the trailing semicolon if needed, but the original might be ScaffoldMessenger...;
                    // Let's just replace the block
                    content = content.substring(0, index) + replacement + content.substring(endIndex + 1);
                    // Reset index
                }
            }
        }
        index++;
    }

    if (content !== original) {
        if (!content.includes('snackbar_utils.dart')) {
            const relPath = path.relative(path.dirname(file), path.join(__dirname, 'lib/core/utils/snackbar_utils.dart')).replace(/\\/g, '/');
            const importLine = `import '${relPath}';\n`;
            const lastImportIndex = content.lastIndexOf('import \'');
            if (lastImportIndex !== -1) {
                const endOfLine = content.indexOf('\n', lastImportIndex);
                content = content.slice(0, endOfLine + 1) + importLine + content.slice(endOfLine + 1);
            } else {
                content = importLine + content;
            }
        }
        
        fs.writeFileSync(file, content, 'utf8');
        modifiedCount++;
        console.log(`Modified: ${file}`);
    }
}

console.log(`Modified ${modifiedCount} files.`);
