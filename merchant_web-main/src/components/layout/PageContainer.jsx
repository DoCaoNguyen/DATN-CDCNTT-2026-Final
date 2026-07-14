import React from 'react';

const PageContainer = ({ children }) => {
  return (
    <div style={{
      width: '100%',
      boxSizing: 'border-box',
      padding: 'var(--page-padding-y) var(--page-padding-x)',
      display: 'flex',
      flexDirection: 'column',
      gap: '24px'
    }}>
      {children}
    </div>
  );
};

export default PageContainer;
