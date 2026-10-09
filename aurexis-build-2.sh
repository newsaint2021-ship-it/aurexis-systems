#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# aurexis-full-build.sh — Part 2 of 3
# Data · Shared · UI Primitives · Layout · Hero · Bento
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

mkdir -p src/{data,styles,app}
mkdir -p src/components/{shared,ui,layout,hero,bento}

# ── Data (7) ───────────────────────────────────────────────────

cat > src/data/navigation.ts << 'AUREXIS_EOF'
import type { NavItem } from '@/types/ui';
export const mainNav: NavItem[] = [
  { label: 'Services', href: '#services', description: 'Engineering, dashboards, growth' },
  { label: 'Platform', href: '#platform', description: 'System ontology and pipeline traces' },
  { label: 'Proof', href: '#proof', description: 'Performance comparisons and ROI model' },
  { label: 'Process', href: '#process', description: 'How we engage' },
];
export const footerNav: NavItem[] = [
  { label: 'Services', href: '#services' },
  { label: 'Platform', href: '#platform' },
  { label: 'Proof', href: '#proof' },
  { label: 'Process', href: '#process' },
];
export const legalNav: NavItem[] = [
  { label: 'Privacy', href: '/privacy' },
  { label: 'Terms', href: '/terms' },
  { label: 'Security', href: '/security' },
];
AUREXIS_EOF

cat > src/data/telemetry.ts << 'AUREXIS_EOF'
import type { Incident } from '@/types/ui';
export const initialTelemetry = {
  uptime: 99.99,
  p95LatencyMs: 41,
  requestsPerSec: 18420,
  regions: 6,
  incidents: [] as Incident[],
};
export const incidentTemplates: Omit<Incident, 'timestamp'>[] = [
  { id: 'inc-001', severity: 'info', message: 'Edge cache warmed for 14 routes' },
  { id: 'inc-002', severity: 'warning', message: 'Replica lag exceeded 8ms, auto-rebalanced' },
  { id: 'inc-003', severity: 'info', message: 'Canary deployment promoted to 100%' },
];
export function latencyFromRps(rps: number): number {
  return 18 + 22 * Math.log(1 + rps / 9000);
}
AUREXIS_EOF

cat > src/data/services.ts << 'AUREXIS_EOF'
import type { ServicePillar } from '@/types/ui';
export const servicePillars: ServicePillar[] = [
  {
    id: 'engineering', number: '01', title: 'Engineering & Upgrades',
    description: 'Next.js migrations, MVP delivery, legacy modernization. We take the work that blocks your roadmap and ship it.',
    capabilities: ['Next.js App Router migrations','TypeScript strict-mode codebases','Legacy monolith decomposition','Design system implementation'],
  },
  {
    id: 'dashboards', number: '02', title: 'Dashboards & Automation',
    description: 'Typed API pipelines, real-time data surfaces, operational dashboards. Your numbers, visible and accurate.',
    capabilities: ['End-to-end typed API contracts','Real-time WebSocket telemetry','Deterministic data lineage tracking','Workflow automation'],
  },
  {
    id: 'growth', number: '03', title: 'Growth & Technical SEO',
    description: 'Core Web Vitals clean, edge-rendered, structured data correct. Rankings follow engineering quality.',
    capabilities: ['Core Web Vitals optimization','Edge-rendered with stale-while-revalidate','Structured data passing Rich Results Test','Render-path profiling'],
  },
];
AUREXIS_EOF

cat > src/data/carousel.ts << 'AUREXIS_EOF'
import type { CarouselSlide } from '@/types/ui';
export const carouselSlides: CarouselSlide[] = [
  { id: 'engineering', eyebrow: 'Pillar 01', title: 'Engineering & Upgrades', body: 'We take the migration nobody wants to own. Next.js App Router, strict TypeScript, design system integration. Shipped in weeks, not quarters.', bullets: ['App Router migration with zero route regressions','Strict TypeScript across the full codebase','Design tokens propagated to every component'] },
  { id: 'dashboards', eyebrow: 'Pillar 02', title: 'Dashboards & Automation', body: 'Typed API pipelines that surface your operational data. No more guessing at cache hit rates or queue depth.', bullets: ['End-to-end typed API contracts','Real-time WebSocket telemetry','Deterministic data lineage tracking'] },
  { id: 'growth', eyebrow: 'Pillar 03', title: 'Growth & Technical SEO', body: 'Core Web Vitals scores in the green. Edge-rendered. Structured data validated. Rankings follow engineering quality.', bullets: ['LCP under 1.8s on Slow 4G','Edge-rendered with stale-while-revalidate','Structured data passing Rich Results Test'] },
  { id: 'platform', eyebrow: 'Platform', title: 'Aurexis Platform', body: 'The infrastructure layer beneath every engagement. Observability, automation, and deployment tooling we bring to your stack.', bullets: ['Canary deployments with auto-rollback','Synthetic monitoring on 6 regions','Incident response under 5 minutes'] },
  { id: 'observability', eyebrow: 'Observability', title: 'Observability Layer', body: 'Every request traced. Every error grouped. Every dashboard queryable. You get the same visibility we use internally.', bullets: ['Distributed tracing across service boundaries','Error grouping with semantic deduplication','Custom dashboards from your data sources'] },
];
AUREXIS_EOF

cat > src/data/ontology.ts << 'AUREXIS_EOF'
import type { OntologyGraph } from '@/types/ontology';
export const ontologyGraph: OntologyGraph = {
  nodes: [
    { id: 'gateway', label: 'API Gateway', type: 'gateway', spec: { summary: 'Routes incoming requests, applies rate limiting and auth.', rows: [ { label: 'Runtime', value: 'Edge (Vercel)' }, { label: 'P50 latency', value: '4ms' }, { label: 'P95 latency', value: '11ms' }, { label: 'Rate limit', value: '1000 req/min' }, { label: 'Auth', value: 'JWT + OIDC' }, { label: 'Circuit breaker', value: 'Closed' } ] } },
    { id: 'auth', label: 'Auth Service', type: 'service', spec: { summary: 'Token validation, session rotation, MFA verification.', rows: [ { label: 'Runtime', value: 'Node.js 20' }, { label: 'P50 latency', value: '8ms' }, { label: 'P95 latency', value: '19ms' }, { label: 'Session store', value: 'Redis' }, { label: 'Token TTL', value: '900s' }, { label: 'MFA', value: 'TOTP' } ] } },
    { id: 'cache', label: 'Cache Layer', type: 'cache', spec: { summary: 'LRU cache with stale-while-revalidate semantics.', rows: [ { label: 'Engine', value: 'Redis 7' }, { label: 'Hit rate', value: '0.94' }, { label: 'Eviction', value: 'LRU' }, { label: 'Max memory', value: '2GB' }, { label: 'TTL default', value: '300s' }, { label: 'Replicas', value: '2' } ] } },
    { id: 'worker', label: 'Worker Pool', type: 'worker', spec: { summary: 'Background job processing with dead-letter handling.', rows: [ { label: 'Runtime', value: 'Bun 1.1' }, { label: 'Concurrency', value: '16' }, { label: 'Queue engine', value: 'BullMQ' }, { label: 'DLQ enabled', value: 'true' }, { label: 'Max retries', value: '3' }, { label: 'Backoff', value: 'exponential' } ] } },
    { id: 'database', label: 'Database', type: 'database', spec: { summary: 'Postgres primary with read replicas and pgBouncer pooling.', rows: [ { label: 'Engine', value: 'Postgres 16' }, { label: 'Pool size', value: '20' }, { label: 'Replica lag', value: '4ms' }, { label: 'Migrations', value: '42 applied' }, { label: 'Index count', value: '87' }, { label: 'Connection limit', value: '100' } ] } },
    { id: 'queue', label: 'Message Queue', type: 'queue', spec: { summary: 'Decouples async work from request path. BullMQ on Redis.', rows: [ { label: 'Engine', value: 'BullMQ' }, { label: 'Throughput', value: '12k jobs/s' }, { label: 'Queue depth', value: '0' }, { label: 'Consumers', value: '4' }, { label: 'Priority', value: 'enabled' }, { label: 'DLQ', value: 'separate queue' } ] } },
  ],
  edges: [
    { from: 'gateway', to: 'auth', label: 'validates token' },
    { from: 'gateway', to: 'cache', label: 'checks cache' },
    { from: 'gateway', to: 'queue', label: 'enqueues job' },
    { from: 'cache', to: 'database', label: 'fills on miss' },
    { from: 'queue', to: 'worker', label: 'dequeues task' },
    { from: 'worker', to: 'database', label: 'writes result' },
  ],
};
AUREXIS_EOF

