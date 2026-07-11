'use client';
import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';

export default function SettingsPage() {
  const [apiKey, setApiKey] = useState('');
  const [secretKey, setSecretKey] = useState('');
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  useEffect(() => {
    fetch('/api/settings')
      .then(res => res.json())
      .then(data => {
        setApiKey(data.apiKey || '');
        setSecretKey(data.secretKey || '');
      });
  }, []);

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    
    try {
      const res = await fetch('/api/settings', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ apiKey, secretKey }),
      });
      
      if (res.ok) {
        alert('Đã lưu cấu hình thành công! Server sẽ tự động reload.');
        router.push('/');
      } else {
        alert('Có lỗi xảy ra khi lưu.');
      }
    } catch (err) {
      alert('Lỗi kết nối.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="container">
      <header className="header">
        <h1>Cài Đặt Cửa Hàng & Tích Hợp</h1>
        <p>Cập nhật API Key & Secret Key để kết nối Ví Điện Tử</p>
      </header>

      <div style={{ background: '#fff', padding: '2rem', borderRadius: '12px', boxShadow: '0 4px 6px rgba(0,0,0,0.05)', marginBottom: '2rem' }}>
        <form onSubmit={handleSave} style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
          <div>
            <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 'bold' }}>MERCHANT_API_KEY</label>
            <input 
              type="text" 
              value={apiKey} 
              onChange={e => setApiKey(e.target.value)} 
              style={{ width: '100%', padding: '0.75rem', borderRadius: '8px', border: '1px solid #ccc', fontSize: '16px' }}
              placeholder="VD: pk_test_..."
              required 
            />
          </div>
          <div>
            <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 'bold' }}>MERCHANT_SECRET_KEY</label>
            <input 
              type="text" 
              value={secretKey} 
              onChange={e => setSecretKey(e.target.value)} 
              style={{ width: '100%', padding: '0.75rem', borderRadius: '8px', border: '1px solid #ccc', fontSize: '16px' }}
              placeholder="VD: sk_test_..."
              required 
            />
          </div>
          
          <div style={{ display: 'flex', gap: '1rem', marginTop: '1rem' }}>
            <button type="submit" className="btn" style={{ flex: 1 }} disabled={loading}>
              {loading ? 'Đang lưu...' : 'Lưu Thay Đổi'}
            </button>
            <Link href="/" className="btn" style={{ flex: 1, backgroundColor: '#f1f5f9', color: '#334155', textAlign: 'center' }}>
              Quay lại
            </Link>
          </div>
        </form>
      </div>

      <div style={{ background: '#f8fafc', padding: '1.5rem', borderRadius: '12px', border: '1px solid #e2e8f0' }}>
        <h2 style={{ color: '#0f172a', marginBottom: '1rem', fontSize: '1.2rem' }}>📌 Lưu ý Tích hợp Quan trọng</h2>
        <p style={{ color: '#334155', marginBottom: '0.5rem' }}>
          Hệ thống ví sẽ bắn <strong>Webhook/Callback</strong> về server của bạn (VD: <code>/api/webhook</code>) khi khách hàng thanh toán thành công.
        </p>
        <p style={{ color: '#334155', marginBottom: '1rem' }}>
          Tuy nhiên, để đề phòng trường hợp rớt mạng, nghẽn mạng hoặc lỗi Webhook, bạn <strong>bắt buộc phải có cơ chế chủ động (Pull)</strong> kiểm tra trạng thái đơn hàng.
        </p>
        <div style={{ background: '#1e293b', padding: '1rem', borderRadius: '8px', color: '#f8fafc', fontFamily: 'monospace' }}>
          GET /api/v1/payment/status?merchant_order_id=YOUR_ORDER_ID<br/>
          Headers:<br/>
          x-api-key: {apiKey || 'YOUR_API_KEY'}
        </div>
        <p style={{ color: '#475569', fontSize: '0.9rem', marginTop: '1rem' }}>
          * Bạn nên dùng API này khi: (1) Setup Cronjob quét đơn quá hạn 15 phút, (2) Khách hàng bấm nút "Tôi đã thanh toán" trên web nhưng đơn vẫn đang hiển thị chờ.
        </p>
      </div>
    </main>
  );
}
