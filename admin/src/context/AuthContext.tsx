import { createContext, useContext, useState, useCallback, type ReactNode } from 'react';
import { loginApi, type LoginResponse } from '../lib/api';

interface AuthUser {
  userId: string;
  fullName: string;
  email: string;
  role: string;
  token: string;
}

interface AuthContextValue {
  user: AuthUser | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  isAdmin: boolean;
}

const AuthContext = createContext<AuthContextValue | null>(null);

function loadUser(): AuthUser | null {
  try {
    const raw = localStorage.getItem('ss_admin_user');
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(loadUser);

  const login = useCallback(async (email: string, password: string) => {
    const res: LoginResponse = await loginApi(email, password);
    const authUser: AuthUser = {
      userId: res.userId,
      fullName: res.fullName,
      email: res.email,
      role: res.role,
      token: res.accessToken,
    };
    localStorage.setItem('ss_admin_token', res.accessToken);
    localStorage.setItem('ss_admin_user', JSON.stringify(authUser));
    setUser(authUser);
  }, []);

  const logout = useCallback(() => {
    localStorage.removeItem('ss_admin_token');
    localStorage.removeItem('ss_admin_user');
    setUser(null);
  }, []);

  return (
    <AuthContext.Provider value={{ user, login, logout, isAdmin: user?.role === 'Admin' }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used inside AuthProvider');
  return ctx;
}
