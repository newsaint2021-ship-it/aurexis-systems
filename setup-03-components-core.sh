#!/usr/bin/env bash
set -euo pipefail
echo "==> Writing core visual components..."

mkdir -p src/components/shared src/components/layout src/components/hero src/components/bento

# ─── SHARED: MOTION VARIANTS ──────────────────────────────────────────────────
cat > src/components/shared/motion-variants.ts << 'EOF'
import type { Variants } from 'framer-motion'

export const spring = { type: 'spring' as const, stiffness: 400, damping: 30 }

export const fadeUp: Variants = {
  hidden: { opacity: 0, y: 12 },
  show: { opacity: 1, y: 0, transition: spring },
}

export const stagger = (delay = 0.04): Variants => ({
  hidden: {},
  show: { transition: { staggerChildren: delay, delayChildren: delay } },
})
EOF

# ─── SHARED: SPEC CALLOUT ─────────────────────────────────────────────────────
cat > src/components/shared/spec-callout.tsx << 'EOF'
'use client'

import { useModeStore } from '@/store/use-mode-store'

export function SpecCallout({ children }: { children: React.ReactNode }) {
  const engineer = useModeStore((s) => s.mode === 'engineer')
  if (!engineer) return null
  return (
    <span className="font-mono text-[10px] uppercase tracking-widest text-cyan/80">
      {children}
    </span>
  )
}
EOF

# ─── LAYOUT: MODE TOGGLE ──────────────────────────────────────────────────────
cat > src/components/layout/mode-toggle.tsx << 'EOF'
'use client'

import { motion } from 'framer-motion'
import { useModeStore } from '@/store/use-mode-store'
import { spring } from '@/components/shared/motion-variants'
import { cn } from '@/lib/utils'

const MODES = [
  { id: 'executive', label: 'Executive' },
  { id: 'engineer', label: 'Engineer' },
] as const

export function ModeToggle() {
  const mode = useModeStore((s) => s.mode)
  const setMode = useModeStore((s) => s.setMode)

  return (
    <div
      role="tablist"
      aria-label="Interface density mode"
      className="relative flex items-center gap-1 rounded-full border border-border bg-surface p-1 font-mono text-[11px] uppercase tracking-wider"
    >
      {MODES.map((m) => {
        const active = mode === m.id
        return (
          <button
            key={m.id}
            role="tab"
            aria-selected={active}
            data-analytics={`mode-${m.id}`}
            onClick={() => setMode(m.id)}
            className={cn(
              'relative z-10 rounded-full px-3 py-1 transition-colors',
              active ? 'text-bg' : 'text-muted hover:text-fg',
            )}
          >
            {active && (
              <motion.span
                layoutId="mode-pill"
                transition={spring}
                className="absolute inset-0 -z-10 rounded-full bg-cyan"
              />
            )}
            {m.label}
          </button>
        )
      })}
    </div>
  )
}
EOF

# ─── LAYOUT: SITE HEADER ──────────────────────────────────────────────────────
cat > src/components/layout/site-header.tsx << 'EOF'
'use client'

import Link from 'next/link'
import { motion } from 'framer-motion'
import { Command, BookOpen } from 'lucide-react'
import { ModeToggle } from './mode-toggle'
import { useUIStore } from '@/store/use-ui-store'
import { useKeyboardShortcut } from '@/hooks/use-keyboard-shortcut'
import { spring } from '@/components/shared/motion-variants'

export function SiteHeader() {
  const setPaletteOpen = useUIStore((s) => s.setPaletteOpen)
  useKeyboardShortcut({ key: 'k', meta: true }, () => setPaletteOpen(true))
  useKeyboardShortcut({ key: 'b' }, () => {
    document.getElementById('book')?.scrollIntoView({ behavior: 'smooth' })
  })

  return (
    <header className="sticky top-0 z-40 border-b border-border bg-bg/80 backdrop-blur-md">
      <nav
        aria-label="Primary"
        className="mx-auto flex h-14 max-w-7xl items-center justify-between px-4 md:px-6"
      >
        <Link href="/" className="flex items-center gap-2">
          <span className="grid h-6 w-6 place-items-center rounded-sm bg-orange font-mono text-[11px] font-bold text-bg">
            A
          </span>
          <span className="text-sm font-semibold tracking-tight">Aurexis Systems</span>
          <span className="hidden font-mono text-[10px] text-muted md:inline">/ INC.</span>
        </Link>

        <div className="flex items-center gap-2">
          <ModeToggle />

          <button
            onClick={() => setPaletteOpen(true)}
            aria-label="Open command palette"
            className="group flex items-center gap-2 rounded-full border border-border bg-surface px-3 py-1.5 text-[11px] text-muted transition-colors hover:border-[#2a2a32] hover:text-fg"
          >
            <Command className="h-3 w-3" />
            <span className="hidden md:inline">Search</span>
            <kbd className="rounded border border-border bg-bg px-1.5 py-0.5 font-mono text-[10px]">
              ⌘K
            </kbd>
          </button>

          <motion.a
            href="#book"
            whileTap={{ scale: 0.96 }}
            transition={spring}
            data-analytics="header-book"
            className="hidden items-center gap-2 rounded-full bg-fg px-3.5 py-1.5 text-[11px] font-medium text-bg transition-colors hover:bg-white md:inline-flex"
          >
            <BookOpen className="h-3 w-3" />
            Book a Call
            <kbd className="rounded border border-bg/20 px-1 py-px font-mono text-[9px]">B</kbd>
          </motion.a>
        </div>
      </nav>
    </header>
  )
}
EOF

