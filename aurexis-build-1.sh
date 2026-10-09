#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# aurexis-full-build.sh — Part 1 of 3
# Config · Types · Stores · Hooks · Lib
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

mkdir -p src/{app,types,store,hooks,lib,data,styles}
mkdir -p src/components/{shared,ui,layout,hero,bento,velocity,ontology,industrial,proof}

# ── Config (7) ──────────────────────────────────────────────────

cat > package.json << 'AUREXIS_EOF'
{
  "name": "aurexis-systems",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "typecheck": "tsc --noEmit",
    "format": "prettier --write ."
  },
  "dependencies": {
    "@radix-ui/react-accordion": "^1.2.1",
    "@radix-ui/react-dialog": "^1.1.2",
    "@radix-ui/react-label": "^2.1.0",
    "@radix-ui/react-select": "^2.1.2",
    "@radix-ui/react-separator": "^1.1.0",
    "@radix-ui/react-slot": "^1.1.0",
    "@radix-ui/react-switch": "^1.1.1",
    "@radix-ui/react-tabs": "^1.1.1",
    "@radix-ui/react-tooltip": "^1.1.3",
    "class-variance-authority": "^0.7.0",
    "clsx": "^2.1.1",
    "framer-motion": "^11.3.19",
    "lucide-react": "^0.460.0",
    "next": "^14.2.15",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "tailwind-merge": "^2.5.4",
    "zustand": "^5.0.1"
  },
  "devDependencies": {
    "@types/node": "^20.16.11",
    "@types/react": "^18.3.11",
    "@types/react-dom": "^18.3.0",
    "autoprefixer": "^10.4.20",
    "eslint": "^8.57.1",
    "eslint-config-next": "^14.2.15",
    "postcss": "^8.4.47",
    "prettier": "^3.3.3",
    "prettier-plugin-tailwindcss": "^0.6.8",
    "tailwindcss": "^3.4.13",
    "typescript": "^5.6.3"
  }
}
AUREXIS_EOF

cat > tsconfig.json << 'AUREXIS_EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./src/*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
AUREXIS_EOF

cat > next.config.mjs << 'AUREXIS_EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  experimental: {
    optimizePackageImports: ['lucide-react', 'framer-motion'],
  },
  compiler: {
    removeConsole: process.env.NODE_ENV === 'production',
  },
};
export default nextConfig;
AUREXIS_EOF

cat > postcss.config.mjs << 'AUREXIS_EOF'
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
AUREXIS_EOF

cat > tailwind.config.ts << 'AUREXIS_EOF'
import type { Config } from 'tailwindcss';

const config: Config = {
  darkMode: ['class'],
  content: [
    './src/app/**/*.{ts,tsx}',
    './src/components/**/*.{ts,tsx}',
    './src/lib/**/*.{ts,tsx}',
    './src/data/**/*.{ts,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        bg: '#090909',
        surface: '#1A1A1A',
        'surface-hover': '#222222',
        border: {
          DEFAULT: 'rgba(255,255,255,0.10)',
          hover: 'rgba(255,255,255,0.20)',
        },
        fg: { DEFAULT: '#F5F5F5' },
        muted: { DEFAULT: '#99999F' },
        dim: { DEFAULT: '#626269' },
        bronze: {
          DEFAULT: '#87776C',
          hover: '#9C8A7C',
          dim: '#5C5147',
        },
        gold: {
          DEFAULT: '#B8935F',
          hover: '#C9A56C',
        },
        danger: {
          DEFAULT: '#E5484D',
          dim: '#6B2A2D',
        },
      },
      fontFamily: {
        sans: ['var(--font-inter)', 'system-ui', 'sans-serif'],
        mono: ['var(--font-jetbrains)', 'monospace'],
      },
      fontSize: {
        display: ['clamp(2.5rem, 6vw, 4.5rem)', { lineHeight: '1.05', letterSpacing: '-0.03em', fontWeight: '600' }],
        headline: ['clamp(1.75rem, 3.5vw, 2.5rem)', { lineHeight: '1.15', letterSpacing: '-0.02em', fontWeight: '600' }],
      },
      borderRadius: { xl: '12px' },
      maxWidth: { '7xl': '1280px' },
      transitionTimingFunction: { smooth: 'cubic-bezier(0.22, 1, 0.36, 1)' },
      keyframes: {
        'border-beam': { '100%': { 'offset-distance': '100%' } },
        'pulse-dot': {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0.4' },
        },
      },
      animation: {
        'border-beam': 'border-beam 3s linear infinite',
        'pulse-dot': 'pulse-dot 2s ease-in-out infinite',
      },
    },
  },
  plugins: [],
};
export default config;
AUREXIS_EOF

cat > .eslintrc.json << 'AUREXIS_EOF'
{
  "extends": ["next/core-web-vitals", "next/typescript"],
  "rules": {
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/ban-ts-comment": "error",
    "react/no-unescaped-entities": "off",
    "react-hooks/exhaustive-deps": "error"
  }
}
AUREXIS_EOF

cat > .prettierrc << 'AUREXIS_EOF'
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "all",
  "printWidth": 100,
  "plugins": ["prettier-plugin-tailwindcss"]
}
AUREXIS_EOF

# ── Types (2) ───────────────────────────────────────────────────

cat > src/types/ui.ts << 'AUREXIS_EOF'
import type { ReactNode } from 'react';

export type Mode = 'executive' | 'engineer';

export type CommandItem = {
  id: string;
  label: string;
  hint?: string;
  group: string;
  keywords?: string;
  action: () => void;
};

export type BentoCardId =
  | 'engineering'
  | 'dashboards'
  | 'growth'
  | 'node-flow'
  | 'terminal';

