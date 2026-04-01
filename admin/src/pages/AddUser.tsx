import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';

// ── Types ──────────────────────────────────────────────────────────────────

type Role = 'super_admin' | 'fleet_manager' | 'support_lead' | 'regional_coordinator';

interface RoleOption {
  id: Role;
  icon: string;
  title: string;
  description: string;
  permissions: string[];
}

// ── Data ───────────────────────────────────────────────────────────────────

const roles: RoleOption[] = [
  {
    id: 'super_admin',
    icon: 'shield_person',
    title: 'Super Admin',
    description: 'Full platform access with all permissions.',
    permissions: [
      'Full platform access',
      'User & role management',
      'Financial controls',
      'System configuration',
      'Audit log access',
    ],
  },
  {
    id: 'fleet_manager',
    icon: 'delivery_dining',
    title: 'Fleet Manager',
    description: 'Manages shoppers, assignments, and routes.',
    permissions: [
      'View & manage shoppers',
      'Assign and reassign orders',
      'View earnings & payouts',
      'Send broadcast messages',
    ],
  },
  {
    id: 'support_lead',
    icon: 'support_agent',
    title: 'Support Lead',
    description: 'Handles customer issues and escalations.',
    permissions: [
      'View all orders',
      'Customer account management',
      'Issue resolution tools',
      'View-only financial data',
    ],
  },
  {
    id: 'regional_coordinator',
    icon: 'map',
    title: 'Regional Coordinator',
    description: 'Oversees market zones and regional ops.',
    permissions: [
      'View regional orders',
      'Manage market listings',
      'Assign zone shoppers',
      'Regional analytics',
    ],
  },
];

// ── Page ───────────────────────────────────────────────────────────────────

