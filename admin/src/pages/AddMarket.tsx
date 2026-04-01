import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { createMarket, uploadImage } from '../lib/api';

// ── Data ───────────────────────────────────────────────────────────────────

const ALL_CATEGORIES = [
  'Groceries', 'Meat & Fish', 'Grains', 'Electronics',
  'Pharmacy', 'Household', 'Fashion', 'Bakery', 'Beverages',
];

// ── Page ───────────────────────────────────────────────────────────────────

export default function AddMarket() {
  const navigate = useNavigate();

  // Form state
  const [name, setName]           = useState('');
  const [address, setAddress]     = useState('');
  const [type, setType]           = useState('Supermarket');
  const [active, setActive]       = useState(true);
  const [openTime, setOpenTime]   = useState('08:00');
  const [closeTime, setCloseTime] = useState('20:00');
  const [radius, setRadius]       = useState(5.2);
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [imageName, setImageName] = useState('');
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState('');

  const [latitude, setLatitude]   = useState('');
  const [longitude, setLongitude] = useState('');

  const [selectedCats, setSelectedCats] = useState<string[]>(['Groceries', 'Meat & Fish']);

  function toggleCat(cat: string) {
    setSelectedCats((prev) =>
      prev.includes(cat) ? prev.filter((c) => c !== cat) : [...prev, cat]
    );
  }

  function handleImageChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (file) {
      setImageFile(file);
      setImageName(file.name);
    }
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setUploading(true);
    try {
      let photoUrl: string | undefined;
      if (imageFile) {
        photoUrl = await uploadImage(imageFile);
      }
      await createMarket({
        name,
        address,
        type,
        isActive: active,
        openingTime: openTime,
        closingTime: closeTime,
        geofenceRadiusKm: radius,
        categories: selectedCats,
        location: '',
        zone: '',
        photoUrl: photoUrl ?? null,
        latitude: latitude ? parseFloat(latitude) : null,
        longitude: longitude ? parseFloat(longitude) : null,
      });
      navigate('/markets');
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to save market');
    } finally {
      setUploading(false);
    }
  }

  return (
    <main className="pt-10 px-8 pb-16 min-h-screen bg-surface">
      <div className="max-w-6xl mx-auto">

        {/* Breadcrumb + header */}
        <div className="mb-8 flex flex-col sm:flex-row sm:justify-between sm:items-end gap-4">
          <div>
            <nav className="flex items-center gap-2 text-xs text-secondary mb-2">
              <Link to="/markets" className="hover:text-primary transition-colors">Markets</Link>
              <span className="material-symbols-outlined text-[10px]">chevron_right</span>
              <span className="text-on-surface font-medium">Add New Market</span>
            </nav>
            <h2 className="text-3xl font-extrabold tracking-tight text-on-surface">New Market Hub</h2>
            <p className="text-secondary mt-1 text-sm">Configure a new geographical shopping hub for SwiftShopper logistics.</p>
          </div>
          <div className="flex gap-3 shrink-0">
            <button
              type="button"
              onClick={() => navigate('/markets')}
              className="px-6 py-2.5 rounded-xl border border-outline-variant text-on-surface font-medium hover:bg-surface-container-low transition-colors text-sm"
            >
              Cancel
            </button>
            <button
              type="submit"
              form="add-market-form"
              disabled={uploading}
              className="px-8 py-2.5 rounded-xl bg-gradient-to-br from-primary to-primary-container text-white font-bold shadow-lg hover:brightness-110 transition-all text-sm flex items-center gap-2 active:scale-95 disabled:opacity-60"
            >
              {uploading ? (
                <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              ) : (
                <span className="material-symbols-outlined text-sm">save</span>
              )}
              {uploading ? 'Saving...' : 'Save Market'}
            </button>
          </div>
        </div>

        {error && (
          <div className="mb-4 px-4 py-3 bg-error-container text-on-error-container rounded-xl text-sm font-medium">
            {error}
          </div>
        )}

        <form id="add-market-form" onSubmit={handleSubmit}>
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">

            {/* ── Left column (2/3) ─────────────────────────────── */}
            <div className="lg:col-span-2 flex flex-col gap-8">

              {/* General Information */}
              <section className="bg-surface-container-lowest p-8 rounded-xl shadow-sm border border-outline-variant/10">
                <div className="flex items-center gap-2 mb-6">
                  <span
                    className="material-symbols-outlined text-primary"
                    style={{ fontVariationSettings: "'FILL' 1" }}
                  >
                    info
                  </span>
                  <h3 className="text-lg font-bold text-on-surface">General Information</h3>
                </div>

                <div className="grid grid-cols-2 gap-6">
                  {/* Market Name */}
                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-2">
                      Market Name
                    </label>
                    <input
                      type="text"
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                      placeholder="e.g. Lekki Central Mall"
                      className="w-full px-4 py-3 bg-surface-container-low border-none rounded-xl focus:outline-none focus:ring-2 focus:ring-primary focus:bg-white transition-all text-sm placeholder:text-secondary/50"
                    />
                  </div>

                  {/* Market Image */}
                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-2">
                      Market Image
                    </label>
                    <label className="relative flex items-center justify-center w-full h-[52px] px-4 bg-surface-container-low border-2 border-dashed border-outline-variant/30 rounded-xl hover:border-primary/50 hover:bg-white transition-all cursor-pointer group">
                      <div className="flex items-center gap-2">
                        <span className="material-symbols-outlined text-secondary group-hover:text-primary text-xl transition-colors">
                          add_a_photo
                        </span>
                        {imageName ? (
                          <p className="text-xs font-medium text-on-surface truncate max-w-[140px]">{imageName}</p>
                        ) : (
                          <p className="text-xs text-secondary font-medium group-hover:text-primary transition-colors">
                            Drag &amp; drop or <span className="text-primary font-bold underline">browse</span>
                          </p>
                        )}
                      </div>
                      <input
                        type="file"
                        accept="image/*"
                        className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                        onChange={handleImageChange}
                      />
                    </label>
                  </div>

                  {/* Market Type */}
                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-2">
                      Market Type
                    </label>
                    <div className="relative">
                      <select
                        value={type}
                        onChange={(e) => setType(e.target.value)}
                        className="w-full px-4 py-3 bg-surface-container-low border-none rounded-xl focus:outline-none focus:ring-2 focus:ring-primary focus:bg-white transition-all text-sm appearance-none cursor-pointer"
                      >
                        <option>Supermarket</option>
                        <option>Local Open Market</option>
                        <option>Specialty Store</option>
                        <option>Mall</option>
                      </select>
                      <span className="material-symbols-outlined absolute right-3 top-1/2 -translate-y-1/2 text-secondary pointer-events-none text-lg">
                        expand_more
                      </span>
                    </div>
                  </div>

                  {/* Service Status */}
                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-2">
                      Service Status
                    </label>
                    <div className="flex items-center gap-3 h-[52px] px-1">
                      <button
                        type="button"
                        role="switch"
                        aria-checked={active}
                        onClick={() => setActive((v) => !v)}
                        className={`relative flex-shrink-0 w-12 h-7 rounded-full transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-primary/40 ${
                          active ? 'bg-primary' : 'bg-neutral-300'
                        }`}
                      >
                        <span
                          className={`absolute top-1 left-1 w-5 h-5 rounded-full bg-white shadow-md transition-transform duration-200 ${
                            active ? 'translate-x-5' : 'translate-x-0'
                          }`}
                        />
                      </button>
                      <span className={`text-sm font-semibold ${active ? 'text-primary' : 'text-secondary'}`}>
                        {active ? 'Active' : 'Inactive'}
                      </span>
                    </div>
                  </div>

                  {/* Full Address */}
                  <div className="col-span-2">
                    <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-2">
                      Full Address
                    </label>
                    <div className="relative">
                      <span className="material-symbols-outlined absolute left-3 top-3.5 text-secondary text-lg">
                        location_on
                      </span>
                      <input
                        type="text"
                        value={address}
                        onChange={(e) => setAddress(e.target.value)}
                        placeholder="Enter physical address in Lagos..."
                        className="w-full pl-10 pr-4 py-3 bg-surface-container-low border-none rounded-xl focus:outline-none focus:ring-2 focus:ring-primary focus:bg-white transition-all text-sm placeholder:text-secondary/50"
                      />
                    </div>
                  </div>

                  {/* GPS Coordinates */}
                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-2">
                      Latitude
                    </label>
                    <div className="relative">
                      <span className="material-symbols-outlined absolute left-3 top-3.5 text-secondary text-lg">
                        explore
                      </span>
                      <input
                        type="number"
                        step="any"
                        value={latitude}
                        onChange={(e) => setLatitude(e.target.value)}
                        placeholder="e.g. 6.5244"
                        className="w-full pl-10 pr-4 py-3 bg-surface-container-low border-none rounded-xl focus:outline-none focus:ring-2 focus:ring-primary focus:bg-white transition-all text-sm placeholder:text-secondary/50"
                      />
                    </div>
                  </div>
                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-2">
                      Longitude
                    </label>
                    <div className="relative">
                      <span className="material-symbols-outlined absolute left-3 top-3.5 text-secondary text-lg">
                        explore
                      </span>
                      <input
                        type="number"
                        step="any"
                        value={longitude}
                        onChange={(e) => setLongitude(e.target.value)}
                        placeholder="e.g. 3.3792"
                        className="w-full pl-10 pr-4 py-3 bg-surface-container-low border-none rounded-xl focus:outline-none focus:ring-2 focus:ring-primary focus:bg-white transition-all text-sm placeholder:text-secondary/50"
                      />
                    </div>
                  </div>
                </div>
              </section>

              {/* Logistics & Operations */}
              <section className="bg-surface-container-lowest p-8 rounded-xl shadow-sm border border-outline-variant/10">
                <div className="flex items-center gap-2 mb-6">
                  <span
                    className="material-symbols-outlined text-primary"
                    style={{ fontVariationSettings: "'FILL' 1" }}
                  >
                    schedule
                  </span>
                  <h3 className="text-lg font-bold text-on-surface">Logistics &amp; Operations</h3>
                </div>

                <div className="space-y-8">
                  {/* Category chips */}
                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-3">
                      Market Categories
                    </label>
                    <div className="flex flex-wrap gap-2">
                      {ALL_CATEGORIES.map((cat) => {
                        const on = selectedCats.includes(cat);
                        return (
                          <button
                            key={cat}
                            type="button"
                            onClick={() => toggleCat(cat)}
                            className={`px-4 py-1.5 rounded-full text-xs font-bold flex items-center gap-1.5 transition-all ${
                              on
                                ? 'bg-primary-fixed-dim text-on-primary-fixed-variant border border-primary/20'
                                : 'bg-surface-container-highest text-secondary hover:bg-surface-container-high'
                            }`}
                          >
                            {cat}
                            {on && <span className="material-symbols-outlined text-[14px]">close</span>}
                          </button>
                        );
                      })}
                    </div>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-8">
                    {/* Operational Hours */}
                    <div>
                      <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-4">
                        Operational Hours
                      </label>
                      <div className="flex items-center gap-3">
                        <div className="flex-1">
                          <p className="text-[10px] text-secondary mb-1 uppercase font-bold">Opening</p>
                          <input
                            type="time"
                            value={openTime}
                            onChange={(e) => setOpenTime(e.target.value)}
                            className="w-full px-3 py-2.5 bg-surface-container-low border-none rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary/30"
                          />
                        </div>
                        <span className="mt-4 text-secondary text-sm">to</span>
                        <div className="flex-1">
                          <p className="text-[10px] text-secondary mb-1 uppercase font-bold">Closing</p>
                          <input
                            type="time"
                            value={closeTime}
                            onChange={(e) => setCloseTime(e.target.value)}
                            className="w-full px-3 py-2.5 bg-surface-container-low border-none rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary/30"
                          />
                        </div>
                      </div>
                    </div>

                    {/* Geofence Radius */}
                    <div>
                      <div className="flex justify-between items-end mb-4">
                        <label className="block text-xs font-bold text-secondary uppercase tracking-wider">
                          Geofence Radius
                        </label>
                        <span className="text-sm font-bold text-primary">{radius.toFixed(1)} km</span>
                      </div>
                      <input
                        type="range"
                        min={1}
                        max={10}
                        step={0.1}
                        value={radius}
                        onChange={(e) => setRadius(parseFloat(e.target.value))}
                        className="w-full h-2 bg-surface-container-highest rounded-lg appearance-none cursor-pointer accent-primary"
                      />
                      <div className="flex justify-between text-[10px] text-secondary mt-2">
                        <span>1 km</span>
                        <span>5 km</span>
                        <span>10 km</span>
                      </div>

                      {/* Visual bar */}
                      <div className="mt-4 h-2 rounded-full bg-surface-container-high overflow-hidden">
                        <div
                          className="h-full bg-gradient-to-r from-primary to-primary-container rounded-full transition-all"
                          style={{ width: `${((radius - 1) / 9) * 100}%` }}
                        />
                      </div>
                    </div>
                  </div>
                </div>
              </section>
            </div>

            {/* ── Right column (1/3) ────────────────────────────── */}
            <div className="flex flex-col gap-6">

              {/* Location Preview / Map */}
              <div className="bg-surface-container-lowest rounded-xl shadow-sm border border-outline-variant/10 overflow-hidden">
                <div className="p-4 border-b border-outline-variant/10 flex justify-between items-center">
                  <h4 className="text-sm font-bold text-on-surface">Location Preview</h4>
                  <span className="px-2 py-0.5 rounded-full bg-tertiary-fixed text-on-tertiary-fixed-variant text-[10px] font-bold">
                    Auto-pin active
                  </span>
                </div>

                {/* Map canvas placeholder */}
                <div className="h-64 relative overflow-hidden bg-surface-container-high group">
                  {/* Styled map background */}
                  <div
                    className="absolute inset-0"
                    style={{
                      background:
                        'radial-gradient(circle at 50% 50%, #e8f5e9 0%, #d4edda 100%)',
                    }}
                  />
                  <svg className="absolute inset-0 w-full h-full pointer-events-none opacity-25" xmlns="http://www.w3.org/2000/svg">
                    <line x1="0" y1="40%" x2="100%" y2="45%" stroke="#006d39" strokeWidth="3" />
                    <line x1="0" y1="68%" x2="100%" y2="63%" stroke="#006d39" strokeWidth="2" />
                    <line x1="38%" y1="0" x2="42%" y2="100%" stroke="#006d39" strokeWidth="3" />
                    <line x1="68%" y1="0" x2="70%" y2="100%" stroke="#006d39" strokeWidth="1.5" />
                    <line x1="0" y1="22%" x2="100%" y2="26%" stroke="#5f5e5e" strokeWidth="1" strokeDasharray="6 4" />
                    <line x1="18%" y1="0" x2="16%" y2="100%" stroke="#5f5e5e" strokeWidth="1" strokeDasharray="6 4" />
                  </svg>
                  {/* Water */}
                  <div className="absolute bottom-0 right-0 w-1/3 h-1/4 bg-blue-200/50 rounded-tl-3xl" />

                  {/* Geofence ring — scales with radius */}
                  <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
                    <div
                      className="rounded-full bg-primary/15 border-2 border-primary animate-pulse flex items-center justify-center transition-all duration-300"
                      style={{
                        width:  `${40 + ((radius - 1) / 9) * 80}px`,
                        height: `${40 + ((radius - 1) / 9) * 80}px`,
                      }}
                    >
                      <div className="w-2 h-2 rounded-full bg-primary shadow-lg" />
                    </div>
                  </div>

                  {/* Controls */}
                  <div className="absolute bottom-3 right-3 flex flex-col gap-2">
                    <button type="button" className="p-1.5 bg-white rounded-lg shadow-md hover:bg-neutral-50 transition-colors">
                      <span className="material-symbols-outlined text-base text-secondary">my_location</span>
                    </button>
                    <button type="button" className="p-1.5 bg-white rounded-lg shadow-md hover:bg-neutral-50 transition-colors">
                      <span className="material-symbols-outlined text-base text-secondary">fullscreen</span>
                    </button>
                  </div>

                  {/* Address label */}
                  {address && (
                    <div className="absolute top-3 left-3 right-12 bg-white/90 backdrop-blur-sm rounded-lg px-3 py-1.5 shadow text-[11px] font-medium text-on-surface truncate">
                      {address}
                    </div>
                  )}
                </div>

                <div className="p-4 bg-surface-container-low/50">
                  <p className="text-xs text-secondary italic flex items-start gap-2">
                    <span className="material-symbols-outlined text-sm mt-0.5 shrink-0">tips_and_updates</span>
                    The geofence radius defines the maximum delivery distance for shoppers assigned to this hub.
                  </p>
                </div>
              </div>

              {/* Estimated Coverage */}
              <div className="bg-surface-container-lowest p-6 rounded-xl shadow-sm border border-outline-variant/10">
                <h4 className="text-sm font-bold text-on-surface mb-4">Estimated Coverage</h4>
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <span className="w-2 h-2 rounded-full bg-primary" />
                      <span className="text-xs text-secondary font-medium">Potential Customers</span>
                    </div>
                    <span className="text-sm font-bold text-on-surface">12.4k</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <span className="w-2 h-2 rounded-full bg-tertiary" />
                      <span className="text-xs text-secondary font-medium">Competition Level</span>
                    </div>
                    <span className="text-sm font-bold text-tertiary">Medium</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <span className="w-2 h-2 rounded-full bg-blue-500" />
                      <span className="text-xs text-secondary font-medium">Available Shoppers</span>
                    </div>
                    <span className="text-sm font-bold text-on-surface">48</span>
                  </div>
                </div>

                <div className="mt-6 pt-6 border-t border-outline-variant/10">
                  <button
                    type="button"
                    className="w-full py-2.5 bg-secondary-container text-on-secondary-fixed text-xs font-bold rounded-lg hover:brightness-95 transition-all flex items-center justify-center gap-2"
                  >
                    <span className="material-symbols-outlined text-sm">analytics</span>
                    Run Simulation
                  </button>
                </div>
              </div>

              {/* Quick tips */}
              <div className="bg-tertiary-fixed-dim/20 rounded-xl border border-outline-variant/10 p-5">
                <div className="flex items-center gap-2 mb-3">
                  <span className="material-symbols-outlined text-tertiary text-lg">lightbulb</span>
                  <h4 className="text-xs font-bold uppercase tracking-widest text-tertiary">Quick Tips</h4>
                </div>
                <ul className="space-y-2.5">
                  {[
                    'Use a geofence of 3–6 km for dense urban markets.',
                    'Specialty stores benefit from tighter, 1–2 km zones.',
                    'Add high-demand categories to improve shopper matching.',
                  ].map((tip) => (
                    <li key={tip} className="flex items-start gap-2">
                      <span className="material-symbols-outlined text-tertiary text-sm mt-0.5 shrink-0">check_circle</span>
                      <span className="text-xs text-secondary leading-relaxed">{tip}</span>
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          </div>
        </form>
      </div>
    </main>
  );
}
