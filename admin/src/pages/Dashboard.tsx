import { useState, useEffect } from 'react';
import { getDashboard, type AdminDashboardDto, type AdminRecentOrderDto } from '../lib/api';

// ── Helpers ─────────────────────────────────────────────────────────────────

const ORDER_STATUS_LABEL: Record<number, string> = {
  0: 'Pending', 1: 'Accepted', 2: 'Shopping', 3: 'Purchased',
  4: 'Out for Delivery', 5: 'Delivered',
};

function fmtNgn(val: number) {
  return '₦' + val.toLocaleString('en-NG', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function statusStyle(status: number) {
  if (status === 5) return 'bg-emerald-100 text-primary';
  if (status === 0) return 'bg-orange-100 text-tertiary';
  return 'bg-blue-100 text-blue-700';
}

// ── Sub-components ─────────────────────────────────────────────────────────

function WeeklyChart({ data }: { data: AdminDashboardDto['monthlyChart'] }) {
  if (!data.length) {
    return (
      <div className="relative h-64 w-full bg-[radial-gradient(#e5e7eb_1px,transparent_1px)] [background-size:16px_16px] flex items-center justify-center text-secondary text-sm">
        No chart data yet
      </div>
    );
  }

  const maxRev = Math.max(...data.map(d => d.revenue), 1);
  const points = data.map((d, i) => {
    const x = (i / (data.length - 1)) * 1000;
    const y = 280 - (d.revenue / maxRev) * 240;
    return { x, y, d };
  });

  const path = points
    .map((p, i) => (i === 0 ? `M${p.x},${p.y}` : `L${p.x},${p.y}`))
    .join(' ');
  const areaPath = `${path} L${points[points.length - 1].x},300 L0,300 Z`;

  return (
    <div className="relative h-64 w-full bg-[radial-gradient(#e5e7eb_1px,transparent_1px)] [background-size:16px_16px]">
      <svg className="w-full h-full drop-shadow-xl overflow-visible" viewBox="0 0 1000 300">
        <defs>
          <linearGradient id="chartGradient" x1="0" x2="0" y1="0" y2="1">
            <stop offset="0%" stopColor="#006d39" stopOpacity="0.15" />
            <stop offset="100%" stopColor="#006d39" stopOpacity="0" />
          </linearGradient>
        </defs>
        <path d={areaPath} fill="url(#chartGradient)" />
        <path d={path} fill="none" stroke="#006d39" strokeWidth="4" strokeLinecap="round" />
        {points.map((p, i) => (
          <circle key={i} cx={p.x} cy={p.y} r="6" fill="#006d39" stroke="white" strokeWidth="2" />
        ))}
      </svg>
      <div className="absolute bottom-0 left-0 w-full flex justify-between px-1">
        {points.map((p, i) => (
          <span key={i} className="text-[10px] text-secondary font-bold">{p.d.month}</span>
        ))}
      </div>
    </div>
  );
}

// ── Dashboard page ─────────────────────────────────────────────────────────

export default function Dashboard() {
  const [data, setData] = useState<AdminDashboardDto | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    getDashboard()
      .then(setData)
      .catch(e => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <section className="pt-10 pb-12 px-8 flex items-center justify-center min-h-96">
        <div className="flex flex-col items-center gap-4 text-secondary">
          <div className="w-10 h-10 border-4 border-primary/30 border-t-primary rounded-full animate-spin" />
          <p className="text-sm font-medium">Loading dashboard...</p>
        </div>
      </section>
    );
  }

  if (error || !data) {
    return (
      <section className="pt-10 pb-12 px-8">
        <div className="bg-red-50 border border-red-200 rounded-xl p-6 text-red-700 flex items-center gap-3">
          <span className="material-symbols-outlined">error</span>
          <div>
            <p className="font-bold">Failed to load dashboard</p>
            <p className="text-sm">{error}</p>
          </div>
        </div>
      </section>
    );
  }

  const metrics = [
    {
      icon: 'payments', iconBg: 'bg-emerald-50', iconColor: 'text-primary',
      label: 'Revenue Today', value: fmtNgn(data.revenueToday),
      badge: 'This month: ' + fmtNgn(data.revenueThisMonth),
      badgeStyle: 'text-primary bg-primary-fixed-dim', badgeIcon: null,
    },
    {
      icon: 'shopping_bag', iconBg: 'bg-emerald-50', iconColor: 'text-primary',
      label: 'Active Orders', value: String(data.activeOrders),
      badge: `${data.totalOrdersToday} today`,
      badgeStyle: 'text-primary bg-primary-fixed-dim', badgeIcon: 'trending_up',
    },
    {
      icon: 'delivery_dining', iconBg: 'bg-orange-50', iconColor: 'text-tertiary',
      label: 'Active Shoppers', value: String(data.activeShoppers),
      badge: `${data.totalShoppers} total`,
      badgeStyle: 'text-tertiary bg-tertiary-fixed-dim', badgeIcon: null,
    },
    {
      icon: 'timer', iconBg: 'bg-blue-50', iconColor: 'text-blue-600',
      label: 'Avg. Wait Time', value: `${data.avgWaitTimeMinutes} mins`,
      badge: 'Target 45m', badgeStyle: 'text-secondary bg-surface-container-high', badgeIcon: null,
    },
  ];

  return (
    <section className="pt-10 pb-12 px-8">
      {/* Heading */}
      <div className="mb-10">
        <h2 className="text-on-surface font-extrabold text-4xl tracking-tight mb-2">Dashboard Overview</h2>
        <p className="text-secondary font-medium">Real-time performance metrics and operations monitoring.</p>
      </div>

      {/* Metric cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-10">
        {metrics.map((m) => (
          <div key={m.label} className="bg-surface-container-lowest p-6 rounded-xl border border-outline-variant/15 flex flex-col justify-between">
            <div className="flex justify-between items-start mb-4">
              <div className={`p-2 ${m.iconBg} rounded-lg`}>
                <span className={`material-symbols-outlined ${m.iconColor}`}>{m.icon}</span>
              </div>
              <span className={`text-xs font-bold px-2 py-1 rounded-full flex items-center gap-1 ${m.badgeStyle}`}>
                {m.badgeIcon && <span className="material-symbols-outlined text-[14px]">{m.badgeIcon}</span>}
                {m.badge}
              </span>
            </div>
            <div>
              <p className="text-xs font-bold uppercase tracking-wider text-secondary mb-1">{m.label}</p>
              <p className="text-2xl font-extrabold text-on-surface">{m.value}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Charts + insight */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="lg:col-span-2 bg-surface-container-lowest rounded-xl border border-outline-variant/15 p-8">
          <div className="flex justify-between items-center mb-10">
            <div>
              <h3 className="text-lg font-bold text-on-surface">Monthly Revenue Trends</h3>
              <p className="text-sm text-secondary">Last 6 months — revenue vs payouts</p>
            </div>
          </div>

          <WeeklyChart data={data.monthlyChart} />

          <div className="flex justify-between mt-6 pt-6 border-t border-neutral-100">
            <div className="flex gap-10">
              <div>
                <p className="text-[10px] font-bold uppercase text-secondary mb-1">Platform Fees Today</p>
                <p className="text-sm font-bold text-on-surface">{fmtNgn(data.platformFeesToday)}</p>
              </div>
              <div>
                <p className="text-[10px] font-bold uppercase text-secondary mb-1">Customers</p>
                <p className="text-sm font-bold text-on-surface">{data.totalCustomers.toLocaleString()}</p>
              </div>
            </div>
          </div>
        </div>

        <div className="space-y-6">
          <div className="bg-secondary p-8 rounded-xl shadow-xl text-white relative overflow-hidden">
            <div className="relative z-10">
              <h4 className="text-2xl font-bold tracking-tight mb-2">Platform Summary</h4>
              <p className="text-neutral-300 text-sm leading-relaxed mb-6">
                {data.completedOrdersToday} orders completed today.{' '}
                {data.activeShoppers} shoppers active across all zones.
              </p>
              <button className="bg-primary hover:bg-primary-container px-6 py-3 rounded-xl font-bold text-sm transition-all active:scale-95">
                View Full Report
              </button>
            </div>
            <div className="absolute -right-10 -bottom-10 w-48 h-48 bg-emerald-500/20 rounded-full blur-3xl" />
          </div>
        </div>
      </div>

      {/* Recent orders */}
      <div className="mt-10 bg-surface-container-lowest rounded-xl border border-outline-variant/15 overflow-hidden">
        <div className="px-8 py-6 border-b border-neutral-100 flex justify-between items-center">
          <h3 className="text-lg font-bold text-on-surface">Recent Orders</h3>
          <a href="/orders" className="text-primary text-xs font-bold hover:underline">View All</a>
        </div>

        {data.recentOrders.length === 0 ? (
          <div className="px-8 py-12 text-center text-secondary text-sm">No orders yet.</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-surface-container-low">
                  {['Order ID', 'Customer', 'Shopper', 'Amount', 'Status'].map((h, i) => (
                    <th key={h} className={`px-8 py-4 text-[10px] font-bold uppercase tracking-widest text-secondary ${i === 3 ? 'text-right' : ''}`}>
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-neutral-100">
                {data.recentOrders.map((order: AdminRecentOrderDto) => (
                  <tr key={order.orderId} className="hover:bg-surface-container-low transition-colors">
                    <td className="px-8 py-4 text-sm font-bold text-on-surface">#{order.orderId.slice(-6).toUpperCase()}</td>
                    <td className="px-8 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-neutral-200 flex items-center justify-center text-[10px] font-bold text-secondary flex-shrink-0">
                          {order.customerInitials}
                        </div>
                        <span className="text-sm font-medium text-on-surface">{order.customerName}</span>
                      </div>
                    </td>
                    <td className="px-8 py-4">
                      {order.shopperName ? (
                        <div className="flex items-center gap-2">
                          <div className="w-6 h-6 rounded-full bg-neutral-300 flex items-center justify-center text-[9px] font-bold text-neutral-600">
                            {order.shopperName.split(' ').map(n => n[0]).join('')}
                          </div>
                          <span className="text-sm text-secondary">{order.shopperName}</span>
                        </div>
                      ) : (
                        <div className="flex items-center gap-2 text-neutral-400">
                          <span className="material-symbols-outlined text-[18px]">person_search</span>
                          <span className="text-sm italic">Assigning...</span>
                        </div>
                      )}
                    </td>
                    <td className="px-8 py-4 text-sm font-bold text-on-surface text-right">{fmtNgn(order.total)}</td>
                    <td className="px-8 py-4">
                      <span className={`px-3 py-1 text-[11px] font-bold rounded-full ${statusStyle(order.status)}`}>
                        {ORDER_STATUS_LABEL[order.status] ?? 'Unknown'}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </section>
  );
}