cat > src/data/pipeline.ts << 'AUREXIS_EOF'
import type { Pipeline } from '@/types/ontology';
export const legacyPipeline: Pipeline = {
  id: 'legacy', label: 'Legacy', color: '#E5484D', totalMs: 1430,
  phases: [
    { id: 'l1', label: 'DNS lookup', startMs: 0, durationMs: 120, parallel: false },
    { id: 'l2', label: 'TLS handshake', startMs: 120, durationMs: 180, parallel: false },
    { id: 'l3', label: 'Server render', startMs: 300, durationMs: 450, parallel: false },
    { id: 'l4', label: 'API waterfall', startMs: 750, durationMs: 520, parallel: false },
    { id: 'l5', label: 'Hydration', startMs: 1270, durationMs: 160, parallel: false },
  ],
};
export const aurexisPipeline: Pipeline = {
  id: 'aurexis', label: 'Aurexis', color: '#87776C', totalMs: 42,
  phases: [
    { id: 'a1', label: 'Edge DNS', startMs: 0, durationMs: 4, parallel: true },
    { id: 'a2', label: 'TLS 1.3', startMs: 0, durationMs: 8, parallel: true },
    { id: 'a3', label: 'Edge render', startMs: 8, durationMs: 12, parallel: true },
    { id: 'a4', label: 'Cache lookup', startMs: 0, durationMs: 6, parallel: true },
    { id: 'a5', label: 'Stream RSC', startMs: 20, durationMs: 14, parallel: true },
    { id: 'a6', label: 'Hydrate', startMs: 34, durationMs: 8, parallel: true },
  ],
};
export const speedupFactor = (legacy: number, aurexis: number): number => legacy / aurexis;
AUREXIS_EOF

cat > src/data/code-samples.ts << 'AUREXIS_EOF'
export type CodeSample = { id: string; filename: string; language: string; label: string; description: string; source: string };
export const codeSamples: CodeSample[] = [
  { id: 'edge-middleware', filename: 'middleware.ts', language: 'typescript', label: 'Edge Middleware', description: 'Runs on every request at the edge. 4ms P50 latency.', source: "import { NextRequest, NextResponse } from 'next/server';\n\nexport function middleware(request: NextRequest) {\n  const token = request.cookies.get('session');\n  \n  if (!token && request.nextUrl.pathname.startsWith('/app')) {\n    const loginUrl = new URL('/login', request.url);\n    loginUrl.searchParams.set('from', request.nextUrl.pathname);\n    return NextResponse.redirect(loginUrl);\n  }\n  \n  const res = NextResponse.next();\n  res.headers.set('x-edge-region', request.geo?.region ?? 'unknown');\n  res.headers.set('x-edge-cache', 'stale-while-revalidate');\n  \n  return res;\n}\n\nexport const config = {\n  matcher: ['/app/:path*', '/api/:path*'],\n};" },
  { id: 'rsc-streaming', filename: 'app/products/page.tsx', language: 'typescript', label: 'RSC Streaming', description: 'React Server Components with streaming. No client JS for data fetching.', source: "import { Suspense } from 'react';\nimport { ProductGrid } from '@/components/product-grid';\nimport { ProductSkeleton } from '@/components/product-skeleton';\n\nexport const revalidate = 60;\n\nasync function getProducts() {\n  const res = await fetch(process.env.API_URL + '/products', {\n    next: { revalidate: 60, tags: ['products'] },\n  });\n  if (!res.ok) throw new Error('Failed to fetch products');\n  return res.json() as Promise<Product[]>;\n}\n\nexport default async function ProductsPage() {\n  return (\n    <section>\n      <h1>Products</h1>\n      <Suspense fallback={<ProductSkeleton count={12} />}>\n        <ProductGrid products={await getProducts()} />\n      </Suspense>\n    </section>\n  );\n}" },
];
AUREXIS_EOF

# ── Shared components (2) ──────────────────────────────────────

cat > src/components/shared/motion-variants.ts << 'AUREXIS_EOF'
import type { Variants, Transition } from 'framer-motion';
export const spring: Transition = { type: 'spring', stiffness: 400, damping: 30 };
export const easeSmooth: Transition = { duration: 0.4, ease: [0.22, 1, 0.36, 1] };
export const fadeUpVariants: Variants = { hidden: { opacity: 0, y: 16 }, visible: { opacity: 1, y: 0, transition: spring } };
export const fadeInVariants: Variants = { hidden: { opacity: 0 }, visible: { opacity: 1, transition: easeSmooth } };
export const scaleInVariants: Variants = { hidden: { opacity: 0, scale: 0.96 }, visible: { opacity: 1, scale: 1, transition: spring } };
export const slideInRightVariants: Variants = { hidden: { opacity: 0, x: 24 }, visible: { opacity: 1, x: 0, transition: spring } };
export const staggerContainer: Variants = { hidden: { opacity: 0 }, visible: { opacity: 1, transition: { staggerChildren: 0.06 } } };
AUREXIS_EOF

cat > src/components/shared/spec-callout.tsx << 'AUREXIS_EOF'
'use client';
import { useModeStore } from '@/store/use-mode-store';
import { cn } from '@/lib/utils';
type SpecCalloutProps = { label: string; value: string; unit?: string; className?: string };
export function SpecCallout({ label, value, unit, className }: SpecCalloutProps) {
  const { mode } = useModeStore();
  if (mode !== 'engineer') return null;
  return (
    <div className={cn('inline-flex items-center gap-2 rounded-md border border-bronze/30 bg-bronze/5 px-2 py-1 font-mono text-[0.6875rem] uppercase tracking-widest text-bronze', className)}>
      <span className="text-dim">{label}</span>
      <span className="text-fg">{value}{unit ? <span className="text-dim">{unit}</span> : null}</span>
    </div>
  );
}
AUREXIS_EOF

