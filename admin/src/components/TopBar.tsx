import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export default function TopBar() {
  const [query, setQuery] = useState('');
  const navigate = useNavigate();
  const { user, logout } = useAuth();

  const displayName = user?.fullName?.trim() || 'Administrator';
  const initials = displayName
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((n) => n[0]?.toUpperCase() ?? '')
    .join('') || 'AD';

  const handleLogout = () => {
    logout();
    navigate('/login', { replace: true });
  };

  return (
    <header className="fixed top-0 right-0 w-[calc(100%-16rem)] h-16 z-40 bg-white/85 backdrop-blur-md shadow-sm border-b border-neutral-100 flex justify-between items-center px-8">
      {/* Search */}
      <div className="flex items-center flex-1 max-w-xl">
        <div className="relative w-full">
          <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-neutral-400 text-[20px]">
            search
          </span>
          <input
            className="w-full bg-surface-container-highest border-none rounded-xl pl-10 pr-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500/20 transition-all"
            placeholder="Search orders, shoppers, or transactions..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
        </div>
      </div>

      {/* Right actions */}
      <div className="flex items-center gap-6">
        <div className="flex items-center gap-4 text-neutral-500">
          <button className="hover:text-emerald-500 transition-colors relative">
            <span className="material-symbols-outlined">notifications</span>
            <span className="absolute top-0 right-0 w-2 h-2 bg-tertiary rounded-full" />
          </button>
          <button className="hover:text-emerald-500 transition-colors flex items-center gap-1">
            <span className="material-symbols-outlined">help_outline</span>
            <span className="text-sm font-medium">Support</span>
          </button>
        </div>

        <div className="h-8 w-px bg-neutral-200" />

        <div className="flex items-center gap-3">
          <span className="text-sm font-semibold text-on-surface">{displayName}</span>
          <div className="w-8 h-8 rounded-full bg-emerald-100 flex items-center justify-center text-emerald-700 font-bold text-xs flex-shrink-0">
            {initials}
          </div>
        </div>

        <button
          onClick={handleLogout}
          className="inline-flex items-center gap-1 px-3 py-1.5 rounded-lg border border-red-200 text-red-600 text-xs font-bold uppercase tracking-wide hover:bg-red-50 transition-colors"
          title="Log out"
        >
          <span className="material-symbols-outlined text-sm">logout</span>
          Logout
        </button>
      </div>
    </header>
  );
}