export type CarouselSlide = {
  id: string;
  eyebrow: string;
  title: string;
  body: string;
  bullets: string[];
};

export type Incident = {
  id: string;
  severity: 'info' | 'warning' | 'critical';
  message: string;
  timestamp: number;
};

export type TelemetrySnapshot = {
  uptime: number;
  p95LatencyMs: number;
  requestsPerSec: number;
  incidents: Incident[];
};

export type ServicePillar = {
  id: string;
  number: string;
  title: string;
  description: string;
  capabilities: string[];
};

export type NavItem = {
  label: string;
  href: string;
  description?: string;
};

export type SpecRow = { label: string; value: string };

export type TooltipProps = { children: ReactNode; content: string };
AUREXIS_EOF

cat > src/types/ontology.ts << 'AUREXIS_EOF'
export type OntologyNodeData = {
  id: string;
  label: string;
  type: 'service' | 'database' | 'cache' | 'queue' | 'gateway' | 'worker';
  spec: {
    summary: string;
    rows: { label: string; value: string }[];
  };
};

export type OntologyEdge = { from: string; to: string; label: string };

export type OntologyGraph = { nodes: OntologyNodeData[]; edges: OntologyEdge[] };

export type PipelinePhase = {
  id: string;
  label: string;
  startMs: number;
  durationMs: number;
  parallel: boolean;
};

export type Pipeline = {
  id: string;
  label: string;
  color: string;
  phases: PipelinePhase[];
  totalMs: number;
};
AUREXIS_EOF

# ── Stores (5) ───────────────────────────────────────────────────

cat > src/store/use-mode-store.ts << 'AUREXIS_EOF'
'use client';

/**
 * useModeStore
 * exports: { mode, setMode, toggle }
 */
import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import type { Mode } from '@/types/ui';

type ModeStore = {
  mode: Mode;
  setMode: (mode: Mode) => void;
  toggle: () => void;
};

export const useModeStore = create<ModeStore>()(
  persist(
    (set) => ({
      mode: 'executive',
      setMode: (mode) => set({ mode }),
      toggle: () => set((state) => ({ mode: state.mode === 'executive' ? 'engineer' : 'executive' })),
    }),
    {
      name: 'aurexis-mode',
      storage: createJSONStorage(() => localStorage),
      skipHydration: true,
    },
  ),
);
AUREXIS_EOF

cat > src/store/use-ui-store.ts << 'AUREXIS_EOF'
'use client';

/**
 * useUIStore
 * exports: { paletteOpen, setPaletteOpen,
 *            carouselIndex, setCarouselIndex,
 *            inspectorOpenId, toggleInspector,
 *            activeBentoId, setActiveBento }
 */
import { create } from 'zustand';
import type { BentoCardId } from '@/types/ui';

type UIStore = {
  paletteOpen: boolean;
  inspectorOpenId: string | null;
  activeBentoId: BentoCardId | null;
  carouselIndex: number;
  setPaletteOpen: (open: boolean) => void;
  toggleInspector: (id: string) => void;
  setActiveBento: (id: BentoCardId) => void;
  setCarouselIndex: (index: number) => void;
};

export const useUIStore = create<UIStore>((set) => ({
  paletteOpen: false,
  inspectorOpenId: null,
  activeBentoId: null,
  carouselIndex: 0,
  setPaletteOpen: (open) => set({ paletteOpen: open }),
  toggleInspector: (id) =>
    set((state) => ({ inspectorOpenId: state.inspectorOpenId === id ? null : id })),
  setActiveBento: (id) => set({ activeBentoId: id }),
  setCarouselIndex: (index) => set({ carouselIndex: index }),
}));
AUREXIS_EOF

cat > src/store/use-audio-store.ts << 'AUREXIS_EOF'
'use client';

/**
 * useAudioStore
 * exports: { muted, unlocked, setMuted, unlock }
 */
import { create } from 'zustand';

type AudioStore = {
  muted: boolean;
  unlocked: boolean;
  setMuted: (muted: boolean) => void;
  unlock: () => void;
};

export const useAudioStore = create<AudioStore>((set) => ({
  muted: true,
  unlocked: false,
  setMuted: (muted) => set({ muted }),
  unlock: () => set({ unlocked: true }),
}));
AUREXIS_EOF

cat > src/store/use-telemetry-store.ts << 'AUREXIS_EOF'
'use client';

/**
 * useTelemetry
 * exports: { uptime, requestsPerSec, p95LatencyMs,
 *            incidents, tick, setSnapshot, pushIncident }
 */
import { create } from 'zustand';
import type { Incident, TelemetrySnapshot } from '@/types/ui';

type TelemetryStore = {
  uptime: number;
  requestsPerSec: number;
  p95LatencyMs: number;
  incidents: Incident[];
  tick: number;
  setSnapshot: (snapshot: Partial<TelemetrySnapshot>) => void;
  pushIncident: (incident: Incident) => void;
  incrementTick: () => void;
};

export const useTelemetryStore = create<TelemetryStore>((set) => ({
  uptime: 99.99,
  requestsPerSec: 18420,
  p95LatencyMs: 41,
  incidents: [],
  tick: 0,
  setSnapshot: (snapshot) => set((state) => ({ ...state, ...snapshot })),
  pushIncident: (incident) =>
    set((state) => ({ incidents: [...state.incidents, incident].slice(-5) })),
  incrementTick: () => set((state) => ({ tick: state.tick + 1 })),
}));
AUREXIS_EOF

cat > src/store/use-command-store.ts << 'AUREXIS_EOF'
'use client';

