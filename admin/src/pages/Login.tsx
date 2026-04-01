import { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export default function Login() {
  const navigate = useNavigate();
  const location = useLocation();
  const { login } = useAuth();
  const [showPassword, setShowPassword] = useState(false);
  const [keepLoggedIn, setKeepLoggedIn] = useState(false);
  const [form, setForm] = useState({ email: '', password: '' });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
    setForm((prev) => ({ ...prev, [e.target.name]: e.target.value }));
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await login(form.email, form.password);
      const from = (location.state as { from?: { pathname: string } })?.from?.pathname || '/dashboard';
      navigate(from, { replace: true });
    } catch {
      setError('Invalid credentials. Please check your email and password.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen flex flex-col bg-surface font-body text-on-surface antialiased">

      {/* Main */}
      <main className="flex-grow flex items-center justify-center p-6 bg-[radial-gradient(#bccabc_0.5px,transparent_0.5px)] [background-size:24px_24px]">
        <div className="w-full max-w-[480px]">

          {/* Branding */}
          <div className="flex flex-col items-center mb-10">
            <div className="flex items-center gap-2 mb-6">
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-primary to-primary-container flex items-center justify-center shadow-lg shadow-primary/20">
                <span
                  className="material-symbols-outlined text-white text-3xl"
                  style={{ fontVariationSettings: "'FILL' 1" }}
                >
                  shield_person
                </span>
              </div>
              <span className="text-2xl font-extrabold tracking-tighter text-on-surface uppercase">
                SwiftShopper
              </span>
            </div>
            <h1 className="text-3xl font-bold text-on-surface tracking-tight mb-2">Admin Portal Login</h1>
            <p className="text-secondary text-center text-sm max-w-[320px]">
              Welcome back, please enter your credentials to manage the platform.
            </p>
          </div>

          {/* Card */}
          <div className="bg-surface-container-lowest rounded-xl shadow-[0px_4px_20px_rgba(26,28,28,0.04),0px_12px_40px_rgba(26,28,28,0.08)] p-8 md:p-10 relative overflow-hidden">
            {/* Top accent bar */}
            <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-primary to-primary-container" />

            <form className="space-y-6" onSubmit={handleSubmit}>

              {/* Email */}
              <div className="space-y-2">
                <label
                  htmlFor="email"
                  className="text-xs font-semibold uppercase tracking-widest text-on-surface-variant ml-1"
                >
                  Email Address
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-outline">
                    <span className="material-symbols-outlined text-[20px]">mail</span>
                  </div>
                  <input
                    id="email"
                    name="email"
                    type="email"
                    required
                    value={form.email}
                    onChange={handleChange}
                    placeholder="admin@swiftshopper.com"
                    className="block w-full pl-11 pr-4 py-3.5 bg-surface-container-highest border border-transparent rounded-xl focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent transition-all placeholder:text-outline/60 text-on-surface"
                  />
                </div>
              </div>

              {/* Password */}
              <div className="space-y-2">
                <div className="flex justify-between items-center px-1">
                  <label
                    htmlFor="password"
                    className="text-xs font-semibold uppercase tracking-widest text-on-surface-variant"
                  >
                    Password
                  </label>
                  <a href="#" className="text-xs font-medium text-primary hover:text-primary-container transition-colors">
                    Forgot Password?
                  </a>
                </div>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-outline">
                    <span className="material-symbols-outlined text-[20px]">lock</span>
                  </div>
                  <input
                    id="password"
                    name="password"
                    type={showPassword ? 'text' : 'password'}
                    required
                    value={form.password}
                    onChange={handleChange}
                    placeholder="••••••••••••"
                    className="block w-full pl-11 pr-12 py-3.5 bg-surface-container-highest border border-transparent rounded-xl focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent transition-all placeholder:text-outline/60 text-on-surface"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword((v) => !v)}
                    className="absolute inset-y-0 right-0 pr-4 flex items-center text-outline hover:text-on-surface transition-colors"
                  >
                    <span className="material-symbols-outlined text-[20px]">
                      {showPassword ? 'visibility_off' : 'visibility'}
                    </span>
                  </button>
                </div>
              </div>

              {/* Keep me logged in */}
              <div className="flex items-center px-1">
                <label className="relative flex items-center cursor-pointer group">
                  <input
                    type="checkbox"
                    className="sr-only peer"
                    checked={keepLoggedIn}
                    onChange={(e) => setKeepLoggedIn(e.target.checked)}
                  />
                  <div className="w-5 h-5 border-2 border-outline-variant rounded bg-surface-container-lowest peer-checked:bg-primary peer-checked:border-primary transition-all duration-200" />
                  {keepLoggedIn && (
                    <span className="absolute left-[2.5px] top-[1px] text-white pointer-events-none">
                      <span
                        className="material-symbols-outlined text-[15px]"
                        style={{ fontVariationSettings: "'wght' 700" }}
                      >
                        check
                      </span>
                    </span>
                  )}
                  <span className="ml-3 text-sm text-secondary group-hover:text-on-surface transition-colors">
                    Keep me logged in
                  </span>
                </label>
              </div>

              {/* Error */}
              {error && (
                <div className="flex items-center gap-2 px-4 py-3 bg-red-50 border border-red-200 rounded-xl text-red-700 text-sm">
                  <span className="material-symbols-outlined text-[18px] flex-shrink-0">error</span>
                  {error}
                </div>
              )}

              {/* Submit */}
              <button
                type="submit"
                disabled={loading}
                className="w-full py-4 rounded-xl bg-gradient-to-r from-primary to-primary-container text-white font-bold tracking-tight shadow-lg shadow-primary/20 hover:shadow-xl hover:shadow-primary/30 active:scale-[0.98] transition-all flex items-center justify-center gap-2 disabled:opacity-60 disabled:cursor-not-allowed"
              >
                {loading ? (
                  <>
                    <span className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                    <span>Signing In...</span>
                  </>
                ) : (
                  <>
                    <span>Sign In</span>
                    <span className="material-symbols-outlined text-[20px]">arrow_forward</span>
                  </>
                )}
              </button>
            </form>

            {/* Security badges */}
            <div className="mt-8 pt-8 border-t border-outline-variant/20">
              <div className="flex items-center justify-center gap-6 opacity-60">
                <div className="flex items-center gap-1.5">
                  <span className="material-symbols-outlined text-sm">verified_user</span>
                  <span className="text-[10px] font-bold uppercase tracking-tighter">Secure Link</span>
                </div>
                <div className="flex items-center gap-1.5">
                  <span className="material-symbols-outlined text-sm">encrypted</span>
                  <span className="text-[10px] font-bold uppercase tracking-tighter">256-bit AES</span>
                </div>
              </div>
            </div>
          </div>

          {/* Support link */}
          <p className="mt-8 text-center text-secondary text-sm">
            Having trouble logging in?{' '}
            <a
              href="#"
              className="text-on-surface font-semibold underline underline-offset-4 decoration-primary/30 hover:decoration-primary"
            >
              Contact IT Support
            </a>
          </p>
        </div>
      </main>

      {/* Footer */}
      <footer className="bg-zinc-50 py-8 border-t border-zinc-200/50">
        <div className="flex flex-col md:flex-row justify-between items-center px-6 w-full max-w-7xl mx-auto gap-4">
          <span className="text-xs uppercase tracking-widest text-zinc-500">
            © 2024 SwiftShopper Systems. All rights reserved.
          </span>
          <div className="flex gap-6">
            {['Privacy Policy', 'Terms of Service', 'Security', 'Help Center'].map((label) => (
              <a
                key={label}
                href="#"
                className="text-xs uppercase tracking-widest text-zinc-500 hover:text-emerald-600 transition-colors opacity-80 hover:opacity-100"
              >
                {label}
              </a>
            ))}
          </div>
        </div>
      </footer>

    </div>
  );
}