# ─── LAYOUT: COMMAND PALETTE ──────────────────────────────────────────────────
cat > src/components/layout/command-palette.tsx << 'EOF'
'use client'

import { useEffect } from 'react'
import { Command } from 'cmdk'
import { AnimatePresence, motion } from 'framer-motion'
import { useRouter } from 'next/navigation'
import { useUIStore } from '@/store/use-ui-store'
import { useModeStore } from '@/store/use-mode-store'
import { NAV_ITEMS } from '@/data/navigation'

const GROUPS = ['Navigate', 'Services', 'Proof'] as const

export function CommandPalette() {
  const open = useUIStore((s) => s.paletteOpen)
  const setOpen = useUIStore((s) => s.setPaletteOpen)
  const mode = useModeStore((s) => s.mode)
  const setMode = useModeStore((s) => s.setMode)
  const router = useRouter()

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setOpen(false)
    }
    if (open) window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [open, setOpen])

  useEffect(() => {
    document.documentElement.style.overflow = open ? 'hidden' : ''
    return () => {
      document.documentElement.style.overflow = ''
    }
  }, [open])

  const run = (fn: () => void) => () => {
    fn()
    setOpen(false)
  }

  return (
    <AnimatePresence>
      {open && (
        <motion.div
          role="dialog"
          aria-modal="true"
          aria-label="Command palette"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.12 }}
          className="fixed inset-0 z-50 grid place-items-start justify-center bg-bg/70 pt-[15vh] backdrop-blur-sm"
          onClick={() => setOpen(false)}
        >
          <motion.div
            initial={{ opacity: 0, y: -8, scale: 0.98 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -8, scale: 0.98 }}
            transition={{ type: 'spring', stiffness: 400, damping: 30 }}
            onClick={(e) => e.stopPropagation()}
            className="w-[min(92vw,640px)] overflow-hidden rounded-xl border border-border bg-surface/95 shadow-[0_24px_80px_-12px_rgba(0,0,0,0.8)]"
          >
            <Command
              label="Command palette"
              loop
              className="[&_[cmdk-group-heading]]:px-3 [&_[cmdk-group-heading]]:pt-3 [&_[cmdk-group-heading]]:font-mono [&_[cmdk-group-heading]]:text-[10px] [&_[cmdk-group-heading]]:uppercase [&_[cmdk-group-heading]]:tracking-widest [&_[cmdk-group-heading]]:text-muted"
            >
              <div className="flex items-center gap-2 border-b border-border px-3 py-2.5">
                <span className="font-mono text-[11px] text-muted">⌘</span>
                <Command.Input
                  autoFocus
                  placeholder="Jump to section, run action…"
                  className="w-full bg-transparent text-sm text-fg placeholder:text-dim focus:outline-none"
                />
              </div>

              <Command.List className="max-h-[min(60vh,420px)] overflow-y-auto p-2">
                <Command.Empty className="px-3 py-6 text-center font-mono text-xs text-muted">
                  No matches.
                </Command.Empty>

                {GROUPS.map((group) => {
                  const items = NAV_ITEMS.filter((i) => i.group === group)
                  if (!items.length) return null
                  return (
                    <Command.Group key={group} heading={group}>
                      {items.map((item) => (
                        <Command.Item
                          key={item.id}
                          value={`${item.label} ${item.id}`}
                          onSelect={run(() => router.push(`/${item.href}`))}
                          className="flex cursor-pointer items-center justify-between rounded-md px-3 py-2 text-sm text-[#c9c9d1] aria-selected:bg-[#15151a] aria-selected:text-fg"
                        >
                          <span>{item.label}</span>
                          {item.shortcut && (
                            <kbd className="rounded border border-border px-1.5 py-0.5 font-mono text-[10px] text-muted">
                              {item.shortcut}
                            </kbd>
                          )}
                        </Command.Item>
                      ))}
                    </Command.Group>
                  )
                })}

                <Command.Separator className="my-2 h-px bg-border" />

                <Command.Group heading="Modes">
                  <Command.Item
                    onSelect={run(() =>
                      setMode(mode === 'engineer' ? 'executive' : 'engineer'),
                    )}
                    className="flex cursor-pointer items-center justify-between rounded-md px-3 py-2 text-sm text-[#c9c9d1] aria-selected:bg-[#15151a]"
                  >
                    <span>Switch to {mode === 'engineer' ? 'Executive' : 'Engineer'} Mode</span>
                    <kbd className="rounded border border-border px-1.5 py-0.5 font-mono text-[10px]">M</kbd>
                  </Command.Item>
                </Command.Group>
              </Command.List>
            </Command>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}
EOF

# ─── LAYOUT: TELEMETRY TICKER ─────────────────────────────────────────────────
cat > src/components/layout/telemetry-ticker.tsx << 'EOF'
'use client'

import { useEffect, useMemo, useRef, useState } from 'react'
import { useTelemetryStore } from '@/store/use-telemetry-store'
import { deriveLatency, REGION_NODES } from '@/data/telemetry'
import { useModeStore } from '@/store/use-mode-store'

