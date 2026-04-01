import { useState, useEffect } from 'react';
import { getEarningsSummary, getPayouts, type AdminEarningsSummaryDto, type AdminPayoutDto, type PagedResult } from '../lib/api';

// ── Types ──────────────────────────────────────────────────────────────────

type PayoutStatus = 'Paid' | 'Processing' | 'Failed';

function fmtNgn(val: number) {
  return '₦' + val.toLocaleString('en-NG', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function fmtDate(iso: string) {
  return new Date(iso).toLocaleString('en-NG', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
}

// ── Sub-components ─────────────────────────────────────────────────────────

function PayoutStatusBadge({ status }: { status: PayoutStatus }) {
  const styles: Record<PayoutStatus, string> = {
    Paid:       'bg-primary-fixed-dim/20 text-on-primary-fixed-variant',
    Processing: 'bg-tertiary-fixed-dim/20 text-on-tertiary-fixed-variant',
    Failed:     'bg-error-container text-on-error-container',
  };
  return (
    <span className={`px-3 py-1 rounded-full text-[10px] font-bold ${styles[status]}`}>
      {status}
    </span>
  );
}

// ── Page ───────────────────────────────────────────────────────────────────

export default function Earnings() {
  const [summary, setSummary] = useState<AdminEarningsSummaryDto | null>(null);
  const [payoutsResult, setPayoutsResult] = useState<PagedResult<AdminPayoutDto> | null>(null);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);

  useEffect(() => {
    Promise.all([
      getEarningsSummary(),
      getPayouts(page, 20)
    ]).then(([s, p]) => {
      setSummary(s);
      setPayoutsResult(p);
    }).finally(() => setLoading(false));
  }, [page]);

  const maxRev = summary ? Math.max(...summary.monthlyChart.map(c => c.revenue), 1) : 1;

  return (
    <main className="pt-10 px-8 pb-12 min-h-screen bg-surface">
      <div className="max-w-7xl mx-auto space-y-10">

        {/* Header */}
        <div className="flex justify-between items-end">
          <div>
            <h2 className="font-bold tracking-tight text-on-surface leading-tight mb-1" style={{ fontSize: '2.75rem' }}>
              Financial Overview
            </h2>
            <p className="text-secondary font-medium">Real-time tracking of platform revenue and merchant payouts.</p>
          </div>
          <div className="flex gap-3">
            <button className="px-6 py-3 rounded-xl bg-secondary-container text-on-secondary-fixed font-semibold text-sm hover:opacity-90 transition-all flex items-center gap-2">
              <span className="material-symbols-outlined text-lg">download</span>
              Export Statement
            </button>
            <button className="px-6 py-3 rounded-xl bg-gradient-to-br from-primary to-primary-container text-white font-bold text-sm shadow-lg hover:brightness-110 transition-all flex items-center gap-2">
              <span className="material-symbols-outlined text-lg">account_balance_wallet</span>
              Initiate Batch Payout
            </button>
          </div>
        </div>

        {loading ? (
          <div className="flex items-center justify-center py-24 text-secondary">
            <div className="w-10 h-10 border-4 border-primary/30 border-t-primary rounded-full animate-spin" />
          </div>
        ) : (<>

        {/* Metric cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {[
            { icon: 'trending_up', iconBg: 'bg-primary/10', iconColor: 'text-primary', bgIcon: 'payments', label: 'Total Revenue', value: fmtNgn(summary?.totalRevenue ?? 0), sub: `${summary?.platformMarginPercent ?? 0}% margin`, subIcon: 'north', subColor: 'text-primary' },
            { icon: 'outbox', iconBg: 'bg-emerald-500/10', iconColor: 'text-emerald-600', bgIcon: 'delivery_dining', label: 'Shopper Payouts', value: fmtNgn(summary?.shopperPayouts ?? 0), sub: `Next: ${summary?.nextPayoutCycle ?? '—'}`, subIcon: null, subColor: 'text-primary' },
            { icon: 'account_balance', iconBg: 'bg-tertiary/10', iconColor: 'text-tertiary', bgIcon: 'token', label: 'Platform Fees', value: fmtNgn(summary?.platformFees ?? 0), sub: `${summary?.platformMarginPercent ?? 0}% Margin`, subIcon: 'insights', subColor: 'text-tertiary' },
          ].map((m) => (
            <div key={m.label} className="bg-surface-container-lowest p-8 rounded-xl shadow-sm border border-outline-variant/15 relative overflow-hidden">
              <div className="absolute top-0 right-0 p-4 opacity-10">
                <span className="material-symbols-outlined text-6xl">{m.bgIcon}</span>
              </div>
              <div className="flex items-center gap-2 mb-4">
                <div className={`p-2 rounded-full ${m.iconBg} ${m.iconColor}`}>
                  <span className="material-symbols-outlined text-xl">{m.icon}</span>
                </div>
                <span className="text-xs font-bold uppercase tracking-widest text-secondary">{m.label}</span>
              </div>
              <span className="text-3xl font-extrabold tracking-tight text-on-surface">{m.value}</span>
              <div className={`mt-2 flex items-center gap-1 text-xs font-bold ${m.subColor}`}>
                {m.subIcon && <span className="material-symbols-outlined text-sm">{m.subIcon}</span>}
                <span>{m.sub}</span>
              </div>
            </div>
          ))}
        </div>

        {/* Chart + insights */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">

          {/* Bar chart */}
          <div className="lg:col-span-8 bg-surface-container-lowest p-8 rounded-xl shadow-sm border border-outline-variant/15">
            <div className="flex justify-between items-center mb-10">
              <div>
                <h3 className="text-lg font-bold text-on-surface">Monthly Revenue &amp; Payouts Trends</h3>
                <p className="text-sm text-secondary">Volume analysis over the last 6 months</p>
              </div>
              <div className="flex gap-4">
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 rounded-full bg-primary-container" />
                  <span className="text-xs font-medium text-secondary">Revenue</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 rounded-full bg-secondary-fixed-dim" />
                  <span className="text-xs font-medium text-secondary">Payouts</span>
                </div>
              </div>
            </div>

            <div className="h-64 flex items-end justify-between gap-4 px-2">
              {(summary?.monthlyChart ?? []).map((bar, i, arr) => {
                const revenueH = Math.max(5, (bar.revenue / maxRev) * 100);
                const payoutH = Math.max(5, (bar.payouts / maxRev) * 100);
                const isCurrent = i === arr.length - 1;
                return (
                  <div key={bar.month} className="flex-1 flex flex-col items-center gap-2">
                    <div className="w-full flex justify-center gap-1 items-end h-full">
                      {isCurrent ? (
                        <>
                          <div className="w-6 bg-secondary-fixed-dim/40 rounded-t-sm border-t border-x border-dashed border-secondary" style={{ height: `${payoutH}%` }} />
                          <div className="w-6 bg-primary-container/40 rounded-t-sm border-t border-x border-dashed border-primary" style={{ height: `${revenueH}%` }} />
                        </>
                      ) : (
                        <>
                          <div className="w-6 bg-secondary-fixed-dim rounded-t-sm" style={{ height: `${payoutH}%` }} />
                          <div className="w-6 bg-primary-container rounded-t-sm" style={{ height: `${revenueH}%` }} />
                        </>
                      )}
                    </div>
                    <span className={`text-[10px] font-bold uppercase ${isCurrent ? 'text-primary' : 'text-secondary'}`}>{bar.month}</span>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Insight column */}
          <div className="lg:col-span-4 flex flex-col gap-6">

            {/* Efficiency insights */}
            <div className="flex-1 bg-surface-container-lowest p-6 rounded-xl shadow-sm border border-outline-variant/15">
              <div className="flex items-center gap-2 mb-6">
                <span className="material-symbols-outlined text-tertiary">bolt</span>
                <h4 className="text-sm font-bold text-on-surface">Efficiency Insights</h4>
              </div>
              <ul className="space-y-4">
                <li className="p-3 rounded-lg bg-surface-container-low flex items-start gap-3">
                  <span className="material-symbols-outlined text-emerald-500 mt-1">verified</span>
                  <div>
                    <p className="text-xs font-bold text-on-surface">Payout Accuracy: 99.9%</p>
                    <p className="text-[10px] text-secondary">Total errors reduced by 40% this quarter.</p>
                  </div>
                </li>
                <li className="p-3 rounded-lg bg-surface-container-low flex items-start gap-3">
                  <span className="material-symbols-outlined text-tertiary mt-1">schedule</span>
                  <div>
                    <p className="text-xs font-bold text-on-surface">Average Payout Delay: 1.2 Days</p>
                    <p className="text-[10px] text-secondary">Aiming for same-day delivery by Dec.</p>
                  </div>
                </li>
              </ul>
            </div>

            {/* Platform goal */}
            <div className="h-40 bg-inverse-surface rounded-xl p-6 text-surface overflow-hidden relative">
              <div className="relative z-10">
                <h4 className="text-sm font-bold mb-2">Platform Goal</h4>
                <p className="text-xs opacity-70 leading-relaxed mb-4">
                  Hitting ₦2.5M revenue will trigger the Tier 2 fee reduction for shoppers.
                </p>
                <div className="w-full bg-white/10 h-2 rounded-full overflow-hidden">
                  <div className="bg-primary-container h-full w-1/2" />
                </div>
                <p className="text-[10px] mt-2 font-medium">50% to target</p>
              </div>
              <span className="material-symbols-outlined absolute -bottom-4 -right-4 text-9xl opacity-5 text-white">
                emoji_events
              </span>
            </div>
          </div>
        </div>

        {/* Payout history table */}
        <div className="bg-surface-container-lowest rounded-xl shadow-sm border border-outline-variant/15 overflow-hidden">
          <div className="px-8 py-6 border-b border-surface-container flex justify-between items-center">
            <h3 className="text-lg font-bold text-on-surface">Payout History</h3>
            <button className="p-2 rounded-lg hover:bg-surface-container transition-colors">
              <span className="material-symbols-outlined text-lg">filter_list</span>
            </button>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead>
                <tr className="bg-surface-container-low/50">
                  {['Shopper', 'Payout Date', 'Amount (₦)', 'Status', 'Actions'].map((h) => (
                    <th key={h} className="px-8 py-4 text-[10px] font-bold uppercase tracking-widest text-secondary">
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-surface-container-low">
                {(payoutsResult?.items ?? []).length === 0 ? (
                  <tr>
                    <td colSpan={5} className="px-8 py-10 text-center text-secondary text-sm">No payouts yet.</td>
                  </tr>
                ) : (payoutsResult?.items ?? []).map((p: AdminPayoutDto) => (
                  <tr key={p.payoutId} className="hover:bg-surface-container-low/30 transition-colors">
                    <td className="px-8 py-5">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-surface-container-highest flex items-center justify-center text-[10px] font-bold flex-shrink-0">
                          {p.shopperInitials}
                        </div>
                        <span className="text-sm font-medium text-on-surface">{p.shopperName}</span>
                      </div>
                    </td>
                    <td className="px-8 py-5 text-sm text-secondary">{fmtDate(p.date)}</td>
                    <td className="px-8 py-5 text-sm font-bold text-on-surface">{fmtNgn(p.amount)}</td>
                    <td className="px-8 py-5">
                      <PayoutStatusBadge status={p.status as PayoutStatus} />
                    </td>
                    <td className="px-8 py-5">
                      <button className="text-secondary hover:text-primary transition-colors">
                        <span className="material-symbols-outlined text-lg">{p.actionIcon}</span>
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          <div className="px-8 py-4 bg-surface-container-low/30 border-t border-surface-container flex items-center justify-between">
            <span className="text-xs text-secondary font-medium">
              Showing {payoutsResult?.items.length ?? 0} of {payoutsResult?.totalCount ?? 0} payouts
            </span>
            <div className="flex gap-2">
              <button
                disabled={page === 1}
                onClick={() => setPage(p => Math.max(1, p - 1))}
                className="p-1 rounded bg-surface-container hover:bg-surface-container-high disabled:opacity-50"
              >
                <span className="material-symbols-outlined text-sm">chevron_left</span>
              </button>
              <button
                disabled={page >= (payoutsResult?.totalPages ?? 1)}
                onClick={() => setPage(p => p + 1)}
                className="p-1 rounded bg-surface-container hover:bg-surface-container-high disabled:opacity-50"
              >
                <span className="material-symbols-outlined text-sm">chevron_right</span>
              </button>
            </div>
          </div>
        </div>

        </>)}
      </div>
    </main>
  );
}