/**
 * useCommandStore
 * exports: { items, register, clear }
 */
import { create } from 'zustand';
import type { CommandItem } from '@/types/ui';

type CommandStore = {
  items: CommandItem[];
  register: (item: CommandItem) => void;
  clear: () => void;
};

export const useCommandStore = create<CommandStore>((set) => ({
  items: [],
  register: (item) =>
    set((state) => ({
      items: state.items.some((i) => i.id === item.id) ? state.items : [...state.items, item],
    })),
  clear: () => set({ items: [] }),
}));
AUREXIS_EOF

# ── Hooks (7) ───────────────────────────────────────────────────

cat > src/hooks/use-mounted.ts << 'AUREXIS_EOF'
'use client';
import { useEffect, useState } from 'react';
export function useMounted(): boolean {
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);
  return mounted;
}
AUREXIS_EOF

cat > src/hooks/use-reduced-motion.ts << 'AUREXIS_EOF'
'use client';
import { useEffect, useState } from 'react';
export function useReducedMotion(): boolean {
  const [reduced, setReduced] = useState(false);
  useEffect(() => {
    const mq = window.matchMedia('(prefers-reduced-motion: reduce)');
    setReduced(mq.matches);
    const handler = (e: MediaQueryListEvent) => setReduced(e.matches);
    mq.addEventListener('change', handler);
    return () => mq.removeEventListener('change', handler);
  }, []);
  return reduced;
}
AUREXIS_EOF

cat > src/hooks/use-media-query.ts << 'AUREXIS_EOF'
'use client';
import { useEffect, useState } from 'react';
export function useMediaQuery(query: string): boolean {
  const [matches, setMatches] = useState(false);
  useEffect(() => {
    const mq = window.matchMedia(query);
    setMatches(mq.matches);
    const handler = (e: MediaQueryListEvent) => setMatches(e.matches);
    mq.addEventListener('change', handler);
    return () => mq.removeEventListener('change', handler);
  }, [query]);
  return matches;
}
AUREXIS_EOF

cat > src/hooks/use-animated-number.ts << 'AUREXIS_EOF'
'use client';
import { useEffect, useRef, useState } from 'react';
export function useAnimatedNumber(target: number, duration = 600): number {
  const [display, setDisplay] = useState(target);
  const fromRef = useRef(target);
  const rafRef = useRef<number>();
  useEffect(() => {
    const from = fromRef.current;
    const start = performance.now();
    const delta = target - from;
    if (delta === 0) return;
    const tick = (now: number) => {
      const elapsed = now - start;
      const t = Math.min(elapsed / duration, 1);
      const eased = 1 - Math.pow(1 - t, 3);
      setDisplay(from + delta * eased);
      if (t < 1) {
        rafRef.current = requestAnimationFrame(tick);
      } else {
        fromRef.current = target;
        setDisplay(target);
      }
    };
    rafRef.current = requestAnimationFrame(tick);
    return () => {
      if (rafRef.current) cancelAnimationFrame(rafRef.current);
      fromRef.current = target;
    };
  }, [target, duration]);
  return display;
}
AUREXIS_EOF

cat > src/hooks/use-keyboard-shortcut.ts << 'AUREXIS_EOF'
'use client';
import { useEffect } from 'react';
type Handler = (e: KeyboardEvent) => void;
export function useKeyboardShortcut(
  key: string,
  handler: Handler,
  options: { metaKey?: boolean; ctrlKey?: boolean } = {},
): void {
  useEffect(() => {
    const { metaKey = false, ctrlKey = false } = options;
    const listener = (e: KeyboardEvent) => {
      if (e.key.toLowerCase() !== key.toLowerCase()) return;
      if (metaKey && !e.metaKey && !e.ctrlKey) return;
      if (ctrlKey && !e.ctrlKey) return;
      if (!metaKey && !ctrlKey && (e.metaKey || e.ctrlKey)) return;
      e.preventDefault();
      handler(e);
    };
    window.addEventListener('keydown', listener);
    return () => window.removeEventListener('keydown', listener);
  }, [key, handler, options.metaKey, options.ctrlKey]);
}
AUREXIS_EOF

cat > src/hooks/use-element-size.ts << 'AUREXIS_EOF'
'use client';
import { useCallback, useEffect, useRef, useState } from 'react';
export type Size = { width: number; height: number };
export function useElementSize<T extends HTMLElement>(): [React.RefObject<T>, Size] {
  const ref = useRef<T>(null);
  const [size, setSize] = useState<Size>({ width: 0, height: 0 });
  const measure = useCallback(() => {
    if (!ref.current) return;
    const rect = ref.current.getBoundingClientRect();
    setSize({ width: rect.width, height: rect.height });
  }, []);
  useEffect(() => {
    measure();
    const ro = new ResizeObserver(measure);
    if (ref.current) ro.observe(ref.current);
    return () => ro.disconnect();
  }, [measure]);
  return [ref, size];
}
AUREXIS_EOF