# ── UI primitives (5) ───────────────────────────────────────────

cat > src/components/ui/keycap.tsx << 'AUREXIS_EOF'
'use client';
import { motion } from 'framer-motion';
import { cn } from '@/lib/utils';
type KeycapProps = { children: React.ReactNode; className?: string; size?: 'sm' | 'md' | 'lg' };
const sizeClasses = { sm: 'h-5 min-w-[1.25rem] px-1 text-[0.625rem]', md: 'h-6 min-w-[1.5rem] px-1.5 text-[0.6875rem]', lg: 'h-7 min-w-[2rem] px-2 text-[0.75rem]' };
export function Keycap({ children, className, size = 'md' }: KeycapProps) {
  return <kbd className={cn('inline-flex items-center justify-center rounded-md border border-border bg-surface font-mono font-medium uppercase tracking-widest text-muted shadow-sm select-none', sizeClasses[size], className)}>{children}</kbd>;
}
type KeycapPressProps = { children: React.ReactNode; onPress?: () => void; className?: string };
export function KeycapPress({ children, onPress, className }: KeycapPressProps) {
  return <motion.button type="button" onClick={onPress} whileTap={{ scale: 0.92 }} transition={{ type: 'spring', stiffness: 400, damping: 30 }} className={cn('inline-flex items-center justify-center rounded-md border border-border bg-surface h-6 min-w-[1.5rem] px-1.5 font-mono text-[0.6875rem] font-medium uppercase tracking-widest text-muted shadow-sm select-none transition-colors hover:border-bronze/40 hover:text-bronze focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-bronze/40', className)}>{children}</motion.button>;
}
AUREXIS_EOF

cat > src/components/ui/images-badge.tsx << 'AUREXIS_EOF'
'use client';
import Link from 'next/link';
import { motion } from 'framer-motion';
import { cn } from '@/lib/utils';
type ImagesBadgeProps = { text: string; subtext: string; href: string; className?: string };
export function ImagesBadge({ text, subtext, href, className }: ImagesBadgeProps) {
  return (
    <Link href={href} className={cn('group relative flex items-center gap-3 rounded-xl border border-border bg-surface/60 p-2 pr-4 transition-colors hover:border-bronze/40 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-bronze/40', className)}>
      <div className="flex -space-x-3">
        {[0, 1, 2].map((i) => (
          <motion.div key={i} initial={false} whileHover={{ y: -2, zIndex: 10 }} transition={{ type: 'spring', stiffness: 400, damping: 30 }} className={cn('h-10 w-10 overflow-hidden rounded-lg border border-border bg-gradient-to-br from-surface to-bg', i === 0 && 'from-bronze/20 to-bg', i === 1 && 'from-bronze/10 to-surface', i === 2 && 'from-gold/10 to-surface')}>
            <div className="flex h-full w-full items-center justify-center"><div className="h-6 w-6 rounded border border-bronze/20" /></div>
          </motion.div>
        ))}
      </div>
      <div className="flex flex-col">
        <span className="text-sm font-medium text-fg">{text}</span>
        <span className="text-xs text-muted group-hover:text-bronze">{subtext}</span>
      </div>
    </Link>
  );
}
AUREXIS_EOF

cat > src/components/ui/text-shimmer.tsx << 'AUREXIS_EOF'
'use client';
import { cn } from '@/lib/utils';
import { useReducedMotion } from '@/hooks/use-reduced-motion';
type TextShimmerProps = { children: React.ReactNode; className?: string; duration?: number };
export function TextShimmer({ children, className, duration = 2 }: TextShimmerProps) {
  const reduced = useReducedMotion();
  if (reduced) return <span className={cn('text-fg', className)}>{children}</span>;
  return <span className={cn('text-shimmer-bg animate-text-shimmer inline-block', className)} style={{ animationDuration: `${duration}s` }}>{children}</span>;
}
AUREXIS_EOF

cat > src/components/ui/segmented.tsx << 'AUREXIS_EOF'
'use client';
import { motion, type Transition } from 'framer-motion';
import { cn } from '@/lib/utils';
import { useReducedMotion } from '@/hooks/use-reduced-motion';
type SegmentedProps<T extends string> = { options: { value: T; label: string }[]; value: T; onChange: (value: T) => void; className?: string; size?: 'sm' | 'md' };
const springTransition: Transition = { type: 'spring', stiffness: 400, damping: 30 };
export function Segmented<T extends string>({ options, value, onChange, className, size = 'md' }: SegmentedProps<T>) {
  const reduced = useReducedMotion();
  return (
    <div role="radiogroup" className={cn('inline-flex items-center rounded-lg border border-border bg-surface p-0.5', className)}>
      {options.map((option) => {
        const isActive = option.value === value;
        return (
          <button key={option.value} type="button" role="radio" aria-checked={isActive} onClick={() => onChange(option.value)} className={cn('relative inline-flex items-center justify-center rounded-md font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-bronze/40', size === 'sm' ? 'px-2.5 py-1 text-xs' : 'px-3 py-1.5 text-sm', isActive ? 'text-fg' : 'text-muted hover:text-fg')}>
            {isActive && !reduced && <motion.div layoutId="segmented-active" transition={springTransition} className="absolute inset-0 rounded-md bg-bronze/15 border border-bronze/30" />}
            {isActive && reduced && <div className="absolute inset-0 rounded-md bg-bronze/15 border border-bronze/30" />}
            <span className="relative z-10">{option.label}</span>
          </button>
        );
      })}
    </div>
  );
}
AUREXIS_EOF

cat > src/components/ui/scroll-progress.tsx << 'AUREXIS_EOF'
'use client';
import { motion, useScroll, useSpring } from 'framer-motion';
import { useReducedMotion } from '@/hooks/use-reduced-motion';
export function ScrollProgress() {
  const { scrollYProgress } = useScroll();
  const reduced = useReducedMotion();
  const scaleX = useSpring(scrollYProgress, { type: 'spring', stiffness: 400, damping: 30 });
  if (reduced) return <div className="fixed top-0 left-0 right-0 z-[60] h-px bg-bronze/20" />;
  return <motion.div className="fixed top-0 left-0 right-0 z-[60] h-px origin-left bg-bronze" style={{ scaleX }} />;
}
AUREXIS_EOF

# ── Layout components (5) ───────────────────────────────────────

