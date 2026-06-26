'use client';

import { useEffect, useState } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import { QRCodeSVG } from 'qrcode.react';

export default function CheckoutPage() {
  const searchParams = useSearchParams();
  const router = useRouter();
  
  const name = searchParams.get('name') || 'Món nước';
  const price = parseInt(searchParams.get('price') || '0', 10);
  
  const [orderId, setOrderId] = useState<number | null>(null);
  const [qrToken, setQrToken] = useState<string | null>(null);
  const [status, setStatus] = useState<string>('PENDING');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  // Bước 1: Gọi API tạo đơn hàng và lấy mã QR
  useEffect(() => {
    if (price <= 0) {
      setError('Số tiền không hợp lệ');
      setLoading(false);
      return;
    }

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
      } catch (err: any) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    createOrder();
  }, [name, price]);

  // Bước 2: Polling liên tục kiểm tra trạng thái thanh toán
  useEffect(() => {
    if (!orderId || status === 'PAID') return;

    const interval = setInterval(async () => {
      try {
        const res = await fetch(`/api/order/${orderId}`);
        const data = await res.json();
        if (data.status === 'PAID') {
          setStatus('PAID');
          clearInterval(interval);
          // Đợi 1 chút rồi chuyển hướng sang trang thành công
          setTimeout(() => {
            router.push(`/success?name=${encodeURIComponent(name)}&amount=${price}`);
          }, 1500);
        }
      } catch (error) {
        console.error("Lỗi khi kiểm tra trạng thái đơn hàng", error);
      }
    }, 2000);

    return () => clearInterval(interval);
  }, [orderId, status, router, name, price]);

  return (
    <div className="container">
      <div className="checkout-container">
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
            <div className="qr-wrapper">
              <QRCodeSVG 
                value={qrToken} // Hiển thị qr_token hoặc có thể chuyển thành scheme uri tùy yêu cầu của App Ví
                size={250}
                bgColor={"#ffffff"}
                fgColor={"#000000"}
                level={"H"}
              />
            </div>
            
            <div>
              <p>Dùng ứng dụng <strong>Ví Điện Tử</strong> để quét mã này</p>
              <div className={`status-badge ${status === 'PENDING' ? 'status-pending' : 'status-paid'}`}>
                {status === 'PENDING' ? '⏳ Đang chờ thanh toán...' : '✅ Đã thanh toán thành công!'}
              </div>
            </div>
          </div>
        )}
        
        <div style={{ marginTop: '2rem' }}>
          <button onClick={() => router.push('/')} className="btn btn-secondary" style={{ width: 'auto', padding: '0.8rem 2rem' }}>
            Hủy và quay lại
          </button>
        </div>
      </div>
    </div>
  );
}
