import { useState } from 'react';

// ── Types ──────────────────────────────────────────────────────────────────

interface NotifToggle {
  label: string;
  key: string;
  default: boolean;
}

interface ServiceZone {
  name: string;
  status: 'ACTIVE' | 'DORMANT';
  shoppers?: string;
  orders?: string;
  note?: string;
}

interface AdminUser {
  initials: string;
  name: string;
  email: string;
  role: string;
  permissions: string;
  lastLogin: string;
}

// ── Mock data ──────────────────────────────────────────────────────────────

const notifToggles: NotifToggle[] = [
  { label: 'Critical System Alerts',  key: 'critical',   default: true  },
  { label: 'Daily Earnings Digest',   key: 'digest',     default: true  },
  { label: 'New Shopper Onboarding',  key: 'onboarding', default: false },
];

const zones: ServiceZone[] = [
  { name: 'Ikeja Central',   status: 'ACTIVE',  shoppers: '24 Active Shoppers', orders: '142 Orders / Day' },
  { name: 'Victoria Island', status: 'ACTIVE',  shoppers: '18 Active Shoppers', orders: '210 Orders / Day' },
  { name: 'Lekki Phase II',  status: 'DORMANT', note: 'Planned Q4 2023' },
];

const admins: AdminUser[] = [
  {
    initials: 'CA', name: 'Chidi Azikiwe',  email: 'chidi@swiftshopper.ng',
    role: 'SUPER ADMIN',   permissions: 'Full system access, payments, service areas...',
    lastLogin: 'Today, 08:42 AM',
  },
  {
    initials: 'FO', name: 'Funke Ojo',      email: 'funke@swiftshopper.ng',
    role: 'FLEET MANAGER', permissions: 'Shopper management, logistics, support...',
    lastLogin: 'Yesterday, 06:15 PM',
  },
];

// ── Sub-components ─────────────────────────────────────────────────────────

function Toggle({ checked, onChange }: { checked: boolean; onChange: () => void }) {
  return (
    <label className="relative inline-flex items-center cursor-pointer" onClick={onChange}>
      <input type="checkbox" className="sr-only peer" readOnly checked={checked} />
      <div className={`w-11 h-6 rounded-full transition-colors ${checked ? 'bg-primary' : 'bg-surface-container-highest'} relative after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all ${checked ? 'after:translate-x-full' : ''}`} />
    </label>
  );
}

// ── Page ───────────────────────────────────────────────────────────────────