function fmt(n: number, digits = 0) {
  return n.toLocaleString('en-US', {
    minimumFractionDigits: digits,
    maximumFractionDigits: digits,
  })
}

export function TelemetryTicker() {
  const [mounted, setMounted] = useState(false)
  const setSnapshot = useTelemetryStore((s) => s.setSnapshot)
  const { uptime, requestsPerSec, incidents, tick } = useTelemetryStore()
  const engineer = useModeStore((s) => s.mode === 'engineer')
  const rafRef = useRef<number>()

  useEffect(() => {
    setMounted(true)
    let last = 0
    const TICK_MS = 1600
    const start = performance.now()
    const loop = (t: number) => {
      if (t - last > TICK_MS) {
        last = t
        const phase = (t - start) / 5000
        const rps = 12480 + Math.sin(phase) * 820 + Math.sin(phase * 0.37) * 240
        setSnapshot({
          requestsPerSec: Math.round(rps),
          p95LatencyMs: deriveLatency(rps),
          uptime: 99.99,
          tick: useTelemetryStore.getState().tick + 1,
        })
      }
      rafRef.current = requestAnimationFrame(loop)
    }
    rafRef.current = requestAnimationFrame(loop)
    return () => {
      if (rafRef.current) cancelAnimationFrame(rafRef.current)
    }
  }, [setSnapshot])

  const cells = useMemo(
    () => [
      { k: 'STATUS', v: 'OPERATIONAL' },
      { k: 'UPTIME', v: `${uptime.toFixed(2)}%` },
      { k: 'REQ/S', v: fmt(requestsPerSec) },
      { k: 'P95', v: `${deriveLatency(requestsPerSec)}ms` },
      { k: 'REGIONS', v: String(REGION_NODES.length) },
      { k: 'INCIDENTS', v: String(incidents.length).padStart(2, '0') },
    ],
    [uptime, requestsPerSec, incidents.length],
  )

  const renderValue = (k: string, v: string) => {
    if (!mounted && (k === 'REQ/S' || k === 'P95')) {
      return k === 'REQ/S' ? '12,480' : '42ms'
    }
    return v
  }

  return (
    <div
      role="status"
      aria-live="polite"
      aria-atomic="true"
      className="sticky top-14 z-30 border-y border-border bg-surface/85 backdrop-blur-md"
    >
      <div className="mx-auto flex max-w-7xl items-center gap-6 overflow-hidden px-4 py-1.5 font-mono text-[10px] uppercase tracking-widest text-muted md:px-6">
        <span className="flex items-center gap-1.5">
          <span className="relative flex h-1.5 w-1.5">
            <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-cyan opacity-60" />
            <span className="relative inline-flex h-1.5 w-1.5 rounded-full bg-cyan" />
          </span>
          <span className="text-cyan">LIVE</span>
        </span>

        {cells.map(({ k, v }) => (
          <span key={k} className="flex items-center gap-2 whitespace-nowrap">
            <span className="text-dim">{k}</span>
            <span className="text-[#c9c9d1] tabular-nums">{renderValue(k, v)}</span>
          </span>
        ))}

        {engineer && (
          <span className="ml-auto hidden items-center gap-2 whitespace-nowrap text-dim md:flex">
            <span>TICK</span>
            <span className="text-cyan tabular-nums">
              {String(tick).padStart(6, '0')}
            </span>
          </span>
        )}
      </div>
    </div>
  )
}
EOF

# ─── HERO: PARTICLE GLOBE ─────────────────────────────────────────────────────
cat > src/components/hero/particle-globe.tsx << 'EOF'
'use client'

import { useEffect, useRef } from 'react'
import { REGION_NODES } from '@/data/telemetry'

interface Vec3 {
  x: number
  y: number
  z: number
}

function latLngToVec3(lat: number, lng: number): Vec3 {
  const phi = (lat * Math.PI) / 180
  const lambda = (lng * Math.PI) / 180
  const cosPhi = Math.cos(phi)
  return {
    x: cosPhi * Math.cos(lambda),
    y: Math.sin(phi),
    z: cosPhi * Math.sin(lambda),
  }
}

function rotate(v: Vec3, yaw: number, pitch: number): Vec3 {
  const cy = Math.cos(yaw), sy = Math.sin(yaw)
  const cx = Math.cos(pitch), sx = Math.sin(pitch)
  const x1 = cy * v.x + sy * v.z
  const y1 = v.y
  const z1 = -sy * v.x + cy * v.z
  return { x: x1, y: cx * y1 - sx * z1, z: sx * y1 + cx * z1 }
}

function buildDots(count = 1600): Vec3[] {
  const dots: Vec3[] = []
  const golden = Math.PI * (3 - Math.sqrt(5))
  for (let i = 0; i < count; i++) {
    const y = 1 - (i / (count - 1)) * 2
    const r = Math.sqrt(1 - y * y)
    const theta = golden * i
    dots.push({ x: Math.cos(theta) * r, y, z: Math.sin(theta) * r })
  }
  for (const n of REGION_NODES) dots.push(latLngToVec3(n.lat, n.lng))
  return dots
}

