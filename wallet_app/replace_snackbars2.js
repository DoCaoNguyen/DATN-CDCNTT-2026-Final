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

    // We will search for ScaffoldMessenger.of(context).showSnackBar(...
    // and try to extract the text if it's a success message.
    
    // Simpler regex to match ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('...'), backgroundColor: Colors.green))
    // Or even multiline.
    
    const regex = /ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\([\s\S]*?content:\s*Text\((['"])([\s\S]*?)\1\)[\s\S]*?backgroundColor:\s*Colors\.green[\s\S]*?\)\s*,\s*\);/g;
    
    content = content.replace(regex, (match, quote, message) => {
        return `SnackbarUtils.showSuccess(context, ${quote}${message}${quote});`;
    });
    
    const regex2 = /ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*const\s*SnackBar\([\s\S]*?content:\s*Text\((['"])([\s\S]*?)\1\)[\s\S]*?backgroundColor:\s*Colors\.green[\s\S]*?\)\s*,\s*\);/g;
    
    content = content.replace(regex2, (match, quote, message) => {
        return `SnackbarUtils.showSuccess(context, ${quote}${message}${quote});`;
    });

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
