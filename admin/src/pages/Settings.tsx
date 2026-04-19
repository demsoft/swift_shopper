import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { getAdminUsers, updateAdminUser, type AdminUserDto } from '../lib/api';

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

// ── Sub-components ─────────────────────────────────────────────────────────

function EditAdminModal({
  user,
  onClose,
  onSaved,
}: {
  user: AdminUserDto;
  onClose: () => void;
  onSaved: (updated: AdminUserDto) => void;
}) {
  const [fullName, setFullName] = useState(user.fullName);
  const [phoneNumber, setPhoneNumber] = useState(user.phoneNumber);
  const [isActive, setIsActive] = useState(user.isActive);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!fullName.trim()) return;
    setError('');
    setSaving(true);
    try {
      const updated = await updateAdminUser(user.userId, {
        fullName: fullName.trim(),
        phoneNumber: phoneNumber.trim(),
        isActive,
      });
      onSaved(updated);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to save');
    } finally {
      setSaving(false);
    }
  }

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm"
      onClick={onClose}
    >
      <div
        className="bg-surface w-full max-w-md rounded-2xl shadow-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        <form onSubmit={handleSubmit}>
          {/* Header */}
          <div className="flex items-center justify-between px-6 py-5 border-b border-outline-variant/20">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-full bg-primary-fixed-dim/40 text-primary flex items-center justify-center text-[11px] font-bold">
                {user.initials}
              </div>
              <div>
                <h3 className="text-base font-extrabold text-on-surface">Edit Administrator</h3>
                <p className="text-xs text-secondary">{user.email}</p>
              </div>
            </div>
            <button type="button" onClick={onClose} className="p-2 rounded-full hover:bg-surface-container-low transition-colors">
              <span className="material-symbols-outlined text-secondary">close</span>
            </button>
          </div>

          <div className="px-6 py-5 flex flex-col gap-4">
            {error && (
              <p className="text-sm text-error bg-error-container/30 rounded-xl px-4 py-3">{error}</p>
            )}

            <div>
              <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-1.5">Full Name</label>
              <input
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                required
                className="w-full px-4 py-2.5 rounded-xl border border-outline-variant/30 bg-surface-container-lowest text-sm focus:outline-none focus:ring-2 focus:ring-primary/20"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-1.5">Phone Number</label>
              <input
                value={phoneNumber}
                onChange={(e) => setPhoneNumber(e.target.value)}
                className="w-full px-4 py-2.5 rounded-xl border border-outline-variant/30 bg-surface-container-lowest text-sm focus:outline-none focus:ring-2 focus:ring-primary/20"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-1.5">Email Address</label>
              <input
                value={user.email}
                disabled
                className="w-full px-4 py-2.5 rounded-xl border border-outline-variant/30 bg-surface-container-low text-sm text-secondary cursor-not-allowed"
              />
              <p className="text-xs text-secondary mt-1">Email cannot be changed.</p>
            </div>

            <div className="flex items-center justify-between py-1">
              <div>
                <p className="text-sm font-semibold">Account Active</p>
                <p className="text-xs text-secondary">Inactive admins cannot log in.</p>
              </div>
              <div
                className={`w-10 h-6 rounded-full transition-colors relative cursor-pointer ${isActive ? 'bg-primary' : 'bg-outline-variant'}`}
                onClick={() => setIsActive((v) => !v)}
              >
                <div className={`absolute top-1 w-4 h-4 rounded-full bg-white shadow transition-transform ${isActive ? 'translate-x-5' : 'translate-x-1'}`} />
              </div>
            </div>
          </div>

          {/* Footer */}
          <div className="px-6 py-4 border-t border-outline-variant/20 flex justify-end gap-3">
            <button
              type="button"
              onClick={onClose}
              className="px-5 py-2 rounded-xl text-sm font-semibold bg-surface-container hover:bg-surface-container-high transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={saving || !fullName.trim()}
              className="px-6 py-2 rounded-xl text-sm font-bold bg-primary text-white hover:bg-primary/90 disabled:opacity-50 transition-colors flex items-center gap-2"
            >
              {saving && (
                <svg className="animate-spin w-4 h-4" viewBox="0 0 24 24" fill="none">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z" />
                </svg>
              )}
              {saving ? 'Saving…' : 'Save Changes'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

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

  const [adminUsers, setAdminUsers] = useState<AdminUserDto[]>([]);
  const [adminsLoading, setAdminsLoading] = useState(true);
  const [adminsError, setAdminsError] = useState('');
  const [editingAdmin, setEditingAdmin] = useState<AdminUserDto | null>(null);

  useEffect(() => {
    getAdminUsers()
      .then(setAdminUsers)
      .catch((e: unknown) => setAdminsError(e instanceof Error ? e.message : 'Failed to load'))
      .finally(() => setAdminsLoading(false));
  }, []);

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
              <Link
                to="/settings/users/add"
                className="px-5 py-2.5 bg-on-surface text-white rounded-xl font-bold text-sm hover:bg-neutral-800 transition-all flex items-center gap-2"
              >
                <span className="material-symbols-outlined text-sm">person_add</span>
                Invite Admin
              </Link>
            </div>

            <div className="overflow-x-auto">
              {adminsLoading && (
                <div className="flex items-center justify-center py-12 gap-3 text-secondary">
                  <svg className="animate-spin w-5 h-5" viewBox="0 0 24 24" fill="none">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z" />
                  </svg>
                  <span className="text-sm font-medium">Loading administrators…</span>
                </div>
              )}
              {adminsError && (
                <div className="flex items-center gap-2 mx-8 my-6 px-4 py-3 bg-error-container/30 rounded-xl text-sm text-error">
                  <span className="material-symbols-outlined text-base">error</span>
                  {adminsError}
                </div>
              )}
              {!adminsLoading && !adminsError && adminUsers.length === 0 && (
                <div className="flex flex-col items-center justify-center py-12 gap-2 text-secondary">
                  <span className="material-symbols-outlined text-4xl opacity-30">admin_panel_settings</span>
                  <p className="text-sm">No administrator accounts yet.</p>
                </div>
              )}
              {!adminsLoading && adminUsers.length > 0 && (
                <table className="w-full text-left">
                  <thead className="bg-surface-container-low">
                    <tr>
                      {['Administrator', 'Role', 'Phone', 'Joined', 'Status', ''].map((h) => (
                        <th key={h} className="px-8 py-4 text-[10px] font-bold uppercase tracking-widest text-secondary">
                          {h}
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-outline-variant/10">
                    {adminUsers.map((a) => (
                      <tr key={a.userId} className="hover:bg-surface transition-colors">
                        <td className="px-8 py-5">
                          <div className="flex items-center gap-3">
                            <div className="w-9 h-9 rounded-full bg-primary-fixed-dim/40 text-primary flex items-center justify-center text-[11px] font-bold flex-shrink-0">
                              {a.initials}
                            </div>
                            <div>
                              <p className="font-semibold text-sm">{a.fullName}</p>
                              <p className="text-xs text-secondary">{a.email}</p>
                            </div>
                          </div>
                        </td>
                        <td className="px-8 py-5">
                          <span className="px-3 py-1 bg-surface-container text-on-surface text-[10px] font-bold rounded-full uppercase tracking-wide">
                            {a.adminRole.replace(/_/g, ' ')}
                          </span>
                        </td>
                        <td className="px-8 py-5 text-sm text-secondary">{a.phoneNumber || '—'}</td>
                        <td className="px-8 py-5 text-sm text-secondary">
                          {new Date(a.createdAt).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })}
                        </td>
                        <td className="px-8 py-5">
                          <div className="flex items-center gap-2">
                            <div className={`w-1.5 h-1.5 rounded-full ${a.isActive ? 'bg-primary' : 'bg-outline-variant'}`} />
                            <span className="text-xs font-medium">{a.isActive ? 'Active' : 'Inactive'}</span>
                          </div>
                        </td>
                        <td className="px-8 py-5 text-right">
                          <button onClick={() => setEditingAdmin(a)} className="text-secondary hover:text-on-surface transition-colors">
                            <span className="material-symbols-outlined">more_horiz</span>
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
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

      {editingAdmin && (
        <EditAdminModal
          user={editingAdmin}
          onClose={() => setEditingAdmin(null)}
          onSaved={(updated) => {
            setAdminUsers((prev) => prev.map((u) => u.userId === updated.userId ? updated : u));
            setEditingAdmin(null);
          }}
        />
      )}
    </main>
  );
}
