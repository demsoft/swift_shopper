const BASE_URL = import.meta.env.VITE_API_URL ?? 'https://footballapi.goserp.co.uk';

function getToken(): string | null {
  return localStorage.getItem('ss_admin_token');
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = getToken();
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const res = await fetch(`${BASE_URL}${path}`, { ...options, headers });

  if (res.status === 401) {
    localStorage.removeItem('ss_admin_token');
    localStorage.removeItem('ss_admin_user');
    window.location.href = '/login';
    throw new Error('Unauthorized');
  }

  if (!res.ok) {
    const text = await res.text().catch(() => res.statusText);
    throw new Error(text || `HTTP ${res.status}`);
  }

  const text = await res.text();
  return (text ? JSON.parse(text) : undefined) as T;
}

// ── Auth ─────────────────────────────────────────────────────────────────────

export interface LoginResponse {
  accessToken: string;
  userId: string;
  fullName: string;
  email: string;
  role: string;
}

interface RawLoginResponse {
  accessToken: string;
  user: {
    userId: string;
    fullName: string;
    email: string;
    phoneNumber: string;
    role: number; // 0=Customer, 1=Shopper, 2=Admin
  };
}

const ROLE_NAMES: Record<number, string> = { 0: 'Customer', 1: 'Shopper', 2: 'Admin' };

export async function loginApi(email: string, password: string): Promise<LoginResponse> {
  const raw = await request<RawLoginResponse>('/api/auth/login', {
    method: 'POST',
    body: JSON.stringify({ emailOrPhoneNumber: email, password }),
  });
  return {
    accessToken: raw.accessToken,
    userId: raw.user.userId,
    fullName: raw.user.fullName,
    email: raw.user.email,
    role: ROLE_NAMES[raw.user.role] ?? String(raw.user.role),
  };
}

// ── Admin: Dashboard ─────────────────────────────────────────────────────────

export interface AdminDashboardDto {
  totalOrdersToday: number;
  activeOrders: number;
  completedOrdersToday: number;
  activeShoppers: number;
  totalShoppers: number;
  totalCustomers: number;
  revenueToday: number;
  revenueThisMonth: number;
  platformFeesToday: number;
  avgWaitTimeMinutes: number;
  recentOrders: AdminRecentOrderDto[];
  monthlyChart: AdminMonthlyStatDto[];
}

export interface AdminRecentOrderDto {
  orderId: string;
  customerName: string;
  customerInitials: string;
  customerLocation: string;
  shopperName: string | null;
  storeName: string;
  marketIcon: string;
  status: number;
  total: number;
  updatedAt: string;
}

export interface AdminMonthlyStatDto {
  month: string;
  revenue: number;
  payouts: number;
}

export function getDashboard(): Promise<AdminDashboardDto> {
  return request('/api/admin/dashboard');
}

// ── Admin: Orders ─────────────────────────────────────────────────────────────

export interface AdminOrderDto {
  orderId: string;
  customerName: string;
  customerInitials: string;
  customerAvatarUrl?: string | null;
  customerLocation: string;
  shopperName: string | null;
  shopperAvatarUrl?: string | null;
  shopperTier: string | null;
  storeName: string;
  marketIcon: string;
  status: number;
  total: number;
  updatedAt: string;
}

export interface AdminOrderItemDto {
  id: number;
  name: string;
  unit: string;
  quantity: number;
  estimatedPrice: number;
  foundPrice: number | null;
  status: number; // 0=Pending, 1=Found, 2=Unavailable
  photoUrl: string | null;
}

export interface AdminOrderDetailDto extends AdminOrderDto {
  items: AdminOrderItemDto[];
}

