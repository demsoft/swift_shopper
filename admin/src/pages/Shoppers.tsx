import { useState, useEffect } from 'react';
import { getShoppers, updateShopperStatus, type AdminShopperDto, type PagedResult } from '../lib/api';

// ── Helpers ─────────────────────────────────────────────────────────────────

type VerifStatus = 'Verified' | 'Pending' | 'Action Required';
type OnlineStatus = 'Online' | 'In Job' | 'Offline';
type Tier = 'Gold Elite' | 'Silver Plus' | 'Bronze';

function toTier(tier: string, completed: number): Tier {
  if (tier === 'PRO SHOPPER' || completed >= 100) return 'Gold Elite';
  if (completed >= 50) return 'Silver Plus';
  return 'Bronze';
}

function toVerifStatus(s: AdminShopperDto): VerifStatus {
  if (!s.isActive) return 'Pending';
  if (s.isVerified) return 'Verified';
  return 'Action Required';
}

function fmtNgn(val: number) {
  return '₦' + val.toLocaleString('en-NG', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

// ── Sub-components ─────────────────────────────────────────────────────────

function TierDot({ tier }: { tier: Tier }) {
  const color = tier === 'Gold Elite' ? 'bg-yellow-500' : tier === 'Silver Plus' ? 'bg-slate-400' : 'bg-amber-700';
  return <span className={`w-2 h-2 rounded-full ${color} flex-shrink-0`} />;
}

function VerifBadge({ status }: { status: VerifStatus }) {
  if (status === 'Verified') {
    return (
      <div className="flex items-center gap-1.5 px-2 py-0.5 w-fit rounded-full bg-primary-fixed-dim/30 text-on-primary-fixed-variant">
        <span className="material-symbols-outlined text-xs" style={{ fontVariationSettings: "'FILL' 1" }}>verified</span>
        <span className="text-[10px] font-bold">Verified</span>
      </div>
    );
  }
  if (status === 'Pending') {
    return (
      <div className="flex items-center gap-1.5 px-2 py-0.5 w-fit rounded-full bg-tertiary-fixed-dim/30 text-on-tertiary-container">
        <span className="material-symbols-outlined text-xs">pending</span>
        <span className="text-[10px] font-bold">Pending</span>
      </div>
    );
  }
  return (
    <div className="flex items-center gap-1.5 px-2 py-0.5 w-fit rounded-full bg-error-container text-on-error-container">
      <span className="material-symbols-outlined text-xs">error_outline</span>
      <span className="text-[10px] font-bold">Action Required</span>
    </div>
  );
}

function OnlineDot({ status }: { status: OnlineStatus }) {
  const dot =
    status === 'Online' ? 'bg-emerald-500 animate-pulse' :
    status === 'In Job'  ? 'bg-orange-400' : 'bg-neutral-300';
  return (
    <div className="flex items-center gap-1.5">
      <div className={`w-2 h-2 rounded-full ${dot}`} />
      <span className="text-[11px] font-medium text-secondary">{status}</span>
    </div>
  );
}

function RowActions({ shopperId, isActive, onToggle }: { shopperId: string; isActive: boolean; onToggle: () => void }) {
  const [busy, setBusy] = useState(false);

  async function handleToggle() {
    setBusy(true);
    try {
      await updateShopperStatus(shopperId, !isActive);
      onToggle();
    } catch { /* ignore */ }
    finally { setBusy(false); }
  }

  return (
    <div className="flex items-center justify-end gap-2">
      <button
        onClick={handleToggle}
        disabled={busy}
        className={`text-[11px] font-bold px-4 py-1.5 rounded-lg transition-all disabled:opacity-50 ${
          isActive
            ? 'bg-red-50 text-red-600 hover:bg-red-100'
            : 'bg-secondary-container text-on-secondary-fixed hover:bg-emerald-500 hover:text-white'
        }`}
      >
        {isActive ? 'Suspend' : 'Activate'}
      </button>
    </div>
  );
}

// ── Page ───────────────────────────────────────────────────────────────────

export default function Shoppers() {
  const [tab, setTab] = useState<'all' | 'pending'>('all');
  const [currentPage, setCurrentPage] = useState(1);
  const [result, setResult] = useState<PagedResult<AdminShopperDto> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [viewingImage, setViewingImage] = useState<{ url: string; name: string } | null>(null);

  function load() {
    setLoading(true);
    getShoppers(tab, currentPage, 20)
      .then(setResult)
      .catch(e => setError(e.message))
      .finally(() => setLoading(false));
  }

  useEffect(() => { load(); }, [tab, currentPage]);

  const displayed = result?.items ?? [];

  return (
    <section className="pt-10 pb-12 px-10 min-h-screen">
      {/* Image viewer modal */}
      {viewingImage && (
        <div
          className="fixed inset-0 z-[200] bg-black/80 flex items-center justify-center"
          onClick={() => setViewingImage(null)}
        >
          <div className="relative" onClick={e => e.stopPropagation()}>
            <img
              src={viewingImage.url}
              alt={viewingImage.name}
              className="max-h-[80vh] max-w-[80vw] rounded-2xl object-contain shadow-2xl"
            />
            <p className="text-center text-white text-sm font-semibold mt-3">{viewingImage.name}</p>
            <button
              onClick={() => setViewingImage(null)}
              className="absolute -top-3 -right-3 w-8 h-8 bg-white rounded-full flex items-center justify-center shadow-lg hover:bg-neutral-100"
            >
              <span className="material-symbols-outlined text-sm text-neutral-700">close</span>
            </button>
          </div>
        </div>
      )}

      {/* Header */}
      <div className="flex justify-between items-end mb-10">
        <div>
          <h2 className="text-on-surface font-extrabold tracking-tight text-4xl mb-2">Shopper Management</h2>
          <p className="text-secondary text-sm font-medium">Review and verify personal shoppers across Lagos metro area.</p>
        </div>
        <div className="flex gap-4">
          <div className="flex gap-2 p-1 bg-surface-container-low rounded-xl">
            <button
              onClick={() => setTab('all')}
              className={`px-4 py-2 rounded-lg text-xs font-bold transition-all ${
                tab === 'all' ? 'bg-surface-container-lowest shadow-sm text-on-surface' : 'text-secondary hover:bg-surface-container-lowest'
              }`}
            >
              All Shoppers
            </button>
            <button
              onClick={() => setTab('pending')}
              className={`px-4 py-2 rounded-lg text-xs font-bold transition-all ${
                tab === 'pending' ? 'bg-surface-container-lowest shadow-sm text-on-surface' : 'text-secondary hover:bg-surface-container-lowest'
              }`}
            >
              Pending Verification
            </button>
          </div>
          <button className="bg-gradient-to-br from-primary to-primary-container text-white px-6 py-2.5 rounded-full text-sm font-bold flex items-center gap-2 shadow-lg hover:shadow-emerald-500/20 active:scale-95 transition-all">
            <span className="material-symbols-outlined text-[20px]">person_add</span>
            Onboard New Shopper
          </button>
        </div>
      </div>

      {/* Filter bento */}
      <div className="grid grid-cols-12 gap-6 mb-8">
        <div className="col-span-8 bg-surface-container-lowest p-6 rounded-xl shadow-sm border border-outline-variant/15 flex items-center justify-between">
          <div className="flex gap-6 items-center">
            <div className="flex flex-col gap-1.5">
              <label className="text-[10px] uppercase tracking-wider font-bold text-secondary">Shopper Tier</label>
              <select className="bg-surface-container-low border-none rounded-lg text-xs font-medium py-2 px-4 focus:ring-emerald-500/20 focus:outline-none">
                <option>All Tiers</option>
                <option>Gold Elite</option>
                <option>Silver Plus</option>
                <option>Bronze Standard</option>
              </select>
            </div>
            <div className="flex flex-col gap-1.5">
              <label className="text-[10px] uppercase tracking-wider font-bold text-secondary">Minimum Rating</label>
              <div className="flex gap-1 items-center bg-surface-container-low px-3 py-1 rounded-lg">
                <span className="material-symbols-outlined text-tertiary text-sm" style={{ fontVariationSettings: "'FILL' 1" }}>star</span>
                <span className="text-xs font-bold">4.0+</span>
              </div>
            </div>
            <div className="flex flex-col gap-1.5">
              <label className="text-[10px] uppercase tracking-wider font-bold text-secondary">Status</label>
              <div className="flex gap-2">
                <span className="px-3 py-1 bg-emerald-100 text-emerald-700 text-[10px] font-bold rounded-full">Online</span>
                <span className="px-3 py-1 bg-neutral-100 text-neutral-500 text-[10px] font-bold rounded-full">Offline</span>
              </div>
            </div>
          </div>
          <button className="text-emerald-600 text-xs font-bold hover:underline flex items-center gap-1">
            <span className="material-symbols-outlined text-sm">filter_list</span>
            Reset Filters
          </button>
        </div>

        <div className="col-span-4 bg-primary text-white p-6 rounded-xl shadow-lg flex flex-col justify-between relative overflow-hidden">
          <div className="relative z-10">
            <p className="text-primary-fixed-dim text-xs font-bold uppercase tracking-widest mb-1">Total Shoppers</p>
            <h3 className="text-4xl font-black tracking-tighter">{result?.totalCount ?? '–'}</h3>
          </div>
          <div className="relative z-10 flex items-center gap-2 text-emerald-300 text-xs">
            <span className="material-symbols-outlined text-sm">person</span>
            <span>{tab === 'pending' ? 'Pending verification' : 'All shoppers'}</span>
          </div>
          <div className="absolute -right-6 -bottom-6 w-32 h-32 bg-emerald-400/20 rounded-full blur-3xl" />
        </div>
      </div>

      {/* Table */}
      <div className="bg-surface-container-lowest rounded-xl shadow-sm border border-outline-variant/15 overflow-hidden">
        <table className="w-full text-left border-collapse">
          <thead className="bg-surface-container-low border-b border-outline-variant/10">
            <tr>
              {['Shopper', 'Tier', 'Performance', 'Status & Verif.', 'Activity', 'Actions'].map((h, i) => (
                <th key={h} className={`px-6 py-4 text-xs uppercase tracking-[0.05em] font-bold text-secondary ${i === 5 ? 'text-right' : ''}`}>
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-surface-container-low">
            {loading ? (
              <tr>
                <td colSpan={6} className="px-6 py-16 text-center text-secondary">
                  <div className="flex flex-col items-center gap-3">
                    <div className="w-8 h-8 border-4 border-primary/30 border-t-primary rounded-full animate-spin" />
                    <span className="text-sm">Loading shoppers...</span>
                  </div>
                </td>
              </tr>
            ) : error ? (
              <tr><td colSpan={6} className="px-6 py-10 text-center text-red-600 text-sm">{error}</td></tr>
            ) : displayed.length === 0 ? (
              <tr><td colSpan={6} className="px-6 py-10 text-center text-secondary text-sm">No shoppers found.</td></tr>
            ) : displayed.map((s: AdminShopperDto) => {
              const tier = toTier(s.tier, s.completedOrders);
              const verifStatus = toVerifStatus(s);
              const onlineStatus: OnlineStatus = s.isOnline ? 'Online' : 'Offline';
              const ratingPct = Math.round((s.rating / 5) * 100);
              return (
                <tr key={s.shopperId} className="hover:bg-surface transition-colors group">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      {s.avatarUrl ? (
                        <img
                          src={s.avatarUrl}
                          alt={s.fullName}
                          className="w-10 h-10 rounded-full object-cover flex-shrink-0 cursor-pointer hover:ring-2 hover:ring-primary transition-all"
                          onClick={() => setViewingImage({ url: s.avatarUrl!, name: s.fullName })}
                        />
                      ) : (
                        <div className="w-10 h-10 rounded-full bg-surface-container-high flex items-center justify-center text-xs font-bold text-secondary flex-shrink-0">
                          {s.initials}
                        </div>
                      )}
                      <div>
                        <p className="text-sm font-semibold text-on-surface">{s.fullName}</p>
                        <p className="text-xs text-secondary">{s.email}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-1.5">
                      <TierDot tier={tier} />
                      <span className="text-xs font-medium text-on-surface">{tier}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex flex-col gap-1">
                      <div className="flex items-center gap-1 text-on-surface">
                        <span className="material-symbols-outlined text-tertiary text-sm" style={{ fontVariationSettings: "'FILL' 1" }}>star</span>
                        <span className="text-sm font-bold text-on-surface">{Number(s.rating).toFixed(1)}</span>
                      </div>
                      <div className="w-20 h-1 bg-surface-container-high rounded-full overflow-hidden">
                        <div className="h-full bg-tertiary rounded-full" style={{ width: `${ratingPct}%` }} />
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex flex-col gap-2">
                      <VerifBadge status={verifStatus} />
                      <OnlineDot status={onlineStatus} />
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex flex-col">
                      <span className="text-sm font-bold text-on-surface">{fmtNgn(s.earningsThisMonth)}</span>
                      <span className="text-xs text-secondary">{s.completedOrders} Trips total</span>
                    </div>
                  </td>
                  <td className="px-6 py-5 text-right">
                    <RowActions shopperId={s.shopperId} isActive={s.isActive} onToggle={load} />
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>

        {/* Pagination */}
        <div className="px-8 py-5 border-t border-outline-variant/10 flex items-center justify-between bg-surface-container-lowest">
          <span className="text-[11px] font-medium text-secondary">
            Showing {displayed.length} of {result?.totalCount ?? 0} shoppers
          </span>
          <div className="flex gap-2">
            <button
              onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
              disabled={currentPage === 1}
              className="p-2 rounded-lg border border-outline-variant/20 text-secondary hover:bg-surface transition-all disabled:opacity-50"
            >
              <span className="material-symbols-outlined">chevron_left</span>
            </button>
            {Array.from({ length: Math.min(result?.totalPages ?? 1, 5) }, (_, i) => i + 1).map((n) => (
              <button
                key={n}
                onClick={() => setCurrentPage(n)}
                className={`w-8 h-8 rounded-lg text-xs font-bold flex items-center justify-center transition-all ${
                  currentPage === n ? 'bg-primary text-white' : 'hover:bg-surface-container-low text-secondary'
                }`}
              >
                {n}
              </button>
            ))}
            <button
              onClick={() => setCurrentPage((p) => Math.min(result?.totalPages ?? 1, p + 1))}
              disabled={currentPage >= (result?.totalPages ?? 1)}
              className="p-2 rounded-lg border border-outline-variant/20 text-secondary hover:bg-surface transition-all disabled:opacity-50"
            >
              <span className="material-symbols-outlined">chevron_right</span>
            </button>
          </div>
        </div>
      </div>

      {/* Insight footer */}
      <div className="mt-10 grid grid-cols-12 gap-8">
        <div className="col-span-4 p-8 bg-surface-container-low rounded-2xl relative overflow-hidden">
          <span className="material-symbols-outlined text-4xl text-primary/10 absolute -right-2 -top-2 scale-150 rotate-12">speed</span>
          <h4 className="text-lg font-extrabold tracking-tight mb-2">Efficiency Rating</h4>
          <p className="text-secondary text-xs leading-relaxed mb-6">
            Gold shoppers are averaging 14% faster delivery times this week across Victoria Island and Lekki Phase 1 districts.
          </p>
          <div className="flex justify-between items-end">
            <span className="text-3xl font-black text-primary">94.2%</span>
            <button className="text-[10px] font-black uppercase tracking-widest text-primary hover:underline">View Analytics</button>
          </div>
        </div>

        <div className="col-span-8 flex flex-col justify-center">
          <div className="flex gap-12 border-l border-outline-variant/30 pl-12">
            <div>
              <p className="text-[10px] uppercase tracking-widest font-black text-secondary mb-1">Weekly Payouts</p>
              <p className="text-2xl font-extrabold tracking-tighter">₦14,802,000</p>
            </div>
            <div>
              <p className="text-[10px] uppercase tracking-widest font-black text-secondary mb-1">Average Trip Rating</p>
              <div className="flex items-center gap-1.5">
                <p className="text-2xl font-extrabold tracking-tighter">4.82</p>
                <span className="material-symbols-outlined text-emerald-500 text-lg">trending_up</span>
              </div>
            </div>
            <div>
              <p className="text-[10px] uppercase tracking-widest font-black text-secondary mb-1">Shopper Churn</p>
              <p className="text-2xl font-extrabold tracking-tighter text-error">1.2%</p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
