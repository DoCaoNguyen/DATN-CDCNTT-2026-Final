'use client';

import { useSearchParams, useRouter } from 'next/navigation';

export default function SuccessPage() {
  const searchParams = useSearchParams();
  const router = useRouter();
  
  const name = searchParams.get('name');
  const amount = parseInt(searchParams.get('amount') || '0', 10);

  return (
    <div className="container" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '80vh' }}>
      <div className="checkout-container" style={{ width: '100%', padding: '4rem 2rem' }}>
        <div className="success-icon">
          ✅
        </div>
        <h1 style={{ color: 'var(--secondary)', marginBottom: '1rem' }}>Thanh toán thành công!</h1>
        <p style={{ color: '#747d8c', fontSize: '1.1rem', marginBottom: '2rem' }}>
          Bạn đã thanh toán <strong>{amount.toLocaleString('vi-VN')}đ</strong> cho món <strong>{name}</strong>.
        </p>
        <p style={{ marginBottom: '3rem' }}>
          Chú Mười đang pha chế món nước thơm ngon cho bạn. Vui lòng đợi trong giây lát! 🥤
        </p>
        
        <button onClick={() => router.push('/')} className="btn">
          Quay lại trang chủ
        </button>
      </div>
    </div>
  );
}
