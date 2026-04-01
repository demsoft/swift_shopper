import { useState, useEffect } from 'react';
import { getCustomers, updateCustomerStatus, type AdminCustomerDto, type PagedResult } from '../lib/api';

// ── Types / helpers ─────────────────────────────────────────────────────────

type Membership = 'Premium' | 'Basic';
type CustomerStatus = 'Active' | 'Suspended';
type FilterTab = 'All Customers' | 'Premium Only' | 'Basic Only' | 'Active' | 'Suspended';

const filterTabs: FilterTab[] = ['All Customers', 'Premium Only', 'Basic Only', 'Active', 'Suspended'];

function fmtNgn(val: number) {
  return '₦' + val.toLocaleString('en-NG', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function fmtDate(iso: string | null) {
  if (!iso) return '—';
  return new Date(iso).toLocaleDateString('en-NG', { day: 'numeric', month: 'short', year: 'numeric' });
}

const barHeights = [40, 65, 35, 85, 70, 50, 95, 60, 30, 45, 75, 100];

// ── Sub-components ─────────────────────────────────────────────────────────

function MembershipBadge({ membership }: { membership: Membership }) {
  if (membership === 'Premium') {
    return (
      <span className="px-3 py-1 bg-primary-fixed-dim/20 text-on-primary-fixed-variant text-[0.7rem] font-bold uppercase tracking-wider rounded-full">
        Premium
      </span>
    );
  }
  return (
    <span className="px-3 py-1 bg-surface-container-highest text-on-surface-variant text-[0.7rem] font-bold uppercase tracking-wider rounded-full">
      Basic
    </span>
  );
}

function StatusCell({ status }: { status: CustomerStatus }) {
  if (status === 'Active') {
    return (
      <div className="flex items-center gap-1.5">
        <div className="w-2 h-2 rounded-full bg-emerald-500" />
        <span className="text-sm font-medium text-emerald-700">Active</span>
      </div>
    );
  }
  return (
    <div className="flex items-center gap-1.5">
      <div className="w-2 h-2 rounded-full bg-error" />
      <span className="text-sm font-medium text-error">Suspended</span>
    </div>
  );
}

// ── Page ───────────────────────────────────────────────────────────────────

export default function Customers() {
  const [activeFilter, setActiveFilter] = useState<FilterTab>('All Customers');
  const [currentPage, setCurrentPage] = useState(1);
  const [result, setResult] = useState<PagedResult<AdminCustomerDto> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  function load() {
    setLoading(true);
    const membership = activeFilter === 'Premium Only' ? 'Premium' : activeFilter === 'Basic Only' ? 'Basic' : undefined;
    const status = activeFilter === 'Active' ? 'active' : activeFilter === 'Suspended' ? 'inactive' : undefined;
    getCustomers(membership, status, currentPage, 20)
      .then(setResult)
      .catch(e => setError(e.message))
      .finally(() => setLoading(false));
  }

  useEffect(() => { load(); }, [activeFilter, currentPage]);

  const filtered = result?.items ?? [];

  return (
    <section className="pt-10 px-8 pb-12 min-h-screen">
      {/* Header */}
      <div className="flex justify-between items-end mb-10">
        <div>
          <h1 className="text-4xl font-bold tracking-tight text-on-surface mb-2">Customer Management</h1>
          <p className="text-secondary font-medium">Manage and monitor your directory of registered users in Lagos.</p>
        </div>
        <div className="flex gap-3">
          <button className="px-6 py-2.5 bg-secondary-container text-on-secondary-container rounded-full font-semibold text-sm hover:brightness-95 transition-all active:scale-95 flex items-center gap-2">
            <span className="material-symbols-outlined text-[18px]">download</span>
            Export CSV
          </button>
          <button className="px-6 py-2.5 bg-gradient-to-br from-primary to-primary-container text-white rounded-full font-bold text-sm shadow-lg shadow-emerald-500/20 hover:scale-[1.02] transition-all active:scale-95 flex items-center gap-2">
            <span className="material-symbols-outlined text-[18px]">person_add</span>
            Add New Customer
          </button>
        </div>
      </div>

      {/* Filter bar */}
      <div className="grid grid-cols-12 gap-6 mb-8">
        <div className="col-span-12 lg:col-span-8 flex items-center gap-2 bg-surface-container-low p-2 rounded-full">
          {filterTabs.map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveFilter(tab)}
              className={`px-4 py-2 rounded-full text-sm font-medium transition-colors ${
                activeFilter === tab
                  ? 'bg-surface-container-lowest shadow-sm text-on-surface flex items-center gap-2'
                  : 'text-secondary hover:bg-surface-container-high'
              }`}
            >
              {activeFilter === tab && (
                <span className="material-symbols-outlined text-emerald-600 text-[18px]">filter_list</span>
              )}
              {tab}
            </button>
          ))}
        </div>

        <div className="col-span-12 lg:col-span-4 flex justify-end">
          <div className="flex items-center gap-2 bg-surface-container-lowest border border-outline-variant/15 px-4 py-2 rounded-full shadow-sm">
            <span className="text-xs font-bold uppercase tracking-wider text-secondary">Sort by:</span>
            <select className="bg-transparent border-none text-sm font-semibold focus:outline-none focus:ring-0 cursor-pointer">
              <option>Recently Joined</option>
              <option>Total Spend</option>
              <option>Alphabetical</option>
            </select>
          </div>
        </div>
      </div>

      {/* Table */}
      <div className="bg-surface-container-lowest rounded-xl shadow-2xl shadow-neutral-200/50 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-low">
                {['Customer', 'Email Address', 'Orders', 'Last Order', 'Total Spend', 'Membership', 'Status', 'Actions'].map((h, i) => (
                  <th key={h} className={`px-6 py-4 text-[0.75rem] font-bold uppercase tracking-[0.05em] text-secondary ${i === 2 ? 'text-center' : ''}`}>
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-surface-container-low">
              {loading ? (
                <tr>
                  <td colSpan={8} className="px-6 py-16 text-center text-secondary">
                    <div className="flex flex-col items-center gap-3">
                      <div className="w-8 h-8 border-4 border-primary/30 border-t-primary rounded-full animate-spin" />
                      <span className="text-sm">Loading customers...</span>
                    </div>
                  </td>
                </tr>
              ) : error ? (
                <tr><td colSpan={8} className="px-6 py-10 text-center text-red-600 text-sm">{error}</td></tr>
              ) : filtered.length === 0 ? (
                <tr><td colSpan={8} className="px-6 py-10 text-center text-secondary text-sm">No customers found.</td></tr>
              ) : filtered.map((c: AdminCustomerDto, idx: number) => (
                <tr
                  key={c.customerId}
                  className={`hover:bg-surface-container-low/30 transition-colors ${idx % 2 !== 0 ? 'bg-surface-container-low/20' : ''}`}
                >
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className={`w-10 h-10 rounded-full ${c.avatarBg} flex items-center justify-center ${c.avatarText} font-bold text-sm flex-shrink-0`}>
                        {c.initials}
                      </div>
                      <div className="flex flex-col">
                        <span className="text-sm font-semibold text-on-surface">{c.fullName}</span>
                        <span className="text-[0.7rem] text-secondary font-medium">ID: {c.customerId.slice(-6).toUpperCase()}</span>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-sm text-secondary">{c.email}</td>
                  <td className="px-6 py-4 text-sm font-bold text-on-surface text-center">{c.totalOrders}</td>
                  <td className="px-6 py-4 text-sm text-secondary">{fmtDate(c.lastOrderAt)}</td>
                  <td className="px-6 py-4 text-sm font-bold text-on-surface">{fmtNgn(c.totalSpend)}</td>
                  <td className="px-6 py-4">
                    <MembershipBadge membership={c.membership as Membership} />
                  </td>
                  <td className="px-6 py-4">
                    <StatusCell status={c.isActive ? 'Active' : 'Suspended'} />
                  </td>
                  <td className="px-6 py-4">
                    <button
                      onClick={() => updateCustomerStatus(c.customerId, !c.isActive).then(load)}
                      className="p-2 hover:bg-surface-container-high rounded-full transition-colors text-secondary"
                      title={c.isActive ? 'Suspend' : 'Activate'}
                    >
                      <span className="material-symbols-outlined text-[20px]">{c.isActive ? 'block' : 'check_circle'}</span>
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div className="px-6 py-4 bg-surface-container-low/50 flex items-center justify-between border-t border-outline-variant/10">
          <span className="text-xs font-medium text-secondary">
            Showing {filtered.length} of {result?.totalCount ?? 0} customers
          </span>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
              disabled={currentPage === 1}
              className="p-2 bg-surface-container-lowest border border-outline-variant/20 rounded-lg text-secondary hover:text-emerald-500 transition-colors disabled:opacity-50"
            >
              <span className="material-symbols-outlined text-[18px]">chevron_left</span>
            </button>
            <div className="flex items-center gap-1">
              {Array.from({ length: Math.min(result?.totalPages ?? 1, 5) }, (_, i) => i + 1).map((n) => (
                <button
                  key={n}
                  onClick={() => setCurrentPage(n)}
                  className={`w-8 h-8 rounded-lg text-xs font-bold transition-colors ${
                    currentPage === n
                      ? 'bg-emerald-600 text-white'
                      : 'bg-surface-container-lowest border border-outline-variant/20 text-on-surface hover:border-emerald-500'
                  }`}
                >
                  {n}
                </button>
              ))}
            </div>
            <button
              onClick={() => setCurrentPage((p) => Math.min(result?.totalPages ?? 1, p + 1))}
              disabled={currentPage >= (result?.totalPages ?? 1)}
              className="p-2 bg-surface-container-lowest border border-outline-variant/20 rounded-lg text-secondary hover:text-emerald-500 transition-colors disabled:opacity-50"
            >
              <span className="material-symbols-outlined text-[18px]">chevron_right</span>
            </button>
          </div>
        </div>
      </div>

      {/* Insights bento */}
      <div className="mt-12 grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Growth trends chart */}
        <div className="md:col-span-2 bg-surface-container-lowest p-8 rounded-xl shadow-sm border border-outline-variant/10">
          <div className="flex justify-between items-start mb-6">
            <div>
              <h3 className="text-xl font-bold text-on-surface">Growth Trends</h3>
              <p className="text-sm text-secondary">Monthly registration volume vs churn rate.</p>
            </div>
            <div className="flex gap-4">
              <div className="flex items-center gap-1">
                <div className="w-2 h-2 rounded-full bg-emerald-500" />
                <span className="text-[0.7rem] font-bold text-secondary uppercase">New Users</span>
              </div>
              <div className="flex items-center gap-1">
                <div className="w-2 h-2 rounded-full bg-neutral-300" />
                <span className="text-[0.7rem] font-bold text-secondary uppercase">Retention</span>
              </div>
            </div>
          </div>
          <div className="h-48 flex items-end gap-2 px-2">
            {barHeights.map((h, i) => (
              <div
                key={i}
                className={`flex-1 rounded-t-lg transition-all ${h >= 60 ? 'bg-emerald-500' : 'bg-surface-container-high'} ${h === 100 ? 'bg-emerald-600' : ''}`}
                style={{ height: `${h}%` }}
              />
            ))}
          </div>
        </div>

        {/* Membership insights */}
        <div className="bg-tertiary-container text-white p-8 rounded-xl shadow-lg relative overflow-hidden flex flex-col justify-between">
          <div className="relative z-10">
            <span className="material-symbols-outlined text-4xl mb-4 opacity-80 block" style={{ fontVariationSettings: "'FILL' 1" }}>
              star
            </span>
            <h3 className="text-2xl font-bold tracking-tight mb-2">Membership Insights</h3>
            <p className="text-white/80 text-sm">
              62% of your revenue comes from the top 15% Premium customers.
            </p>
          </div>
          <div className="relative z-10 mt-6">
            <button className="w-full py-3 bg-white text-tertiary font-bold rounded-full hover:bg-white/90 transition-all active:scale-95">
              View Loyalty Program
            </button>
          </div>
          <div className="absolute -bottom-10 -right-10 w-40 h-40 bg-white/10 rounded-full blur-3xl" />
          <div className="absolute -top-10 -left-10 w-32 h-32 bg-on-tertiary-container/20 rounded-full blur-2xl" />
        </div>
      </div>

      {/* FAB */}
      <button className="fixed bottom-8 right-8 z-[70] w-14 h-14 bg-gradient-to-br from-primary to-primary-container rounded-full shadow-2xl flex items-center justify-center text-white hover:scale-110 active:scale-90 transition-all">
        <span className="material-symbols-outlined text-[28px]" style={{ fontVariationSettings: "'FILL' 1" }}>add</span>
      </button>
    </section>
  );
}
