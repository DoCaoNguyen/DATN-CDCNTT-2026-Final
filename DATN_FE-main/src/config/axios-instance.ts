import axios from 'axios';

export const axiosInstance = axios.create({
  // Sử dụng biến môi trường của Vite, mặc định fallback về localhost
  baseURL: import.meta.env.VITE_API_BASE_URL || import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1',
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 30000,
});

// Tự động đính kèm Token vào mỗi request gửi đi
axiosInstance.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('access_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Bắt lỗi toàn cục từ Response
axiosInstance.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.data?.error_code === 'FORCE_CHANGE_PASSWORD') {
      window.location.href = '/change-password';
    }
    return Promise.reject(error);
  }
);