
import clsx from 'clsx';
import styles from './Badge.module.css';

export const Badge = ({ children, variant = 'default', className, ...props }) => {
  return (
    <span className={clsx(styles.badge, styles[variant], className)} {...props}>
      {children}
    </span>
  );
};
