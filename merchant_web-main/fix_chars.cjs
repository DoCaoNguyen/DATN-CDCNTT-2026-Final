const fs = require('fs');
const path = require('path');

const replacements = [
  { from: /\x10H Merchant/g, to: 'ĐH Merchant' },
  { from: /\x10ang/g, to: 'Đang' },
  { from: /\x11ang/g, to: 'đang' },
  { from: /\x11i(<\/| )/g, to: 'đi$1' },
  { from: /\|\| '\x14'/g, to: "|| '-'" },
  { from: /\? '\x14'/g, to: "? '-'" },
  { from: /: '\x14'/g, to: ": '-'" },
  { from: /ci sẽ bị/g, to: 'cũ sẽ bị' },
  { from: /  ang sử dụng/g, to: ' đang sử dụng' },
  { from: /gián  oạn/g, to: 'gián đoạn' }
];

function walk(dir) {
  const list = fs.readdirSync(dir);
  list.forEach(file => {
    const fullPath = path.join(dir, file);
    const stat = fs.statSync(fullPath);
    if (stat && stat.isDirectory()) {
      walk(fullPath);
    } else if (file.endsWith('.jsx') || file.endsWith('.js')) {
      let content = fs.readFileSync(fullPath, 'utf8');
      let original = content;
      
      replacements.forEach(r => {
        content = content.replace(r.from, r.to);
      });
      
      if (content !== original) {
        fs.writeFileSync(fullPath, content, 'utf8');
        console.log('Fixed:', fullPath);
      }
    }
  });
}

walk(path.join(__dirname, 'src'));