export default function ParticleGlobe() {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const stateRef = useRef({
    yaw: 0,
    pitch: -0.35,
    dragging: false,
    px: 0,
    py: 0,
    vy: 0.0025,
  })

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return

    const dots = buildDots()
    const nodeVecs = REGION_NODES.map((n) => latLngToVec3(n.lat, n.lng))

    let raf = 0
    let w = 0, h = 0
    const dpr = Math.min(window.devicePixelRatio || 1, 2)

    const resize = () => {
      const rect = canvas.getBoundingClientRect()
      w = rect.width
      h = rect.height
      canvas.width = w * dpr
      canvas.height = h * dpr
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
    }
    resize()
    const ro = new ResizeObserver(resize)
    ro.observe(canvas)

    const onDown = (e: PointerEvent) => {
      stateRef.current.dragging = true
      stateRef.current.px = e.clientX
      stateRef.current.py = e.clientY
      canvas.setPointerCapture(e.pointerId)
    }
    const onMove = (e: PointerEvent) => {
      const s = stateRef.current
      if (!s.dragging) return
      const dx = e.clientX - s.px
      const dy = e.clientY - s.py
      s.yaw += dx * 0.006
      s.pitch = Math.max(-1.2, Math.min(1.2, s.pitch + dy * 0.005))
      s.vy = dx * 0.0008
      s.px = e.clientX
      s.py = e.clientY
    }
    const onUp = () => {
      stateRef.current.dragging = false
    }

    canvas.addEventListener('pointerdown', onDown)
    canvas.addEventListener('pointermove', onMove)
    canvas.addEventListener('pointerup', onUp)
    canvas.addEventListener('pointercancel', onUp)

    const draw = () => {
      const s = stateRef.current
      if (!s.dragging) {
        s.yaw += s.vy
        s.vy += (0.0025 - s.vy) * 0.02
      }

      ctx.clearRect(0, 0, w, h)
      const cx = w / 2
      const cy = h / 2
      const R = Math.min(w, h) * 0.38

      ctx.strokeStyle = 'rgba(53,230,242,0.08)'
      ctx.lineWidth = 1
      ctx.beginPath()
      ctx.arc(cx, cy, R, 0, Math.PI * 2)
      ctx.stroke()

      const g = ctx.createRadialGradient(cx, cy, R * 0.2, cx, cy, R * 1.1)
      g.addColorStop(0, 'rgba(53,230,242,0.06)')
      g.addColorStop(1, 'rgba(53,230,242,0)')
      ctx.fillStyle = g
      ctx.beginPath()
      ctx.arc(cx, cy, R, 0, Math.PI * 2)
      ctx.fill()

      for (const d of dots) {
        const r = rotate(d, s.yaw, s.pitch)
        if (r.z < -0.05) continue
        const sx = cx + r.x * R
        const sy = cy - r.y * R
        const alpha = 0.12 + Math.max(0, r.z) * 0.55
        const size = 0.6 + Math.max(0, r.z) * 0.9
        ctx.fillStyle = `rgba(200,220,240,${alpha})`
        ctx.fillRect(sx, sy, size, size)
      }

      for (const nv of nodeVecs) {
        const r = rotate(nv, s.yaw, s.pitch)
        if (r.z < 0) continue
        const sx = cx + r.x * R
        const sy = cy - r.y * R
        const alpha = 0.35 + r.z * 0.6
        ctx.fillStyle = `rgba(53,230,242,${alpha})`
        ctx.beginPath()
        ctx.arc(sx, sy, 2 + r.z * 2, 0, Math.PI * 2)
        ctx.fill()
        ctx.fillStyle = `rgba(53,230,242,${alpha * 0.2})`
        ctx.beginPath()
        ctx.arc(sx, sy, 6 + r.z * 4, 0, Math.PI * 2)
        ctx.fill()
      }

      raf = requestAnimationFrame(draw)
    }
    raf = requestAnimationFrame(draw)

    return () => {
      cancelAnimationFrame(raf)
      ro.disconnect()
      canvas.removeEventListener('pointerdown', onDown)
      canvas.removeEventListener('pointermove', onMove)
      canvas.removeEventListener('pointerup', onUp)
      canvas.removeEventListener('pointercancel', onUp)
    }
  }, [])

  return (
    <canvas
      ref={canvasRef}
      aria-hidden="true"
      className="h-full w-full cursor-grab touch-none active:cursor-grabbing"
    />
  )
}
EOF

# ─── HERO: GLOBE FALLBACK ─────────────────────────────────────────────────────
cat > src/components/hero/globe-fallback.tsx << 'EOF'
'use client'