cat > src/hooks/use-knob-drag.ts << 'AUREXIS_EOF'
'use client';
import { useCallback, useEffect, useRef, useState } from 'react';
type KnobDragOptions = {
  min: number;
  max: number;
  step: number;
  initialValue: number;
  onChange: (value: number) => void;
};
export function useKnobDrag(options: KnobDragOptions) {
  const { min, max, step, initialValue, onChange } = options;
  const [angle, setAngle] = useState(0);
  const [value, setValue] = useState(initialValue);
  const dragRef = useRef(false);
  const startRef = useRef({ x: 0, y: 0, angle: 0 });
  const angleFromValue = useCallback(
    (v: number) => {
      const normalized = (v - min) / (max - min);
      return -135 + normalized * 270;
    },
    [min, max],
  );
  const valueFromAngle = useCallback(
    (a: number) => {
      const normalized = (a + 135) / 270;
      const clamped = Math.max(0, Math.min(1, normalized));
      const raw = min + clamped * (max - min);
      const quantized = min + Math.round((raw - min) / step) * step;
      return Math.max(min, Math.min(max, quantized));
    },
    [min, max, step],
  );
  useEffect(() => {
    setAngle(angleFromValue(initialValue));
    setValue(initialValue);
  }, [initialValue, angleFromValue]);
  const onPointerDown = useCallback(
    (e: React.PointerEvent) => {
      dragRef.current = true;
      startRef.current = { x: e.clientX, y: e.clientY, angle };
      (e.target as HTMLElement).setPointerCapture(e.pointerId);
    },
    [angle],
  );
  const onPointerMove = useCallback(
    (e: React.PointerEvent) => {
      if (!dragRef.current) return;
      const dx = e.clientX - startRef.current.x;
      const dy = startRef.current.y - e.clientY;
      const delta = (dx + dy) * 0.8;
      const newAngle = Math.max(-135, Math.min(135, startRef.current.angle + delta));
      setAngle(newAngle);
      const newValue = valueFromAngle(newAngle);
      setValue(newValue);
      onChange(newValue);
    },
    [valueFromAngle, onChange],
  );
  const onPointerUp = useCallback((e: React.PointerEvent) => {
    dragRef.current = false;
    (e.target as HTMLElement).releasePointerCapture(e.pointerId);
  }, []);
  const onKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      let delta = 0;
      if (e.key === 'ArrowLeft' || e.key === 'ArrowDown') delta = -step;
      if (e.key === 'ArrowRight' || e.key === 'ArrowUp') delta = step;
      if (delta === 0) return;
      e.preventDefault();
      const newValue = Math.max(min, Math.min(max, value + delta));
      setValue(newValue);
      setAngle(angleFromValue(newValue));
      onChange(newValue);
    },
    [min, max, step, value, onChange, angleFromValue],
  );
  return { angle, value, onPointerDown, onPointerMove, onPointerUp, onKeyDown };
}
AUREXIS_EOF

# ── Lib (11) ────────────────────────────────────────────────────

cat > src/lib/utils.ts << 'AUREXIS_EOF'
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';
export function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}
export function formatNumber(n: number): string {
  if (n >= 1_000_000) return (n / 1_000_000).toFixed(2) + 'M';
  if (n >= 1_000) return (n / 1_000).toFixed(1) + 'K';
  return n.toFixed(0);
}
export function formatMs(ms: number): string {
  if (ms < 1) return (ms * 1000).toFixed(0) + 'us';
  if (ms < 1000) return ms.toFixed(0) + 'ms';
  return (ms / 1000).toFixed(2) + 's';
}
export function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}
export function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * t;
}
AUREXIS_EOF

cat > src/lib/seo.ts << 'AUREXIS_EOF'
import type { Metadata } from 'next';
export const siteConfig = {
  name: 'Aurexis Systems Inc.',
  description:
    'Elite digital engineering partner for SaaS and fast-scaling tech companies. We remove technical bottlenecks so companies scale revenue and operations without friction.',
  url: 'https://aurexis.com',
  ogImage: 'https://aurexis.com/og.png',
} as const;
export function createMetadata(path = ''): Metadata {
  const url = `${siteConfig.url}${path}`;
  return {
    title: { default: `${siteConfig.name} — Digital Engineering`, template: `%s — ${siteConfig.name}` },
    description: siteConfig.description,
    openGraph: { title: siteConfig.name, description: siteConfig.description, url, siteName: siteConfig.name, locale: 'en_US', type: 'website' },
    twitter: { card: 'summary_large_image', title: siteConfig.name, description: siteConfig.description },
    robots: { index: true, follow: true },
  };
}
AUREXIS_EOF

cat > src/lib/bezier.ts << 'AUREXIS_EOF'
export type Point = { x: number; y: number };
export function cubicBezier(t: number, p0: Point, p1: Point, p2: Point, p3: Point): Point {
  const u = 1 - t;
  const tt = t * t;
  const uu = u * u;
  const uuu = uu * u;
  const ttt = tt * t;
  return {
    x: uuu * p0.x + 3 * uu * t * p1.x + 3 * u * tt * p2.x + ttt * p3.x,
    y: uuu * p0.y + 3 * uu * t * p1.y + 3 * u * tt * p2.y + ttt * p3.y,
  };
}
export function controlPoints(from: Point, to: Point): { p1: Point; p2: Point } {
  const dx = to.x - from.x;
  const offset = 0.4;
  return { p1: { x: from.x + dx * offset, y: from.y }, p2: { x: from.x + dx * (1 - offset), y: to.y } };
}
export function pulseOffset(elapsed: number, velocity: number, index: number, total: number): number {
  const raw = (elapsed * velocity + index / total) % 1;
  return ((raw + 1) % 1 + 1) % 1;
}
export function pointOnPath(t: number, from: Point, to: Point): Point {
  const { p1, p2 } = controlPoints(from, to);
  return cubicBezier(t, from, p1, p2, to);
}
AUREXIS_EOF