cat > src/components/layout/site-header.tsx << 'AUREXIS_EOF'
'use client';
import Link from 'next/link';
import { motion } from 'framer-motion';
import { Menu, Terminal, X } from 'lucide-react';
import { useState } from 'react';
import { useUIStore } from '@/store/use-ui-store';
import { useKeyboardShortcut } from '@/hooks/use-keyboard-shortcut';
import { useAudioStore } from '@/store/use-audio-store';
import { playClick } from '@/lib/audio-engine';
import { ModeToggle } from '@/components/layout/mode-toggle';
import { Keycap } from '@/components/ui/keycap';
import { mainNav } from '@/data/navigation';
import { cn } from '@/lib/utils';
export function SiteHeader() {
  const [mobileOpen, setMobileOpen] = useState(false);
  const { setPaletteOpen } = useUIStore();
  const { muted, unlock } = useAudioStore();
  useKeyboardShortcut('k', () => setPaletteOpen(true), { metaKey: true });
  const handlePalette = () => { if (!muted) { unlock(); playClick(); } setPaletteOpen(true); };
  return (
    <>
      <header className="sticky top-0 z-50 h-14 border-b border-border bg-bg/95 backdrop-blur-sm">
        <div className="mx-auto flex h-full max-w-7xl items-center justify-between px-4 md:px-6">
          <div className="flex items-center gap-8">
            <Link href="/" className="flex items-center gap-2 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-bronze/40 rounded-md">
              <Terminal className="h-5 w-5 text-bronze" aria-hidden="true" />
              <span className="font-mono text-sm font-semibold tracking-tight text-fg">AUREXIS</span>
            </Link>
            <nav className="hidden md:flex items-center gap-1">
              {mainNav.map((item) => (<Link key={item.href} href={item.href} className="px-3 py-1.5 text-sm text-muted transition-colors hover:text-fg rounded-md focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-bronze/40">{item.label}</Link>))}
            </nav>
          </div>
          <div className="flex items-center gap-2 md:gap-3">
            <button type="button" onClick={handlePalette} className="hidden md:inline-flex items-center gap-2 rounded-lg border border-border bg-surface px-3 py-1.5 text-sm text-muted transition-colors hover:border-bronze/40 hover:text-fg focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-bronze/40" aria-label="Open command palette">
              <span>Search</span><Keycap size="sm">K</Keycap>
            </button>
            <ModeToggle />
            <Link href="#contact" className="inline-flex items-center rounded-lg bg-gold px-4 py-1.5 text-sm font-medium text-bg transition-colors hover:bg-gold-hover focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gold/40">Book a call</Link>
            <button type="button" onClick={() => setMobileOpen(!mobileOpen)} className="md:hidden inline-flex items-center justify-center rounded-lg border border-border bg-surface p-2 text-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-bronze/40" aria-label="Toggle menu" aria-expanded={mobileOpen}>
              {mobileOpen ? <X className="h-4 w-4" /> : <Menu className="h-4 w-4" />}
            </button>
          </div>
        </div>
      </header>
      {mobileOpen && (
        <motion.nav initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} transition={{ type: 'spring', stiffness: 400, damping: 30 }} className="md:hidden border-b border-border bg-bg overflow-hidden">
          <div className="px-4 py-3 flex flex-col gap-1">
            {mainNav.map((item) => (<Link key={item.href} href={item.href} onClick={() => setMobileOpen(false)} className={cn('px-3 py-2 text-sm text-muted rounded-md hover:text-fg hover:bg-surface focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-bronze/40')}>{item.label}</Link>))}
          </div>
        </motion.nav>
      )}
    </>
  );
}
AUREXIS_EOF

cat > src/components/layout/mode-toggle.tsx << 'AUREXIS_EOF'
'use client';
import { useModeStore } from '@/store/use-mode-store';
import { useAudioStore } from '@/store/use-audio-store';
import { playToggle } from '@/lib/audio-engine';
import { Segmented } from '@/components/ui/segmented';
export function ModeToggle() {
  const { mode, setMode } = useModeStore();
  const { muted, unlock } = useAudioStore();
  const handleChange = (value: 'executive' | 'engineer') => {
    if (!muted) { unlock(); playToggle(); }
    setMode(value);
  };
  return (
    <div className="flex items-center gap-2">
      <Segmented size="sm" options={[{ value: 'executive', label: 'Exec' }, { value: 'engineer', label: 'Eng' }]} value={mode} onChange={handleChange} />
    </div>
  );
}
AUREXIS_EOF

