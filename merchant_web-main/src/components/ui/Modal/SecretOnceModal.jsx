import { Modal } from './Modal';
import { Button } from '../Button/Button';
import { CopyButton } from '../CopyButton/CopyButton';

export const SecretOnceModal = ({ isOpen, onClose, apiKey, apiSecret, title = 'Tạo API Key thành công' }) => {
  return (
    <Modal isOpen={isOpen} onClose={onClose} title={title}>
      <div style={{ backgroundColor: 'var(--status-warning-bg)', border: '1px solid rgba(249, 115, 22, 0.2)', padding: '1rem', borderRadius: 'var(--radius-md)', marginBottom: '1.5rem' }}>
        <p style={{ color: 'var(--status-warning)', fontSize: '0.875rem', fontWeight: 500, margin: 0 }}>
          ⚠️ API Secret chỉ hiển thị một lần. Hãy copy và lưu lại ngay. Sau khi đóng modal, hệ thống sẽ không thể hiển thị lại secret này.
        </p>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem', marginBottom: '2rem' }}>
        <div>
          <label style={{ display: 'block', fontSize: '0.875rem', fontWeight: 500, color: 'var(--text-main)', marginBottom: '0.5rem' }}>API Key</label>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', backgroundColor: 'var(--bg-main)', padding: '0.75rem 1rem', borderRadius: 'var(--radius-md)', border: '1px solid var(--border-color)' }}>
            <code style={{ fontSize: '0.875rem', color: 'var(--text-main)', wordBreak: 'break-all' }}>{apiKey}</code>
            <CopyButton text={apiKey} />
          </div>
        </div>

        <div>
          <label style={{ display: 'block', fontSize: '0.875rem', fontWeight: 500, color: 'var(--text-main)', marginBottom: '0.5rem' }}>API Secret</label>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', backgroundColor: 'var(--bg-main)', padding: '0.75rem 1rem', borderRadius: 'var(--radius-md)', border: '1px solid var(--border-color)' }}>
            <code style={{ fontSize: '0.875rem', color: 'var(--text-main)', wordBreak: 'break-all' }}>{apiSecret}</code>
            <CopyButton text={apiSecret} />
          </div>
        </div>
      </div>

      <Button variant="primary" style={{ width: '100%' }} onClick={onClose}>
        Tôi đã lưu secret
      </Button>
    </Modal>
  );
};