export function GlobeFallback() {
  const size = 320
  const cx = size / 2
  const cy = size / 2
  const R = size * 0.4
  const rows = 12
  const cols = 24

  const rings: React.ReactElement[] = []
  for (let i = 1; i < rows; i++) {
    const phi = (i / rows) * Math.PI
    const r = Math.sin(phi) * R
    const ry = R * 0.25
    const y = cy - Math.cos(phi) * R
    rings.push(
      <ellipse
        key={`lat-${i}`}
        cx={cx}
        cy={y}
        rx={r}
        ry={ry}
        fill="none"
        stroke="#35e6f2"
        strokeWidth={0.5}
        opacity={0.15}
      />,
    )
  }
  for (let i = 0; i < cols; i++) {
    const theta = (i / cols) * Math.PI
    rings.push(
      <ellipse
        key={`lng-${i}`}
        cx={cx}
        cy={cy}
        rx={R * Math.abs(Math.cos(theta))}
        ry={R}
        fill="none"
        stroke="#35e6f2"
        strokeWidth={0.5}
        opacity={0.1}
      />,
    )
  }

  return (
    <div className="grid h-full w-full place-items-center">
      <svg
        viewBox={`0 0 ${size} ${size}`}
        width="100%"
        height="100%"
        aria-hidden="true"
        className="max-h-[420px] max-w-[420px]"
      >
        <defs>
          <radialGradient id="globe-fallback-glow" cx="50%" cy="50%" r="50%">
            <stop offset="0%" stopColor="#35e6f2" stopOpacity="0.14" />
            <stop offset="100%" stopColor="#35e6f2" stopOpacity="0" />
          </radialGradient>
        </defs>
        <circle cx={cx} cy={cy} r={R * 1.3} fill="url(#globe-fallback-glow)" />
        {rings}
        <circle
          cx={cx}
          cy={cy}
          r={R}
          fill="none"
          stroke="#35e6f2"
          strokeWidth={1}
          opacity={0.4}
        />
        {[
          { x: cx - R * 0.3, y: cy - R * 0.2 },
          { x: cx + R * 0.4, y: cy - R * 0.1 },
          { x: cx + R * 0.1, y: cy + R * 0.5 },
          { x: cx - R * 0.4, y: cy + R * 0.3 },
        ].map((p, i) => (
          <circle
            key={i}
            cx={p.x}
            cy={p.y}
            r={3}
            fill="#35e6f2"
            style={{ filter: 'drop-shadow(0 0 6px #35e6f2)' }}
          />
        ))}
      </svg>
    </div>
  )
}
EOF

# ─── HERO: HERO SECTION ───────────────────────────────────────────────────────
cat > src/components/hero/hero-section.tsx << 'EOF'
'use client'

import dynamic from 'next/dynamic'
import { motion } from 'framer-motion'
import { useMediaQuery } from '@/hooks/use-media-query'
import { useReducedMotion } from '@/hooks/use-reduced-motion'
import { fadeUp, stagger } from '@/components/shared/motion-variants'
import { GlobeFallback } from './globe-fallback'

const ParticleGlobe = dynamic(() => import('./particle-globe'), {
  ssr: false,
  loading: () => <GlobeFallback />,
})

export function HeroSection() {
  const isDesktop = useMediaQuery('(min-width: 1024px)')
  const reduced = useReducedMotion()
  const showGlobe = isDesktop && !reduced

  return (
    <section className="relative overflow-hidden border-b border-border">
      <div className="mx-auto grid max-w-7xl grid-cols-1 gap-8 px-4 py-20 md:px-6 lg:grid-cols-[1.1fr_1fr] lg:py-28">
        <motion.div
          initial="hidden"
          animate="show"
          variants={stagger(0.06)}
          className="flex flex-col justify-center"
        >
          <motion.p
            variants={fadeUp}
            className="mb-4 font-mono text-[11px] uppercase tracking-[0.2em] text-orange"
          >
            Aurexis Systems Inc. — Build 3.14.2
          </motion.p>

          <motion.h1
            variants={fadeUp}
            className="text-balance text-4xl font-semibold leading-[1.05] tracking-tight md:text-5xl lg:text-6xl"
          >
            We remove technical bottlenecks so companies scale revenue and operations{' '}
            <span className="text-muted">effortlessly.</span>
          </motion.h1>

          <motion.p
            variants={fadeUp}
            className="mt-6 max-w-xl text-base text-muted md:text-lg"
          >
            Elite digital engineering for SaaS and fast-scaling tech. Next.js architecture,
            typed data pipelines, and Core-Web-Vitals-clean performance — shipped as one
            system.
          </motion.p>

          <motion.div variants={fadeUp} className="mt-8 flex flex-wrap items-center gap-3">
            <a
              href="#book"
              data-analytics="hero-book"
              className="rounded-full bg-orange px-5 py-2.5 text-sm font-medium text-bg transition-colors hover:bg-[#ff7038]"
            >
              Book a Call →
            </a>
            <a
              href="#platform"
              className="rounded-full border border-border px-5 py-2.5 text-sm text-[#c9c9d1] transition-colors hover:border-[#2a2a32] hover:text-fg"
            >
              See the platform
            </a>
          </motion.div>
        </motion.div>

        <div className="relative aspect-square w-full lg:aspect-auto">
          <div className="absolute inset-0">
            {showGlobe ? <ParticleGlobe /> : <GlobeFallback />}
          </div>
        </div>
      </div>
    </section>
  )
}
EOF

# ─── BENTO: BORDER BEAM ───────────────────────────────────────────────────────
cat > src/components/bento/border-beam.tsx << 'EOF'
'use client'

import { motion, useReducedMotion } from 'framer-motion'