cat > src/components/layout/command-palette.tsx << 'AUREXIS_EOF'
'use client';
import { useEffect, useState, useMemo, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Search, ArrowRight } from 'lucide-react';
import { useUIStore } from '@/store/use-ui-store';
import { useCommandStore } from '@/store/use-command-store';
import { useKeyboardShortcut } from '@/hooks/use-keyboard-shortcut';
import { cn } from '@/lib/utils';
export function CommandPalette() {
  const { paletteOpen, setPaletteOpen } = useUIStore();
  const { items } = useCommandStore();
  const [query, setQuery] = useState('');
  const [activeIndex, setActiveIndex] = useState(0);
  useKeyboardShortcut('k', () => setPaletteOpen(true), { metaKey: true });
  useKeyboardShortcut('escape', () => setPaletteOpen(false), {});
  const filtered = useMemo(() => {
    if (!query.trim()) return items;
    const q = query.toLowerCase();
    return items.filter((item) => item.label.toLowerCase().includes(q) || item.group.toLowerCase().includes(q) || item.keywords?.toLowerCase().includes(q));
  }, [query, items]);
  useEffect(() => { if (!paletteOpen) { setQuery(''); setActiveIndex(0); } }, [paletteOpen]);
  useEffect(() => { setActiveIndex(0); }, [query]);
  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (e.key === 'ArrowDown') { e.preventDefault(); setActiveIndex((prev) => Math.min(prev + 1, filtered.length - 1)); }
    else if (e.key === 'ArrowUp') { e.preventDefault(); setActiveIndex((prev) => Math.max(prev - 1, 0)); }
    else if (e.key === 'Enter') { e.preventDefault(); const item = filtered[activeIndex]; if (item) { item.action(); setPaletteOpen(false); } }
  }, [filtered, activeIndex, setPaletteOpen]);
  return (
    <AnimatePresence>
      {paletteOpen && (
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.15 }} className="fixed inset-0 z-[100] flex items-start justify-center pt-[15vh] px-4" role="dialog" aria-modal="true" aria-label="Command palette">
          <div className="absolute inset-0 bg-black/60" onClick={() => setPaletteOpen(false)} />
          <motion.div initial={{ opacity: 0, scale: 0.98, y: -8 }} animate={{ opacity: 1, scale: 1, y: 0 }} exit={{ opacity: 0, scale: 0.98, y: -8 }} transition={{ type: 'spring', stiffness: 400, damping: 30 }} className={cn('relative w-full max-w-xl overflow-hidden rounded-xl bg-[#1A1A1A]/40 backdrop-blur-xl border border-white/10 shadow-[0_8px_32px_0_rgba(0,0,0,0.37)]')}>
            <div className="flex items-center gap-3 border-b border-border px-4 py-3">
              <Search className="h-4 w-4 text-dim" aria-hidden="true" />
              <input type="text" value={query} onChange={(e) => setQuery(e.target.value)} onKeyDown={handleKeyDown} placeholder="Type a command or search..." className="flex-1 bg-transparent text-sm text-fg placeholder:text-dim focus:outline-none" autoFocus aria-label="Search commands" />
              <kbd className="text-[0.6875rem] font-mono text-dim">ESC</kbd>
            </div>
            <div className="max-h-[300px] overflow-y-auto p-2">
              {filtered.length === 0 && <div className="px-3 py-8 text-center text-sm text-dim">No results found.</div>}
              {filtered.map((item, index) => (
                <button key={item.id} type="button" onMouseEnter={() => setActiveIndex(index)} onClick={() => { item.action(); setPaletteOpen(false); }} className={cn('flex w-full items-center justify-between rounded-lg px-3 py-2 text-left transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-bronze/40', index === activeIndex ? 'bg-bronze/10 text-fg' : 'text-muted hover:text-fg')}>
                  <div className="flex flex-col"><span className="text-sm font-medium">{item.label}</span>{item.hint && <span className="text-xs text-dim">{item.hint}</span>}</div>
                  <div className="flex items-center gap-2"><span className="text-[0.6875rem] font-mono uppercase tracking-widest text-dim">{item.group}</span><ArrowRight className="h-3 w-3 text-dim" aria-hidden="true" /></div>
                </button>
              ))}
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
AUREXIS_EOF

cat > src/components/layout/telemetry-ticker.tsx << 'AUREXIS_EOF'
'use client';
import { useEffect, useRef } from 'react';
import { useTelemetryStore } from '@/store/use-telemetry-store';
import { useModeStore } from '@/store/use-mode-store';
import { latencyFromRps } from '@/data/telemetry';
export function TelemetryTicker() {
  const { uptime, p95LatencyMs, requestsPerSec, incidents, tick, incrementTick, setSnapshot } = useTelemetryStore();
  const { mode } = useModeStore();
  const intervalRef = useRef<ReturnType<typeof setInterval>>();
  useEffect(() => {
    intervalRef.current = setInterval(() => {
      const seed = Date.now() / 1000;
      const baseRps = 18420;
      const variance = Math.sin(seed * 0.7) * 800 + Math.sin(seed * 0.3) * 400;
      const newRps = Math.round(baseRps + variance);
      const newP95 = latencyFromRps(newRps);
      setSnapshot({ requestsPerSec: newRps, p95LatencyMs: newP95 });
      incrementTick();
    }, 2000);
    return () => { if (intervalRef.current) clearInterval(intervalRef.current); };
  }, [setSnapshot, incrementTick]);
  return (
    <div className="sticky top-14 z-40 h-7 border-b border-border bg-surface/80 backdrop-blur-sm">
      <div className="mx-auto flex h-full max-w-7xl items-center justify-between px-4 md:px-6">
        <div className="flex items-center gap-4 md:gap-6 overflow-x-auto">
          <div className="flex items-center gap-1.5 whitespace-nowrap">
            <span className="h-1.5 w-1.5 rounded-full bg-bronze animate-pulse-dot" />
            <span className="font-mono text-[0.6875rem] uppercase tracking-widest text-muted">Status</span>
            <span className="font-mono text-[0.6875rem] font-medium text-fg">Operational</span>
          </div>
          <span className="hidden sm:inline-flex items-center gap-1.5 whitespace-nowrap"><span className="font-mono text-[0.6875rem] uppercase tracking-widest text-dim">UP</span><span className="font-mono text-[0.6875rem] font-medium text-fg">{uptime.toFixed(2)}%</span></span>
          <span className="inline-flex items-center gap-1.5 whitespace-nowrap"><span className="font-mono text-[0.6875rem] uppercase tracking-widest text-dim">REQ/S</span><span className="font-mono text-[0.6875rem] font-medium text-fg">{requestsPerSec.toLocaleString()}</span></span>
          <span className="hidden sm:inline-flex items-center gap-1.5 whitespace-nowrap"><span className="font-mono text-[0.6875rem] uppercase tracking-widest text-dim">P95</span><span className="font-mono text-[0.6875rem] font-medium text-fg">{p95LatencyMs.toFixed(0)}ms</span></span>
          <span className="hidden md:inline-flex items-center gap-1.5 whitespace-nowrap"><span className="font-mono text-[0.6875rem] uppercase tracking-widest text-dim">REG</span><span className="font-mono text-[0.6875rem] font-medium text-fg">6</span></span>
          <span className="hidden md:inline-flex items-center gap-1.5 whitespace-nowrap"><span className="font-mono text-[0.6875rem] uppercase tracking-widest text-dim">INC</span><span className="font-mono text-[0.6875rem] font-medium text-fg">{incidents.length}</span></span>
        </div>
        {mode === 'engineer' && (
          <div className="flex items-center gap-1.5 whitespace-nowrap">
            <span className="font-mono text-[0.6875rem] uppercase tracking-widest text-dim">TICK</span>
            <span className="font-mono text-[0.6875rem] font-medium text-bronze">{tick.toString().padStart(6, '0')}</span>
          </div>
        )}
      </div>
    </div>
  );
}
AUREXIS_EOF

cat > src/components/layout/footer-clock.tsx << 'AUREXIS_EOF'
'use client';
import { useEffect, useState } from 'react';
export function FooterClock() {
  const [time, setTime] = useState<string>('--:--:--');
  useEffect(() => {
    const update = () => {
      const formatter = new Intl.DateTimeFormat('en-ZA', { timeZone: 'Africa/Johannesburg', hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false });
      setTime(formatter.format(new Date()));
    };
    update();
    const interval = setInterval(update, 1000);
    return () => clearInterval(interval);
  }, []);
  return <span className="font-mono text-sm text-fg tabular-nums" suppressHydrationWarning>{time}</span>;
}
AUREXIS_EOF

# ── Hero components (3) ─────────────────────────────────────────

cat > src/components/hero/hero-section.tsx << 'AUREXIS_EOF'
'use client';
import dynamic from 'next/dynamic';
import { motion } from 'framer-motion';
import { ArrowRight } from 'lucide-react';
import { ImagesBadge } from '@/components/ui/images-badge';
import { TextShimmer } from '@/components/ui/text-shimmer';
import { fadeUpVariants, staggerContainer, spring } from '@/components/shared/motion-variants';
import { useReducedMotion } from '@/hooks/use-reduced-motion';
const ParticleGlobe = dynamic(() => import('@/components/hero/particle-globe').then((m) => m.ParticleGlobe), { ssr: false, loading: () => <div className="aspect-square w-full animate-pulse rounded-xl bg-surface" /> });
const GlobeFallback = dynamic(() => import('@/components/hero/globe-fallback').then((m) => m.GlobeFallback), { ssr: true });
export function HeroSection() {
  const reduced = useReducedMotion();
  return (
    <section className="relative py-20 md:py-28" aria-label="Hero">
      <div className="mx-auto grid max-w-7xl grid-cols-1 gap-12 px-4 md:px-6 lg:grid-cols-[1.1fr_1fr] lg:items-center">
        <motion.div variants={reduced ? undefined : staggerContainer} initial="hidden" animate="visible" className="flex flex-col gap-6">
          <motion.div variants={reduced ? undefined : fadeUpVariants}><span className="font-mono text-[0.6875rem] uppercase tracking-[0.2em] text-bronze">Digital Engineering Partner</span></motion.div>
          <motion.h1 variants={reduced ? undefined : fadeUpVariants} className="text-display text-fg">We remove technical bottlenecks so companies scale revenue and operations <TextShimmer>without friction.</TextShimmer></motion.h1>
          <motion.p variants={reduced ? undefined : fadeUpVariants} className="max-w-xl text-base leading-relaxed text-muted">Most agencies sell outputs. We engineer leverage. Next.js migrations, typed API pipelines, edge-rendered growth. Your roadmap, unblocked.</motion.p>
          <motion.div variants={reduced ? undefined : fadeUpVariants} className="flex flex-col gap-4 sm:flex-row sm:items-center">
            <a href="#contact" className="inline-flex items-center gap-2 rounded-lg bg-gold px-5 py-2.5 text-sm font-medium text-bg transition-colors hover:bg-gold-hover focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gold/40">Book a call<ArrowRight className="h-4 w-4" aria-hidden="true" /></a>
            <a href="#proof" className="inline-flex items-center gap-2 rounded-lg border border-border bg-surface px-5 py-2.5 text-sm font-medium text-fg transition-colors hover:border-bronze/40 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-bronze/40">See the proof</a>
          </motion.div>
          <motion.div variants={reduced ? undefined : fadeUpVariants}><ImagesBadge text="3 projects shipped this month" subtext="See them →" href="#work" /></motion.div>
        </motion.div>
        <motion.div initial={reduced ? undefined : { opacity: 0, scale: 0.95 }} animate={reduced ? undefined : { opacity: 1, scale: 1 }} transition={spring} className="relative aspect-square w-full lg:aspect-[4/5]">
          <div className="hidden lg:block"><ParticleGlobe /></div>
          <div className="lg:hidden"><GlobeFallback /></div>
        </motion.div>
      </div>
    </section>
  );
}
AUREXIS_EOF

cat > src/components/hero/particle-globe.tsx << 'AUREXIS_EOF'
'use client';
import { useEffect, useRef } from 'react';
import { useReducedMotion } from '@/hooks/use-reduced-motion';
import { useElementSize } from '@/hooks/use-element-size';
const GOLDEN_ANGLE = Math.PI * (3 - Math.sqrt(5));
type Particle = { x: number; y: number; z: number };
function generateFibonacciSphere(n: number): Particle[] {
  const particles: Particle[] = [];
  for (let i = 0; i < n; i++) {
    const y = 1 - (i / (n - 1)) * 2;
    const radius = Math.sqrt(1 - y * y);
    const theta = GOLDEN_ANGLE * i;
    particles.push({ x: Math.cos(theta) * radius, y, z: Math.sin(theta) * radius });
  }
  return particles;
}
function rotateParticle(p: Particle, yaw: number, pitch: number): Particle {
  const cosY = Math.cos(yaw); const sinY = Math.sin(yaw); const cosP = Math.cos(pitch); const sinP = Math.sin(pitch);
  const x1 = p.x * cosY - p.z * sinY; const z1 = p.x * sinY + p.z * cosY; const y1 = p.y;
  const y2 = y1 * cosP - z1 * sinP; const z2 = y1 * sinP + z1 * cosP;
  return { x: x1, y: y2, z: z2 };
}
export function ParticleGlobe() {
  const [containerRef, size] = useElementSize<HTMLDivElement>();
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const reduced = useReducedMotion();
  const rafRef = useRef<number>();
  const yawRef = useRef(0); const pitchRef = useRef(0.3);
  useEffect(() => {
    const canvas = canvasRef.current; if (!canvas || size.width === 0) return;
    const ctx = canvas.getContext('2d'); if (!ctx) return;
    const dpr = window.devicePixelRatio || 1;
    canvas.width = size.width * dpr; canvas.height = size.height * dpr;
    canvas.style.width = `${size.width}px`; canvas.style.height = `${size.height}px`;
    ctx.scale(dpr, dpr);
    const particles = generateFibonacciSphere(320);
    const cx = size.width / 2; const cy = size.height / 2;
    const radius = Math.min(size.width, size.height) * 0.38;
    let lastTime = performance.now();
    const render = (now: number) => {
      const dt = (now - lastTime) / 1000; lastTime = now;
      if (!reduced) { yawRef.current += dt * 0.15; pitchRef.current = 0.3 + Math.sin(now * 0.0003) * 0.15; }
      ctx.clearRect(0, 0, size.width, size.height);
      const projected = particles.map((p) => { const rotated = rotateParticle(p, yawRef.current, pitchRef.current); const scale = (rotated.z + 2) / 3; return { x: cx + rotated.x * radius, y: cy + rotated.y * radius, z: rotated.z, scale }; });
      const sorted = [...projected].sort((a, b) => a.z - b.z);
      for (const p of sorted) {
        if (p.z < -0.3) continue;
        const alpha = (p.z + 0.5) / 1.5;
        const dotSize = Math.max(0.5, p.scale * 2.2);
        const isBronze = p.z > 0.3;
        const color = isBronze ? '135, 119, 108' : '98, 98, 105';
        ctx.beginPath(); ctx.arc(p.x, p.y, dotSize, 0, Math.PI * 2);
        ctx.fillStyle = `rgba(${color}, ${alpha})`; ctx.fill();
      }
      rafRef.current = requestAnimationFrame(render);
    };
    rafRef.current = requestAnimationFrame(render);
    return () => { if (rafRef.current) cancelAnimationFrame(rafRef.current); };
  }, [size, reduced]);
  return (<div ref={containerRef} className="h-full w-full"><canvas ref={canvasRef} className="h-full w-full" role="img" aria-label="Interactive 3D particle globe visualizing global edge network distribution" /></div>);
}
AUREXIS_EOF

cat > src/components/hero/globe-fallback.tsx << 'AUREXIS_EOF'
'use client';
export function GlobeFallback() {
  const latLines = 7; const lonLines = 12; const cx = 100; const cy = 100; const r = 70;
  return (
    <svg viewBox="0 0 200 200" className="h-full w-full" role="img" aria-label="Globe mesh visualization">
      <circle cx={cx} cy={cy} r={r} fill="none" stroke="#87776C" strokeWidth="0.5" opacity="0.3" />
      {Array.from({ length: latLines }).map((_, i) => {
        const offset = (i / (latLines - 1) - 0.5) * 2;
        const y = cy + offset * r * 0.62;
        const rx = r * Math.sqrt(1 - offset * offset);
        return <ellipse key={`lat-${i}`} cx={cx} cy={y} rx={rx} ry={rx * 0.25} fill="none" stroke="#87776C" strokeWidth="0.5" opacity="0.2" />;
      })}
      {Array.from({ length: lonLines }).map((_, i) => {
        const angle = (i / lonLines) * Math.PI * 2;
        const rx = Math.abs(r * Math.cos(angle));
        return <ellipse key={`lon-${i}`} cx={cx} cy={cy} rx={rx * 0.3} ry={r} fill="none" stroke="#87776C" strokeWidth="0.5" opacity="0.15" transform={`rotate(${(angle * 180) / Math.PI} ${cx} ${cy})`} />;
      })}
      {Array.from({ length: 20 }).map((_, i) => {
        const angle = (i / 20) * Math.PI * 2;
        return <circle key={`dot-${i}`} cx={cx + Math.cos(angle) * r * 0.8} cy={cy + Math.sin(angle) * r * 0.8 * 0.62} r="1.5" fill="#87776C" opacity="0.6" />;
      })}
    </svg>
  );
}
AUREXIS_EOF

# ── Bento components (6) ───────────────────────────────────────

cat > src/components/bento/bento-grid.tsx << 'AUREXIS_EOF'
'use client';
import { motion } from 'framer-motion';
import { BentoCard } from '@/components/bento/bento-card';
import { SvgNodeFlow } from '@/components/bento/svg-node-flow';
import { TerminalLogs } from '@/components/bento/terminal-logs';
import { servicePillars } from '@/data/services';
import { staggerContainer, fadeUpVariants } from '@/components/shared/motion-variants';
import { useReducedMotion } from '@/hooks/use-reduced-motion';
import { SpecCallout } from '@/components/shared/spec-callout';
export function BentoGrid() {
  const reduced = useReducedMotion();
  const [engineering, dashboards, growth] = servicePillars;
  return (
    <section id="services" className="py-20 md:py-28" aria-label="Services">
      <div className="mx-auto max-w-7xl px-4 md:px-6">
        <motion.div variants={reduced ? undefined : staggerContainer} initial="hidden" whileInView="visible" viewport={{ once: true, margin: '-80px' }} className="mb-10 flex flex-col gap-2">
          <motion.div variants={reduced ? undefined : fadeUpVariants}><SpecCallout label="GRID" value="5 cells, asymmetric" /></motion.div>
          <motion.h2 variants={reduced ? undefined : fadeUpVariants} className="text-headline text-fg">Three pillars. One engineering standard.</motion.h2>
        </motion.div>
        <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
          <BentoCard id="engineering" className="lg:col-span-2 lg:row-span-2" pillar={engineering!} large />
          <BentoCard id="dashboards" pillar={dashboards!} />
          <BentoCard id="growth" pillar={growth!} />
          <BentoCard id="node-flow" className="md:col-span-1"><SvgNodeFlow /></BentoCard>
          <BentoCard id="terminal" className="lg:col-span-2"><TerminalLogs /></BentoCard>
        </div>
      </div>
    </section>
  );
}
AUREXIS_EOF

cat > src/components/bento/bento-card.tsx << 'AUREXIS_EOF'
'use client';
import { motion } from 'framer-motion';
import { useState, type ReactNode } from 'react';
import { BorderBeam } from '@/components/bento/border-beam';
import { BlueprintOverlay } from '@/components/industrial/blueprint-overlay';
import { SpecCallout } from '@/components/shared/spec-callout';
import { useModeStore } from '@/store/use-mode-store';
import { useUIStore } from '@/store/use-ui-store';
import type { ServicePillar, BentoCardId } from '@/types/ui';
import { cn } from '@/lib/utils';
import { fadeUpVariants, staggerContainer } from '@/components/shared/motion-variants';
import { useReducedMotion } from '@/hooks/use-reduced-motion';
type BentoCardProps = { id: BentoCardId; pillar?: ServicePillar; children?: ReactNode; className?: string; large?: boolean; blueprintSpecs?: { label: string; value: string }[] };
export function BentoCard({ id, pillar, children, className, large, blueprintSpecs }: BentoCardProps) {
  const [hovered, setHovered] = useState(false);
  const { mode } = useModeStore();
  const { setActiveBento } = useUIStore();
  const reduced = useReducedMotion();
  const specs = blueprintSpecs ?? [{ label: 'CELL', value: id }, { label: 'SPAN', value: large ? '2x2' : '1x1' }];
  return (
    <motion.div variants={reduced ? undefined : fadeUpVariants} onMouseEnter={() => { setHovered(true); setActiveBento(id); }} onMouseLeave={() => setHovered(false)} className={cn('group relative overflow-hidden rounded-xl border border-border bg-surface transition-colors hover:border-bronze/30 focus-within:border-bronze/30', className)}>
      {hovered && !reduced && <BorderBeam />}
      <BlueprintOverlay specs={specs} />
      <div className={cn('relative z-10', large ? 'p-6 md:p-8' : 'p-5')}>
        {pillar && (
          <>
            <div className="mb-4 flex items-center justify-between">
              <span className="font-mono text-[0.6875rem] uppercase tracking-[0.2em] text-bronze">{pillar.number}</span>
              {mode === 'engineer' && <SpecCallout label="ID" value={pillar.id} />}
            </div>
            <h3 className={cn('font-semibold text-fg', large ? 'text-xl' : 'text-base')}>{pillar.title}</h3>
            <p className={cn('mt-2 text-muted', large ? 'text-sm leading-relaxed' : 'text-xs')}>{pillar.description}</p>
            {large && (
              <motion.ul variants={reduced ? undefined : staggerContainer} initial="hidden" whileInView="visible" viewport={{ once: true }} className="mt-6 space-y-2">
                {pillar.capabilities.map((cap) => (<motion.li key={cap} variants={reduced ? undefined : fadeUpVariants} className="flex items-center gap-2 text-sm text-muted"><span className="h-1 w-1 rounded-full bg-bronze" />{cap}</motion.li>))}
              </motion.ul>
            )}
            {!large && (<ul className="mt-3 space-y-1">{pillar.capabilities.slice(0, 2).map((cap) => (<li key={cap} className="text-xs text-dim">{cap}</li>))}</ul>)}
          </>
        )}
        {children}
      </div>
    </motion.div>
  );
}
AUREXIS_EOF

cat > src/components/bento/border-beam.tsx << 'AUREXIS_EOF'
'use client';
export function BorderBeam() {
  return (
    <div className="pointer-events-none absolute inset-0 rounded-xl overflow-hidden" aria-hidden="true">
      <div className="animate-border-beam-rotate absolute inset-[-1px] rounded-xl" style={{ background: 'conic-gradient(from 0deg at 50% 50%, transparent 0deg, transparent 270deg, rgba(135,119,108,0.4) 315deg, rgba(135,119,108,0.6) 360deg)' }}>
        <div className="absolute inset-[1px] rounded-xl bg-surface" />
      </div>
    </div>
  );
}
AUREXIS_EOF

cat > src/components/bento/svg-node-flow.tsx << 'AUREXIS_EOF'
'use client';
import { useEffect, useRef, useState } from 'react';
import { useReducedMotion } from '@/hooks/use-reduced-motion';
type FlowNode = { id: string; label: string; x: number; y: number };
const nodes: FlowNode[] = [{ id: 'req', label: 'Request', x: 20, y: 40 }, { id: 'edge', label: 'Edge', x: 100, y: 20 }, { id: 'cache', label: 'Cache', x: 100, y: 60 }, { id: 'api', label: 'API', x: 180, y: 40 }, { id: 'db', label: 'DB', x: 260, y: 40 }];
const edges: { from: string; to: string }[] = [{ from: 'req', to: 'edge' }, { from: 'req', to: 'cache' }, { from: 'edge', to: 'api' }, { from: 'cache', to: 'api' }, { from: 'api', to: 'db' }];
export function SvgNodeFlow() {
  const reduced = useReducedMotion();
  const [tick, setTick] = useState(0);
  const rafRef = useRef<number>();
  const startRef = useRef<number>(0);
  useEffect(() => {
    if (reduced) return;
    startRef.current = performance.now();
    const animate = (now: number) => { const elapsed = (now - startRef.current) / 1000; setTick(elapsed); rafRef.current = requestAnimationFrame(animate); };
    rafRef.current = requestAnimationFrame(animate);
    return () => { if (rafRef.current) cancelAnimationFrame(rafRef.current); };
  }, [reduced]);
  const nodeMap = new Map(nodes.map((n) => [n.id, n]));
  return (
    <div className="flex flex-col gap-2">
      <span className="font-mono text-[0.6875rem] uppercase tracking-[0.2em] text-bronze">Request Flow</span>
      <svg viewBox="0 0 300 100" className="w-full" role="img" aria-label="System request flow diagram">
        {edges.map((edge) => {
          const from = nodeMap.get(edge.from)!; const to = nodeMap.get(edge.to)!;
          const midX = (from.x + to.x) / 2; const midY = (from.y + to.y) / 2 - 10;
          return (
            <g key={`${edge.from}-${edge.to}`}>
              <path d={`M ${from.x} ${from.y} Q ${midX} ${midY}, ${to.x} ${to.y}`} fill="none" stroke="#87776C" strokeWidth="0.75" opacity="0.4" />
              {!reduced && Array.from({ length: 2 }).map((_, i) => {
                const t = ((tick * 0.3 + i / 2) % 1 + 1) % 1;
                const px = (1 - t) * (1 - t) * from.x + 2 * (1 - t) * t * midX + t * t * to.x;
                const py = (1 - t) * (1 - t) * from.y + 2 * (1 - t) * t * midY + t * t * to.y;
                return <circle key={i} cx={px} cy={py} r="1.5" fill="#87776C" />;
              })}
            </g>
          );
        })}
        {nodes.map((node) => (
          <g key={node.id}>
            <rect x={node.x - 24} y={node.y - 8} width="48" height="16" rx="3" fill="#090909" stroke="#87776C" strokeWidth="0.5" opacity="0.6" />
            <text x={node.x} y={node.y + 3} textAnchor="middle" className="font-mono" fontSize="6" fill="#99999F">{node.label}</text>
          </g>
        ))}
      </svg>
    </div>
  );
}
AUREXIS_EOF

cat > src/components/bento/terminal-logs.tsx << 'AUREXIS_EOF'
'use client';
import { useEffect, useRef, useState } from 'react';
import { useReducedMotion } from '@/hooks/use-reduced-motion';
import { generateLogBatch, type LogEntry } from '@/lib/logs';
import { useModeStore } from '@/store/use-mode-store';
import { cn } from '@/lib/utils';
const levelColors: Record<LogEntry['level'], string> = { INFO: 'text-muted', WARN: 'text-gold', ERROR: 'text-danger', DEBUG: 'text-dim' };
export function TerminalLogs() {
  const reduced = useReducedMotion();
  const { mode } = useModeStore();
  const [logs, setLogs] = useState<LogEntry[]>(() => generateLogBatch(1, 8));
  const containerRef = useRef<HTMLDivElement>(null);
  const seedRef = useRef(100);
  const intervalRef = useRef<ReturnType<typeof setInterval>>();
  useEffect(() => {
    if (reduced) return;
    intervalRef.current = setInterval(() => { seedRef.current += 1; const entry = generateLogEntry(seedRef.current); setLogs((prev) => [...prev.slice(-11), entry]); }, 1800);
    return () => { if (intervalRef.current) clearInterval(intervalRef.current); };
  }, [reduced]);
  useEffect(() => { if (containerRef.current) containerRef.current.scrollTop = containerRef.current.scrollHeight; }, [logs]);
  return (
    <div className="flex flex-col gap-2">
      <div className="flex items-center justify-between">
        <span className="font-mono text-[0.6875rem] uppercase tracking-[0.2em] text-bronze">Live Logs</span>
        <div className="flex items-center gap-1.5"><span className="h-1.5 w-1.5 rounded-full bg-bronze animate-pulse-dot" /><span className="font-mono text-[0.6875rem] uppercase tracking-widest text-dim">streaming</span></div>
      </div>
      <div ref={containerRef} className={cn('h-32 overflow-y-auto rounded-lg bg-black/40 p-2 font-mono text-[0.6875rem] leading-relaxed border border-border')} role="log" aria-label="Live system logs" aria-live="polite">
        {logs.map((entry, i) => (
          <div key={i} className="flex gap-2 whitespace-nowrap">
            <span className="text-dim">{entry.timestamp}</span>
            <span className={cn('font-medium', levelColors[entry.level])}>{entry.level}</span>
            <span className="text-bronze">{entry.source}</span>
            <span className="text-muted">{entry.message}</span>
            {mode === 'engineer' && <span className="text-dim">pid={1000 + i}</span>}
          </div>
        ))}
      </div>
    </div>
  );
}
AUREXIS_EOF

cat > src/components/bento/live-counter.tsx << 'AUREXIS_EOF'
'use client';
import { useEffect, useState } from 'react';
import { useTelemetryStore } from '@/store/use-telemetry-store';
import { useAnimatedNumber } from '@/hooks/use-animated-number';
import { cn } from '@/lib/utils';
type LiveCounterProps = { label: string; value: number; unit?: string; className?: string };
export function LiveCounter({ label, value, unit, className }: LiveCounterProps) {
  const animated = useAnimatedNumber(value);
  return (
    <div className={cn('flex flex-col gap-1', className)}>
      <span className="font-mono text-[0.6875rem] uppercase tracking-[0.2em] text-dim">{label}</span>
      <span className="font-mono text-lg font-semibold text-fg">{animated.toFixed(unit === '%' ? 2 : 0)}{unit && <span className="text-dim">{unit}</span>}</span>
    </div>
  );
}
export function LiveCounterWidget() {
  const { uptime, p95LatencyMs, requestsPerSec, incidents } = useTelemetryStore();
  const [incidentCount, setIncidentCount] = useState(0);
  useEffect(() => { setIncidentCount(incidents.length); }, [incidents]);
  return (
    <div className="grid grid-cols-2 gap-4">
      <LiveCounter label="Uptime" value={uptime} unit="%" />
      <LiveCounter label="P95 Latency" value={p95LatencyMs} unit="ms" />
      <LiveCounter label="Requests/s" value={requestsPerSec} />
      <LiveCounter label="Incidents (24h)" value={incidentCount} />
    </div>
  );
}
AUREXIS_EOF

echo "Part 2 complete: Data, Shared, UI, Layout, Hero, Bento"
