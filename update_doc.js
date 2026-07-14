const fs = require('fs'); 
let content = fs.readFileSync('d:/DATN/DATN-CDCNTT-2026-Final/MoTaManHinhAdmin.md', 'utf8');
const lines = content.split('\n');
let newLines = [];
let skip = false;
let decrement = 0;
for(let i=0; i<lines.length; i++) {
  let line = lines[i];
  if(line.startsWith('## 3.2')) {
    newLines.push(line);
    newLines.push('### 3.2.1. Mục đích chức năng');
    newLines.push('Giúp Admin quản lý tập trung toàn bộ người dùng ví trong hệ thống. Chức năng hỗ trợ theo dõi thông tin tài khoản, trạng thái xác minh, tình trạng sử dụng ví và xem chi tiết hồ sơ định danh (KYC) của người dùng.');
    newLines.push('### 3.2.2 Giao diện chức năng');
    newLines.push('Giao diện hiển thị danh sách người dùng kèm các thông tin cơ bản. Khi truy cập chi tiết, ngoài các thẻ Thông tin chung và Lịch sử, hệ thống cung cấp thêm tab "Hồ sơ KYC" để đối chiếu ảnh giấy tờ tùy thân (CCCD), ảnh selfie, kết quả quét thông tin (OCR) và tỷ lệ trùng khớp khuôn mặt (Face Match) từ AI.');
    newLines.push('*[Chèn ảnh Giao diện danh sách và chi tiết người dùng ví]*');
    newLines.push('Hình: Giao diện quản lý và chi tiết người dùng ví');
    newLines.push('### 3.2.3 Kết quả thực hiện');
    newLines.push('Admin có thể nhanh chóng tra cứu, kiểm tra trạng thái tài khoản và rà soát hồ sơ định danh pháp lý của người dùng trong cùng một màn hình tập trung.');
    skip = true;
    decrement = 2; // we skip 3.3 and 3.4
  } else if(line.startsWith('## 3.5')) {
    skip = false;
  }
  
  if(!skip && line.startsWith('## 3.')) {
    const match = line.match(/^## 3\.(\d+) (.*)/);
    if(match) {
      let num = parseInt(match[1]) - decrement;
      newLines.push('## 3.' + num + ' ' + match[2]);
    } else {
      newLines.push(line);
    }
  } else if(!skip && line.startsWith('### 3.')) {
    const match = line.match(/^### 3\.(\d+)\.(.*)/);
    if(match) {
      let num = parseInt(match[1]) - decrement;
      newLines.push('### 3.' + num + '.' + match[2]);
    } else {
      newLines.push(line);
    }
  } else if(!skip) {
    if (!line.startsWith('## 3.2') && !line.startsWith('### 3.2')) {
      newLines.push(line);
    }
  }
}
fs.writeFileSync('d:/DATN/DATN-CDCNTT-2026-Final/MoTaManHinhAdmin.md', newLines.join('\n'));
console.log('Done!');