export function BorderBeam({ duration = 6 }: { duration?: number }) {
  const reduced = useReducedMotion()
  if (reduced) return null
  return (
    <div
      aria-hidden="true"
      className="pointer-events-none absolute inset-0 rounded-[inherit] [mask:linear-gradient(#000,#000)_content-box,linear-gradient(#000,#000)] [mask-composite:exclude] p-px"
    >
      <motion.div
        initial={{ rotate: 0 }}
        animate={{ rotate: 360 }}
        transition={{ duration, repeat: Infinity, ease: 'linear' }}
        className="absolute inset-[-100%] rounded-full"
        style={{
          background:
            'conic-gradient(from 0deg, transparent 0deg, #35e6f2 40deg, transparent 90deg, transparent 270deg, #ff5b1f 320deg, transparent 360deg)',
        }}
      />
    </div>
  )
}
EOF

# ─── BENTO: LIVE COUNTER ──────────────────────────────────────────────────────
cat > src/components/bento/live-counter.tsx << 'EOF'
'use client'

import { useAnimatedNumber } from '@/hooks/use-animated-number'

interface Props {
  to: number
  digits?: number
  suffix?: string
  prefix?: string
  decimals?: number
}

export function LiveCounter({ to, digits = 0, suffix = '', prefix = '', decimals = 0 }: Props) {
  const n = useAnimatedNumber(to)
  const fmt = n.toLocaleString('en-US', {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  })
  return (
    <span className="tabular-nums">
      {prefix}
      {fmt.padStart(digits, '0')}
      {suffix}
    </span>
  )
}
EOF

# ─── BENTO: INCIDENT BADGES ───────────────────────────────────────────────────
cat > src/components/bento/incident-badges.tsx << 'EOF'
'use client'

import { useTelemetryStore } from '@/store/use-telemetry-store'

const SEVERITY_STYLE = {
  info: { dot: '#35e6f2', label: 'INFO' },
  warn: { dot: '#f5a623', label: 'WARN' },
  critical: { dot: '#ef4444', label: 'CRIT' },
} as const

export function IncidentBadges() {
  const incidents = useTelemetryStore((s) => s.incidents)
  const all =
    incidents.length === 0
      ? [
          {
            id: 'ok',
            severity: 'info' as const,
            region: 'global',
            message: 'All systems nominal',
            startedAt: 0,
          },
        ]
      : incidents.slice(0, 3)

  return (
    <ul className="flex flex-wrap gap-1.5" aria-label="Recent incidents">
      {all.map((i) => {
        const s = SEVERITY_STYLE[i.severity]
        return (
          <li
            key={i.id}
            className="inline-flex items-center gap-1.5 rounded-full border border-border bg-surface px-2 py-0.5 font-mono text-[9px] uppercase tracking-widest text-muted"
          >
            <span className="relative flex h-1.5 w-1.5 shrink-0" aria-hidden="true">
              <span
                className="absolute inline-flex h-full w-full animate-ping rounded-full opacity-60"
                style={{ background: s.dot }}
              />
              <span
                className="relative inline-flex h-1.5 w-1.5 rounded-full"
                style={{ background: s.dot }}
              />
            </span>
            <span style={{ color: s.dot }}>{s.label}</span>
            <span className="text-dim">{i.region}</span>
          </li>
        )
      })}
    </ul>
  )
}
EOF

# ─── BENTO: SVG NODE FLOW ─────────────────────────────────────────────────────
cat > src/components/bento/svg-node-flow.tsx << 'EOF'
'use client'

import { useEffect, useMemo, useRef } from 'react'
import { bezierPath, bezierPoint } from '@/lib/bezier'
import { useReducedMotion } from '@/hooks/use-reduced-motion'

const NODES = [
  { id: 'in', label: 'INGEST' },
  { id: 'val', label: 'VALIDATE' },
  { id: 'xform', label: 'TRANSFORM' },
  { id: 'out', label: 'SERVE' },
]

const VW = 420
const VH = 120
const PAD_X = 48

function layout() {
  const step = (VW - PAD_X * 2) / (NODES.length - 1)
  return NODES.map((n, i) => ({ ...n, x: PAD_X + step * i, y: VH / 2 }))
}

