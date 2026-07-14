import clsx from 'clsx';
import { useState, useEffect } from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import styles from './Pagination.module.css';

export const Pagination = ({ 
  currentPage = 1, 
  totalPages = 1, 
  limit = 10,
  totalItems,
  onPageChange, 
  onLimitChange 
}) => {
  const [inputValue, setInputValue] = useState(currentPage);

  useEffect(() => {
    setInputValue(currentPage);
  }, [currentPage]);

  const handleInputBlur = () => {
    let newPage = parseInt(inputValue, 10);
    if (isNaN(newPage) || newPage < 1) newPage = 1;
    if (newPage > totalPages) newPage = totalPages;
    setInputValue(newPage);
    if (newPage !== currentPage) {
      onPageChange(newPage);
    }
  };

  const handleInputKeyDown = (e) => {
    if (e.key === 'Enter') {
      handleInputBlur();
    }
  };

  const getPages = () => {
    if (totalPages <= 7) {
      return Array.from({ length: totalPages }, (_, i) => i + 1);
    }
    
    if (currentPage <= 3) {
      return [1, 2, 3, 4, '...', totalPages];
    }
    
    if (currentPage >= totalPages - 2) {
      return [1, '...', totalPages - 3, totalPages - 2, totalPages - 1, totalPages];
    }
    
    return [1, '...', currentPage - 1, currentPage, currentPage + 1, '...', totalPages];
  };

  if (totalPages <= 0) return null;

  const pages = getPages();

  return (
    <div className={styles.paginationContainer}>
      <div className={styles.leftSection} style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
        <span className={styles.label}>Trang</span>
        <input 
          type="number" 
          className={styles.pageInput}
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
          onBlur={handleInputBlur}
          onKeyDown={handleInputKeyDown}
          min={1}
          max={totalPages}
        />
        <span style={{ color: 'var(--border-color)' }}>|</span>
        <span className={styles.label}>Số dòng trên mỗi trang</span>
        <select 
          className={styles.limitSelect}
          value={limit}
          onChange={(e) => {
            if(onLimitChange) onLimitChange(Number(e.target.value));
          }}
        >
          <option value={10}>10</option>
          <option value={20}>20</option>
          <option value={50}>50</option>
          <option value={100}>100</option>
        </select>
        {totalItems !== undefined && (
          <span className={styles.label} style={{ color: 'var(--text-muted)' }}>({totalItems} bản ghi)</span>
        )}
      </div>

      <div className={styles.rightSection} style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
        <button 
          className={clsx(styles.navButton, { [styles.disabled]: currentPage <= 1 })}
          onClick={() => currentPage > 1 && onPageChange(currentPage - 1)}
          disabled={currentPage <= 1}
        >
          <ChevronLeft size={16} /> Trước
        </button>

        <div className={styles.pageNumbers} style={{ display: 'flex', gap: '4px' }}>
          {pages.map((p, i) => (
            p === '...' ? (
              <span key={"dots-" + i} className={styles.dots}>...</span>
            ) : (
              <button
                key={p}
                className={clsx(styles.pageButton, { [styles.active]: p === currentPage })}
                onClick={() => p !== currentPage && onPageChange(p)}
              >
                {p}
              </button>
            )
          ))}
        </div>

        <button 
          className={clsx(styles.navButton, { [styles.disabled]: currentPage >= totalPages })}
          onClick={() => currentPage < totalPages && onPageChange(currentPage + 1)}
          disabled={currentPage >= totalPages}
        >
          Sau <ChevronRight size={16} />
        </button>
      </div>
    </div>
  );
};
