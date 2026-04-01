import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { getMarkets, type AdminMarketDto } from '../lib/api';

// ── Types ──────────────────────────────────────────────────────────────────

type MarketStatus = 'Active' | 'Out of Service';
type ViewMode = 'table' | 'map';

interface Market {
  id: string;
  icon: string;
  iconColor: string;
  name: string;
  type: string;
  location: string;
  zone: string;
  status: MarketStatus;
  categories: string[];
  activeShoppers: number;
  ordersToday: number;
  pinX: number;
  pinY: number;
}

// ── Helpers ─────────────────────────────────────────────────────────────────

function typeIcon(type: string): string {
  if (type === 'Supermarket') return 'storefront';
  if (type === 'OpenMarket' || type === 'Open Market') return 'shopping_basket';
  if (type === 'Specialty') return 'star';
  if (type === 'Mall') return 'local_mall';
  return 'storefront';
}

// Deterministic pseudo-random pin position from market ID
function pinPos(id: string, axis: 'x' | 'y'): number {
  let hash = 0;
  const seed = id + axis;
  for (let i = 0; i < seed.length; i++) hash = (hash * 31 + seed.charCodeAt(i)) & 0xffff;
  return 15 + (hash % 70); // 15–85%
}

function toMarket(dto: AdminMarketDto): Market {
  return {
    id: dto.marketId,
    icon: typeIcon(dto.type),
    iconColor: dto.isActive ? 'text-primary' : 'text-secondary',
    name: dto.name,
    type: dto.type,
    location: dto.location || dto.address || '—',
    zone: dto.zone || '—',
    status: dto.isActive ? 'Active' : 'Out of Service',
    categories: dto.categories,
    activeShoppers: dto.activeShoppers,
    ordersToday: dto.ordersToday,
    pinX: pinPos(dto.marketId, 'x'),
    pinY: pinPos(dto.marketId, 'y'),
  };
}


// ── Sub-components ─────────────────────────────────────────────────────────

function StatusBadge({ status }: { status: MarketStatus }) {
  if (status === 'Active') {
    return (
      <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-primary-fixed-dim/20 text-on-primary-fixed-variant text-[10px] font-bold uppercase tracking-wide">
        <span className="w-1.5 h-1.5 bg-primary-container rounded-full" />
        Active
      </span>
    );
  }
  return (
    <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-error-container text-on-error-container text-[10px] font-bold uppercase tracking-wide">
      <span className="w-1.5 h-1.5 bg-error rounded-full" />
      Out of Service
    </span>
  );
}

function MapPin({ market, selected, onClick }: { market: Market; selected: boolean; onClick: () => void }) {
  const colour =
    market.status === 'Active' ? 'bg-primary-container border-primary' : 'bg-error border-error';
  return (
    <button
      onClick={onClick}
      style={{ left: `${market.pinX}%`, top: `${market.pinY}%` }}
      className="absolute -translate-x-1/2 -translate-y-1/2 group"
    >
      {/* Pulse ring for active */}
      {market.status === 'Active' && (
        <span className="absolute inset-0 rounded-full bg-primary-container animate-ping opacity-30" />
      )}
      <div className={`w-5 h-5 rounded-full border-2 ${colour} shadow-lg transition-transform group-hover:scale-125 ${selected ? 'scale-150' : ''}`} />
      {/* Tooltip */}
      <div className={`absolute bottom-full left-1/2 -translate-x-1/2 mb-2 pointer-events-none transition-all ${selected ? 'opacity-100 scale-100' : 'opacity-0 scale-95 group-hover:opacity-100 group-hover:scale-100'}`}>
        <div className="bg-inverse-surface text-inverse-on-surface text-[10px] font-bold px-3 py-1.5 rounded-lg whitespace-nowrap shadow-xl">
          {market.name}
          <br />
          <span className="font-normal opacity-70">{market.location}</span>
        </div>
        <div className="w-2 h-2 bg-inverse-surface rotate-45 mx-auto -mt-1" />
      </div>
    </button>
  );
}

// ── Page ───────────────────────────────────────────────────────────────────