cat > src/lib/iso.ts << 'AUREXIS_EOF'
export type IsoPoint = { x: number; y: number };
const COS30 = Math.cos(Math.PI / 6);
const SIN30 = Math.sin(Math.PI / 6);
export function toIso(x: number, y: number, z: number = 0): IsoPoint {
  return { x: (x - y) * COS30, y: (x + y) * SIN30 - z };
}
export function isoCubePoints(size: number, height: number): {
  top: IsoPoint[]; left: IsoPoint[]; right: IsoPoint[];
} {
  const s = size; const h = height;
  const bottom = [toIso(0, 0, 0), toIso(s, 0, 0), toIso(s, s, 0), toIso(0, s, 0)];
  const top = [toIso(0, 0, h), toIso(s, 0, h), toIso(s, s, h), toIso(0, s, h)];
  return {
    top: [top[0]!, top[1]!, top[2]!, top[3]!],
    left: [bottom[3]!, top[3]!, top[2]!, bottom[2]!],
    right: [bottom[2]!, top[2]!, top[1]!, bottom[1]!],
  };
}
export function isoGrid(size: number, cells: number): IsoPoint[][] {
  const grid: IsoPoint[][] = [];
  for (let y = 0; y < cells; y++) {
    const row: IsoPoint[] = [];
    for (let x = 0; x < cells; x++) row.push(toIso(x * size, y * size, 0));
    grid.push(row);
  }
  return grid;
}
export function isoRing(cx: number, cy: number, radius: number, segments: number): IsoPoint[] {
  const points: IsoPoint[] = [];
  for (let i = 0; i <= segments; i++) {
    const angle = (i / segments) * Math.PI * 2;
    points.push({ x: cx + Math.cos(angle) * radius, y: cy + Math.sin(angle) * radius * 0.5 });
  }
  return points;
}
export function isoCylinder(cx: number, cy: number, radius: number, height: number, segments: number): {
  top: IsoPoint[]; bottom: IsoPoint[]; leftVisible: boolean;
} {
  const top: IsoPoint[] = [];
  const bottom: IsoPoint[] = [];
  for (let i = 0; i <= segments; i++) {
    const angle = (i / segments) * Math.PI * 2;
    const x = Math.cos(angle) * radius;
    const y = Math.sin(angle) * radius * 0.5;
    top.push({ x: cx + x, y: cy + y - height });
    bottom.push({ x: cx + x, y: cy + y });
  }
  return { top, bottom, leftVisible: true };
}
AUREXIS_EOF

cat > src/lib/iso-scenes.ts << 'AUREXIS_EOF'
import { isoCubePoints, isoRing, isoCylinder } from './iso';
import type { IsoPoint } from './iso';
export type SceneCommand =
  | { type: 'polygon'; points: IsoPoint[]; fill: string; stroke?: string; strokeWidth?: number; opacity?: number }
  | { type: 'line'; from: IsoPoint; to: IsoPoint; stroke: string; strokeWidth: number; opacity?: number }
  | { type: 'circle'; cx: number; cy: number; r: number; fill: string; stroke?: string; strokeWidth?: number }
  | { type: 'polyline'; points: IsoPoint[]; stroke: string; strokeWidth: number; fill: string; opacity?: number };

export function engineeringScene(cellSize: number): SceneCommand[] {
  const commands: SceneCommand[] = [];
  const base = isoCubePoints(cellSize, cellSize * 0.8);
  commands.push({ type: 'polygon', points: base.left, fill: '#1A1A1A', stroke: '#87776C', strokeWidth: 1, opacity: 0.7 });
  commands.push({ type: 'polygon', points: base.right, fill: '#222222', stroke: '#87776C', strokeWidth: 1, opacity: 0.7 });
  commands.push({ type: 'polygon', points: base.top, fill: '#2A2A2A', stroke: '#87776C', strokeWidth: 1, opacity: 0.9 });
  const small = isoCubePoints(cellSize * 0.5, cellSize * 0.4);
  const ox = cellSize * 0.3; const oy = -cellSize * 0.6 + cellSize * 0.3;
  const st = (arr: IsoPoint[]) => arr.map((p) => ({ x: p.x + ox, y: p.y + oy }));
  commands.push({ type: 'polygon', points: st(small.left), fill: '#1A1A1A', stroke: '#87776C', strokeWidth: 1, opacity: 0.8 });
  commands.push({ type: 'polygon', points: st(small.right), fill: '#1E1E1E', stroke: '#87776C', strokeWidth: 1, opacity: 0.8 });
  commands.push({ type: 'polygon', points: st(small.top), fill: '#282828', stroke: '#87776C', strokeWidth: 1, opacity: 0.9 });
  return commands;
}

export function dashboardsScene(cellSize: number): SceneCommand[] {
  const commands: SceneCommand[] = [];
  commands.push({ type: 'polyline', points: isoRing(0, 0, cellSize * 0.8, 48), stroke: '#87776C', strokeWidth: 1.5, fill: 'none', opacity: 0.6 });
  commands.push({ type: 'polyline', points: isoRing(0, 0, cellSize * 0.5, 32), stroke: '#87776C', strokeWidth: 1, fill: 'none', opacity: 0.4 });
  for (let i = 0; i < 6; i++) {
    const angle = (i / 6) * Math.PI * 2;
    commands.push({ type: 'line', from: { x: 0, y: 0 }, to: { x: Math.cos(angle) * cellSize * 0.8, y: Math.sin(angle) * cellSize * 0.4 }, stroke: '#87776C', strokeWidth: 0.5, opacity: 0.3 });
  }
  const cyl = isoCylinder(0, 0, cellSize * 0.35, cellSize * 0.6, 24);
  commands.push({ type: 'polygon', points: cyl.top, fill: '#2A2A2A', stroke: '#87776C', strokeWidth: 1, opacity: 0.9 });
  commands.push({ type: 'polygon', points: cyl.bottom, fill: '#1A1A1A', stroke: '#87776C', strokeWidth: 1, opacity: 0.7 });
  return commands;
}

