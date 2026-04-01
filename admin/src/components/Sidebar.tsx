import { NavLink } from 'react-router-dom';

const navItems = [
  { to: '/dashboard', icon: 'dashboard', label: 'Dashboard' },
  { to: '/orders', icon: 'shopping_cart', label: 'Orders' },
  { to: '/shoppers', icon: 'delivery_dining', label: 'Shoppers' },
  { to: '/customers', icon: 'group', label: 'Customers' },
  { to: '/markets', icon: 'storefront', label: 'Markets' },
  { to: '/earnings', icon: 'payments', label: 'Earnings' },
  { to: '/settings', icon: 'settings', label: 'Settings' },
];

export default function Sidebar() {
  return (
    <aside className="h-screen w-64 fixed left-0 top-0 overflow-y-auto bg-neutral-900 shadow-2xl z-50 border-r border-neutral-800 flex flex-col py-6">
      {/* Brand */}
      <div className="px-6 mb-10">
        <h1 className="text-emerald-500 font-bold text-xl tracking-tighter">SwiftShopper</h1>
        <p className="text-neutral-500 text-xs font-medium uppercase tracking-widest mt-1">Admin Portal</p>
      </div>

      {/* Nav */}
      <nav className="flex-1 space-y-1 px-2 custom-scrollbar">
        {navItems.map(({ to, icon, label }) => (
          <NavLink
            key={to}
            to={to}
            className={({ isActive }) =>
              isActive
                ? 'flex items-center gap-3 px-4 py-3 bg-emerald-500/10 text-emerald-500 border-l-4 border-emerald-500 font-medium cursor-pointer transition-all duration-200'
                : 'flex items-center gap-3 px-4 py-3 text-neutral-400 hover:text-white hover:bg-neutral-800 transition-all duration-200 cursor-pointer active:scale-95'
            }
          >
            <span className="material-symbols-outlined">{icon}</span>
            <span className="font-inter antialiased tracking-tight">{label}</span>
          </NavLink>
        ))}
      </nav>

      {/* Profile */}
      <div className="px-6 mt-10 pt-6 border-t border-neutral-800 flex items-center gap-3">
        <div className="w-10 h-10 rounded-full border-2 border-emerald-500/20 bg-emerald-900 flex items-center justify-center text-emerald-400 font-bold text-sm flex-shrink-0">
          AU
        </div>
        <div className="overflow-hidden">
          <p className="text-white text-sm font-bold truncate">Admin User</p>
          <p className="text-neutral-500 text-xs truncate">Head of Logistics</p>
        </div>
      </div>
    </aside>
  );
}