export function SvgNodeFlow() {
  const reduced = useReducedMotion()
  const nodes = useMemo(layout, [])
  const dotsRef = useRef<Array<SVGCircleElement | null>>([])

  const edges = useMemo(
    () =>
      nodes.slice(0, -1).map((from, i) => {
        const to = nodes[i + 1]!
        return {
          key: `${from.id}-${to.id}`,
          bezier: {
            p0: { x: from.x + 14, y: from.y },
            p1: { x: from.x + (to.x - from.x) * 0.4, y: from.y - 14 },
            p2: { x: to.x - (to.x - from.x) * 0.4, y: to.y + 14 },
            p3: { x: to.x - 14, y: to.y },
          },
        }
      }),
    [nodes],
  )

  useEffect(() => {
    if (reduced) return
    let raf = 0
    const t0 = performance.now()
    const loop = (now: number) => {
      const elapsed = (now - t0) / 1000
      let idx = 0
      edges.forEach((e, ei) => {
        for (let k = 0; k < 2; k++) {
          const el = dotsRef.current[idx++]
          if (!el) continue
          const t = (elapsed * 0.6 + k / 2 + ei * 0.15) % 1
          const p = bezierPoint(t, e.bezier)
          el.setAttribute('cx', String(p.x))
          el.setAttribute('cy', String(p.y))
          el.setAttribute('opacity', String(Math.sin(t * Math.PI) * 0.9))
        }
      })
      raf = requestAnimationFrame(loop)
    }
    raf = requestAnimationFrame(loop)
    return () => cancelAnimationFrame(raf)
  }, [edges, reduced])

  return (
    <div className="rounded-xl border border-border bg-bg p-4">
      <div className="mb-2 flex items-center justify-between font-mono text-[9px] uppercase tracking-widest text-dim">
        <span>API TRAFFIC FLOW</span>
        <span className="text-cyan">12,480 rps</span>
      </div>
      <svg viewBox={`0 0 ${VW} ${VH}`} width="100%" className="block">
        <defs>
          <marker
            id="flow-arrow"
            viewBox="0 0 10 10"
            refX="8"
            refY="5"
            markerWidth="6"
            markerHeight="6"
            orient="auto-start-reverse"
          >
            <path d="M 0 0 L 10 5 L 0 10 z" fill="#35e6f2" opacity="0.7" />
          </marker>
        </defs>

        {edges.map((e) => (
          <path
            key={e.key}
            d={bezierPath(e.bezier)}
            stroke="#35e6f2"
            strokeWidth={1}
            strokeOpacity={0.28}
            fill="none"
            markerEnd="url(#flow-arrow)"
          />
        ))}

        {edges.flatMap((e, ei) =>
          [0, 1].map((k) => (
            <circle
              key={`${e.key}-${k}`}
              ref={(el) => {
                dotsRef.current[ei * 2 + k] = el
              }}
              r={2.4}
              fill="#35e6f2"
              opacity={0}
            />
          )),
        )}

        {nodes.map((n) => (
          <g key={n.id}>
            <circle cx={n.x} cy={n.y} r={12} fill="#0b0b0e" stroke="#1c1c22" />
            <circle cx={n.x} cy={n.y} r={4} fill="#35e6f2" />
            <text
              x={n.x}
              y={n.y + 28}
              textAnchor="middle"
              className="select-none font-mono"
              fontSize={8}
              fill="#8a8a94"
              style={{ letterSpacing: '0.1em' }}
            >
              {n.label}
            </text>
          </g>
        ))}
      </svg>
    </div>
  )
}
EOF

# ─── BENTO: TERMINAL LOGS ─────────────────────────────────────────────────────
cat > src/components/bento/terminal-logs.tsx << 'EOF'
'use client'

import { useEffect, useRef, useState } from 'react'
import { makeLine, type LogLine } from '@/lib/logs'
import { useModeStore } from '@/store/use-mode-store'
import { useReducedMotion } from '@/hooks/use-reduced-motion'

const LEVEL_COLOR: Record<LogLine['level'], string> = {
  INFO: '#8a8a94',
  DEBUG: '#5a5a64',
  OK: '#22c55e',
  WARN: '#f5a623',
  ERR: '#ef4444',
}

const MAX_LINES = 14
const INTERVAL_MS = 620
const INTERVAL_MS_ENGINEER = 240

function formatTime(t: number) {
  const d = new Date(t)
  const hh = String(d.getHours()).padStart(2, '0')
  const mm = String(d.getMinutes()).padStart(2, '0')
  const ss = String(d.getSeconds()).padStart(2, '0')
  const ms = String(d.getMilliseconds()).padStart(3, '0')
  return `${hh}:${mm}:${ss}.${ms}`
}

export function TerminalLogs() {
  const engineer = useModeStore((s) => s.mode === 'engineer')
  const reduced = useReducedMotion()
  const [lines, setLines] = useState<LogLine[]>([])
  const counterRef = useRef(0)
  const scrollRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (reduced) {
      setLines(Array.from({ length: 8 }, (_, i) => makeLine(i)))
      return
    }
    let alive = true
    let handle: number | undefined
    const period = engineer ? INTERVAL_MS_ENGINEER : INTERVAL_MS

    const push = () => {
      if (!alive) return
      const next = makeLine(counterRef.current++)
      setLines((prev) => {
        const arr = [...prev, next]
        return arr.length > MAX_LINES ? arr.slice(arr.length - MAX_LINES) : arr
      })
      handle = window.setTimeout(push, period + (next.id % 5) * 40)
    }
    push()
    return () => {
      alive = false
      if (handle) clearTimeout(handle)
    }
  }, [engineer, reduced])

  useEffect(() => {
    const el = scrollRef.current
    if (!el) return
    const atBottom = el.scrollHeight - el.scrollTop - el.clientHeight < 24
    if (atBottom) el.scrollTop = el.scrollHeight
  }, [lines])

  return (
    <div className="rounded-xl border border-border bg-bg p-4">
      <div className="mb-3 flex items-center gap-2">
        <span className="flex gap-1" aria-hidden="true">
          <span className="h-2 w-2 rounded-full bg-[#ef4444]" />
          <span className="h-2 w-2 rounded-full bg-[#f5a623]" />
          <span className="h-2 w-2 rounded-full bg-[#22c55e]" />
        </span>
        <span className="font-mono text-[10px] uppercase tracking-widest text-muted">
          aurexis@edge — live
        </span>
        <span className="ml-auto font-mono text-[10px] text-dim">
          {engineer ? 'VERBOSE' : 'FILTERED'}
        </span>
      </div>

      <div
        ref={scrollRef}
        role="log"
        aria-live="polite"
        aria-relevant="additions"
        aria-label="Operational logs"
        className="max-h-[220px] min-h-[220px] overflow-y-auto rounded-md bg-[#050506] p-3 font-mono text-[10.5px] leading-relaxed"
      >
        {lines.map((l) => (
          <div key={l.id} className="flex gap-2 whitespace-pre">
            <span className="text-[#3a3a42]">{formatTime(l.t)}</span>
            <span style={{ color: LEVEL_COLOR[l.level] }} className="w-10 shrink-0">
              {l.level}
            </span>
            <span className="shrink-0 text-dim">{l.src.padEnd(11, ' ')}</span>
            <span className="text-[#c9c9d1]">{l.msg}</span>
          </div>
        ))}
        {!reduced && (
          <span className="inline-block h-3 w-1.5 translate-y-[2px] bg-cyan motion-safe:animate-pulse" />
        )}
      </div>
    </div>
  )
}
EOF

