import { useState, useEffect } from 'react';
import { getOrders, type AdminOrderDto, type PagedResult } from '../lib/api';

// ── Helpers ─────────────────────────────────────────────────────────────────

type OrderStatusLabel = 'Shopping' | 'Negotiating' | 'Delivering' | 'Completed' | 'Cancelled' | 'Pending' | 'Accepted' | 'Purchased';
type ShopperTier = 'PRO SHOPPER' | 'BASIC' | null;

const STATUS_MAP: Record<number, OrderStatusLabel> = {
  0: 'Pending', 1: 'Accepted', 2: 'Shopping', 3: 'Purchased',
  4: 'Delivering', 5: 'Completed',
};

function fmtNgn(val: number) {
  return '₦' + val.toLocaleString('en-NG', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

// ── Sub-components ─────────────────────────────────────────────────────────

function StatusBadge({ status }: { status: OrderStatusLabel }) {
  const styles: Record<string, string> = {
    Shopping:    'bg-blue-100 text-blue-700',
    Negotiating: 'bg-orange-100 text-orange-700',
    Delivering:  'bg-emerald-100 text-emerald-700',
    Completed:   'bg-neutral-200 text-neutral-600',
    Cancelled:   'bg-red-100 text-red-700',
    Pending:     'bg-orange-100 text-orange-700',
    Accepted:    'bg-blue-50 text-blue-600',
    Purchased:   'bg-purple-100 text-purple-700',
  };
  return (
    <span className={`px-3 py-1 rounded-full text-[11px] font-bold uppercase tracking-wide ${styles[status] ?? 'bg-neutral-100 text-neutral-500'}`}>
      {status}
    </span>
  );
}

function ShopperCell({ name, tier }: { name: string | null; tier: ShopperTier }) {
  if (!name) {
    return <span className="text-secondary italic text-sm">Assigning...</span>;
  }
  return (
    <div className="flex items-center gap-3">
      <div className="w-8 h-8 rounded-full bg-surface-container-high flex items-center justify-center text-xs font-bold text-secondary flex-shrink-0">
        {name.split(' ').map((n) => n[0]).join('')}
      </div>
      <div className="flex flex-col">
        <span className="text-sm font-semibold text-on-surface">{name}</span>
        {tier === 'PRO SHOPPER' ? (
          <span className="text-xs text-primary font-bold uppercase tracking-tight">PRO SHOPPER</span>
        ) : (
          <span className="text-xs text-secondary font-bold uppercase tracking-tight">BASIC</span>
        )}
      </div>
    </div>
  );
}

// ── Page ───────────────────────────────────────────────────────────────────

export default function Orders() {
  const [currentPage, setCurrentPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState('');
  const [result, setResult] = useState<PagedResult<AdminOrderDto> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    setLoading(true);
    getOrders(statusFilter || undefined, currentPage, 20)
      .then(setResult)
      .catch(e => setError(e.message))
      .finally(() => setLoading(false));
  }, [currentPage, statusFilter]);

  const orders = result?.items ?? [];
  const totalPages = result?.totalPages ?? 1;

  return (
    <main className="pt-10 px-8 pb-12 min-h-screen bg-surface">
      {/* Header */}
      <div className="grid grid-cols-12 gap-6 mb-8">
        <div className="col-span-12 lg:col-span-8">
          <h2 className="font-extrabold tracking-tight text-on-surface mb-2" style={{ fontSize: '2.75rem', letterSpacing: '-0.02em' }}>
            Order Management
          </h2>
          <p className="text-sm text-secondary font-medium">
            {result ? `${result.totalCount} total orders` : 'Loading orders...'}
          </p>
        </div>
        <div className="col-span-12 lg:col-span-4 flex justify-end items-center gap-3">
          <button className="px-5 py-2.5 rounded-xl border border-outline-variant/30 text-on-surface font-medium text-sm bg-surface-container-lowest shadow-sm hover:bg-surface-container-low transition-all">
            Export Report
          </button>
          <button className="px-6 py-2.5 rounded-xl bg-gradient-to-br from-primary to-primary-container text-white font-semibold text-sm shadow-lg shadow-emerald-500/20 active:scale-95 transition-all flex items-center gap-2">
            <span className="material-symbols-outlined text-sm">add</span>
            Create New Order
          </button>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-surface-container-lowest rounded-xl p-5 shadow-sm mb-8 border border-outline-variant/10">
        <div className="flex flex-wrap items-center gap-6">
          <div className="flex flex-col gap-1.5">
            <label className="text-[10px] font-bold uppercase tracking-widest text-neutral-400 px-1">Order Status</label>
            <select
              value={statusFilter}
              onChange={e => { setStatusFilter(e.target.value); setCurrentPage(1); }}
              className="appearance-none bg-surface-container-high border-none rounded-full px-4 py-1.5 text-xs font-medium focus:outline-none focus:ring-2 focus:ring-primary/20 cursor-pointer min-w-[140px]"
            >
              <option value="">All Statuses</option>
              <option value="Pending">Pending</option>
              <option value="Accepted">Accepted</option>
              <option value="Shopping">Shopping</option>
              <option value="Purchased">Purchased</option>
              <option value="OutForDelivery">Out for Delivery</option>
              <option value="Delivered">Delivered</option>
            </select>
          </div>

          <div className="flex flex-col gap-1.5 border-l border-neutral-100 pl-6">
            <label className="text-[10px] font-bold uppercase tracking-widest text-neutral-400 px-1">Market Type</label>
            <select className="appearance-none bg-surface-container-high border-none rounded-full px-4 py-1.5 text-xs font-medium focus:outline-none focus:ring-2 focus:ring-primary/20 cursor-pointer min-w-[140px]">
              <option>All Markets</option>
              <option>Modern Retail</option>
              <option>Open Air Markets</option>
              <option>Local Artisans</option>
            </select>
          </div>

          <div className="flex flex-col gap-1.5 border-l border-neutral-100 pl-6">
            <label className="text-[10px] font-bold uppercase tracking-widest text-neutral-400 px-1">Date Range</label>
            <button className="flex items-center gap-3 bg-surface-container-high rounded-full px-4 py-1.5 text-xs font-medium text-on-surface hover:bg-surface-container-highest transition-colors">
              <span className="material-symbols-outlined text-sm">calendar_today</span>
              <span>Last 30 Days</span>
              <span className="material-symbols-outlined text-sm">expand_more</span>
            </button>
          </div>

          <div className="ml-auto flex items-center gap-2">
            <button className="p-2 text-neutral-400 hover:text-primary transition-colors">
              <span className="material-symbols-outlined">filter_list</span>
            </button>
            <button className="p-2 text-neutral-400 hover:text-primary transition-colors">
              <span className="material-symbols-outlined">refresh</span>
            </button>
          </div>
        </div>
      </div>

      {/* Table */}
      <div className="bg-surface-container-lowest rounded-xl shadow-sm border border-outline-variant/10 overflow-hidden">
        <div className="overflow-x-auto custom-scrollbar">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-low">
                {['Order ID', 'Customer', 'Shopper', 'Market/Store', 'Status', 'Total', 'Actions'].map((h, i) => (
                  <th key={h} className={`px-6 py-4 text-xs font-bold uppercase tracking-[0.05em] text-secondary border-b border-outline-variant/10 ${i === 6 ? 'text-right' : ''}`}>
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-surface-container-low">
              {loading ? (
                <tr>
                  <td colSpan={7} className="px-6 py-16 text-center text-secondary">
                    <div className="flex flex-col items-center gap-3">
                      <div className="w-8 h-8 border-4 border-primary/30 border-t-primary rounded-full animate-spin" />
                      <span className="text-sm">Loading orders...</span>
                    </div>
                  </td>
                </tr>
              ) : error ? (
                <tr>
                  <td colSpan={7} className="px-6 py-10 text-center text-red-600 text-sm">{error}</td>
                </tr>
              ) : orders.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-6 py-10 text-center text-secondary text-sm">No orders found.</td>
                </tr>
              ) : orders.map((order: AdminOrderDto, idx: number) => (
                <tr
                  key={order.orderId}
                  className={`hover:bg-primary/5 transition-colors group ${idx % 2 === 0 ? 'bg-white' : 'bg-surface-container-low'}`}
                >
                  <td className="px-6 py-4 text-sm font-bold text-on-surface">#{order.orderId.slice(-6).toUpperCase()}</td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-full bg-surface-container-high flex items-center justify-center text-xs font-bold text-secondary flex-shrink-0">
                        {order.customerInitials}
                      </div>
                      <div className="flex flex-col">
                        <span className="text-sm font-semibold text-on-surface">{order.customerName}</span>
                        <span className="text-xs text-secondary">{order.customerLocation}</span>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <ShopperCell name={order.shopperName} tier={(order.shopperTier as ShopperTier) ?? null} />
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      <span className="material-symbols-outlined text-sm text-secondary">{order.marketIcon || 'storefront'}</span>
                      <span className="text-sm font-medium text-on-surface">{order.storeName}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <StatusBadge status={STATUS_MAP[order.status] ?? 'Pending'} />
                  </td>
                  <td className="px-6 py-4 text-sm font-bold text-on-surface">{fmtNgn(order.total)}</td>
                  <td className="px-6 py-4 text-right">
                    <button className="p-2 rounded-full hover:bg-surface-container-high transition-colors text-neutral-400 group-hover:text-on-surface">
                      <span className="material-symbols-outlined">more_vert</span>
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div className="px-6 py-4 bg-surface-container-low border-t border-outline-variant/10 flex items-center justify-between">
          <span className="text-xs font-medium text-secondary">
            Showing <span className="text-on-surface">{orders.length}</span> of <span className="text-on-surface">{result?.totalCount ?? 0}</span> results
          </span>
          <div className="flex items-center gap-1">
            <button
              onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
              disabled={currentPage === 1}
              className="p-1.5 rounded-lg border border-outline-variant/20 hover:bg-surface-container-highest transition-colors disabled:opacity-50"
            >
              <span className="material-symbols-outlined text-sm">chevron_left</span>
            </button>
            {Array.from({ length: Math.min(totalPages, 5) }, (_, i) => i + 1).map((n) => (
              <button
                key={n}
                onClick={() => setCurrentPage(n)}
                className={`w-8 h-8 rounded-lg text-xs font-bold transition-colors ${
                  currentPage === n ? 'bg-primary text-white' : 'hover:bg-surface-container-high'
                }`}
              >
                {n}
              </button>
            ))}
            <button
              onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
              disabled={currentPage >= totalPages}
              className="p-1.5 rounded-lg border border-outline-variant/20 hover:bg-surface-container-highest transition-colors disabled:opacity-50"
            >
              <span className="material-symbols-outlined text-sm">chevron_right</span>
            </button>
          </div>
        </div>
      </div>

      {/* Analytics insight section */}
      <div className="mt-10 grid grid-cols-1 md:grid-cols-3 gap-8">
        {/* Market volatility alert */}
        <div className="md:col-span-2 bg-gradient-to-br from-neutral-900 to-neutral-800 rounded-2xl p-8 text-white relative overflow-hidden shadow-xl">
          <div className="relative z-10 flex justify-between items-start">
            <div>
              <h3 className="text-xl font-bold mb-2">Market Volatility Alert</h3>
              <p className="text-neutral-400 text-sm max-w-sm">
                Prices in Balogun Market have increased by 14% this morning due to logistics disruptions.
                Shoppers are being advised to renegotiate quotes.
              </p>
              <button className="mt-6 px-4 py-2 bg-emerald-500 rounded-full text-xs font-bold uppercase tracking-wider hover:bg-emerald-400 transition-colors">
                Broadcast to Shoppers
              </button>
            </div>
            <span className="hidden lg:block material-symbols-outlined text-emerald-500/20" style={{ fontSize: '120px', fontVariationSettings: "'FILL' 1" }}>
              trending_up
            </span>
          </div>
          <div className="absolute top-0 right-0 w-64 h-full opacity-10 bg-[radial-gradient(circle_at_center,_var(--tw-gradient-stops))] from-emerald-500 via-transparent to-transparent pointer-events-none" />
        </div>

        {/* Average wait time */}
        <div className="bg-surface-container-lowest rounded-2xl p-6 border border-outline-variant/20 shadow-sm flex flex-col justify-center items-center text-center">
          <div className="w-12 h-12 bg-tertiary-fixed-dim rounded-full flex items-center justify-center mb-4">
            <span className="material-symbols-outlined text-on-tertiary-fixed">timer</span>
          </div>
          <h4 className="text-neutral-500 text-[10px] font-bold uppercase tracking-widest mb-1">Average Wait Time</h4>
          <p className="text-3xl font-extrabold text-on-surface">
            18.4 <span className="text-sm font-medium text-neutral-400">min</span>
          </p>
          <div className="mt-4 flex items-center gap-1.5 text-emerald-600 font-bold text-xs">
            <span className="material-symbols-outlined text-sm">arrow_downward</span>
            <span>2.3m faster than yesterday</span>
          </div>
        </div>
      </div>
    </main>
  );
}
