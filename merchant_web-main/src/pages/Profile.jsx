import { useQuery } from '@tanstack/react-query';
import axiosClient from '../api/axiosClient';

const Profile = () => {
  const { data, isLoading } = useQuery({
    queryKey: ['merchantProfileFull'],
    queryFn: async () => {
      const res = await axiosClient.get('/merchant/profile');
      return res.data;
    }
  });

  if (isLoading) return <p>Đang tải...</p>;

  return (
    <div>
      <h2 style={{ fontSize: '1.5rem', fontWeight: 'bold', marginBottom: '1.5rem' }}>Hồ sơ Merchant</h2>
      <div className="glass-panel" style={{ padding: '2rem', maxWidth: '600px' }}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: '1rem' }}>
          <div style={{ color: 'var(--text-muted)' }}>Mã Merchant:</div>
          <div style={{ fontWeight: '500' }}>{data?.merchant_code}</div>
          
          <div style={{ color: 'var(--text-muted)' }}>Tên doanh nghiệp:</div>
          <div style={{ fontWeight: '500' }}>{data?.merchant_name}</div>
          
          <div style={{ color: 'var(--text-muted)' }}>Trạng thái:</div>
          <div>
            <span className={`badge ${data?.status === 'ACTIVE' ? 'success' : 'danger'}`}>
              {data?.status}
            </span>
          </div>
          
          <div style={{ color: 'var(--text-muted)' }}>Vai trò của bạn:</div>
          <div style={{ fontWeight: '500' }}>{data?.role_code}</div>
        </div>
      </div>
    </div>
  );
};

export default Profile;
