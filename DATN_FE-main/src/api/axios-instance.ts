import axios from 'axios';

// Cờ để đảm bảo chỉ có 1 request gọi refresh token tại một thời điểm
let isRefreshing = false;
let refreshPromise: Promise<string> | null = null;

export const axiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1',
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 10000,
});

// Interceptor Request: Gắn token vào header
axiosInstance.interceptors.request.use(
  (config) => {
    // Tạm thời giữ localStorage theo thiết kế cũ
    const token = localStorage.getItem('access_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Interceptor Response: Xử lý 401 Unauthorized
axiosInstance.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    // Nếu lỗi 401 và chưa retry lần nào
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;
      
      const refreshToken = localStorage.getItem('refresh_token');
      
      // Nếu không có refresh token thì đăng xuất luôn
      if (!refreshToken) {
        localStorage.removeItem('access_token');
        localStorage.removeItem('refresh_token');
        localStorage.removeItem('user_info');
        window.location.href = '/login';
        return Promise.reject(error);
      }

      // Ngăn chặn việc gọi refresh token nhiều lần đồng thời khi có nhiều request fail cùng lúc
      if (!isRefreshing) {
        isRefreshing = true;
        refreshPromise = (async () => {
          try {
            // TODO: Thay thế endpoint này bằng endpoint thực tế của hệ thống
            const response = await axios.post(
              `${import.meta.env.VITE_API_BASE_URL || import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1'}/auth/refresh-token`,
              { refresh_token: refreshToken }
            );
            
            const newAccessToken = response.data.data?.access_token || response.data.access_token;
            localStorage.setItem('access_token', newAccessToken);
            
            // Nếu API có trả về refresh token mới thì lưu lại, không thì giữ nguyên cũ
            if (response.data.data?.refresh_token || response.data.refresh_token) {
               localStorage.setItem('refresh_token', response.data.data?.refresh_token || response.data.refresh_token);
            }
            
            isRefreshing = false;
            return newAccessToken;
          } catch (err) {
            isRefreshing = false;
            // Nếu gọi refresh lỗi (token hết hạn) -> Xóa toàn bộ và về trang login
            localStorage.removeItem('access_token');
            localStorage.removeItem('refresh_token');
            localStorage.removeItem('user_info');
            window.location.href = '/login';
            throw err;
          }
        })();
      }

      try {
        const newAccessToken = await refreshPromise;
        // Cập nhật lại header cho request bị fail
        originalRequest.headers.Authorization = `Bearer ${newAccessToken}`;
        // Retry lại request
        return axiosInstance(originalRequest);
      } catch (err) {
        return Promise.reject(err);
      }
    }

    return Promise.reject(error);
  }
);