export function growthScene(cellSize: number): SceneCommand[] {
  const commands: SceneCommand[] = [];
  const heights = [0.3, 0.5, 0.7, 0.9, 1.2];
  for (let i = 0; i < heights.length; i++) {
    const x = (i - 2) * cellSize * 0.35;
    const h = heights[i]! * cellSize;
    const cube = isoCubePoints(cellSize * 0.25, h);
    const st = (arr: IsoPoint[]) => arr.map((p) => ({ x: p.x + x, y: p.y - h }));
    commands.push({ type: 'polygon', points: st(cube.left), fill: '#1A1A1A', stroke: '#87776C', strokeWidth: 1, opacity: 0.7 });
    commands.push({ type: 'polygon', points: st(cube.right), fill: '#222222', stroke: '#87776C', strokeWidth: 1, opacity: 0.7 });
    commands.push({ type: 'polygon', points: st(cube.top), fill: '#2A2A2A', stroke: '#87776C', strokeWidth: 1, opacity: 0.9 });
  }
  return commands;
}

export function platformScene(cellSize: number): SceneCommand[] {
  const commands: SceneCommand[] = [];
  for (let layer = 0; layer < 3; layer++) {
    const s = cellSize * (0.9 - layer * 0.15);
    const h = cellSize * 0.15;
    const yOff = layer * cellSize * 0.3;
    const cube = isoCubePoints(s, h);
    const st = (arr: IsoPoint[]) => arr.map((p) => ({ x: p.x, y: p.y - yOff }));
    commands.push({ type: 'polygon', points: st(cube.left), fill: '#1A1A1A', stroke: '#87776C', strokeWidth: 1, opacity: 0.6 });
    commands.push({ type: 'polygon', points: st(cube.right), fill: '#222222', stroke: '#87776C', strokeWidth: 1, opacity: 0.6 });
    commands.push({ type: 'polygon', points: st(cube.top), fill: '#282828', stroke: '#87776C', strokeWidth: 1, opacity: 0.85 });
  }
  return commands;
}

export function observabilityScene(cellSize: number): SceneCommand[] {
  const commands: SceneCommand[] = [];
  commands.push({ type: 'polyline', points: isoRing(0, 0, cellSize * 0.9, 64), stroke: '#87776C', strokeWidth: 1, fill: 'none', opacity: 0.5 });
  commands.push({ type: 'polyline', points: isoRing(0, 0, cellSize * 0.6, 48), stroke: '#87776C', strokeWidth: 1, fill: 'none', opacity: 0.4 });
  commands.push({ type: 'polyline', points: isoRing(0, 0, cellSize * 0.3, 32), stroke: '#87776C', strokeWidth: 1, fill: 'none', opacity: 0.3 });
  for (let i = 0; i < 8; i++) {
    const angle = (i / 8) * Math.PI * 2;
    commands.push({ type: 'circle', cx: Math.cos(angle) * cellSize * 0.9, cy: Math.sin(angle) * cellSize * 0.45, r: 3, fill: i % 3 === 0 ? '#B8935F' : '#87776C', stroke: '#090909', strokeWidth: 1 });
  }
  commands.push({ type: 'circle', cx: 0, cy: 0, r: 4, fill: '#B8935F' });
  return commands;
}
AUREXIS_EOF

cat > src/lib/ontology-layout.ts << 'AUREXIS_EOF'
import type { OntologyGraph, OntologyEdge } from '@/types/ontology';
export type LaidOutNode = { id: string; x: number; y: number; layer: number; label: string };
export type LaidOutEdge = { from: string; to: string; fromPoint: { x: number; y: number }; toPoint: { x: number; y: number }; label: string };
export function topologicalLayers(edges: OntologyEdge[]): Map<string, number> {
  const depth = new Map<string, number>();
  const preds = new Map<string, string[]>();
  for (const edge of edges) {
    if (!preds.has(edge.to)) preds.set(edge.to, []);
    preds.get(edge.to)!.push(edge.from);
    if (!depth.has(edge.from)) depth.set(edge.from, 0);
    if (!depth.has(edge.to)) depth.set(edge.to, 0);
  }
  let changed = true;
  while (changed) {
    changed = false;
    for (const node of [...depth.keys()].sort()) {
      const predecessors = preds.get(node) ?? [];
      if (predecessors.length === 0) {
        if (depth.get(node) !== 0) { depth.set(node, 0); changed = true; }
      } else {
        const maxPred = Math.max(...predecessors.map((p) => depth.get(p) ?? 0));
        if (depth.get(node) !== maxPred + 1) { depth.set(node, maxPred + 1); changed = true; }
      }
    }
  }
  return depth;
}
export function layoutOntology(graph: OntologyGraph, cx: number, cy: number, radius: number): { nodes: LaidOutNode[]; edges: LaidOutEdge[] } {
  const depth = topologicalLayers(graph.edges);
  const maxLayer = Math.max(...depth.values());
  const nodes: LaidOutNode[] = graph.nodes.map((node) => {
    const layer = depth.get(node.id) ?? 0;
    const theta = Math.PI + (layer / Math.max(maxLayer, 1)) * Math.PI;
    return { id: node.id, x: cx + radius * Math.cos(theta), y: cy + radius * Math.sin(theta) * 0.62, layer, label: node.label };
  });
  const nodeMap = new Map(nodes.map((n) => [n.id, n]));
  const edges: LaidOutEdge[] = graph.edges.map((edge) => {
    const from = nodeMap.get(edge.from)!; const to = nodeMap.get(edge.to)!;
    return { from: edge.from, to: edge.to, fromPoint: { x: from.x, y: from.y }, toPoint: { x: to.x, y: to.y }, label: edge.label };
  });
  return { nodes, edges };
}
AUREXIS_EOF