export default function Settings() {
  const [notifs, setNotifs] = useState<Record<string, boolean>>(
    Object.fromEntries(notifToggles.map((t) => [t.key, t.default]))
  );
  const [showPassword, setShowPassword] = useState(false);
  const [commission, setCommission] = useState(12);
  const [deliveryFee, setDeliveryFee] = useState(1200);

  const toggleNotif = (key: string) =>
    setNotifs((prev) => ({ ...prev, [key]: !prev[key] }));

  return (
    <main className="pt-10 px-8 pb-12 min-h-screen">
      <div className="max-w-6xl mx-auto">

        {/* Header */}
        <header className="mb-10 flex justify-between items-end">
          <div>
            <h1 className="text-4xl font-extrabold tracking-tight text-on-surface mb-2">System Settings</h1>
            <p className="text-secondary font-medium">Configure your SwiftShopper Lagos instance and global parameters.</p>
          </div>
          <div className="flex gap-3">
            <button className="px-6 py-2.5 bg-secondary-container text-on-secondary-fixed font-semibold rounded-xl hover:bg-neutral-200 transition-all active:scale-95">
              Discard Changes
            </button>
            <button className="px-8 py-2.5 bg-gradient-to-br from-primary to-primary-container text-white font-bold rounded-xl shadow-lg shadow-emerald-500/20 hover:shadow-emerald-500/40 transition-all active:scale-95">
              Save All Settings
            </button>
          </div>
        </header>

        {/* Bento grid */}
        <div className="grid grid-cols-12 gap-8">

          {/* Profile settings */}
          <section className="col-span-12 lg:col-span-7 bg-surface-container-lowest rounded-xl p-8 shadow-sm border border-outline-variant/15">
            <div className="flex items-center gap-3 mb-6">
              <span className="p-2 bg-primary-fixed-dim/30 text-primary rounded-lg material-symbols-outlined">person</span>
              <h2 className="text-xl font-bold">Profile Settings</h2>
            </div>
            <div className="space-y-6">
              <div className="grid grid-cols-2 gap-6">
                <div className="space-y-2">
                  <label className="text-xs font-bold uppercase tracking-wider text-secondary">Full Name</label>
                  <input
                    type="text"
                    defaultValue="Oluwaseun Adeyemi"
                    className="w-full bg-surface-container-highest border-none rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all"
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-xs font-bold uppercase tracking-wider text-secondary">Email Address</label>
                  <input
                    type="email"
                    defaultValue="admin@swiftshopper.ng"
                    className="w-full bg-surface-container-highest border-none rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all"
                  />
                </div>
              </div>
              <div className="space-y-2">
                <label className="text-xs font-bold uppercase tracking-wider text-secondary">New Password</label>
                <div className="relative">
                  <input
                    type={showPassword ? 'text' : 'password'}
                    placeholder="••••••••••••"
                    className="w-full bg-surface-container-highest border-none rounded-xl px-4 py-3 pr-12 focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword((v) => !v)}
                    className="material-symbols-outlined absolute right-4 top-1/2 -translate-y-1/2 text-neutral-400 cursor-pointer"
                  >
                    {showPassword ? 'visibility_off' : 'visibility'}
                  </button>
                </div>
              </div>
              <div className="pt-4 border-t border-outline-variant/10 flex items-center justify-between">
                <p className="text-sm text-secondary">Last changed: 14 days ago</p>
                <button className="text-primary font-bold hover:underline">Setup 2FA Authentication</button>
              </div>
            </div>
          </section>

          {/* Platform fees */}
          <section className="col-span-12 lg:col-span-5 bg-surface-container-lowest rounded-xl p-8 shadow-sm border border-outline-variant/15">
            <div className="flex items-center gap-3 mb-6">
              <span className="p-2 bg-tertiary-fixed-dim/30 text-tertiary rounded-lg material-symbols-outlined">payments</span>
              <h2 className="text-xl font-bold">Platform Fees</h2>
            </div>
            <div className="space-y-8">
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-semibold">Merchant Commission</p>
                  <p className="text-xs text-secondary">Percentage taken from each order</p>
                </div>
                <div className="flex items-center gap-2">
                  <input
                    type="number"
                    value={commission}
                    onChange={(e) => setCommission(Number(e.target.value))}
                    className="w-16 bg-surface-container-highest border-none rounded-lg text-center font-bold focus:outline-none focus:ring-2 focus:ring-primary/20"
                  />
                  <span className="font-bold text-secondary">%</span>
                </div>
              </div>
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-semibold">Base Delivery Fee</p>
                  <p className="text-xs text-secondary">Flat rate for first 5km</p>
                </div>
                <div className="flex items-center gap-2">
                  <span className="font-bold text-secondary">₦</span>
                  <input
                    type="number"
                    value={deliveryFee}
                    onChange={(e) => setDeliveryFee(Number(e.target.value))}
                    className="w-24 bg-surface-container-highest border-none rounded-lg text-right font-bold focus:outline-none focus:ring-2 focus:ring-primary/20"
                  />
                </div>
              </div>
              <div className="bg-surface-container-low p-4 rounded-xl border border-dashed border-outline-variant">
                <div className="flex items-center gap-2 mb-2">
                  <span className="material-symbols-outlined text-tertiary text-sm">info</span>
                  <span className="text-xs font-bold uppercase tracking-widest text-on-tertiary-container">Dynamic Pricing</span>
                </div>
                <p className="text-xs text-on-surface-variant">
                  Surge pricing is currently <strong className="text-primary">ACTIVE</strong> for Ikeja and Victoria Island zones.
                </p>
              </div>
            </div>
          </section>

          {/* Service areas */}
          <section className="col-span-12 lg:col-span-8 bg-surface-container-lowest rounded-xl overflow-hidden shadow-sm border border-outline-variant/15">
            <div className="p-8 pb-4">
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-3">
                  <span className="p-2 bg-primary-fixed-dim/30 text-primary rounded-lg material-symbols-outlined">map</span>
                  <h2 className="text-xl font-bold">Service Areas</h2>
                </div>
                <button className="flex items-center gap-2 text-primary font-bold hover:bg-primary/5 px-4 py-2 rounded-lg transition-all">
                  <span className="material-symbols-outlined">add_location_alt</span>
                  Add Zone
                </button>
              </div>
              <p className="text-sm text-secondary mb-6">Manage geofences and delivery boundaries across Lagos districts.</p>
            </div>

            {/* Map placeholder */}
            <div className="relative h-[320px] bg-surface-container-high w-full">
              <div className="absolute inset-0 flex items-center justify-center">
                <div className="text-center">
                  <span className="material-symbols-outlined text-6xl text-outline-variant/40 mb-2 block">map</span>
                  <p className="text-secondary text-sm">Interactive map engine loading...</p>
                </div>
              </div>
              <div className="absolute inset-0 opacity-10 pointer-events-none bg-[radial-gradient(circle_at_center,_var(--tw-gradient-stops))] from-primary via-transparent to-transparent" />
            </div>

            {/* Zone cards */}
            <div className="p-6 grid grid-cols-3 gap-4">
              {zones.map((z) => (
                <div key={z.name} className={`p-4 bg-surface-container-low rounded-xl border border-outline-variant/10 ${z.status === 'DORMANT' ? 'opacity-60' : ''}`}>
                  <div className="flex justify-between items-start mb-2">
                    <p className="font-bold">{z.name}</p>
                    <span className={`px-2 py-0.5 text-[10px] font-bold rounded-full ${z.status === 'ACTIVE' ? 'bg-primary/10 text-primary' : 'bg-secondary-container text-secondary'}`}>
                      {z.status}
                    </span>
                  </div>
                  {z.shoppers && <p className="text-xs text-secondary">{z.shoppers}</p>}
                  {z.orders   && <p className="text-xs text-secondary">{z.orders}</p>}
                  {z.note     && <p className="text-xs text-secondary">{z.note}</p>}
                </div>
              ))}
            </div>
          </section>

          {/* Notifications + System Health */}
          <div className="col-span-12 lg:col-span-4 space-y-8">

            {/* Notifications */}
            <section className="bg-surface-container-lowest rounded-xl p-6 shadow-sm border border-outline-variant/15">
              <div className="flex items-center gap-3 mb-6">
                <span className="p-2 bg-secondary-container text-secondary rounded-lg material-symbols-outlined">notifications_active</span>
                <h2 className="text-lg font-bold">Notifications</h2>
              </div>
              <div className="space-y-4">
                {notifToggles.map((t) => (
                  <div key={t.key} className="flex items-center justify-between">
                    <span className="text-sm font-medium">{t.label}</span>
                    <Toggle checked={notifs[t.key]} onChange={() => toggleNotif(t.key)} />
                  </div>
                ))}
              </div>
            </section>

            {/* System health */}
            <section className="bg-secondary text-white rounded-xl p-6 shadow-xl relative overflow-hidden">
              <div className="relative z-10">
                <h3 className="text-lg font-bold mb-2">System Health</h3>
                <div className="flex items-center gap-2 mb-4">
                  <div className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
                  <span className="text-xs font-medium text-emerald-100">All Lagos Nodes operational</span>
                </div>
                <button className="w-full py-2 bg-white/10 hover:bg-white/20 rounded-lg text-sm font-bold transition-all border border-white/20">
                  View System Logs
                </button>
              </div>
              <div className="absolute -right-10 -bottom-10 w-32 h-32 bg-primary-container rounded-full blur-3xl opacity-30" />
            </section>
          </div>

          {/* Roles & Permissions */}
          <section className="col-span-12 bg-surface-container-lowest rounded-xl overflow-hidden shadow-sm border border-outline-variant/15">
            <div className="p-8 border-b border-outline-variant/10 flex justify-between items-center">
              <div className="flex items-center gap-3">
                <span className="p-2 bg-secondary-container text-secondary rounded-lg material-symbols-outlined">admin_panel_settings</span>
                <div>
                  <h2 className="text-xl font-bold">Roles &amp; Permissions</h2>
                  <p className="text-sm text-secondary">Manage administrative access levels for the Lagos region.</p>
                </div>
              </div>
              <button className="px-5 py-2.5 bg-on-surface text-white rounded-xl font-bold text-sm hover:bg-neutral-800 transition-all flex items-center gap-2">
                <span className="material-symbols-outlined text-sm">person_add</span>
                Invite Admin
              </button>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left">
                <thead className="bg-surface-container-low">
                  <tr>
                    {['Administrator', 'Role', 'Permissions', 'Last Login', 'Status', ''].map((h) => (
                      <th key={h} className="px-8 py-4 text-[10px] font-bold uppercase tracking-widest text-secondary">
                        {h}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody className="divide-y divide-outline-variant/10">
                  {admins.map((a) => (
                    <tr key={a.email} className="hover:bg-surface transition-colors">
                      <td className="px-8 py-5">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-full bg-surface-container flex items-center justify-center text-[10px] font-bold flex-shrink-0">
                            {a.initials}
                          </div>
                          <div>
                            <p className="font-semibold text-sm">{a.name}</p>
                            <p className="text-xs text-secondary">{a.email}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-8 py-5">
                        <span className="px-3 py-1 bg-surface-container text-on-surface text-[10px] font-bold rounded-full">
                          {a.role}
                        </span>
                      </td>
                      <td className="px-8 py-5">
                        <p className="text-xs text-on-surface-variant max-w-xs truncate">{a.permissions}</p>
                      </td>
                      <td className="px-8 py-5 text-sm text-secondary">{a.lastLogin}</td>
                      <td className="px-8 py-5">
                        <div className="flex items-center gap-2">
                          <div className="w-1.5 h-1.5 rounded-full bg-primary" />
                          <span className="text-xs font-medium">Active</span>
                        </div>
                      </td>
                      <td className="px-8 py-5 text-right">
                        <button className="text-secondary hover:text-on-surface transition-colors">
                          <span className="material-symbols-outlined">more_horiz</span>
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>

        </div>

        {/* Footer */}
        <footer className="mt-16 pt-8 border-t border-outline-variant/15 flex flex-col md:flex-row justify-between items-center gap-4 text-xs font-medium text-secondary">
          <p>© 2023 SwiftShopper Nigeria Limited. All rights reserved.</p>
          <div className="flex gap-6">
            <a href="#" className="hover:text-primary transition-colors">Security Policy</a>
            <a href="#" className="hover:text-primary transition-colors">API Documentation</a>
            <a href="#" className="hover:text-primary transition-colors">Release Notes (v4.2.1)</a>
          </div>
        </footer>

      </div>
    </main>
  );
}
