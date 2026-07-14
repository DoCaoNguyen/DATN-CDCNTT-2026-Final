
import clsx from 'clsx';
import { PackageOpen } from 'lucide-react';
import styles from './EmptyState.module.css';

export const EmptyState = ({ 
  icon: Icon = PackageOpen, 
  title = 'Không có dữ liệu', 
  description = 'Chưa có dữ liệu nào để hiển thị tại đây.', 
  action, 
  className 
}) => {
  return (
    <div className={clsx(styles.emptyState, className)}>
      <div className={styles.iconContainer}>
        <Icon className={styles.icon} strokeWidth={1.5} />
      </div>
      <h3 className={styles.title}>{title}</h3>
      <p className={styles.description}>{description}</p>
      {action && <div className={styles.action}>{action}</div>}
    </div>
  );
};