cat > src/lib/roi.ts << 'AUREXIS_EOF'
export const GOLDEN_K = 900;
export function conversionLift(legacyTtiMs: number, aurexisTtiMs: number): number {
  const deltaT = legacyTtiMs - aurexisTtiMs;
  if (deltaT <= 0) return 0;
  return 0.14 * (1 - Math.exp(-deltaT / GOLDEN_K));
}
export function revenueRecovered(traffic: number, conversionRate: number, aov: number, legacyTtiMs: number, aurexisTtiMs: number): number {
  const lift = conversionLift(legacyTtiMs, aurexisTtiMs);
  return traffic * conversionRate * aov * lift;
}
export function laborSavings(manualHoursPerMonth: number, hourlyRate: number): number {
  return manualHoursPerMonth * hourlyRate;
}
export function annualTotal(traffic: number, conversionRate: number, aov: number, legacyTtiMs: number, aurexisTtiMs: number, manualHoursPerMonth: number, hourlyRate: number): number {
  const recovered = revenueRecovered(traffic, conversionRate, aov, legacyTtiMs, aurexisTtiMs);
  const savings = laborSavings(manualHoursPerMonth, hourlyRate);
  return (recovered + savings) * 12;
}
export function roiMultiple(annualReturn: number, annualEngagementCost: number): number {
  if (annualEngagementCost <= 0) return 0;
  return annualReturn / annualEngagementCost;
}
AUREXIS_EOF

cat > src/lib/knob-math.ts << 'AUREXIS_EOF'
export function angleToValue(angle: number, min: number, max: number, step: number): number {
  const normalized = (angle + 135) / 270;
  const clamped = Math.max(0, Math.min(1, normalized));
  const raw = min + clamped * (max - min);
  const quantized = min + Math.round((raw - min) / step) * step;
  return Math.max(min, Math.min(max, quantized));
}
export function valueToAngle(value: number, min: number, max: number): number {
  const normalized = (value - min) / (max - min);
  return -135 + normalized * 270;
}
export function formatKnobValue(value: number, unit: string): string {
  if (value >= 1000) return (value / 1000).toFixed(1) + 'k' + unit;
  return value.toFixed(0) + unit;
}
AUREXIS_EOF

cat > src/lib/dot-matrix-font.ts << 'AUREXIS_EOF'
export const FONT_5X7: Record<string, number[]> = {
  A: [0x0E, 0x11, 0x11, 0x1F, 0x11, 0x11, 0x11], B: [0x1E, 0x11, 0x11, 0x1E, 0x11, 0x11, 0x1E],
  C: [0x0F, 0x10, 0x10, 0x10, 0x10, 0x10, 0x0F], D: [0x1E, 0x11, 0x11, 0x11, 0x11, 0x11, 0x1E],
  E: [0x1F, 0x10, 0x10, 0x1E, 0x10, 0x10, 0x1F], F: [0x1F, 0x10, 0x10, 0x1E, 0x10, 0x10, 0x10],
  G: [0x0F, 0x10, 0x10, 0x13, 0x11, 0x11, 0x0F], H: [0x11, 0x11, 0x11, 0x1F, 0x11, 0x11, 0x11],
  I: [0x0E, 0x04, 0x04, 0x04, 0x04, 0x04, 0x0E], J: [0x07, 0x02, 0x02, 0x02, 0x02, 0x12, 0x0C],
  K: [0x11, 0x12, 0x14, 0x18, 0x14, 0x12, 0x11], L: [0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x1F],
  M: [0x11, 0x1B, 0x15, 0x15, 0x11, 0x11, 0x11], N: [0x11, 0x11, 0x19, 0x15, 0x13, 0x11, 0x11],
  O: [0x0E, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0E], P: [0x1E, 0x11, 0x11, 0x1E, 0x10, 0x10, 0x10],
  Q: [0x0E, 0x11, 0x11, 0x11, 0x15, 0x12, 0x0D], R: [0x1E, 0x11, 0x11, 0x1E, 0x14, 0x12, 0x11],
  S: [0x0F, 0x10, 0x10, 0x0E, 0x01, 0x01, 0x1E], T: [0x1F, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04],
  U: [0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0E], V: [0x11, 0x11, 0x11, 0x11, 0x11, 0x0A, 0x04],
  W: [0x11, 0x11, 0x11, 0x15, 0x15, 0x15, 0x0A], X: [0x11, 0x11, 0x0A, 0x04, 0x0A, 0x11, 0x11],
  Y: [0x11, 0x11, 0x0A, 0x04, 0x04, 0x04, 0x04], Z: [0x1F, 0x01, 0x02, 0x04, 0x08, 0x10, 0x1F],
  '0': [0x0E, 0x11, 0x13, 0x15, 0x19, 0x11, 0x0E], '1': [0x04, 0x0C, 0x04, 0x04, 0x04, 0x04, 0x0E],
  '2': [0x0E, 0x11, 0x01, 0x06, 0x08, 0x10, 0x1F], '3': [0x1F, 0x01, 0x02, 0x06, 0x01, 0x11, 0x0E],
  '4': [0x02, 0x06, 0x0A, 0x12, 0x1F, 0x02, 0x02], '5': [0x1F, 0x10, 0x1E, 0x01, 0x01, 0x11, 0x0E],
  '6': [0x06, 0x08, 0x10, 0x1E, 0x11, 0x11, 0x0E], '7': [0x1F, 0x01, 0x02, 0x04, 0x08, 0x08, 0x08],
  '8': [0x0E, 0x11, 0x11, 0x0E, 0x11, 0x11, 0x0E], '9': [0x0E, 0x11, 0x11, 0x0F, 0x01, 0x02, 0x0C],
  ' ': [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], '.': [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04],
  '-': [0x00, 0x00, 0x00, 0x0E, 0x00, 0x00, 0x00], '+': [0x00, 0x04, 0x04, 0x1F, 0x04, 0x04, 0x00],
  '%': [0x11, 0x01, 0x02, 0x04, 0x08, 0x10, 0x11], ':': [0x00, 0x04, 0x00, 0x00, 0x00, 0x04, 0x00],
};
export type DotMatrixChar = { char: string; rows: number[] };
export function getCharRows(char: string): number[] {
  return FONT_5X7[char.toUpperCase()] ?? FONT_5X7[' ']!;
}
export function textToDotMatrix(text: string): DotMatrixChar[] {
  return text.split('').map((char) => ({ char, rows: getCharRows(char) }));
}
export function dotMatrixWidth(text: string, pxSize: number, gapPx: number): number {
  if (text.length === 0) return 0;
  return text.length * 5 * pxSize + (text.length - 1) * gapPx;
}
AUREXIS_EOF

