import { useState, useEffect, useRef, useCallback } from 'react';

const BASE_URL = import.meta.env.VITE_API_URL ?? 'https://footballapi.goserp.co.uk';
const CACHE_TTL_MS = 24 * 60 * 60 * 1000; // 24 hours

interface Prediction {
  placeId: string;
  description: string;
}

export interface PlaceResult {
  address: string;
  lat: number;
  lng: number;
}

interface Props {
  initialValue?: string;
  onPlaceSelected: (result: PlaceResult) => void;
  className?: string;
  inputClassName?: string;
  label?: string;
  placeholder?: string;
}

// ── Cache ──────────────────────────────────────────────────────────────────

function cacheGet(query: string): Prediction[] | null {
  try {
    const raw = localStorage.getItem(`gplaces_${query}`);
    if (!raw) return null;
    const { ts, data } = JSON.parse(raw) as { ts: number; data: Prediction[] };
    if (Date.now() - ts > CACHE_TTL_MS) {
      localStorage.removeItem(`gplaces_${query}`);
      return null;
    }
    return data;
  } catch { return null; }
}

function cacheSet(query: string, data: Prediction[]) {
  try {
    localStorage.setItem(`gplaces_${query}`, JSON.stringify({ ts: Date.now(), data }));
  } catch { /* storage full — skip */ }
}

// ── Session token ──────────────────────────────────────────────────────────

function newToken() { return crypto.randomUUID(); }

// ── Component ──────────────────────────────────────────────────────────────

export default function PlacesAutocomplete({
  initialValue = '',
  onPlaceSelected,
  className = '',
  inputClassName = '',
  label,
  placeholder = 'Search address…',
}: Props) {
  const [value, setValue] = useState(initialValue);
  const [predictions, setPredictions] = useState<Prediction[]>([]);
  const [status, setStatus] = useState<'idle' | 'loading' | 'results' | 'no-results' | 'error' | 'details-error'>('idle');
  const [open, setOpen] = useState(false);

  const sessionToken = useRef(newToken());
  const debounceTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const inFlight = useRef(new Set<string>());
  const wrapperRef = useRef<HTMLDivElement>(null);
  const suppressSearch = useRef(false);

  // Update value when initialValue changes (e.g. edit modal opens with existing address)
  useEffect(() => { setValue(initialValue); }, [initialValue]);

  // Close dropdown on outside click
  useEffect(() => {
    function onMouseDown(e: MouseEvent) {
      if (wrapperRef.current && !wrapperRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener('mousedown', onMouseDown);
    return () => document.removeEventListener('mousedown', onMouseDown);
  }, []);

  const fetchPredictions = useCallback(async (query: string) => {
    const key = query.toLowerCase().trim();
    if (inFlight.current.has(key)) return;

    const cached = cacheGet(key);
    if (cached) {
      setPredictions(cached);
      setStatus(cached.length ? 'results' : 'no-results');
      setOpen(true);
      return;
    }

    inFlight.current.add(key);
    setStatus('loading');
    try {
      const params = new URLSearchParams({
        query,
        sessiontoken: sessionToken.current,
      });
      const res = await fetch(`${BASE_URL}/api/places/google/autocomplete?${params}`, {
        signal: AbortSignal.timeout(8000),
      });
      if (!res.ok) { setStatus('error'); return; }

      const json = await res.json() as { predictions: Prediction[] };
      const results = json.predictions ?? [];
      cacheSet(key, results);
      setPredictions(results);
      setStatus(results.length ? 'results' : 'no-results');
      setOpen(true);
    } catch (e) {
      console.error('[Places] autocomplete error:', e);
      setStatus('error');
    } finally {
      inFlight.current.delete(key);
    }
  }, []);

  function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
    if (suppressSearch.current) return;
    const v = e.target.value;
    setValue(v);
    if (status === 'details-error') setStatus('idle');

    if (debounceTimer.current) clearTimeout(debounceTimer.current);

    const trimmed = v.trim();
    if (trimmed.length < 3) {
      setPredictions([]);
      setStatus('idle');
      setOpen(false);
      return;
    }

    setStatus('loading');
    debounceTimer.current = setTimeout(() => fetchPredictions(trimmed), 400);
  }

  async function selectPrediction(prediction: Prediction) {
    const previousValue = value; // snapshot before we change anything
    suppressSearch.current = true;
    setValue(prediction.description);
    setOpen(false);
    setPredictions([]);
    setStatus('loading');

    const token = sessionToken.current;
    sessionToken.current = newToken(); // close billing session

    let failed = false;
    try {
      const signal = typeof AbortSignal.timeout === 'function'
        ? AbortSignal.timeout(8000)
        : undefined;
      const params = new URLSearchParams({ placeid: prediction.placeId, sessiontoken: token });
      const res = await fetch(`${BASE_URL}/api/places/google/details?${params}`, { signal });
      if (!res.ok) throw new Error(`details HTTP ${res.status}`);

      const place = await res.json() as PlaceResult;
      if (!place.lat && !place.lng) throw new Error('details returned no coordinates');

      setValue(place.address);
      onPlaceSelected(place);
    } catch (e) {
      console.error('[Places] details error:', e);
      failed = true;
      setValue(previousValue); // revert — don't corrupt parent's lat/lng with zeros
    } finally {
      suppressSearch.current = false;
      setStatus(failed ? 'details-error' : 'idle');
    }
  }

  const showDropdown = open && (status === 'results' || status === 'no-results' || status === 'error');

  return (
    <div ref={wrapperRef} className={className}>
      {label && (
        <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-1.5">
          {label}
        </label>
      )}
      <div className="relative">
        <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-secondary text-lg pointer-events-none select-none">
          location_on
        </span>
        <input
          type="text"
          value={value}
          onChange={handleChange}
          onFocus={() => { if (predictions.length) setOpen(true); }}
          placeholder={placeholder}
          autoComplete="off"
          className={`w-full pl-10 pr-10 text-sm focus:outline-none transition-all ${inputClassName}`}
        />
        {status === 'loading' && (
          <svg
            className="absolute right-3 top-1/2 -translate-y-1/2 animate-spin text-secondary"
            width="16" height="16" viewBox="0 0 24 24" fill="none"
          >
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z" />
          </svg>
        )}
      </div>

      {status === 'details-error' && (
        <p className="mt-1.5 text-xs text-red-500 flex items-center gap-1">
          <span className="material-symbols-outlined text-sm">error</span>
          Could not retrieve coordinates — please try selecting again or check your connection.
        </p>
      )}

      {showDropdown && (
        <div className="absolute z-50 w-full mt-1 bg-white rounded-xl shadow-lg border border-outline-variant/20 overflow-hidden max-h-56 overflow-y-auto">
          {status === 'no-results' && (
            <p className="px-4 py-3 text-sm text-secondary">No results found</p>
          )}
          {status === 'error' && (
            <p className="px-4 py-3 text-sm text-error">Search unavailable — check connection</p>
          )}
          {status === 'results' && predictions.map((p) => (
            <button
              key={p.placeId}
              type="button"
              onMouseDown={() => selectPrediction(p)}
              className="w-full flex items-start gap-3 px-4 py-3 hover:bg-surface-container-low text-left transition-colors border-b border-outline-variant/10 last:border-0"
            >
              <span className="material-symbols-outlined text-base text-secondary mt-0.5 shrink-0">
                location_on
              </span>
              <span className="text-sm text-on-surface leading-snug">{p.description}</span>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
