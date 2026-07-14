
import { Outlet } from 'react-router-dom';
import styles from './AuthLayout.module.css';

const AuthLayout = () => {
  return (
    <div className={styles.container}>
      <div className={styles.card}>
        <div className={styles.header}>
          <div className={styles.logo}>
            {/* You can replace this with an actual image logo later */}
            <span className={styles.logoIcon}>M</span>
            <span className={styles.logoText}>Merchant Portal</span>
          </div>
        </div>
        <Outlet />
      </div>
    </div>
  );
};

export default AuthLayout;