export interface PagedResult<T> {
  items: T[];
  totalCount: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

export function getOrders(status?: string, page = 1, pageSize = 20): Promise<PagedResult<AdminOrderDto>> {
  const params = new URLSearchParams({ page: String(page), pageSize: String(pageSize) });
  if (status) params.set('status', status);
  return request(`/api/admin/orders?${params}`);
}

export function getOrderDetail(orderId: string): Promise<AdminOrderDetailDto> {
  return request(`/api/admin/orders/${orderId}`);
}

export function updateOrderStatus(orderId: string, status: number) {
  return request(`/api/admin/orders/${orderId}/status`, {
    method: 'PATCH',
    body: JSON.stringify({ status }),
  });
}

// ── Admin: Shoppers ───────────────────────────────────────────────────────────

export interface AdminShopperDto {
  shopperId: string;
  fullName: string;
  initials: string;
  avatarUrl?: string | null;
  email: string;
  phoneNumber: string;
  isOnline: boolean;
  isVerified: boolean;
  isActive: boolean;
  tier: string;
  rating: number;
  completedOrders: number;
  ordersThisMonth: number;
  earningsThisMonth: number;
  joinedAt: string;
  lastActiveAt: string | null;
}

export function getShoppers(tab = 'all', page = 1, pageSize = 20): Promise<PagedResult<AdminShopperDto>> {
  const params = new URLSearchParams({ tab, page: String(page), pageSize: String(pageSize) });
  return request(`/api/admin/shoppers?${params}`);
}

export function updateShopperStatus(shopperId: string, isActive: boolean) {
  return request(`/api/admin/shoppers/${shopperId}/status`, {
    method: 'PATCH',
    body: JSON.stringify({ isActive }),
  });
}

// ── Admin: Customers ──────────────────────────────────────────────────────────

export interface AdminCustomerDto {
  customerId: string;
  fullName: string;
  initials: string;
  avatarUrl?: string | null;
  avatarBg: string;
  avatarText: string;
  email: string;
  totalOrders: number;
  lastOrderAt: string | null;
  totalSpend: number;
  membership: string;
  isActive: boolean;
  joinedAt: string;
}

export function getCustomers(membership?: string, status?: string, page = 1, pageSize = 20): Promise<PagedResult<AdminCustomerDto>> {
  const params = new URLSearchParams({ page: String(page), pageSize: String(pageSize) });
  if (membership) params.set('membership', membership);
  if (status) params.set('status', status);
  return request(`/api/admin/customers?${params}`);
}

export function updateCustomerStatus(customerId: string, isActive: boolean) {
  return request(`/api/admin/customers/${customerId}/status`, {
    method: 'PATCH',
    body: JSON.stringify({ isActive }),
  });
}

// ── Admin: Earnings ───────────────────────────────────────────────────────────

export interface AdminEarningsSummaryDto {
  totalRevenue: number;
  shopperPayouts: number;
  platformFees: number;
  platformMarginPercent: number;
  nextPayoutCycle: string;
  monthlyChart: AdminMonthlyStatDto[];
}

export interface AdminPayoutDto {
  payoutId: string;
  shopperId: string;
  shopperName: string;
  shopperInitials: string;
  date: string;
  amount: number;
  status: string;
  actionIcon: string;
}

export function getEarningsSummary(): Promise<AdminEarningsSummaryDto> {
  return request('/api/admin/earnings/summary');
}

export function getPayouts(page = 1, pageSize = 20): Promise<PagedResult<AdminPayoutDto>> {
  const params = new URLSearchParams({ page: String(page), pageSize: String(pageSize) });
  return request(`/api/admin/earnings/payouts?${params}`);
}

// ── Admin: Markets ────────────────────────────────────────────────────────────

export interface AdminMarketDto {
  marketId: string;
  name: string;
  type: string;
  location: string;
  zone: string;
  address: string;
  isActive: boolean;
  categories: string[];
  openingTime: string;
  closingTime: string;
  geofenceRadiusKm: number;
  activeShoppers: number;
  ordersToday: number;
  photoUrl: string | null;
  latitude: number | null;
  longitude: number | null;
  createdAt: string;
}

export function getMarkets(type?: string, status?: string, page = 1, pageSize = 20): Promise<PagedResult<AdminMarketDto>> {
  const params = new URLSearchParams({ page: String(page), pageSize: String(pageSize) });
  if (type) params.set('type', type);
  if (status) params.set('status', status);
  return request(`/api/admin/markets?${params}`);
}

export function createMarket(body: Omit<AdminMarketDto, 'marketId' | 'activeShoppers' | 'ordersToday' | 'createdAt'>) {
  return request<AdminMarketDto>('/api/admin/markets', { method: 'POST', body: JSON.stringify(body) });
}

export function updateMarket(marketId: string, body: Omit<AdminMarketDto, 'marketId' | 'activeShoppers' | 'ordersToday' | 'createdAt'>) {
  return request<AdminMarketDto>(`/api/admin/markets/${marketId}`, { method: 'PATCH', body: JSON.stringify(body) });
}

export function deleteMarket(marketId: string) {
  return request(`/api/admin/markets/${marketId}`, { method: 'DELETE' });
}

// ── Admin: Admin Users ────────────────────────────────────────────────────────

export interface AdminUserDto {
  userId: string;
  fullName: string;
  initials: string;
  email: string;
  phoneNumber: string;
  adminRole: string;
  isActive: boolean;
  forcePasswordReset: boolean;
  createdAt: string;
}

export function getAdminUsers(): Promise<AdminUserDto[]> {
  return request('/api/admin/users');
}

export function createAdminUser(body: {
  fullName: string;
  email: string;
  phoneNumber: string;
  adminRole: string;
  temporaryPassword: string;
  forcePasswordReset: boolean;
}) {
  return request<AdminUserDto>('/api/admin/users', { method: 'POST', body: JSON.stringify(body) });
}

// ── Upload ────────────────────────────────────────────────────────────────────

export async function uploadImage(file: File): Promise<string> {
  const token = getToken();
  const formData = new FormData();
  formData.append('file', file);

  const res = await fetch(`${BASE_URL}/api/upload/image`, {
    method: 'POST',
    headers: token ? { Authorization: `Bearer ${token}` } : {},
    body: formData,
  });

  if (!res.ok) {
    const text = await res.text().catch(() => res.statusText);
    throw new Error(text || `HTTP ${res.status}`);
  }

  const data = await res.json();
  return data.url as string;
}

export async function updateAvatar(file: File): Promise<string> {
  const token = getToken();
  const formData = new FormData();
  formData.append('file', file);

  const res = await fetch(`${BASE_URL}/api/users/me/avatar`, {
    method: 'PATCH',
    headers: token ? { Authorization: `Bearer ${token}` } : {},
    body: formData,
  });

  if (!res.ok) {
    const text = await res.text().catch(() => res.statusText);
    throw new Error(text || `HTTP ${res.status}`);
  }

  const data = await res.json();
  return data.avatarUrl as string;
}

// ── Seed (no auth needed) ─────────────────────────────────────────────────────

export function seedFirstAdmin(body: {
  fullName: string;
  email: string;
  phoneNumber: string;
  adminRole: string;
  temporaryPassword: string;
  forcePasswordReset: boolean;
}) {
  return request<AdminUserDto>('/api/admin/seed-first-admin', { method: 'POST', body: JSON.stringify(body) });
}
