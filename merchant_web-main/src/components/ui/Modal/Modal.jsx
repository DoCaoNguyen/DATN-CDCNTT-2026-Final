import { X } from 'lucide-react';
import styles from './Modal.module.css';

export const Modal = ({ isOpen, onClose, title, children, maxWidth }) => {
  if (!isOpen) return null;

  return (
    <div className={styles.overlay}>
      <div className={styles.modal} style={maxWidth ? { maxWidth, width: '100%' } : {}}>
        <div className={styles.header}>
          <h3 className={styles.title}>{title}</h3>
          <button className={styles.closeBtn} onClick={onClose}>
            <X size={20} />
          </button>
        </div>
        <div className={styles.content}>
          {children}
        </div>
      </div>
    </div>
  );
};
