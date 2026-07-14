
import clsx from 'clsx';
import { EmptyState } from '../EmptyState/EmptyState';
import styles from './Table.module.css';

export const Table = ({ children, className, ...props }) => (
  <div className={styles.tableWrapper}>
    <table className={clsx(styles.table, className)} {...props}>
      {children}
    </table>
  </div>
);

export const TableHeader = ({ children, className, ...props }) => (
  <thead className={clsx(styles.header, className)} {...props}>
    {children}
  </thead>
);

export const TableBody = ({ children, className, isEmpty, emptyProps, ...props }) => {
  if (isEmpty) {
    return (
      <tbody className={clsx(styles.body, className)} {...props}>
        <tr>
          <td colSpan={100} className={styles.emptyCell}>
            <EmptyState {...emptyProps} />
          </td>
        </tr>
      </tbody>
    );
  }

  return (
    <tbody className={clsx(styles.body, className)} {...props}>
      {children}
    </tbody>
  );
};

export const TableRow = ({ children, className, ...props }) => (
  <tr className={clsx(styles.row, className)} {...props}>
    {children}
  </tr>
);

import { ChevronDown, ChevronRight } from 'lucide-react';

export const ExpandableTableRow = ({ 
  children, 
  className, 
  isExpanded, 
  onToggle, 
  expandedContent,
  colSpan = 10,
  ...props 
}) => {
  return (
    <>
      <tr className={clsx(styles.row, className)} {...props}>
        <td style={{ width: '40px', padding: '1rem', color: 'var(--text-muted)' }}>
          <button 
            type="button" 
            style={{ background: 'transparent', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '4px', borderRadius: '4px' }}
            onClick={(e) => {
              e.stopPropagation();
              if (onToggle) onToggle();
            }}
          >
            {isExpanded ? <ChevronDown size={18} /> : <ChevronRight size={18} />}
          </button>
        </td>
        {children}
      </tr>
      {isExpanded && (
        <tr className={styles.expandedRowContent}>
          <td colSpan={colSpan} className={styles.expandedInner}>
            {expandedContent}
          </td>
        </tr>
      )}
    </>
  );
};

export const TableHead = ({ children, className, align = 'left', ...props }) => (
  <th 
    className={clsx(styles.head, className)} 
    style={{ textAlign: align }} 
    {...props}
  >
    {children}
  </th>
);

export const TableCell = ({ children, className, align = 'left', ...props }) => (
  <td 
    className={clsx(styles.cell, className)} 
    style={{ textAlign: align }} 
    {...props}
  >
    {children}
  </td>
);
