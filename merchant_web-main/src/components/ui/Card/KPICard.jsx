import React from 'react';
import { Card, CardContent } from './Card';

export const KPICard = ({ title, value, subtitle, icon: Icon, iconColor = 'var(--primary-color)', iconBg = 'var(--primary-light)' }) => {
  return (
    <Card style={{ height: '100%' }}>
      <CardContent style={{ padding: '1.25rem', display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.25rem' }}>
            <span style={{ fontSize: '0.875rem', fontWeight: 500, color: 'var(--text-muted)' }}>{title}</span>
            <div style={{ fontSize: '1.25rem', fontWeight: 700, color: 'var(--text-main)', display: 'flex', alignItems: 'baseline', gap: '0.25rem', wordBreak: 'break-word', flexWrap: 'wrap' }}>
              {value}
            </div>
            {subtitle && (
              <span style={{ fontSize: '0.75rem', color: 'var(--text-disabled)' }}>{subtitle}</span>
            )}
          </div>
          {Icon && (
            <div style={{ 
              display: 'flex', 
              alignItems: 'center', 
              justifyContent: 'center',
              width: '40px',
              height: '40px',
              borderRadius: 'var(--radius-md)',
              backgroundColor: iconBg,
              color: iconColor
            }}>
              <Icon size={20} />
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  );
};
