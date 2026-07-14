import { useState, useEffect, useRef } from 'react';
import clsx from 'clsx';
import styles from './Input.module.css';

export const SearchInput = ({ value, onChange, placeholder, disabled, className }) => {
  const [innerValue, setInnerValue] = useState(value || '');
  const onChangeRef = useRef(onChange);
  const isFirstMount = useRef(true);

  useEffect(() => {
    onChangeRef.current = onChange;
  }, [onChange]);

  useEffect(() => {
    if (value !== undefined && value !== innerValue) {
      setInnerValue(value);
    }
  }, [value]);

  useEffect(() => {
    if (isFirstMount.current) {
      isFirstMount.current = false;
      return;
    }
    const handler = setTimeout(() => {
      if (onChangeRef.current) {
        onChangeRef.current(innerValue);
      }
    }, 400);

    return () => clearTimeout(handler);
  }, [innerValue]);

  return (
    <div className={clsx(styles.inputWrapper, className)}>
      <svg className={styles.searchIcon} xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <circle cx="11" cy="11" r="8"></circle>
        <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
      </svg>
      <input
        type="text"
        className={styles.input}
        placeholder={placeholder}
        disabled={disabled}
        value={innerValue}
        onChange={(e) => setInnerValue(e.target.value)}
      />
    </div>
  );
};