export default function AddUser() {
  const navigate = useNavigate();

  const [selectedRole, setSelectedRole] = useState<Role>('fleet_manager');
  const [showPassword, setShowPassword] = useState(false);
  const [forceReset, setForceReset] = useState(true);

  const [form, setForm] = useState({
    fullName: '',
    email: '',
    phone: '',
    password: '',
  });

  const activeRole = roles.find((r) => r.id === selectedRole)!;

  function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
    setForm((prev) => ({ ...prev, [e.target.name]: e.target.value }));
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    // TODO: wire to API
    navigate('/settings');
  }

  return (
    <main className="pt-10 px-8 pb-16 min-h-screen bg-surface">
      <div className="max-w-5xl mx-auto">

        {/* Breadcrumb */}
        <nav className="flex items-center gap-2 text-xs text-secondary mb-8">
          <Link to="/settings" className="hover:text-on-surface transition-colors font-medium">Settings</Link>
          <span className="material-symbols-outlined text-sm">chevron_right</span>
          <span className="font-medium">Users</span>
          <span className="material-symbols-outlined text-sm">chevron_right</span>
          <span className="font-bold text-on-surface">Add New</span>
        </nav>

        {/* Page header */}
        <div className="mb-10">
          <h1 className="text-4xl font-bold tracking-tight text-on-surface mb-2">Add New User</h1>
          <p className="text-secondary font-medium">Create an admin portal account and assign a role.</p>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">

            {/* ── Left / Main column ───────────────────────────────── */}
            <div className="lg:col-span-2 space-y-8">

              {/* Personal Information */}
              <div className="bg-surface-container-lowest rounded-xl border border-outline-variant/15 shadow-sm p-8">
                <div className="flex items-center gap-3 mb-6">
                  <div className="p-2 rounded-full bg-primary/10">
                    <span className="material-symbols-outlined text-primary text-xl">person</span>
                  </div>
                  <h2 className="text-base font-bold text-on-surface">Personal Information</h2>
                </div>

                <div className="space-y-5">
                  {/* Full Name */}
                  <div>
                    <label className="block text-xs font-bold uppercase tracking-widest text-secondary mb-2">
                      Full Name
                    </label>
                    <input
                      type="text"
                      name="fullName"
                      value={form.fullName}
                      onChange={handleChange}
                      placeholder="e.g. Adebayo Okafor"
                      className="w-full px-4 py-3 rounded-xl bg-surface-container-low border border-outline-variant/20 text-sm text-on-surface placeholder:text-secondary/50 focus:outline-none focus:ring-2 focus:ring-primary/30 transition-all"
                    />
                  </div>

                  {/* Email */}
                  <div>
                    <label className="block text-xs font-bold uppercase tracking-widest text-secondary mb-2">
                      Email Address
                    </label>
                    <div className="relative">
                      <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-secondary text-lg">
                        mail
                      </span>
                      <input
                        type="email"
                        name="email"
                        value={form.email}
                        onChange={handleChange}
                        placeholder="name@swiftshopper.ng"
                        className="w-full pl-11 pr-4 py-3 rounded-xl bg-surface-container-low border border-outline-variant/20 text-sm text-on-surface placeholder:text-secondary/50 focus:outline-none focus:ring-2 focus:ring-primary/30 transition-all"
                      />
                    </div>
                  </div>

                  {/* Phone */}
                  <div>
                    <label className="block text-xs font-bold uppercase tracking-widest text-secondary mb-2">
                      Phone Number
                    </label>
                    <div className="flex gap-2">
                      <div className="flex items-center gap-2 px-4 py-3 rounded-xl bg-surface-container-low border border-outline-variant/20 text-sm font-medium text-on-surface shrink-0">
                        <span className="text-base">🇳🇬</span>
                        <span>+234</span>
                      </div>
                      <input
                        type="tel"
                        name="phone"
                        value={form.phone}
                        onChange={handleChange}
                        placeholder="080 0000 0000"
                        className="flex-1 px-4 py-3 rounded-xl bg-surface-container-low border border-outline-variant/20 text-sm text-on-surface placeholder:text-secondary/50 focus:outline-none focus:ring-2 focus:ring-primary/30 transition-all"
                      />
                    </div>
                  </div>
                </div>
              </div>

              {/* Role Assignment */}
              <div className="bg-surface-container-lowest rounded-xl border border-outline-variant/15 shadow-sm p-8">
                <div className="flex items-center gap-3 mb-6">
                  <div className="p-2 rounded-full bg-tertiary/10">
                    <span className="material-symbols-outlined text-tertiary text-xl">manage_accounts</span>
                  </div>
                  <h2 className="text-base font-bold text-on-surface">Role Assignment</h2>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  {roles.map((role) => {
                    const isSelected = selectedRole === role.id;
                    return (
                      <button
                        type="button"
                        key={role.id}
                        onClick={() => setSelectedRole(role.id)}
                        className={`text-left p-5 rounded-xl border-2 transition-all ${
                          isSelected
                            ? 'border-primary bg-primary/5 shadow-sm'
                            : 'border-outline-variant/20 bg-surface-container-low hover:border-outline-variant/40'
                        }`}
                      >
                        <div className="flex items-start gap-3">
                          <div className={`p-2 rounded-lg mt-0.5 ${isSelected ? 'bg-primary/15' : 'bg-surface-container-high'}`}>
                            <span className={`material-symbols-outlined text-xl ${isSelected ? 'text-primary' : 'text-secondary'}`}>
                              {role.icon}
                            </span>
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center justify-between">
                              <span className={`text-sm font-bold ${isSelected ? 'text-primary' : 'text-on-surface'}`}>
                                {role.title}
                              </span>
                              <div className={`w-4 h-4 rounded-full border-2 flex items-center justify-center flex-shrink-0 ${
                                isSelected ? 'border-primary' : 'border-outline-variant/40'
                              }`}>
                                {isSelected && <div className="w-2 h-2 rounded-full bg-primary" />}
                              </div>
                            </div>
                            <p className="text-xs text-secondary mt-1 leading-relaxed">{role.description}</p>
                          </div>
                        </div>
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Security */}
              <div className="bg-inverse-surface rounded-xl p-8 text-surface shadow-sm relative overflow-hidden">
                <div className="relative z-10">
                  <div className="flex items-center gap-3 mb-6">
                    <div className="p-2 rounded-full bg-white/10">
                      <span className="material-symbols-outlined text-xl" style={{ fontVariationSettings: "'FILL' 1" }}>
                        lock
                      </span>
                    </div>
                    <h2 className="text-base font-bold">Security</h2>
                  </div>

                  {/* Temporary password */}
                  <div className="mb-5">
                    <label className="block text-xs font-bold uppercase tracking-widest opacity-60 mb-2">
                      Temporary Password
                    </label>
                    <div className="relative">
                      <input
                        type={showPassword ? 'text' : 'password'}
                        name="password"
                        value={form.password}
                        onChange={handleChange}
                        placeholder="Min. 8 characters"
                        className="w-full px-4 py-3 pr-12 rounded-xl bg-white/10 border border-white/20 text-sm text-surface placeholder:text-surface/40 focus:outline-none focus:ring-2 focus:ring-white/30 transition-all"
                      />
                      <button
                        type="button"
                        onClick={() => setShowPassword((v) => !v)}
                        className="absolute right-3 top-1/2 -translate-y-1/2 opacity-60 hover:opacity-100 transition-opacity"
                      >
                        <span className="material-symbols-outlined text-lg">
                          {showPassword ? 'visibility_off' : 'visibility'}
                        </span>
                      </button>
                    </div>
                  </div>

                  {/* Force reset toggle */}
                  <div className="flex items-center justify-between p-4 rounded-xl bg-white/10">
                    <div>
                      <p className="text-sm font-bold">Force Password Reset</p>
                      <p className="text-xs opacity-60 mt-0.5">User must change password on first login.</p>
                    </div>
                    <button
                      type="button"
                      onClick={() => setForceReset((v) => !v)}
                      className={`relative w-11 h-6 rounded-full transition-colors ${forceReset ? 'bg-primary' : 'bg-white/20'}`}
                    >
                      <span
                        className={`absolute top-0.5 w-5 h-5 rounded-full bg-white shadow transition-transform ${
                          forceReset ? 'translate-x-5' : 'translate-x-0.5'
                        }`}
                      />
                    </button>
                  </div>
                </div>

                {/* Decorative blob */}
                <span className="material-symbols-outlined absolute -bottom-6 -right-6 text-9xl opacity-5" style={{ fontVariationSettings: "'FILL' 1" }}>
                  security
                </span>
              </div>
            </div>

            {/* ── Right / Sidebar column ───────────────────────────── */}
            <div className="space-y-6">

              {/* Avatar upload */}
              <div className="bg-surface-container-lowest rounded-xl border border-outline-variant/15 shadow-sm p-6">
                <h3 className="text-xs font-bold uppercase tracking-widest text-secondary mb-4">Profile Photo</h3>
                <div className="flex flex-col items-center gap-4">
                  <div className="w-24 h-24 rounded-full bg-surface-container-high border-2 border-dashed border-outline-variant/40 flex flex-col items-center justify-center text-secondary hover:border-primary hover:text-primary transition-colors cursor-pointer">
                    <span className="material-symbols-outlined text-3xl">add_a_photo</span>
                    <span className="text-[9px] font-bold uppercase tracking-wider mt-1">Upload</span>
                  </div>
                  <p className="text-[10px] text-secondary text-center leading-relaxed">
                    JPG, PNG or GIF · Max 2 MB<br />Recommended: 400×400 px
                  </p>
                </div>
              </div>

              {/* Permissions overview */}
              <div className="bg-surface-container-lowest rounded-xl border border-outline-variant/15 shadow-sm p-6">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-xs font-bold uppercase tracking-widest text-secondary">Permissions</h3>
                  <span className="px-2.5 py-1 rounded-full bg-primary/10 text-primary text-[10px] font-bold">
                    {activeRole.title}
                  </span>
                </div>

                <ul className="space-y-2.5">
                  {activeRole.permissions.map((perm) => (
                    <li key={perm} className="flex items-start gap-2.5">
                      <span className="material-symbols-outlined text-primary text-base mt-0.5 flex-shrink-0" style={{ fontVariationSettings: "'FILL' 1" }}>
                        check_circle
                      </span>
                      <span className="text-xs text-on-surface font-medium leading-relaxed">{perm}</span>
                    </li>
                  ))}
                </ul>

                <p className="mt-4 text-[10px] text-secondary leading-relaxed">
                  Permissions are inherited from the selected role and cannot be customised per user in this view.
                </p>
              </div>

              {/* Quick tips */}
              <div className="bg-tertiary-fixed-dim/20 rounded-xl border border-outline-variant/10 p-6">
                <div className="flex items-center gap-2 mb-3">
                  <span className="material-symbols-outlined text-tertiary text-lg">tips_and_updates</span>
                  <h3 className="text-xs font-bold uppercase tracking-widest text-tertiary">Quick Tip</h3>
                </div>
                <p className="text-xs text-secondary leading-relaxed">
                  New users receive a welcome email with login instructions. The temporary password expires after 24 hours if not used.
                </p>
              </div>
            </div>
          </div>

          {/* Action bar */}
          <div className="mt-10 flex items-center justify-between pt-6 border-t border-outline-variant/15">
            <button
              type="button"
              onClick={() => navigate('/settings')}
              className="px-6 py-3 rounded-xl border border-outline-variant/30 text-on-surface font-semibold text-sm hover:bg-surface-container-low transition-all"
            >
              Discard
            </button>
            <button
              type="submit"
              className="px-8 py-3 rounded-xl bg-gradient-to-br from-primary to-primary-container text-white font-bold text-sm shadow-lg hover:brightness-110 transition-all flex items-center gap-2"
            >
              <span className="material-symbols-outlined text-lg" style={{ fontVariationSettings: "'FILL' 1" }}>person_add</span>
              Create User
            </button>
          </div>
        </form>

      </div>
    </main>
  );
}
