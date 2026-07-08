'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useState } from 'react';

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
  const router = useRouter();
  const [showPendingModal, setShowPendingModal] = useState(false);
  const [targetProduct, setTargetProduct] = useState<any>(null);
  const [pendingOrderInfo, setPendingOrderInfo] = useState<any>(null);
  const [isProcessing, setIsProcessing] = useState(false);

  const handleBuy = async (product: any) => {
    const pending = localStorage.getItem('pendingOrder');
    if (pending) {
      try {
        const pendingData = JSON.parse(pending);
        if (pendingData && pendingData.orderId) {
          // Check actual status from backend
          const res = await fetch(`/api/order/${pendingData.orderId}`);
          if (res.ok) {
            const data = await res.json();
            if (data.status === 'PENDING') {
              setPendingOrderInfo(pendingData);
              setTargetProduct(product);
              setShowPendingModal(true);
              return;
            } else {
              // PAID, CANCELED, EXPIRED -> clear and proceed
              localStorage.removeItem('pendingOrder');
            }
          } else {
             // If order not found or error, clear local storage
             localStorage.removeItem('pendingOrder');
          }
        }
      } catch (e) {
        console.error("Error checking pending order", e);
        localStorage.removeItem('pendingOrder');
      }
    }
    
    // Proceed to checkout new order
    router.push(`/checkout?productId=${product.id}&name=${encodeURIComponent(product.name)}&price=${product.price}`);
  };

  const handleContinuePending = () => {
    setShowPendingModal(false);
    if (pendingOrderInfo) {
      router.push(`/checkout?name=${encodeURIComponent(pendingOrderInfo.name)}&price=${pendingOrderInfo.price}&orderId=${pendingOrderInfo.orderId}&qrToken=${encodeURIComponent(pendingOrderInfo.qrToken)}`);
    }
  };

  const handleCancelOldAndBuyNew = async () => {
    setIsProcessing(true);
    try {
      if (pendingOrderInfo && pendingOrderInfo.orderId) {
        await fetch('/api/order/cancel', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ orderId: pendingOrderInfo.orderId })
        });
      }
    } catch (e) {
      console.error(e);
    } finally {
      localStorage.removeItem('pendingOrder');
      setIsProcessing(false);
      setShowPendingModal(false);
      if (targetProduct) {
        router.push(`/checkout?productId=${targetProduct.id}&name=${encodeURIComponent(targetProduct.name)}&price=${targetProduct.price}`);
      }
    }
  };

  return (
    <main className="container" style={{ position: 'relative' }}>
      <header className="header" style={{ position: 'relative' }}>
        <h1>Nước Ép & Trà Sữa Chú Mười</h1>
        <p>Thanh toán siêu tốc 1 chạm qua Ví Điện Tử!</p>
        <Link 
          href="/settings" 
          className="btn" 
          style={{ 
            position: 'absolute', 
            top: '20px', 
            right: '20px', 
            width: 'auto', 
            padding: '0.5rem 1rem', 
            backgroundColor: '#f1f5f9', 
            color: '#334155' 
          }}
        >
          Cài đặt
        </Link>
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
              <button 
                onClick={() => handleBuy(product)} 
                className="btn" 
                style={{ border: 'none', cursor: 'pointer', fontFamily: 'inherit', fontSize: '1rem' }}
              >
                Mua ngay
              </button>
            </div>
          </div>
        ))}
      </div>

      {showPendingModal && (
        <div style={{
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
          background: 'rgba(0,0,0,0.5)', zIndex: 100,
          display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
          padding: '2rem'
        }}>
          <div style={{
            background: 'white', padding: '2rem', borderRadius: '24px', maxWidth: '400px', width: '100%',
            display: 'flex', flexDirection: 'column', alignItems: 'center'
          }}>
            <h3 style={{ marginBottom: '1rem', color: '#333' }}>Đơn hàng chờ thanh toán</h3>
            <p style={{ textAlign: 'center', marginBottom: '2rem', color: '#666' }}>
              Bạn đang có một đơn hàng chưa thanh toán. Bạn muốn tiếp tục thanh toán đơn cũ hay hủy đơn cũ để tạo đơn mới?
            </p>
            <div style={{ display: 'flex', gap: '1rem', width: '100%', flexDirection: 'column' }}>
              <button 
                onClick={handleContinuePending} 
                className="btn" 
                style={{ background: 'var(--primary)', color: 'white' }}
                disabled={isProcessing}
              >
                Tiếp tục thanh toán
              </button>
              <button 
                onClick={handleCancelOldAndBuyNew} 
                className="btn btn-secondary" 
                style={{ background: '#f1f5f9', color: '#e74c3c' }}
                disabled={isProcessing}
              >
                {isProcessing ? 'Đang xử lý...' : 'Hủy đơn cũ và tạo đơn mới'}
              </button>
              <button 
                onClick={() => setShowPendingModal(false)} 
                className="btn btn-secondary" 
                style={{ background: 'transparent', color: '#666', marginTop: '-0.5rem' }}
                disabled={isProcessing}
              >
                Đóng
              </button>
            </div>
          </div>
        </div>
      )}
    </main>
  );
}
