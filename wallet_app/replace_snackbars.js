const fs = require('fs');
const path = require('path');

function walk(dir, fileList = []) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const filePath = path.join(dir, file);
        const stat = fs.statSync(filePath);
        if (stat.isDirectory()) {
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

    // Pattern 1: ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message'), backgroundColor: Colors.green));
    // Pattern 2: Multi-line
    
    // We will use a regex to match SnackBar blocks with Colors.green
    // This is a naive regex but works for simple cases.
    const regex = /ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*(?:const\s*)?SnackBar\(\s*content:\s*(?:const\s*)?Text\((['"])(.*?)\1\)[^)]*backgroundColor:\s*Colors\.green[^)]*\)\s*,\s*\);/g;
    
    content = content.replace(regex, (match, quote, message) => {
        return `SnackbarUtils.showSuccess(context, ${quote}${message}${quote});`;
    });
    
    // And what about error messages with Colors.red? The user only asked for success messages.
    // "sửa lại tất cả thông báo liên quan đến thành công đẹp lên xíu"
    
    if (content !== original) {
        // Need to add import
        if (!content.includes('snackbar_utils.dart')) {
            // Find the depth of lib/
            const relPath = path.relative(path.dirname(file), path.join(__dirname, 'lib/core/utils/snackbar_utils.dart')).replace(/\\/g, '/');
            
            // Insert import at the top after other imports
            const importLine = `import '${relPath}';\n`;
            
            // Find last import
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
