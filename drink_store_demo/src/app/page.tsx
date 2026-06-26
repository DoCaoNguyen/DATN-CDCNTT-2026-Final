import Link from 'next/link';

const products = [
  {
    id: 1,
    name: 'Cà Phê Sữa Đá',
    description: 'Đậm đà hương vị cà phê Việt Nam truyền thống, pha chút sữa đặc ngọt ngào.',
    price: 35000,
    emoji: '☕',
  },
  {
    id: 2,
    name: 'Trà Đào Cam Sả',
    description: 'Thanh mát giải nhiệt mùa hè với đào miếng giòn sần sật và hương sả thơm lừng.',
    price: 45000,
    emoji: '🍹',
  },
  {
    id: 3,
    name: 'Sinh Tố Dâu Tây',
    description: 'Dâu tây Đà Lạt xay nhuyễn cùng sữa chua, tốt cho da và sức khỏe.',
    price: 55000,
    emoji: '🍓',
  },
  {
    id: 4,
    name: 'Trà Sữa Trân Châu Đường Đen',
    description: 'Trà sữa đậm vị kết hợp cùng trân châu dai giòn thấm đẫm đường đen Hàn Quốc.',
    price: 50000,
    emoji: '🧋',
  }
];

export default function Home() {
  return (
    <main className="container">
      <header className="header">
        <h1>Nước Ép & Trà Sữa Chú Mười</h1>
        <p>Thanh toán siêu tốc 1 chạm qua Ví Điện Tử!</p>
      </header>

      <div className="product-grid">
        {products.map((product) => (
          <div key={product.id} className="product-card">
            <div className="product-image">
              {product.emoji}
            </div>
            <div className="product-info">
              <h2 className="product-title">{product.name}</h2>
              <p className="product-desc">{product.description}</p>
              <div className="product-price">
                {product.price.toLocaleString('vi-VN')}đ
              </div>
              <Link href={`/checkout?productId=${product.id}&name=${encodeURIComponent(product.name)}&price=${product.price}`} className="btn">
                Mua ngay
              </Link>
            </div>
          </div>
        ))}
      </div>
    </main>
  );
}
