import clsx from 'clsx';
import styles from './Tabs.module.css';

export const Tabs = ({ tabs, activeTab, onChange, className }) => {
  return (
    <div className={clsx(styles.tabsContainer, className)}>
      {tabs.map((tab) => (
        <button
          key={tab.value}
          className={clsx(styles.tab, { [styles.active]: activeTab === tab.value })}
          onClick={() => onChange(tab.value)}
        >
          {tab.label}
        </button>
      ))}
    </div>
  );
};
