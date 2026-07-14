import React from 'react';

const PageHeader = ({ title, description, action }) => {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: '16px' }}>
      <div>
        <h1 style={{ fontSize: '1.5rem', fontWeight: 600, color: 'var(--text-main)', margin: '0 0 8px 0' }}>
          {title}
        </h1>
        {description && (
          <p style={{ color: 'var(--text-muted)', margin: 0, fontSize: '0.875rem' }}>
            {description}
          </p>
        )}
      </div>
      {action && (
        <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
          {action}
        </div>
      )}
    </div>
  );
};

export default PageHeader;