export default function Markets() {
  const navigate = useNavigate();
  const [viewMode, setViewMode] = useState<ViewMode>('table');
  const [currentPage, setCurrentPage] = useState(1);
  const [selectedMarket, setSelectedMarket] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [mapPipExpanded, setMapPipExpanded] = useState(false);
  const [markets, setMarkets] = useState<Market[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [typeFilter, setTypeFilter] = useState('');
  const [totalPages, setTotalPages] = useState(1);

  useEffect(() => {
    setLoading(true);
    getMarkets(typeFilter || undefined, undefined, currentPage, 20)
      .then((res) => {
        setMarkets(res.items.map(toMarket));
        setTotalCount(res.totalCount);
        setTotalPages(res.totalPages);
      })
      .finally(() => setLoading(false));
  }, [currentPage, typeFilter]);

  const filtered = markets.filter((m) =>
    search === '' ||
    m.name.toLowerCase().includes(search.toLowerCase()) ||
    m.location.toLowerCase().includes(search.toLowerCase()) ||
    m.type.toLowerCase().includes(search.toLowerCase())
  );

  const activeMarket = markets.find((m) => m.id === selectedMarket) ?? null;
  const activeCount = markets.filter(m => m.status === 'Active').length;

  return (
    <main className="pt-10 px-8 pb-32 min-h-screen bg-surface">
      <div className="max-w-7xl mx-auto">

        {/* ── Header ──────────────────────────────────────────────── */}
        <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 mb-10">
          <div>
            <h2 className="text-4xl font-extrabold tracking-tight text-on-surface mb-2">Market Directory</h2>
            <p className="text-secondary text-sm">Managing {totalCount} market hubs across Lagos Metropolitan area.</p>
          </div>
          <div className="flex items-center gap-3">
            <div className="flex bg-surface-container-high p-1 rounded-xl">
              {(['table', 'map'] as ViewMode[]).map((mode) => (
                <button
                  key={mode}
                  onClick={() => setViewMode(mode)}
                  className={`px-4 py-2 rounded-lg text-xs font-bold flex items-center gap-2 transition-colors capitalize ${
                    viewMode === mode
                      ? 'bg-surface-container-lowest shadow-sm text-primary'
                      : 'text-secondary hover:text-primary'
                  }`}
                >
                  <span className="material-symbols-outlined text-sm">
                    {mode === 'table' ? 'list' : 'map'}
                  </span>
                  {mode === 'table' ? 'Table View' : 'Map View'}
                </button>
              ))}
            </div>
            <button
              onClick={() => navigate('/markets/add')}
              className="bg-gradient-to-br from-primary to-primary-container text-white px-6 py-3 rounded-xl font-bold text-sm shadow-lg shadow-primary/20 flex items-center gap-2 hover:opacity-90 transition-all active:scale-95"
            >
              <span className="material-symbols-outlined">add_circle</span>
              Add New Market
            </button>
          </div>
        </div>

        {/* ── Stats bento ─────────────────────────────────────────── */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-6 mb-10">
          {[
            { label: 'Total Markets',    value: String(totalCount),  badge: null, extra: null },
            { label: 'Active Hubs',      value: String(activeCount), badge: null, extra: null },
            { label: 'Active Geofences', value: String(totalCount),  badge: null, extra: 'near_me' },
            { label: 'Service Status',   value: totalCount > 0 ? Math.round((activeCount / totalCount) * 100) + '%' : '—', badge: null, extra: 'pulse' },
          ].map((s) => (
            <div key={s.label} className="bg-surface-container-lowest p-6 rounded-xl border border-outline-variant/15 shadow-sm">
              <p className="text-[10px] font-bold text-secondary uppercase tracking-widest mb-4">{s.label}</p>
              <div className="flex items-end justify-between">
                <h3 className="text-3xl font-bold text-on-surface">{s.value}</h3>
                {s.extra === 'near_me' && (
                  <span className="material-symbols-outlined text-primary-container">near_me</span>
                )}
                {s.extra === 'pulse' && (
                  <span className="w-3 h-3 bg-primary-container rounded-full animate-pulse" />
                )}
              </div>
            </div>
          ))}
        </div>

        {/* ── TABLE VIEW ──────────────────────────────────────────── */}
        {viewMode === 'table' && (
          <>
            {/* Search + filter bar */}
            <div className="flex flex-col sm:flex-row gap-4 mb-6">
              <div className="relative flex-1 max-w-sm">
                <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-secondary text-lg">search</span>
                <input
                  type="text"
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  placeholder="Search markets, locations…"
                  className="w-full pl-10 pr-4 py-2.5 rounded-xl bg-surface-container-lowest border border-outline-variant/20 text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 placeholder:text-secondary/50"
                />
              </div>
              <div className="flex gap-3 items-center">
                <select
                  value={typeFilter}
                  onChange={e => { setTypeFilter(e.target.value); setCurrentPage(1); }}
                  className="appearance-none bg-surface-container-lowest border border-outline-variant/20 rounded-xl px-4 py-2.5 text-sm text-on-surface focus:outline-none focus:ring-2 focus:ring-primary/20 cursor-pointer"
                >
                  <option value="">All Types</option>
                  <option value="Supermarket">Supermarket</option>
                  <option value="OpenMarket">Open Market</option>
                  <option value="Specialty">Specialty</option>
                  <option value="Mall">Mall</option>
                </select>
                <select className="appearance-none bg-surface-container-lowest border border-outline-variant/20 rounded-xl px-4 py-2.5 text-sm text-on-surface focus:outline-none focus:ring-2 focus:ring-primary/20 cursor-pointer">
                  <option>All Zones</option>
                  <option>Lekki</option>
                  <option>Island</option>
                  <option>Mainland</option>
                </select>
                <button className="p-2.5 rounded-xl border border-outline-variant/20 bg-surface-container-lowest hover:bg-surface-container-low transition-colors text-secondary">
                  <span className="material-symbols-outlined text-lg">filter_list</span>
                </button>
              </div>
            </div>

            <div className="bg-surface-container-lowest rounded-2xl border border-outline-variant/15 overflow-hidden shadow-sm">
              <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="bg-surface-container-low">
                      {['Market Name', 'Type', 'Location', 'Status', 'Today', 'Categories', 'Actions'].map((h, i) => (
                        <th
                          key={h}
                          className={`px-6 py-4 text-[11px] font-bold text-on-secondary-container uppercase tracking-widest ${i === 6 ? 'text-right' : ''}`}
                        >
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
                            <span className="text-sm">Loading markets...</span>
                          </div>
                        </td>
                      </tr>
                    ) : filtered.length === 0 ? (
                      <tr>
                        <td colSpan={7} className="px-6 py-16 text-center text-secondary text-sm">
                          {search ? 'No markets match your search.' : 'No markets added yet.'}
                        </td>
                      </tr>
                    ) : filtered.map((m) => (
                      <tr key={m.id} className="hover:bg-surface-container/30 transition-colors group">
                        {/* Name */}
                        <td className="px-6 py-5">
                          <div className="flex items-center gap-4">
                            <div className={`w-10 h-10 rounded-xl bg-surface-container flex items-center justify-center ${m.iconColor} group-hover:bg-primary-fixed-dim/20 transition-colors flex-shrink-0`}>
                              <span className="material-symbols-outlined">{m.icon}</span>
                            </div>
                            <div>
                              <p className="text-sm font-bold text-on-surface">{m.name}</p>
                              <p className="text-xs text-secondary">ID: {m.id.slice(-6).toUpperCase()}</p>
                            </div>
                          </div>
                        </td>

                        {/* Type */}
                        <td className="px-6 py-5">
                          <div className="flex items-center gap-1.5">
                            <span className="material-symbols-outlined text-sm text-secondary">{m.icon}</span>
                            <span className="text-xs font-medium text-secondary">{m.type}</span>
                          </div>
                        </td>

                        {/* Location */}
                        <td className="px-6 py-5">
                          <div className="flex items-center gap-1.5 text-xs text-on-surface-variant font-medium">
                            <span className="material-symbols-outlined text-sm">location_on</span>
                            <span>{m.location}</span>
                          </div>
                          <span className="mt-0.5 inline-block px-2 py-0.5 bg-surface-container text-[9px] font-bold uppercase tracking-wider rounded-full text-secondary">
                            {m.zone}
                          </span>
                        </td>

                        {/* Status */}
                        <td className="px-6 py-5">
                          <StatusBadge status={m.status} />
                        </td>

                        {/* Today stats */}
                        <td className="px-6 py-5">
                          <div className="flex flex-col gap-0.5">
                            <div className="flex items-center gap-1 text-xs text-on-surface font-bold">
                              <span className="material-symbols-outlined text-sm text-primary">receipt_long</span>
                              {m.ordersToday} orders
                            </div>
                            <div className="flex items-center gap-1 text-[10px] text-secondary">
                              <span className="material-symbols-outlined text-xs">delivery_dining</span>
                              {m.activeShoppers} shoppers
                            </div>
                          </div>
                        </td>

                        {/* Categories */}
                        <td className="px-6 py-5">
                          <div className="flex flex-wrap gap-1.5">
                            {m.categories.map((cat) => (
                              <span key={cat} className="px-2 py-0.5 bg-surface-container text-[10px] font-medium rounded-full text-secondary">
                                {cat}
                              </span>
                            ))}
                          </div>
                        </td>

                        {/* Actions */}
                        <td className="px-6 py-5 text-right">
                          <button className="p-2 hover:bg-surface-container rounded-full transition-colors">
                            <span className="material-symbols-outlined text-secondary">more_vert</span>
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {/* Pagination */}
              <div className="px-6 py-4 bg-surface-container-low flex items-center justify-between border-t border-outline-variant/10">
                <p className="text-xs text-secondary">Showing {filtered.length} of {totalCount} markets</p>
                <div className="flex gap-2">
                  <button
                    onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
                    disabled={currentPage === 1}
                    className="p-2 rounded-lg border border-outline-variant/20 hover:bg-white text-secondary transition-colors disabled:opacity-40"
                  >
                    <span className="material-symbols-outlined text-sm">chevron_left</span>
                  </button>
                  {Array.from({ length: Math.min(totalPages, 5) }, (_, i) => i + 1).map((n) => (
                    <button
                      key={n}
                      onClick={() => setCurrentPage(n)}
                      className={`px-3 py-1 rounded-lg text-xs font-bold transition-colors ${
                        currentPage === n ? 'bg-primary text-white' : 'hover:bg-white text-secondary'
                      }`}
                    >
                      {n}
                    </button>
                  ))}
                  <button
                    onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
                    disabled={currentPage >= totalPages}
                    className="p-2 rounded-lg border border-outline-variant/20 hover:bg-white text-secondary transition-colors disabled:opacity-40"
                  >
                    <span className="material-symbols-outlined text-sm">chevron_right</span>
                  </button>
                </div>
              </div>
            </div>
          </>
        )}

        {/* ── MAP VIEW ────────────────────────────────────────────── */}
        {viewMode === 'map' && (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">

            {/* Map canvas */}
            <div className="lg:col-span-8 bg-surface-container-lowest rounded-2xl border border-outline-variant/15 shadow-sm overflow-hidden">
              {/* Toolbar */}
              <div className="px-5 py-3 border-b border-outline-variant/10 flex items-center justify-between">
                <div className="flex items-center gap-4 text-xs text-secondary font-medium">
                  <div className="flex items-center gap-1.5"><span className="w-2.5 h-2.5 rounded-full bg-primary-container" /> Active</div>
                  <div className="flex items-center gap-1.5"><span className="w-2.5 h-2.5 rounded-full bg-tertiary" /> Maintenance</div>
                  <div className="flex items-center gap-1.5"><span className="w-2.5 h-2.5 rounded-full bg-error" /> Out of Service</div>
                </div>
                <div className="flex gap-1">
                  <button className="p-1.5 rounded-lg hover:bg-surface-container-low transition-colors text-secondary">
                    <span className="material-symbols-outlined text-sm">add</span>
                  </button>
                  <button className="p-1.5 rounded-lg hover:bg-surface-container-low transition-colors text-secondary">
                    <span className="material-symbols-outlined text-sm">remove</span>
                  </button>
                  <button className="p-1.5 rounded-lg hover:bg-surface-container-low transition-colors text-secondary">
                    <span className="material-symbols-outlined text-sm">my_location</span>
                  </button>
                </div>
              </div>

              {/* Canvas area */}
              <div
                className="relative h-[480px] overflow-hidden cursor-crosshair"
                style={{
                  background:
                    'radial-gradient(circle at 50% 50%, #e8f5e9 0%, #f9f9f9 70%), ' +
                    'repeating-linear-gradient(0deg, transparent, transparent 39px, #bccabc22 39px, #bccabc22 40px), ' +
                    'repeating-linear-gradient(90deg, transparent, transparent 39px, #bccabc22 39px, #bccabc22 40px)',
                }}
              >
                {/* Road-like lines */}
                <svg className="absolute inset-0 w-full h-full pointer-events-none opacity-20" xmlns="http://www.w3.org/2000/svg">
                  <line x1="0" y1="40%" x2="100%" y2="45%" stroke="#006d39" strokeWidth="3" />
                  <line x1="0" y1="65%" x2="100%" y2="60%" stroke="#006d39" strokeWidth="2" />
                  <line x1="35%" y1="0" x2="40%" y2="100%" stroke="#006d39" strokeWidth="3" />
                  <line x1="60%" y1="0" x2="65%" y2="100%" stroke="#006d39" strokeWidth="2" />
                  <line x1="0" y1="20%" x2="100%" y2="25%" stroke="#5f5e5e" strokeWidth="1" strokeDasharray="8 4" />
                  <line x1="20%" y1="0" x2="18%" y2="100%" stroke="#5f5e5e" strokeWidth="1" strokeDasharray="8 4" />
                </svg>

                {/* Water body placeholder */}
                <div className="absolute bottom-0 right-0 w-1/3 h-1/3 bg-blue-100/50 rounded-tl-[80px]" />
                <span className="absolute bottom-6 right-6 text-[10px] font-bold text-blue-400 uppercase tracking-widest">Atlantic Ocean</span>

                {/* Zone labels */}
                <span className="absolute text-[9px] font-bold text-secondary uppercase tracking-widest opacity-40" style={{ top: '15%', left: '20%' }}>Mainland</span>
                <span className="absolute text-[9px] font-bold text-secondary uppercase tracking-widest opacity-40" style={{ top: '55%', left: '55%' }}>Island</span>

                {/* Market pins */}
                {markets.map((m) => (
                  <MapPin
                    key={m.id}
                    market={m}
                    selected={selectedMarket === m.id}
                    onClick={() => setSelectedMarket(selectedMarket === m.id ? null : m.id)}
                  />
                ))}

                {/* Watermark */}
                <div className="absolute bottom-3 left-3 flex items-center gap-1 opacity-30">
                  <span className="material-symbols-outlined text-xs">map</span>
                  <span className="text-[9px] font-bold uppercase tracking-widest">Lagos Metro · SwiftShopper</span>
                </div>
              </div>
            </div>

            {/* Market list sidebar */}
            <div className="lg:col-span-4 flex flex-col gap-4">
              <div className="relative">
                <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-secondary text-lg">search</span>
                <input
                  type="text"
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  placeholder="Search markets…"
                  className="w-full pl-10 pr-4 py-2.5 rounded-xl bg-surface-container-lowest border border-outline-variant/20 text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 placeholder:text-secondary/50"
                />
              </div>

              <div className="flex flex-col gap-3 overflow-y-auto max-h-[480px] pr-1">
                {filtered.map((m) => (
                  <button
                    key={m.id}
                    onClick={() => setSelectedMarket(selectedMarket === m.id ? null : m.id)}
                    className={`text-left p-4 rounded-xl border-2 transition-all ${
                      selectedMarket === m.id
                        ? 'border-primary bg-primary/5 shadow-sm'
                        : 'border-outline-variant/15 bg-surface-container-lowest hover:border-outline-variant/30'
                    }`}
                  >
                    <div className="flex items-start gap-3">
                      <div className={`w-9 h-9 rounded-lg bg-surface-container flex items-center justify-center flex-shrink-0 ${m.iconColor}`}>
                        <span className="material-symbols-outlined text-base">{m.icon}</span>
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center justify-between gap-2">
                          <p className="text-sm font-bold text-on-surface truncate">{m.name}</p>
                          <StatusBadge status={m.status} />
                        </div>
                        <p className="text-xs text-secondary mt-0.5">{m.location}</p>
                        {m.status === 'Active' && (
                          <div className="flex items-center gap-3 mt-2">
                            <span className="text-[10px] text-primary font-bold flex items-center gap-1">
                              <span className="material-symbols-outlined text-xs">receipt_long</span>
                              {m.ordersToday} today
                            </span>
                            <span className="text-[10px] text-secondary flex items-center gap-1">
                              <span className="material-symbols-outlined text-xs">delivery_dining</span>
                              {m.activeShoppers} active
                            </span>
                          </div>
                        )}
                      </div>
                    </div>
                  </button>
                ))}
              </div>

              {/* Selected market detail */}
              {activeMarket && (
                <div className="mt-auto p-5 rounded-xl bg-inverse-surface text-inverse-on-surface shadow-lg">
                  <div className="flex items-center justify-between mb-3">
                    <p className="text-xs font-bold uppercase tracking-widest opacity-60">Selected Hub</p>
                    <button onClick={() => setSelectedMarket(null)} className="opacity-60 hover:opacity-100 transition-opacity">
                      <span className="material-symbols-outlined text-sm">close</span>
                    </button>
                  </div>
                  <p className="font-bold text-base mb-1">{activeMarket.name}</p>
                  <p className="text-xs opacity-70 mb-4">{activeMarket.location} · {activeMarket.zone} Zone</p>
                  <div className="grid grid-cols-2 gap-2 mb-4">
                    <div className="p-2.5 rounded-lg bg-white/10 text-center">
                      <p className="text-lg font-bold">{activeMarket.ordersToday}</p>
                      <p className="text-[10px] opacity-60">Orders Today</p>
                    </div>
                    <div className="p-2.5 rounded-lg bg-white/10 text-center">
                      <p className="text-lg font-bold">{activeMarket.activeShoppers}</p>
                      <p className="text-[10px] opacity-60">Active Shoppers</p>
                    </div>
                  </div>
                  <button className="w-full py-2.5 bg-primary-container text-on-primary rounded-lg text-xs font-bold hover:opacity-90 transition-opacity">
                    View Full Profile
                  </button>
                </div>
              )}
            </div>
          </div>
        )}

        {/* ── Insights row ────────────────────────────────────────── */}
        <div className="mt-12 grid grid-cols-1 md:grid-cols-3 gap-8">

          {/* Geofencing card */}
          <div className="md:col-span-2 bg-surface-container-lowest p-8 rounded-2xl border border-outline-variant/15 shadow-sm relative overflow-hidden group">
            <div className="absolute top-0 right-0 p-8 pointer-events-none opacity-10 group-hover:opacity-20 transition-opacity">
              <span className="material-symbols-outlined text-[128px] text-secondary">near_me</span>
            </div>
            <div className="relative z-10">
              <div className="flex items-center gap-3 mb-4">
                <div className="p-2 rounded-full bg-primary/10">
                  <span className="material-symbols-outlined text-primary text-xl">near_me</span>
                </div>
                <h4 className="text-xl font-bold text-on-surface">Geofencing &amp; Coverage</h4>
              </div>
              <p className="text-secondary text-sm max-w-lg mb-8">
                Optimize your shopper dispatch rules by adjusting market radiuses. Currently, Lekki markets are
                experiencing a 15% overlap in coverage.
              </p>
              <div className="flex gap-4">
                <div className="flex-1 p-4 bg-surface-container-low rounded-xl border border-outline-variant/10">
                  <p className="text-[10px] font-bold text-primary uppercase mb-1 tracking-wider">Optimized Hubs</p>
                  <p className="text-2xl font-bold text-on-surface">32</p>
                </div>
                <div className="flex-1 p-4 bg-surface-container-low rounded-xl border border-outline-variant/10">
                  <p className="text-[10px] font-bold text-tertiary uppercase mb-1 tracking-wider">High Overlap</p>
                  <p className="text-2xl font-bold text-on-surface">12</p>
                </div>
                <div className="flex-1 p-4 bg-surface-container-low rounded-xl border border-outline-variant/10">
                  <p className="text-[10px] font-bold text-secondary uppercase mb-1 tracking-wider">Unassigned</p>
                  <p className="text-2xl font-bold text-on-surface">4</p>
                </div>
              </div>
              <button className="mt-6 px-5 py-2.5 rounded-xl bg-primary text-white text-sm font-bold hover:opacity-90 transition-all flex items-center gap-2 shadow-md shadow-primary/20">
                <span className="material-symbols-outlined text-lg">tune</span>
                Adjust Geofences
              </button>
            </div>
          </div>

          {/* Operational alert card */}
          <div className="bg-secondary text-white p-8 rounded-2xl shadow-xl flex flex-col justify-between overflow-hidden relative">
            <div className="absolute inset-0 pointer-events-none">
              <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-64 h-64 bg-emerald-400 rounded-full blur-[100px] opacity-20" />
            </div>
            <div className="relative z-10">
              <span className="inline-block px-2 py-1 bg-white/10 rounded-lg text-[10px] font-bold uppercase mb-4 tracking-wider">
                Operational Alert
              </span>
              <h4 className="text-2xl font-bold mb-2">Market Surge in Ikeja</h4>
              <p className="text-white/70 text-sm mb-6">
                Traffic volume at Mile 12 has increased by 40% in the last hour. Consider activating surge pricing.
              </p>
              <div className="flex items-center gap-3 p-3 bg-white/10 rounded-xl mb-6">
                <span className="material-symbols-outlined text-emerald-400">trending_up</span>
                <div>
                  <p className="text-xs font-bold">+40% volume spike</p>
                  <p className="text-[10px] opacity-60">Last updated: 2 min ago</p>
                </div>
              </div>
            </div>
            <button className="relative z-10 w-full py-3 bg-white text-secondary font-bold rounded-xl text-sm hover:bg-emerald-50 transition-colors shadow-lg active:scale-95">
              Manage Logistics
            </button>
          </div>
        </div>

      </div>

      {/* ── Fixed map pip (bottom-right, always visible on desktop) ── */}
      <div
        className={`fixed bottom-8 right-8 z-[60] hidden md:block shadow-2xl rounded-2xl border-4 border-white overflow-hidden cursor-pointer group transition-all duration-300 ${
          mapPipExpanded ? 'w-96 h-60' : 'w-80 h-48'
        }`}
        onClick={() => {
          setViewMode('map');
          window.scrollTo({ top: 0, behavior: 'smooth' });
        }}
      >
        {/* Styled map canvas */}
        <div
          className="w-full h-full relative"
          style={{
            background:
              'radial-gradient(circle at 50% 50%, #e8f5e9 0%, #d4edda 100%)',
          }}
        >
          <svg className="absolute inset-0 w-full h-full pointer-events-none opacity-30" xmlns="http://www.w3.org/2000/svg">
            <line x1="0" y1="45%" x2="100%" y2="50%" stroke="#006d39" strokeWidth="4" />
            <line x1="0" y1="70%" x2="100%" y2="65%" stroke="#006d39" strokeWidth="2" />
            <line x1="38%" y1="0" x2="42%" y2="100%" stroke="#006d39" strokeWidth="3" />
            <line x1="65%" y1="0" x2="68%" y2="100%" stroke="#006d39" strokeWidth="2" />
            <line x1="0" y1="25%" x2="100%" y2="28%" stroke="#5f5e5e" strokeWidth="1" strokeDasharray="6 4" />
          </svg>
          {/* Mini pins */}
          {markets.filter((m) => m.status === 'Active').map((m) => (
            <div
              key={m.id}
              className="absolute w-3 h-3 rounded-full bg-primary-container border-2 border-white shadow"
              style={{ left: `${m.pinX}%`, top: `${m.pinY}%`, transform: 'translate(-50%,-50%)' }}
            />
          ))}
          {markets.filter((m) => m.status !== 'Active').map((m) => (
            <div
              key={m.id}
              className="absolute w-3 h-3 rounded-full bg-error border-2 border-white shadow"
              style={{ left: `${m.pinX}%`, top: `${m.pinY}%`, transform: 'translate(-50%,-50%)' }}
            />
          ))}
          <div className="absolute bottom-0 right-0 w-1/3 h-1/4 bg-blue-200/60 rounded-tl-3xl" />
        </div>

        {/* Overlay */}
        <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />
        <div className="absolute bottom-3 left-4 text-white">
          <p className="text-[9px] font-bold uppercase tracking-widest opacity-70">Quick Map Preview</p>
          <p className="text-xs font-bold">Lagos Metropolitan Coverage</p>
        </div>
        <div
          onClick={(e) => { e.stopPropagation(); setMapPipExpanded((v) => !v); }}
          className="absolute top-3 right-3 bg-white/20 backdrop-blur-md p-1.5 rounded-lg text-white hover:bg-white/30 transition-colors"
        >
          <span className="material-symbols-outlined text-sm">
            {mapPipExpanded ? 'close_fullscreen' : 'open_in_full'}
          </span>
        </div>
      </div>
    </main>
  );
}
