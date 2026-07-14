import React from 'react';
import clsx from 'clsx';
import styles from './Button.module.css';

export const Button = React.forwardRef(({ 
  children, 
  variant = 'primary', 
  size = 'md', 
  className, 
  isLoading, 
  disabled, 
  ...props 
}, ref) => {
  return (
    <button
      ref={ref}
      className={clsx(
        styles.button,
        styles[variant],
        styles[size],
        { [styles.loading]: isLoading },
        className
      )}
      disabled={disabled || isLoading}
      {...props}
    >
      {isLoading && <span className={styles.spinner} />}
      {children}
    </button>
  );
});

Button.displayName = 'Button';
