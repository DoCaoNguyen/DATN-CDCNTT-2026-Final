import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './styles/global.css'; 
import { Providers } from './app/providers';

ReactDOM.createRoot(document.getElementById('root') as HTMLElement).render(
    <Providers>
      <App />
    </Providers>
);