cat > src/lib/audio-engine.ts << 'AUREXIS_EOF'
'use client';
let audioCtx: AudioContext | null = null;
function getCtx(): AudioContext | null {
  if (typeof window === 'undefined') return null;
  if (!audioCtx) {
    const Ctx = window.AudioContext ?? (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
    if (!Ctx) return null;
    audioCtx = new Ctx();
  }
  return audioCtx;
}
export function playClick(): void {
  const ctx = getCtx(); if (!ctx) return;
  const osc = ctx.createOscillator(); const gain = ctx.createGain();
  osc.frequency.value = 180; osc.type = 'square';
  gain.gain.setValueAtTime(0.08, ctx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.05);
  osc.connect(gain); gain.connect(ctx.destination);
  osc.start(); osc.stop(ctx.currentTime + 0.05);
}
export function playHover(): void {
  const ctx = getCtx(); if (!ctx) return;
  const osc = ctx.createOscillator(); const gain = ctx.createGain();
  osc.frequency.value = 420; osc.type = 'sine';
  gain.gain.setValueAtTime(0.03, ctx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.03);
  osc.connect(gain); gain.connect(ctx.destination);
  osc.start(); osc.stop(ctx.currentTime + 0.03);
}
export function playToggle(): void {
  const ctx = getCtx(); if (!ctx) return;
  const osc = ctx.createOscillator(); const gain = ctx.createGain();
  osc.frequency.setValueAtTime(220, ctx.currentTime);
  osc.frequency.exponentialRampToValueAtTime(110, ctx.currentTime + 0.08);
  osc.type = 'triangle';
  gain.gain.setValueAtTime(0.06, ctx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.1);
  osc.connect(gain); gain.connect(ctx.destination);
  osc.start(); osc.stop(ctx.currentTime + 0.1);
}
export function resumeAudio(): void {
  const ctx = getCtx();
  if (ctx && ctx.state === 'suspended') void ctx.resume();
}
AUREXIS_EOF

cat > src/lib/logs.ts << 'AUREXIS_EOF'
export type LogEntry = { timestamp: string; level: 'INFO' | 'WARN' | 'ERROR' | 'DEBUG'; source: string; message: string };
const SOURCES = ['edge-router','api-gateway','worker-pool','cache-layer','db-pool','build-pipeline','cdn-edge','auth-service'] as const;
const ACTIONS: Record<string, string[]> = {
  'edge-router': ['request proxied to origin','cache HIT for /products/*','route matched /api/v2/*','redirect applied 301 -> /blog/*'],
  'api-gateway': ['rate limit check passed','JWT validated for user_id','schema version check ok','circuit breaker closed'],
  'worker-pool': ['job dequeued from queue:default','task completed in 12ms','worker scaled to 4 instances','dead-letter queue empty'],
  'cache-layer': ['eviction triggered, LRU','warm cache populated for user:*','TTL refreshed for session:*','miss ratio 0.02 within threshold'],
  'db-pool': ['connection acquired from pool','query executed in 3.2ms','migration applied 0042_add_index','replica lag 4ms within SLA'],
  'build-pipeline': ['incremental build cached','deployment queued to production','rollout strategy: canary','health check passed'],
  'cdn-edge': ['asset purged for /static/*','edge node synced to latest','compression brotli applied','origin shield bypass active'],
  'auth-service': ['token rotated for session','MFA challenge verified','rate limit applied to IP','audit log entry written'],
};
const LEVELS: LogEntry['level'][] = ['INFO','INFO','INFO','DEBUG','WARN'];
export function generateLogEntry(seed: number): LogEntry {
  const sourceIdx = seed % SOURCES.length;
  const source = SOURCES[sourceIdx]!;
  const actions = ACTIONS[source]!;
  const actionIdx = Math.floor(seed / SOURCES.length) % actions.length;
  const message = actions[actionIdx]!;
  const level = LEVELS[seed % LEVELS.length]!;
  const now = new Date();
  const timestamp = now.toISOString().split('T')[1]?.replace('Z','') ?? '';
  return { timestamp: timestamp.slice(0, 12), level, source, message };
}
export function generateLogBatch(seed: number, count: number): LogEntry[] {
  const entries: LogEntry[] = [];
  for (let i = 0; i < count; i++) entries.push(generateLogEntry(seed + i));
  return entries;
}
AUREXIS_EOF

echo "Part 1 complete: Config, Types, Stores, Hooks, Lib"
