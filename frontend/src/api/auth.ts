import api from './client';
import type { ApiResponse, AuthResponse, LoginRequest } from '@/types';

export const authApi = {
  login: (data: LoginRequest) =>
    api.post<ApiResponse<AuthResponse>>('/api/auth/login', data).then(r => r.data.data),
  me: () =>
    api.get<ApiResponse<AuthResponse>>('/api/auth/me').then(r => r.data.data),
};