# ─── BENTO: BENTO CARD ────────────────────────────────────────────────────────
cat > src/components/bento/bento-card.tsx << 'EOF'
'use client'

import { motion } from 'framer-motion'
import { cn } from '@/lib/utils'
import { spring } from '@/components/shared/motion-variants'
import { SpecCallout } from '@/components/shared/spec-callout'
import { useModeStore } from '@/store/use-mode-store'
import { BorderBeam } from './border-beam'
import { SvgNodeFlow } from './svg-node-flow'
import { TerminalLogs } from './terminal-logs'
import type { ServiceCell } from '@/data/services'

export function BentoCard({ cell }: { cell: ServiceCell }) {
  const engineer = useModeStore((s) => s.mode === 'engineer')

  return (
    <motion.article
      whileHover={{ y: -3 }}
      transition={spring}
      className={cn(
        'group relative overflow-hidden rounded-xl border border-border bg-surface p-5',
        'transition-colors hover:border-[#2a2a32]',
        cell.span === 'lg' && 'lg:col-span-2 lg:row-span-2',
        cell.span === 'md' && 'lg:col-span-1',
        cell.span === 'sm' && 'lg:col-span-1',
      )}
    >
      <BorderBeam duration={8} />

      <div className="relative flex h-full flex-col gap-4">
        <header className="flex items-start justify-between gap-3">
          <span className="font-mono text-[10px] uppercase tracking-widest text-dim">
            {cell.eyebrow}
          </span>
          <SpecCallout>
            EXEC {cell.spec.execMs}ms · {cell.spec.bundleKb}KB
          </SpecCallout>
        </header>

        <h3 className="text-lg font-medium tracking-tight text-fg">{cell.title}</h3>
        <p className="text-sm leading-relaxed text-muted">{cell.body}</p>

        {cell.kind === 'node-flow' && <SvgNodeFlow />}
        {cell.kind === 'terminal' && <TerminalLogs />}

        {engineer && cell.code && (
          <pre className="mt-auto overflow-x-auto rounded-md border border-border bg-bg p-3 font-mono text-[10px] leading-relaxed text-cyan">
            {cell.code}
          </pre>
        )}
      </div>
    </motion.article>
  )
}
EOF

# ─── BENTO: BENTO GRID ────────────────────────────────────────────────────────
cat > src/components/bento/bento-grid.tsx << 'EOF'
'use client'

import { motion } from 'framer-motion'
import { SERVICE_CELLS } from '@/data/services'
import { BentoCard } from './bento-card'
import { stagger } from '@/components/shared/motion-variants'

export function BentoGrid() {
  return (
    <section id="services" className="border-b border-border">
      <div className="mx-auto max-w-7xl px-4 py-20 md:px-6">
        <header className="mb-10 max-w-2xl">
          <p className="font-mono text-[11px] uppercase tracking-[0.2em] text-orange">
            Services · Pillars 01–03
          </p>
          <h2 className="mt-3 text-3xl font-semibold tracking-tight md:text-4xl">
            One engineering partner. Three pillars. Zero bottlenecks.
          </h2>
        </header>

        <motion.div
          initial="hidden"
          whileInView="show"
          viewport={{ once: true, margin: '-80px' }}
          variants={stagger(0.05)}
          className="grid auto-rows-[minmax(180px,auto)] grid-cols-1 gap-3 md:grid-cols-2 lg:grid-cols-3"
        >
          {SERVICE_CELLS.map((c) => (
            <BentoCard key={c.id} cell={c} />
          ))}
        </motion.div>
      </div>
    </section>
  )
}
EOF

# ─── APP: PAGE REWRITE ────────────────────────────────────────────────────────
cat > src/app/page.tsx << 'EOF'
import { SiteHeader } from '@/components/layout/site-header'
import { CommandPalette } from '@/components/layout/command-palette'
import { TelemetryTicker } from '@/components/layout/telemetry-ticker'
import { HeroSection } from '@/components/hero/hero-section'
import { BentoGrid } from '@/components/bento/bento-grid'

export default function HomePage() {
  return (
    <>
      <SiteHeader />
      <CommandPalette />
      <TelemetryTicker />
      <main>
        <HeroSection />
        <BentoGrid />
      </main>
    </>
  )
}
EOF

echo ""
echo "==> Done. Files written:"
find src/components src/app/page.tsx -type f | sort
echo ""
echo "==> Total: $(find src/components -type f | wc -l) components + 1 page"
echo ""
echo "==> Next: commit, then run all four scripts in order."
