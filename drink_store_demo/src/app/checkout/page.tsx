'use client';

import { useEffect, useState, Suspense, useRef } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import { QRCodeSVG } from 'qrcode.react';

function CheckoutContent() {
  const searchParams = useSearchParams();
  const router = useRouter();
  
  const name = searchParams.get('name') || 'Món nước';
  const price = parseInt(searchParams.get('price') || '0', 10);
  
  const initialOrderId = searchParams.get('orderId');
  const initialQrToken = searchParams.get('qrToken');
  
  const [orderId, setOrderId] = useState<number | null>(initialOrderId ? parseInt(initialOrderId) : null);
  const [qrToken, setQrToken] = useState<string | null>(initialQrToken || null);
  const [status, setStatus] = useState<string>('PENDING');
  const [loading, setLoading] = useState(!initialOrderId);
  const [error, setError] = useState('');
  
  const [isCancelModalOpen, setIsCancelModalOpen] = useState(false);
  const [isCanceling, setIsCanceling] = useState(false);
  
  const orderCreatedRef = useRef(false);

  // Bước 1: Gọi API tạo đơn hàng và lấy mã QR
  useEffect(() => {
    if (price <= 0) {
      setError('Số tiền không hợp lệ');
      setLoading(false);
      return;
    }

    if (orderCreatedRef.current) return;
    
    if (initialOrderId && initialQrToken) {
      orderCreatedRef.current = true;
      return;
    }
    
    orderCreatedRef.current = true;

    const createOrder = async () => {
      try {
        const res = await fetch('/api/checkout', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ productName: name, amount: price })
        });
        
        const data = await res.json();
        
        if (!res.ok) {
          throw new Error(data.error || 'Failed to create order');
        }
        
        setOrderId(data.orderId);
        setQrToken(data.qrToken);
        
        localStorage.setItem('pendingOrder', JSON.stringify({
          orderId: data.orderId,
          name: name,
          price: price,
          qrToken: data.qrToken,
          timestamp: Date.now(),
          merchantOrderId: data.merchantOrderId
        }));
      } catch (err: any) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    createOrder();
  }, [name, price, initialOrderId, initialQrToken]);

  // Bước 2: Polling liên tục kiểm tra trạng thái thanh toán
  useEffect(() => {
    if (!orderId || status === 'PAID' || status === 'SUCCESS' || status === 'EXPIRED' || status === 'CANCELED') return;

    // Hết hạn sau 15 phút (900000 ms)
    const timeout = setTimeout(() => {
      setStatus('EXPIRED');
      localStorage.removeItem('pendingOrder');
    }, 15 * 60 * 1000);

    const interval = setInterval(async () => {
      try {
        const res = await fetch(`/api/order/${orderId}`, { cache: 'no-store' });
        const data = await res.json();
        
        if (data.status === 'PAID' || data.status === 'SUCCESS') {
          setStatus('PAID');
          clearInterval(interval);
          clearTimeout(timeout);
          localStorage.removeItem('pendingOrder');
          setTimeout(() => {
            router.push(`/success?name=${encodeURIComponent(name)}&amount=${price}`);
          }, 1500);
        } else if (data.status === 'EXPIRED') {
          setStatus('EXPIRED');
          clearInterval(interval);
          clearTimeout(timeout);
          localStorage.removeItem('pendingOrder');
        } else if (data.status === 'CANCELED') {
          setStatus('CANCELED');
          clearInterval(interval);
          clearTimeout(timeout);
          localStorage.removeItem('pendingOrder');
        }
      } catch (error) {
        console.error("Lỗi khi kiểm tra trạng thái đơn hàng", error);
      }
    }, 2000);

    return () => {
      clearInterval(interval);
      clearTimeout(timeout);
    };
  }, [orderId, status, router, name, price]);

  const handleCancelClick = () => {
    setIsCancelModalOpen(true);
  };

  const handleConfirmCancel = async () => {
    setIsCanceling(true);
    try {
      await fetch('/api/order/cancel', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ orderId })
      });
      localStorage.removeItem('pendingOrder');
      router.push('/');
    } catch (e) {
      console.error(e);
      alert('Lỗi khi hủy đơn');
    } finally {
      setIsCanceling(false);
    }
  };

  const handleCheckStatus = async () => {
    if (!orderId) return;
    try {
      const res = await fetch(`/api/order/${orderId}/sync`, { method: 'POST' });
      const data = await res.json();
      if (data.status === 'PAID') {
        setStatus('PAID');
        localStorage.removeItem('pendingOrder');
        router.push(`/success?name=${encodeURIComponent(name)}&amount=${price}`);
      } else if (data.status === 'EXPIRED') {
        setStatus('EXPIRED');
        localStorage.removeItem('pendingOrder');
      } else if (data.status === 'CANCELED') {
        setStatus('CANCELED');
        localStorage.removeItem('pendingOrder');
      } else {
        alert('Đơn hàng vẫn đang chờ thanh toán!');
      }
    } catch (e) {
      alert('Lỗi kiểm tra trạng thái.');
    }
  };

  return (
    <div className="container">
      <div className="checkout-container" style={{ position: 'relative' }}>
        <h2>Thanh toán đơn hàng</h2>
        <p style={{ margin: '1rem 0', color: '#747d8c' }}>{name}</p>
        <h1 style={{ color: 'var(--primary)', fontSize: '2.5rem' }}>
          {price.toLocaleString('vi-VN')}đ
        </h1>

        {loading && (
          <div style={{ margin: '3rem 0' }}>
            <div className="spinner"></div>
            <p style={{ marginTop: '1rem' }}>Đang khởi tạo mã QR...</p>
          </div>
        )}

        {error && (
          <div style={{ color: 'red', margin: '2rem 0', padding: '1rem', background: '#ffeaa7', borderRadius: '12px' }}>
            {error}
          </div>
        )}

        {qrToken && (
          <div>
            <div className="qr-wrapper" style={{ opacity: (status === 'EXPIRED' || status === 'CANCELED') ? 0.3 : 1, transition: '0.3s' }}>
              <QRCodeSVG 
                value={qrToken}
                size={250}
                bgColor={"#ffffff"}
                fgColor={"#000000"}
                level={"H"}
              />
            </div>
            
            <div>
              <p>Dùng ứng dụng <strong>Ví Điện Tử</strong> để quét mã này</p>
              <div className={`status-badge ${status === 'PENDING' ? 'status-pending' : (status === 'EXPIRED' || status === 'CANCELED' ? 'status-expired' : 'status-paid')}`} style={(status === 'EXPIRED' || status === 'CANCELED') ? { background: '#ff7675', color: '#fff' } : {}}>
                {status === 'PENDING' ? '⏳ Đang chờ thanh toán...' : (status === 'EXPIRED' ? '❌ Mã QR đã hết hạn' : (status === 'CANCELED' ? '❌ Đơn hàng đã bị hủy' : '✅ Đã thanh toán thành công!'))}
              </div>
            </div>
            
            {status === 'PENDING' && (
              <div style={{ marginTop: '1rem' }}>
                <button onClick={handleCheckStatus} className="btn" style={{ width: 'auto', padding: '0.5rem 1.5rem', fontSize: '0.9rem', backgroundColor: '#3498db' }}>
                  Tôi đã thanh toán (Lấy trạng thái)
                </button>
              </div>
            )}
          </div>
        )}
        
        <div style={{ marginTop: '2rem' }}>
          <button onClick={handleCancelClick} className="btn btn-secondary" style={{ width: 'auto', padding: '0.8rem 2rem' }}>
            Hủy và quay lại
          </button>
        </div>
        
        {/* Modal Hủy Đơn */}
        {isCancelModalOpen && (
          <div style={{
            position: 'absolute', top: 0, left: 0, right: 0, bottom: 0,
            background: 'rgba(255,255,255,0.95)', zIndex: 10,
            display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
            padding: '2rem', borderRadius: '24px'
          }}>
            <h3 style={{ marginBottom: '1rem', color: '#333' }}>Xác nhận hủy</h3>
            <p style={{ textAlign: 'center', marginBottom: '2rem', color: '#666' }}>
              Bạn có chắc muốn hủy thanh toán đơn này không?<br/>Mã QR hiện tại sẽ không còn hiệu lực.
            </p>
            <div style={{ display: 'flex', gap: '1rem', width: '100%', flexDirection: 'column' }}>
              <button 
                onClick={() => setIsCancelModalOpen(false)} 
                className="btn" 
                style={{ background: 'var(--primary)', color: 'white' }}
                disabled={isCanceling}
              >
                Tiếp tục thanh toán
              </button>
              <button 
                onClick={handleConfirmCancel} 
                className="btn btn-secondary" 
                style={{ background: '#f1f5f9', color: '#e74c3c' }}
                disabled={isCanceling}
              >
                {isCanceling ? 'Đang hủy...' : 'Hủy đơn'}
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

export default function CheckoutPage() {
  return (
    <Suspense fallback={<div className="container"><div className="checkout-container"><div style={{ margin: '3rem 0' }}><div className="spinner"></div><p style={{ marginTop: '1rem' }}>Đang tải...</p></div></div></div>}>
      <CheckoutContent />
    </Suspense>
  );
}
