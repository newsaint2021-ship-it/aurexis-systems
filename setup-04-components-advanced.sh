#!/usr/bin/env bash
set -euo pipefail
echo "==> Writing advanced components (velocity, ontology, industrial, proof)..."

mkdir -p src/components/velocity src/components/ontology src/components/industrial src/components/proof src/components/ui

# ─── UI: KEYCAP ───────────────────────────────────────────────────────────────
cat > src/components/ui/keycap.tsx << 'EOF'
'use client'

import { motion } from 'framer-motion'
import { spring } from '@/components/shared/motion-variants'
import { cn } from '@/lib/utils'

interface Props {
  children: React.ReactNode
  label?: string
  className?: string
  active?: boolean
}

export function Keycap({ children, label, className, active = false }: Props) {
  return (
    <motion.span
      whileHover={{ y: -1 }}
      whileTap={{ y: 1, scale: 0.96 }}
      transition={spring}
      role={label ? 'img' : undefined}
      aria-label={label}
      className={cn(
        'inline-flex h-6 min-w-6 select-none items-center justify-center rounded-[6px] border px-1.5 font-mono text-[10px] leading-none',
        active
          ? 'border-cyan/50 bg-[#0b1a1c] text-cyan shadow-[inset_0_-1px_0_rgba(53,230,242,0.25)]'
          : 'border-border bg-surface text-[#c9c9d1] shadow-[inset_0_-1px_0_rgba(255,255,255,0.04)]',
        className,
      )}
    >
      {children}
    </motion.span>
  )
}

export function ShortcutHint({ keys, label }: { keys: string[]; label: string }) {
  return (
    <span className="inline-flex items-center gap-1.5">
      <span className="flex items-center gap-1">
        {keys.map((k) => (
          <Keycap key={k}>{k}</Keycap>
        ))}
      </span>
      <span className="font-mono text-[10px] uppercase tracking-widest text-dim">{label}</span>
    </span>
  )
}
EOF

# ─── INDUSTRIAL: KNOB DRAG HOOK ───────────────────────────────────────────────
cat > src/hooks/use-knob-drag.ts << 'EOF'
'use client'

import { useCallback, useRef, useState } from 'react'
import {
  angleToValue,
  clamp,
  pointToAngle,
  valueToAngle,
  type KnobSpec,
} from '@/lib/knob-math'

interface Options {
  spec: KnobSpec
  value: number
  onChange: (v: number) => void
  onStep?: (direction: 1 | -1) => void
}

export function useKnobDrag({ spec, value, onChange, onStep }: Options) {
  const ref = useRef<SVGSVGElement>(null)
  const dragRef = useRef<{ prev: number } | null>(null)
  const [dragging, setDragging] = useState(false)

  const fromPointer = useCallback(
    (clientX: number, clientY: number): number => {
      const el = ref.current
      if (!el) return value
      const r = el.getBoundingClientRect()
      const cx = r.left + r.width / 2
      const cy = r.top + r.height / 2
      return pointToAngle(cx, cy, clientX, clientY)
    },
    [value],
  )

  const onPointerDown = useCallback(
    (e: React.PointerEvent<SVGSVGElement>) => {
      e.preventDefault()
      ref.current?.setPointerCapture(e.pointerId)
      const theta = fromPointer(e.clientX, e.clientY)
      const v = angleToValue(theta, spec)
      onChange(v)
      dragRef.current = { prev: theta }
      setDragging(true)
    },
    [fromPointer, onChange, spec],
  )

  const onPointerMove = useCallback(
    (e: React.PointerEvent<SVGSVGElement>) => {
      if (!dragRef.current) return
      const theta = fromPointer(e.clientX, e.clientY)
      const v = angleToValue(theta, spec)
      if (v !== value) {
        onStep?.(v > value ? 1 : -1)
        onChange(v)
      }
      dragRef.current.prev = theta
    },
    [fromPointer, onChange, onStep, spec, value],
  )

  const onPointerUp = useCallback((e: React.PointerEvent<SVGSVGElement>) => {
    ref.current?.releasePointerCapture(e.pointerId)
    dragRef.current = null
    setDragging(false)
  }, [])

  const onKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      const coarse = spec.step * 10
      let next: number | null = null
      if (e.key === 'ArrowUp' || e.key === 'ArrowRight') next = value + spec.step
      else if (e.key === 'ArrowDown' || e.key === 'ArrowLeft') next = value - spec.step
      else if (e.key === 'PageUp') next = value + coarse
      else if (e.key === 'PageDown') next = value - coarse
      else if (e.key === 'Home') next = spec.min
      else if (e.key === 'End') next = spec.max
      if (next !== null) {
        e.preventDefault()
        const clamped = clamp(next, spec.min, spec.max)
        onStep?.(clamped > value ? 1 : -1)
        onChange(clamped)
      }
    },
    [value, spec, onChange, onStep],
  )

  return {
    ref,
    dragging,
    angle: valueToAngle(value, spec),
    handlers: { onPointerDown, onPointerMove, onPointerUp, onKeyDown },
  }
}
EOF

# ─── INDUSTRIAL: AUDIO HAPTICS HOOK ──────────────────────────────────────────
cat > src/hooks/use-audio-haptics.ts << 'EOF'
'use client'

import { useMemo } from 'react'
import { useAudioStore } from '@/store/use-audio-store'
import {
  click as rawClick,
  toggle as rawToggle,
  detent as rawDetent,
  ensureRunning,
} from '@/lib/audio-engine'

export function useAudioHaptics() {
  const muted = useAudioStore((s) => s.muted)
  const unlocked = useAudioStore((s) => s.unlocked)

  return useMemo(() => {
    const gate = async () => {
      if (muted || !unlocked) return false
      return ensureRunning()
    }
    return {
      click: () => {
        void gate().then((ok) => ok && rawClick())
      },
      toggle: (on: boolean) => {
        void gate().then((ok) => ok && rawToggle(on))
      },
      detent: () => {
        void gate().then((ok) => ok && rawDetent())
      },
    }
  }, [muted, unlocked])
}
EOF

# ─── INDUSTRIAL: ROTARY KNOB ─────────────────────────────────────────────────
cat > src/components/industrial/rotary-knob.tsx << 'EOF'
'use client'

import { motion } from 'framer-motion'
import { useKnobDrag } from '@/hooks/use-knob-drag'
import { DEFAULT_KNOB, tipPoint, type KnobSpec } from '@/lib/knob-math'
import { useAudioHaptics } from '@/hooks/use-audio-haptics'
import { cn } from '@/lib/utils'

interface Props {
  label: string
  value: number
  onChange: (v: number) => void
  format?: (v: number) => string
  spec?: KnobSpec
  size?: number
  accent?: string
}

export function RotaryKnob({
  label,
  value,
  onChange,
  format = (v) => String(v),
  spec = DEFAULT_KNOB,
  size = 92,
  accent = '#35e6f2',
}: Props) {
  const haptics = useAudioHaptics()
  const { ref, dragging, angle, handlers } = useKnobDrag({
    spec,
    value,
    onChange,
    onStep: () => haptics.detent(),
  })

  const cx = size / 2
  const cy = size / 2
  const R_OUTER = size * 0.44
  const R_TRACK = size * 0.4
  const R_BODY = size * 0.33
  const R_TIP = size * 0.22

  const a0 = ((spec.thetaMin - 90) * Math.PI) / 180
  const a1 = ((spec.thetaMax - 90) * Math.PI) / 180
  const large = spec.thetaMax - spec.thetaMin > 180 ? 1 : 0

  const trackPath = `M ${cx + Math.cos(a0) * R_TRACK} ${cy + Math.sin(a0) * R_TRACK}
    A ${R_TRACK} ${R_TRACK} 0 ${large} 1 ${cx + Math.cos(a1) * R_TRACK} ${cy + Math.sin(a1) * R_TRACK}`

  const aV = ((angle - 90) * Math.PI) / 180
  const fillPath = `M ${cx + Math.cos(a0) * R_TRACK} ${cy + Math.sin(a0) * R_TRACK}
    A ${R_TRACK} ${R_TRACK} 0 ${Math.abs(angle - spec.thetaMin) > 180 ? 1 : 0} 1
    ${cx + Math.cos(aV) * R_TRACK} ${cy + Math.sin(aV) * R_TRACK}`

  const ticks = Array.from({ length: 9 }, (_, i) => {
    const t = i / 8
    const th = spec.thetaMin + t * (spec.thetaMax - spec.thetaMin)
    const inner = tipPoint(cx, cy, R_TRACK + 2, th)
    const outer = tipPoint(cx, cy, R_OUTER, th)
    return { x1: inner.x, y1: inner.y, x2: outer.x, y2: outer.y, key: i }
  })

  return (
    <div className="flex flex-col items-center gap-2">
      <svg
        ref={ref}
        role="slider"
        aria-label={label}
        aria-valuemin={spec.min}
        aria-valuemax={spec.max}
        aria-valuenow={value}
        aria-valuetext={format(value)}
        tabIndex={0}
        width={size}
        height={size}
        viewBox={`0 0 ${size} ${size}`}
        className={cn(
          'select-none touch-none outline-none',
          dragging ? 'cursor-grabbing' : 'cursor-grab',
        )}
        {...handlers}
      >
        <defs>
          <radialGradient id={`knob-body-${label}`} cx="42%" cy="38%" r="65%">
            <stop offset="0%" stopColor="#1a1a20" />
            <stop offset="100%" stopColor="#0a0a0e" />
          </radialGradient>
          <radialGradient id={`knob-inner-${label}`} cx="50%" cy="50%" r="60%">
            <stop offset="0%" stopColor="#101016" />
            <stop offset="100%" stopColor="#05050a" />
          </radialGradient>
        </defs>

        <circle cx={cx} cy={cy} r={R_OUTER} fill="#0b0b0e" stroke="#1c1c22" strokeWidth={1} />

        {ticks.map((t) => (
          <line key={t.key} x1={t.x1} y1={t.y1} x2={t.x2} y2={t.y2} stroke="#2a2a32" strokeWidth={1} />
        ))}

        <path d={trackPath} stroke="#1c1c22" strokeWidth={3} fill="none" strokeLinecap="round" />

        {Math.abs(angle - spec.thetaMin) > 0.01 && (
          <path d={fillPath} stroke={accent} strokeWidth={3} fill="none" strokeLinecap="round" opacity={0.85} />
        )}

        <motion.circle
          cx={cx}
          cy={cy}
          r={R_BODY}
          fill={`url(#knob-body-${label})`}
          stroke="#2a2a32"
          strokeWidth={1}
          animate={{ filter: dragging ? 'brightness(1.15)' : 'brightness(1)' }}
          transition={{ duration: 0.12 }}
        />

        <circle cx={cx} cy={cy} r={R_BODY - 4} fill={`url(#knob-inner-${label})`} opacity={0.9} />

        {Array.from({ length: 24 }).map((_, i) => {
          const th = (i / 24) * 360
          const a = ((th - 90) * Math.PI) / 180
          const r1 = R_BODY - 1
          const r2 = R_BODY + 2
          return (
            <line
              key={i}
              x1={cx + Math.cos(a) * r1}
              y1={cy + Math.sin(a) * r1}
              x2={cx + Math.cos(a) * r2}
              y2={cy + Math.sin(a) * r2}
              stroke="#3a3a42"
              strokeWidth={0.6}
            />
          )
        })}

        <motion.g
          animate={{ rotate: angle }}
          transition={{ type: 'spring', stiffness: 400, damping: 30 }}
          style={{ transformOrigin: `${cx}px ${cy}px` }}
        >
          <line
            x1={cx}
            y1={cy - R_TIP}
            x2={cx}
            y2={cy - R_TIP - 6}
            stroke={accent}
            strokeWidth={2}
            strokeLinecap="round"
          />
        </motion.g>

        <circle cx={cx} cy={cy} r={2.5} fill="#1c1c22" />
      </svg>

      <div className="text-center">
        <div className="font-mono text-[9px] uppercase tracking-[0.18em] text-muted">{label}</div>
        <div className="font-mono text-xs tabular-nums text-fg">{format(value)}</div>
      </div>
    </div>
  )
}
EOF

# ─── INDUSTRIAL: MECHANICAL TOGGLE ───────────────────────────────────────────
cat > src/components/industrial/mechanical-toggle.tsx << 'EOF'
'use client'

import { motion } from 'framer-motion'
import { useAudioHaptics } from '@/hooks/use-audio-haptics'
import { spring } from '@/components/shared/motion-variants'
import { cn } from '@/lib/utils'

interface Props {
  checked: boolean
  onChange: (v: boolean) => void
  label: string
  hint?: string
}

export function MechanicalToggle({ checked, onChange, label, hint }: Props) {
  const haptics = useAudioHaptics()

  const flip = () => {
    haptics.toggle(!checked)
    onChange(!checked)
  }

  return (
    <div className="flex items-center justify-between gap-4">
      <div className="min-w-0">
        <div className="font-mono text-[10px] uppercase tracking-widest text-muted">{label}</div>
        {hint && <div className="mt-0.5 text-xs text-dim">{hint}</div>}
      </div>

      <button
        role="switch"
        aria-checked={checked}
        aria-label={label}
        onClick={flip}
        onKeyDown={(e) => {
          if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault()
            flip()
          }
        }}
        className="relative h-7 w-14 shrink-0 rounded-full border border-border bg-bg p-[3px] transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-cyan focus-visible:ring-offset-2 focus-visible:ring-offset-bg"
      >
        <span className="absolute inset-0 rounded-full bg-gradient-to-b from-black/60 to-transparent" />

        <motion.span
          layout
          animate={{ x: checked ? 28 : 0 }}
          transition={spring}
          className={cn(
            'relative z-10 block h-5 w-6 rounded-full border transition-colors',
            checked ? 'border-cyan/60 bg-[#0e1a1c]' : 'border-[#2a2a32] bg-[#15151a]',
          )}
        >
          <span className="pointer-events-none absolute inset-0 flex items-center justify-center gap-[2px]">
            {[0, 1, 2].map((i) => (
              <span
                key={i}
                className={cn('h-2.5 w-[1px] rounded-full', checked ? 'bg-cyan/80' : 'bg-[#3a3a42]')}
              />
            ))}
          </span>
        </motion.span>
      </button>
    </div>
  )
}
EOF

# ─── INDUSTRIAL: LED READOUT ─────────────────────────────────────────────────
cat > src/components/industrial/led-readout.tsx << 'EOF'
'use client'

import { useMemo } from 'react'
import { motion } from 'framer-motion'
import { glyph, GLYPH_H, GLYPH_W, textWidth } from '@/lib/dot-matrix-font'

interface Props {
  value: string | number
  label: string
  px?: number
  accent?: string
  ghost?: boolean
}

export function LedReadout({
  value,
  label,
  px = 3,
  accent = '#35e6f2',
  ghost = true,
}: Props) {
  const text = String(value)
  const chars = useMemo(() => Array.from(text), [text])

  const gapPx = px
  const w = textWidth(text, px, 1) + 8
  const h = GLYPH_H * px + 8
  const charStep = GLYPH_W * px + gapPx

  return (
    <div className="inline-flex flex-col items-center gap-2">
      <div
        className="rounded-md border border-border bg-[#040406] p-1 shadow-[inset_0_0_12px_rgba(0,0,0,0.9)]"
        role="img"
        aria-label={`${label}: ${text}`}
      >
        <svg width={w} height={h} viewBox={`0 0 ${w} ${h}`}>
          {ghost &&
            chars.map((_, ci) =>
              Array.from({ length: GLYPH_H }).map((__, ri) =>
                Array.from({ length: GLYPH_W }).map((___, xi) => (
                  <circle
                    key={`g-${ci}-${ri}-${xi}`}
                    cx={4 + ci * charStep + xi * px + px / 2}
                    cy={4 + ri * px + px / 2}
                    r={px / 2 - 0.4}
                    fill={accent}
                    opacity={0.06}
                  />
                )),
              ),
            )}

          {chars.map((ch, ci) => {
            const rows = glyph(ch)
            return rows.map((row, ri) =>
              Array.from({ length: GLYPH_W }).map((_, xi) => {
                const bit = (row >> (GLYPH_W - 1 - xi)) & 1
                if (!bit) return null
                return (
                  <motion.circle
                    key={`l-${ci}-${ri}-${xi}`}
                    cx={4 + ci * charStep + xi * px + px / 2}
                    cy={4 + ri * px + px / 2}
                    r={px / 2 - 0.4}
                    fill={accent}
                    initial={{ opacity: 0.75 }}
                    animate={{ opacity: [0.75, 1, 0.75] }}
                    transition={{ duration: 2.6, repeat: Infinity, delay: (ri + xi) * 0.03 }}
                    style={{ filter: `drop-shadow(0 0 ${px * 0.9}px ${accent}aa)` }}
                  />
                )
              }),
            )
          })}
        </svg>
      </div>
      <div className="font-mono text-[9px] uppercase tracking-[0.18em] text-muted">{label}</div>
    </div>
  )
}
EOF

# ─── INDUSTRIAL: BLUEPRINT OVERLAY ───────────────────────────────────────────
cat > src/components/industrial/blueprint-overlay.tsx << 'EOF'
'use client'

import { motion } from 'framer-motion'
import { useModeStore } from '@/store/use-mode-store'

interface Spec {
  label: string
  value: string
}

interface Props {
  specs: Spec[]
  anchor?: 'tl' | 'tr' | 'bl' | 'br'
  title?: string
}

const POS: Record<NonNullable<Props['anchor']>, string> = {
  tl: 'left-3 top-3',
  tr: 'right-3 top-3',
  bl: 'left-3 bottom-3',
  br: 'right-3 bottom-3',
}

export function BlueprintOverlay({ specs, anchor = 'tr', title = 'SPEC' }: Props) {
  const engineer = useModeStore((s) => s.mode === 'engineer')

  return (
    <motion.div
      aria-hidden={!engineer}
      initial={false}
      animate={{ opacity: engineer ? 1 : 0, y: engineer ? 0 : 4 }}
      transition={{ duration: 0.18 }}
      className={`pointer-events-none absolute z-10 ${POS[anchor]}`}
    >
      <div className="relative rounded-md border border-dashed border-cyan/30 bg-bg/85 px-3 py-2 font-mono text-[9px] uppercase tracking-widest text-cyan backdrop-blur-sm">
        <CornerMarks />
        <div className="mb-1 text-[8px] text-dim">[ {title} ]</div>
        <dl className="grid grid-cols-[auto_1fr] gap-x-3 gap-y-0.5">
          {specs.map((s) => (
            <div key={s.label} className="contents">
              <dt className="text-dim">{s.label}</dt>
              <dd className="text-right tabular-nums">{s.value}</dd>
            </div>
          ))}
        </dl>
      </div>
    </motion.div>
  )
}

function CornerMarks() {
  return (
    <>
      {[
        { cls: 'left-0 top-0', d: 'M 0 4 L 0 0 L 4 0' },
        { cls: 'right-0 top-0', d: 'M 0 0 L 4 0 L 4 4' },
        { cls: 'left-0 bottom-0', d: 'M 0 0 L 0 4 L 4 4' },
        { cls: 'right-0 bottom-0', d: 'M 4 0 L 4 4 L 0 4' },
      ].map((m, i) => (
        <svg
          key={i}
          width={5}
          height={5}
          viewBox="0 0 5 5"
          className={`absolute ${m.cls}`}
          style={{ margin: -1 }}
        >
          <path d={m.d} stroke="#35e6f2" strokeWidth={1} fill="none" opacity={0.5} />
        </svg>
      ))}
    </>
  )
}
EOF

# ─── VELOCITY: ISOMETRIC ILLUSTRATION ────────────────────────────────────────
cat > src/components/velocity/isometric-illustration.tsx << 'EOF'
'use client'

import { useMemo } from 'react'
import { motion } from 'framer-motion'
import { SCENES, type SceneId } from '@/lib/iso-scenes'
import { project, type IsoView } from '@/lib/iso'
import { useReducedMotion } from '@/hooks/use-reduced-motion'

interface Props {
  scene: SceneId
  size?: number
  accent?: string
  className?: string
}

export function IsometricIllustration({
  scene,
  size = 240,
  accent = '#35e6f2',
  className,
}: Props) {
  const reduced = useReducedMotion()
  const { mesh, focal } = useMemo(() => SCENES[scene](), [scene])

  const view: IsoView = { scale: 1.4, cx: size / 2, cy: size / 2 + 20 }
  const projected = useMemo(() => mesh.vertices.map((v) => project(v, view)), [mesh, view])
  const focal2 = useMemo(() => project(focal, view), [focal, view])

  return (
    <svg
      aria-hidden="true"
      viewBox={`0 0 ${size} ${size}`}
      width="100%"
      height="100%"
      className={className}
      style={{ overflow: 'visible' }}
    >
      <defs>
        <radialGradient id={`glow-${scene}`} cx="50%" cy="65%" r="60%">
          <stop offset="0%" stopColor={accent} stopOpacity="0.18" />
          <stop offset="100%" stopColor={accent} stopOpacity="0" />
        </radialGradient>
        <filter id={`bloom-${scene}`} x="-40%" y="-40%" width="180%" height="180%">
          <feGaussianBlur stdDeviation="2.4" />
        </filter>
      </defs>

      <ellipse
        cx={focal2.x}
        cy={size - 20}
        rx={size * 0.42}
        ry={size * 0.08}
        fill={`url(#glow-${scene})`}
      />

      {!reduced && (
        <g filter={`url(#bloom-${scene})`} opacity={0.5}>
          {mesh.edges.map(([a, b], i) => (
            <line
              key={`g-${i}`}
              x1={projected[a]!.x}
              y1={projected[a]!.y}
              x2={projected[b]!.x}
              y2={projected[b]!.y}
              stroke={accent}
              strokeWidth={1}
              strokeLinecap="round"
            />
          ))}
        </g>
      )}

      {mesh.edges.map(([a, b], i) => (
        <motion.line
          key={i}
          x1={projected[a]!.x}
          y1={projected[a]!.y}
          x2={projected[b]!.x}
          y2={projected[b]!.y}
          stroke={i % 7 === 0 ? accent : '#8a8a94'}
          strokeWidth={1}
          strokeLinecap="round"
          initial={{ pathLength: 0, opacity: 0 }}
          whileInView={{ pathLength: 1, opacity: i % 7 === 0 ? 0.9 : 0.55 }}
          viewport={{ once: true, margin: '-80px' }}
          transition={{
            duration: 0.9,
            delay: reduced ? 0 : (i % 24) * 0.012,
            ease: [0.22, 1, 0.36, 1],
          }}
        />
      ))}

      {projected.map((p, i) => (
        <circle key={`v-${i}`} cx={p.x} cy={p.y} r={1.3} fill="#c9c9d1" opacity={0.4} />
      ))}

      {!reduced && (
        <motion.circle
          cx={focal2.x}
          cy={focal2.y}
          r={3.4}
          fill={accent}
          animate={{ r: [3.4, 5.4, 3.4], opacity: [0.9, 0.5, 0.9] }}
          transition={{ duration: 2.4, repeat: Infinity, ease: 'easeInOut' }}
        />
      )}
      <circle cx={focal2.x} cy={focal2.y} r={2.2} fill={accent} />
    </svg>
  )
}
EOF

# ─── VELOCITY: ISOMETRIC CAROUSEL ────────────────────────────────────────────
cat > src/components/velocity/isometric-carousel.tsx << 'EOF'
'use client'

import { useCallback, useEffect, useRef, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import { CAROUSEL_SLIDES } from '@/data/carousel'
import { IsometricIllustration } from './isometric-illustration'
import { spring } from '@/components/shared/motion-variants'
import { useModeStore } from '@/store/use-mode-store'
import { useReducedMotion } from '@/hooks/use-reduced-motion'
import { cn } from '@/lib/utils'

export function IsometricCarousel() {
  const reduced = useReducedMotion()
  const engineer = useModeStore((s) => s.mode === 'engineer')
  const [index, setIndex] = useState(0)
  const scrollerRef = useRef<HTMLDivElement>(null)
  const slideRefs = useRef<Array<HTMLElement | null>>([])

  const scrollTo = useCallback(
    (i: number) => {
      const clamped = Math.max(0, Math.min(CAROUSEL_SLIDES.length - 1, i))
      const target = slideRefs.current[clamped]
      if (!target) return
      target.scrollIntoView({
        behavior: reduced ? 'auto' : 'smooth',
        inline: 'start',
        block: 'nearest',
      })
      setIndex(clamped)
    },
    [reduced],
  )

  useEffect(() => {
    const el = scrollerRef.current
    if (!el) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'ArrowRight') {
        e.preventDefault()
        scrollTo(index + 1)
      }
      if (e.key === 'ArrowLeft') {
        e.preventDefault()
        scrollTo(index - 1)
      }
    }
    el.addEventListener('keydown', onKey)
    return () => el.removeEventListener('keydown', onKey)
  }, [index, scrollTo])

  useEffect(() => {
    const el = scrollerRef.current
    if (!el) return
    const io = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting && entry.intersectionRatio > 0.6) {
            const i = slideRefs.current.findIndex((n) => n === entry.target)
            if (i >= 0) setIndex(i)
          }
        }
      },
      { root: el, threshold: [0.6] },
    )
    slideRefs.current.forEach((n) => n && io.observe(n))
    return () => io.disconnect()
  }, [])

  const slide = CAROUSEL_SLIDES[index]!

  return (
    <section id="platform" className="border-b border-border">
      <div className="mx-auto max-w-7xl px-4 py-20 md:px-6">
        <header className="mb-8 flex flex-wrap items-end justify-between gap-4">
          <div className="max-w-xl">
            <p className="font-mono text-[11px] uppercase tracking-[0.2em] text-orange">
              Platform · Five scenes
            </p>
            <h2 className="mt-3 text-3xl font-semibold tracking-tight md:text-4xl">
              One runtime. Five things it does well.
            </h2>
          </div>

          <div className="flex items-center gap-2" role="tablist" aria-label="Carousel navigation">
            <button
              onClick={() => scrollTo(index - 1)}
              disabled={index === 0}
              aria-label="Previous slide"
              className={cn(
                'grid h-9 w-9 place-items-center rounded-full border border-border transition-colors',
                index === 0
                  ? 'cursor-not-allowed text-[#3a3a42]'
                  : 'text-[#c9c9d1] hover:border-[#2a2a32] hover:text-fg',
              )}
            >
              <ChevronLeft className="h-4 w-4" />
            </button>
            <span className="font-mono text-[10px] tabular-nums text-muted">
              {String(index + 1).padStart(2, '0')} / {String(CAROUSEL_SLIDES.length).padStart(2, '0')}
            </span>
            <button
              onClick={() => scrollTo(index + 1)}
              disabled={index === CAROUSEL_SLIDES.length - 1}
              aria-label="Next slide"
              className={cn(
                'grid h-9 w-9 place-items-center rounded-full border border-border transition-colors',
                index === CAROUSEL_SLIDES.length - 1
                  ? 'cursor-not-allowed text-[#3a3a42]'
                  : 'text-[#c9c9d1] hover:border-[#2a2a32] hover:text-fg',
              )}
            >
              <ChevronRight className="h-4 w-4" />
            </button>
          </div>
        </header>

        <div
          ref={scrollerRef}
          tabIndex={0}
          role="region"
          aria-roledescription="carousel"
          aria-label="Platform capabilities"
          className="flex snap-x snap-mandatory gap-4 overflow-x-auto pb-4 outline-none [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
        >
          {CAROUSEL_SLIDES.map((s, i) => (
            <article
              key={s.id}
              ref={(el) => {
                slideRefs.current[i] = el
              }}
              role="group"
              aria-roledescription="slide"
              aria-label={`${i + 1} of ${CAROUSEL_SLIDES.length}: ${s.title}`}
              className={cn(
                'relative flex min-h-[440px] w-[86vw] shrink-0 snap-start flex-col overflow-hidden rounded-2xl border border-border bg-surface p-6 md:w-[560px] md:p-8',
                'transition-colors',
                index === i ? 'border-[#2a2a32]' : 'opacity-70',
              )}
            >
              <span
                className="absolute right-5 top-5 h-1.5 w-1.5 rounded-full"
                style={{ background: s.accent, boxShadow: `0 0 12px ${s.accent}80` }}
              />

              <span className="font-mono text-[10px] uppercase tracking-[0.2em] text-muted">
                {s.eyebrow}
              </span>

              <h3 className="mt-3 text-2xl font-medium tracking-tight">{s.title}</h3>
              <p className="mt-3 max-w-md text-sm leading-relaxed text-muted">{s.body}</p>

              <div className="relative mx-auto my-4 h-[220px] w-[220px] md:h-[240px] md:w-[240px]">
                <IsometricIllustration scene={s.scene} accent={s.accent} size={240} />
              </div>

              <ul className="mt-auto grid gap-1.5 font-mono text-[11px] text-muted">
                {s.bullets.map((b) => (
                  <li key={b} className="flex items-center gap-2">
                    <span className="h-1 w-1 rounded-full" style={{ background: s.accent }} />
                    {b}
                  </li>
                ))}
              </ul>

              <AnimatePresence>
                {engineer && (
                  <motion.pre
                    initial={{ opacity: 0, height: 0 }}
                    animate={{ opacity: 1, height: 'auto' }}
                    exit={{ opacity: 0, height: 0 }}
                    transition={spring}
                    className="mt-4 overflow-x-auto rounded-md border border-border bg-bg p-3 font-mono text-[10px] leading-relaxed text-cyan"
                  >
                    {s.code}
                  </motion.pre>
                )}
              </AnimatePresence>
            </article>
          ))}
        </div>

        <div className="mt-4 flex items-center justify-center gap-1.5" aria-hidden="true">
          {CAROUSEL_SLIDES.map((_, i) => (
            <button
              key={i}
              onClick={() => scrollTo(i)}
              tabIndex={-1}
              className="group h-1.5 rounded-full transition-all"
              style={{
                width: index === i ? 24 : 6,
                background: index === i ? slide.accent : '#2a2a32',
              }}
            />
          ))}
        </div>
      </div>
    </section>
  )
}
EOF

# ─── ONTOLOGY: NODE ──────────────────────────────────────────────────────────
cat > src/components/ontology/ontology-node.tsx << 'EOF'
'use client'

import { motion } from 'framer-motion'
import type { OntologyNode } from '@/types/ontology'
import { KIND_COLOR } from '@/data/ontology'
import { cn } from '@/lib/utils'

interface Props {
  node: OntologyNode
  x: number
  y: number
  active: boolean
  dimmed: boolean
  onSelect: () => void
  onHover: (v: boolean) => void
}

const R = 26

export function OntologyNodeShape({ node, x, y, active, dimmed, onSelect, onHover }: Props) {
  const color = KIND_COLOR[node.kind]
  const labelY = y + R + 16

  return (
    <g
      role="button"
      tabIndex={0}
      aria-label={`${node.label}. ${node.summary}`}
      aria-pressed={active}
      onClick={onSelect}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault()
          onSelect()
        }
      }}
      onMouseEnter={() => onHover(true)}
      onMouseLeave={() => onHover(false)}
      onFocus={() => onHover(true)}
      onBlur={() => onHover(false)}
      className={cn('cursor-pointer outline-none', dimmed && 'opacity-30')}
      style={{ transition: 'opacity 220ms ease' }}
    >
      <circle
        cx={x}
        cy={y}
        r={R + 6}
        fill="none"
        stroke={active ? color : 'transparent'}
        strokeWidth={1}
        opacity={0.5}
      />

      <motion.circle
        cx={x}
        cy={y}
        r={R}
        fill={color}
        opacity={active ? 0.14 : 0.06}
        animate={{ r: active ? R + 4 : R }}
        transition={{ type: 'spring', stiffness: 400, damping: 30 }}
      />

      <circle cx={x} cy={y} r={R} fill="#0b0b0e" stroke={color} strokeWidth={1.4} />

      <KindGlyph kind={node.kind} x={x} y={y} color={color} />

      <text
        x={x}
        y={labelY}
        textAnchor="middle"
        className="select-none font-mono"
        fill={active ? '#f5f5f7' : '#c9c9d1'}
        fontSize={11}
        style={{ letterSpacing: '0.04em' }}
      >
        {node.short}
      </text>

      {active && (
        <motion.circle
          cx={x}
          cy={y}
          r={R}
          fill="none"
          stroke={color}
          strokeWidth={1}
          initial={{ opacity: 0.6, scale: 1 }}
          animate={{ opacity: 0, scale: 1.6 }}
          transition={{ duration: 1.6, repeat: Infinity, ease: 'easeOut' }}
          style={{ transformOrigin: `${x}px ${y}px` }}
        />
      )}
    </g>
  )
}

function KindGlyph({ kind, x, y, color }: { kind: OntologyNode['kind']; x: number; y: number; color: string }) {
  const s = 8
  switch (kind) {
    case 'source':
      return (
        <g stroke={color} strokeWidth={1.2} fill="none">
          <ellipse cx={x} cy={y - s * 0.6} rx={s * 0.9} ry={s * 0.35} />
          <path d={`M ${x - s * 0.9} ${y - s * 0.6} v ${s} a ${s * 0.9} ${s * 0.35} 0 0 0 ${s * 1.8} 0 v ${-s}`} />
        </g>
      )
    case 'ingest':
      return (
        <g stroke={color} strokeWidth={1.2} fill="none">
          <path d={`M ${x - s} ${y} h ${s * 1.1}`} />
          <path d={`M ${x - s * 0.4} ${y - 3} l 3 3 l -3 3`} />
          <path d={`M ${x + s * 0.4} ${y - s * 0.7} v ${s * 1.4}`} />
        </g>
      )
    case 'compute':
      return (
        <g stroke={color} strokeWidth={1.2} fill="none">
          <rect x={x - 4} y={y - 4} width={8} height={8} rx={1.5} />
          <path d={`M ${x - 7} ${y} h 3 M ${x + 4} ${y} h 3 M ${x} ${y - 7} v 3 M ${x} ${y + 4} v 3`} />
        </g>
      )
    case 'api':
      return (
        <text x={x} y={y + 4} textAnchor="middle" fill={color} fontSize={14} fontFamily="monospace">
          {'{ }'}
        </text>
      )
    case 'render':
      return (
        <g stroke={color} strokeWidth={1.2} fill="none">
          <rect x={x - 6} y={y - 5} width={12} height={10} rx={1.5} />
          <path d={`M ${x - 6} ${y - 2} h 12`} />
        </g>
      )
    case 'observe':
      return (
        <path
          d={`M ${x - 7} ${y} l 2 -3 l 2 6 l 2 -8 l 2 8 l 2 -3`}
          stroke={color}
          strokeWidth={1.2}
          fill="none"
        />
      )
  }
}
EOF

# ─── ONTOLOGY: EDGE ──────────────────────────────────────────────────────────
cat > src/components/ontology/ontology-edge.tsx << 'EOF'
'use client'

import { useEffect, useMemo, useRef } from 'react'
import type { BezierPoints } from '@/types/ontology'
import { bezierPath, bezierPoint } from '@/lib/bezier'

interface Props {
  id: string
  bezier: BezierPoints
  color: string
  load: number
  active: boolean
  dimmed: boolean
  frozen: boolean
}

const BASE_SPEED = 0.22

export function OntologyEdge({ id, bezier, color, load, active, dimmed, frozen }: Props) {
  const particles = useMemo(() => {
    const n = 2 + Math.round(load * 2)
    return Array.from({ length: n }, (_, i) => i)
  }, [load])

  const refs = useRef<Array<SVGCircleElement | null>>([])
  const path = useMemo(() => bezierPath(bezier), [bezier])

  useEffect(() => {
    if (frozen) return
    let raf = 0
    const t0 = performance.now()
    const speed = BASE_SPEED * (0.7 + load * 0.8)

    const loop = (now: number) => {
      const elapsed = (now - t0) / 1000
      for (let i = 0; i < particles.length; i++) {
        const el = refs.current[i]
        if (!el) continue
        const offset = (((elapsed * speed + i / particles.length) % 1) + 1) % 1
        const p = bezierPoint(offset, bezier)
        const alpha = Math.sin(offset * Math.PI)
        el.setAttribute('cx', String(p.x))
        el.setAttribute('cy', String(p.y))
        el.setAttribute('opacity', String(alpha * (active ? 1 : 0.7)))
      }
      raf = requestAnimationFrame(loop)
    }
    raf = requestAnimationFrame(loop)
    return () => cancelAnimationFrame(raf)
  }, [bezier, particles.length, load, active, frozen])

  const strokeW = 0.9 + load * 1.2
  const baseOpacity = dimmed ? 0.08 : active ? 0.95 : 0.32

  return (
    <g aria-hidden="true" style={{ transition: 'opacity 220ms ease' }} opacity={dimmed ? 0.25 : 1}>
      {active && (
        <path
          d={path}
          stroke={color}
          strokeWidth={strokeW + 4}
          strokeLinecap="round"
          fill="none"
          opacity={0.14}
          style={{ filter: 'blur(3px)' }}
        />
      )}

      <path
        id={`edge-${id}`}
        d={path}
        stroke={color}
        strokeWidth={strokeW}
        strokeLinecap="round"
        fill="none"
        opacity={baseOpacity}
        strokeDasharray={active ? undefined : '4 5'}
      />

      {active && <Chevron bezier={bezier} color={color} />}

      {particles.map((i) => (
        <circle
          key={i}
          ref={(el) => {
            refs.current[i] = el
          }}
          r={active ? 2.4 : 1.8}
          fill={color}
          opacity={0}
        />
      ))}
    </g>
  )
}

function Chevron({ bezier, color }: { bezier: BezierPoints; color: string }) {
  const p = bezierPoint(0.5, bezier)
  const q = bezierPoint(0.52, bezier)
  const angle = Math.atan2(q.y - p.y, q.x - p.x) * (180 / Math.PI)
  return (
    <g transform={`translate(${p.x} ${p.y}) rotate(${angle})`}>
      <path d="M -4 -3 L 0 0 L -4 3" stroke={color} strokeWidth={1.4} fill="none" strokeLinecap="round" />
    </g>
  )
}
EOF

# ─── ONTOLOGY: SIDE PANEL ────────────────────────────────────────────────────
cat > src/components/ontology/ontology-side-panel.tsx << 'EOF'
'use client'

import { AnimatePresence, motion } from 'framer-motion'
import type { OntologyNode } from '@/types/ontology'
import { KIND_COLOR } from '@/data/ontology'
import { useModeStore } from '@/store/use-mode-store'
import { spring } from '@/components/shared/motion-variants'

interface Props {
  node: OntologyNode | null
  onClose: () => void
}

export function OntologySidePanel({ node, onClose }: Props) {
  const engineer = useModeStore((s) => s.mode === 'engineer')

  return (
    <AnimatePresence>
      {node && (
        <motion.aside
          key={node.id}
          role="complementary"
          aria-labelledby={`ont-${node.id}-title`}
          initial={{ opacity: 0, x: 24 }}
          animate={{ opacity: 1, x: 0 }}
          exit={{ opacity: 0, x: 24 }}
          transition={spring}
          className="pointer-events-auto absolute right-3 top-3 z-10 w-[min(320px,calc(100%-24px))] overflow-hidden rounded-xl border border-border bg-surface/95 backdrop-blur-md"
        >
          <header className="flex items-start justify-between gap-3 border-b border-border p-4">
            <div className="min-w-0">
              <div className="flex items-center gap-2">
                <span
                  className="h-1.5 w-1.5 shrink-0 rounded-full"
                  style={{ background: KIND_COLOR[node.kind] }}
                />
                <span className="font-mono text-[10px] uppercase tracking-widest text-muted">
                  {node.kind} · {node.id}
                </span>
              </div>
              <h4
                id={`ont-${node.id}-title`}
                className="mt-1 truncate text-sm font-medium text-fg"
              >
                {node.label}
              </h4>
            </div>
            <button
              onClick={onClose}
              aria-label="Close details"
              className="rounded-md border border-border px-1.5 py-0.5 font-mono text-[10px] text-muted transition-colors hover:text-fg"
            >
              ESC
            </button>
          </header>

          <div className="p-4">
            <p className="text-xs leading-relaxed text-[#a0a0ab]">{node.summary}</p>

            {engineer && (
              <dl className="mt-4 grid grid-cols-[auto_1fr] gap-x-3 gap-y-1.5 border-t border-border pt-4 font-mono text-[10px]">
                {Object.entries(node.spec).map(([k, v]) => (
                  <div key={k} className="contents">
                    <dt className="text-dim uppercase tracking-widest">{k}</dt>
                    <dd className="truncate text-right text-cyan tabular-nums">{v}</dd>
                  </div>
                ))}
              </dl>
            )}

            {!engineer && (
              <p className="mt-3 font-mono text-[10px] uppercase tracking-widest text-dim">
                Switch to Engineer mode for raw spec ↴
              </p>
            )}
          </div>
        </motion.aside>
      )}
    </AnimatePresence>
  )
}
EOF

# ─── ONTOLOGY: GRAPH ─────────────────────────────────────────────────────────
cat > src/components/ontology/ontology-graph.tsx << 'EOF'
'use client'

import { useMemo, useState } from 'react'
import { useElementSize } from '@/hooks/use-element-size'
import { useMediaQuery } from '@/hooks/use-media-query'
import { useReducedMotion } from '@/hooks/use-reduced-motion'
import { ONTOLOGY_NODES, ONTOLOGY_EDGES, KIND_COLOR } from '@/data/ontology'
import { layoutArc, edgeControlPoints } from '@/lib/ontology-layout'
import { OntologyNodeShape } from './ontology-node'
import { OntologyEdge } from './ontology-edge'
import { OntologySidePanel } from './ontology-side-panel'

const SVG_H = 420

export function OntologyGraph() {
  const [wrapRef, { width }] = useElementSize<HTMLDivElement>()
  const vertical = useMediaQuery('(max-width: 767px)')
  const reduced = useReducedMotion()

  const [selected, setSelected] = useState<string | null>(null)
  const [hovered, setHovered] = useState<string | null>(null)

  const focus = hovered ?? selected

  const positions = useMemo(
    () =>
      layoutArc(ONTOLOGY_NODES, ONTOLOGY_EDGES, {
        width: width || 900,
        height: SVG_H,
        vertical,
      }),
    [width, vertical],
  )

  const edges = useMemo(() => {
    return ONTOLOGY_EDGES.map((e, i) => {
      const from = positions.get(e.from)
      const to = positions.get(e.to)
      if (!from || !to) return null
      return {
        key: `${e.from}->${e.to}-${i}`,
        data: e,
        bezier: edgeControlPoints(from, to, vertical),
      }
    }).filter(Boolean) as Array<{
      key: string
      data: (typeof ONTOLOGY_EDGES)[number]
      bezier: ReturnType<typeof edgeControlPoints>
    }>
  }, [positions, vertical])

  const incident = useMemo(() => {
    if (!focus) return { nodes: new Set<string>(), edges: new Set<string>() }
    const nodes = new Set<string>([focus])
    const edges = new Set<string>()
    for (const e of edges0(ONTOLOGY_EDGES, positions, vertical)) {
      if (e.data.from === focus || e.data.to === focus) {
        nodes.add(e.data.from)
        nodes.add(e.data.to)
        edges.add(e.key)
      }
    }
    return { nodes, edges }
  }, [focus, positions, vertical])

  const selectedNode = selected
    ? ONTOLOGY_NODES.find((n) => n.id === selected) ?? null
    : null

  const maxLayer = Math.max(...Array.from(positions.values()).map((p) => p.layer))

  return (
    <div className="rounded-2xl border border-border bg-bg p-6">
      <div className="mb-4 flex items-center justify-between gap-3">
        <div className="flex items-center gap-3 font-mono text-[10px] uppercase tracking-widest text-muted">
          <span className="flex items-center gap-1.5">
            <span className="h-1.5 w-1.5 rounded-full bg-cyan" />
            NODES {ONTOLOGY_NODES.length}
          </span>
          <span className="hidden sm:inline">EDGES {ONTOLOGY_EDGES.length}</span>
          <span className="hidden md:inline">TOPO_DEPTH {maxLayer + 1}</span>
        </div>
        {selected && (
          <button
            onClick={() => setSelected(null)}
            className="rounded-full border border-border px-2.5 py-1 font-mono text-[10px] uppercase tracking-widest text-muted transition-colors hover:border-[#2a2a32] hover:text-fg"
          >
            Clear ✕
          </button>
        )}
      </div>

      <div ref={wrapRef} className="relative w-full">
        <svg
          role="img"
          aria-label="System ontology graph"
          viewBox={`0 0 ${width || 900} ${SVG_H}`}
          width="100%"
          height={SVG_H}
          preserveAspectRatio="xMidYMid meet"
          className="block"
        >
          <defs>
            <radialGradient id="graph-bg" cx="50%" cy="65%" r="65%">
              <stop offset="0%" stopColor="#35e6f2" stopOpacity="0.05" />
              <stop offset="100%" stopColor="#35e6f2" stopOpacity="0" />
            </radialGradient>
          </defs>

          <rect width="100%" height="100%" fill="url(#graph-bg)" />

          {edges.map(({ key, data, bezier }) => {
            const fromNode = ONTOLOGY_NODES.find((n) => n.id === data.from)!
            return (
              <OntologyEdge
                key={key}
                id={key}
                bezier={bezier}
                color={KIND_COLOR[fromNode.kind]}
                load={data.load}
                active={incident.edges.has(key)}
                dimmed={focus !== null && !incident.edges.has(key)}
                frozen={reduced}
              />
            )
          })}

          {ONTOLOGY_NODES.map((n) => {
            const p = positions.get(n.id)
            if (!p) return null
            const isActive = focus === n.id || incident.nodes.has(n.id)
            const isDimmed = focus !== null && !incident.nodes.has(n.id) && focus !== n.id
            return (
              <OntologyNodeShape
                key={n.id}
                node={n}
                x={p.x}
                y={p.y}
                active={selected === n.id || hovered === n.id}
                dimmed={isDimmed}
                onSelect={() => setSelected((s) => (s === n.id ? null : n.id))}
                onHover={(v) => setHovered(v ? n.id : null)}
              />
            )
          })}
        </svg>

        <OntologySidePanel node={selectedNode} onClose={() => setSelected(null)} />
      </div>
    </div>
  )
}

// Helper — rebuilds the same edges array shape used in the render loop.
function edges0(
  raw: typeof ONTOLOGY_EDGES,
  positions: Map<string, { x: number; y: number; layer: number }>,
  vertical: boolean,
) {
  return raw
    .map((e, i) => {
      const from = positions.get(e.from)
      const to = positions.get(e.to)
      if (!from || !to) return null
      return {
        key: `${e.from}->${e.to}-${i}`,
        data: e,
        bezier: edgeControlPoints(from, to, vertical),
      }
    })
    .filter(Boolean) as Array<{
    key: string
    data: (typeof ONTOLOGY_EDGES)[number]
    bezier: ReturnType<typeof edgeControlPoints>
  }>
}
EOF

# ─── ONTOLOGY: PIPELINE LINEAGE ──────────────────────────────────────────────
cat > src/components/ontology/pipeline-lineage.tsx << 'EOF'
'use client'

import { useEffect, useMemo, useRef, useState } from 'react'
import { motion } from 'framer-motion'
import { Play, RotateCcw } from 'lucide-react'
import { LEGACY_PIPELINE, AUREXIS_PIPELINE, type PipelineSpec } from '@/data/pipeline'
import { useReducedMotion } from '@/hooks/use-reduced-motion'
import { cn } from '@/lib/utils'

const SLOWMO = 2.6
const MIN_VISIBLE_MS = 260
const HOLD_MS = 1400

const SPEEDUP = (LEGACY_PIPELINE.totalMs / AUREXIS_PIPELINE.totalMs).toFixed(1)

export function PipelineLineage() {
  const reduced = useReducedMotion()
  const [runId, setRunId] = useState(0)
  const [playing, setPlaying] = useState(false)
  const timerRef = useRef<number>()

  const legacyWall = useMemo(() => LEGACY_PIPELINE.totalMs * SLOWMO, [])
  const aurexisWall = useMemo(
    () => Math.max(AUREXIS_PIPELINE.totalMs * SLOWMO, MIN_VISIBLE_MS),
    [],
  )

  useEffect(() => {
    if (!playing) return
    const maxWall = Math.max(legacyWall, aurexisWall) + HOLD_MS
    timerRef.current = window.setTimeout(() => {
      setPlaying(false)
    }, maxWall)
    return () => {
      if (timerRef.current) clearTimeout(timerRef.current)
    }
  }, [playing, legacyWall, aurexisWall])

  const start = () => {
    setRunId((n) => n + 1)
    setPlaying(true)
  }
  const reset = () => {
    setPlaying(false)
    setRunId((n) => n + 1)
  }

  return (
    <div className="rounded-2xl border border-border bg-bg p-6">
      <header className="mb-5 flex flex-wrap items-center justify-between gap-3">
        <div>
          <div className="flex items-center gap-2 font-mono text-[10px] uppercase tracking-widest text-muted">
            <span className="h-1.5 w-1.5 rounded-full bg-orange" />
            Pipeline Lineage · Trace Compare
          </div>
          <h3 className="mt-1.5 text-lg font-medium tracking-tight">
            Same payload, two execution paths.
          </h3>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={start}
            disabled={playing}
            data-analytics="pipeline-run"
            className={cn(
              'inline-flex items-center gap-2 rounded-full border border-border bg-surface px-3 py-1.5 text-xs transition-colors',
              playing
                ? 'cursor-not-allowed text-dim'
                : 'text-fg hover:border-cyan/60',
            )}
          >
            <Play className="h-3 w-3" />
            {playing ? 'Running…' : 'Run trace'}
          </button>
          <button
            onClick={reset}
            aria-label="Reset trace"
            className="rounded-full border border-border p-1.5 text-muted transition-colors hover:text-fg"
          >
            <RotateCcw className="h-3.5 w-3.5" />
          </button>
        </div>
      </header>

      <div className="grid gap-5 lg:grid-cols-2">
        <PipelineColumn
          spec={LEGACY_PIPELINE}
          runId={runId}
          playing={playing}
          wallMs={legacyWall}
          reduced={reduced}
        />
        <PipelineColumn
          spec={AUREXIS_PIPELINE}
          runId={runId}
          playing={playing}
          wallMs={aurexisWall}
          reduced={reduced}
        />
      </div>

      <footer className="mt-5 flex flex-wrap items-center gap-x-6 gap-y-2 border-t border-border pt-4 font-mono text-[10px] uppercase tracking-widest text-dim">
        <span>
          LEGACY_TOTAL&nbsp;
          <span className="text-[#ef4444] tabular-nums">{LEGACY_PIPELINE.totalMs}ms</span>
        </span>
        <span>
          AUREXIS_TOTAL&nbsp;
          <span className="text-cyan tabular-nums">{AUREXIS_PIPELINE.totalMs}ms</span>
        </span>
        <span>
          SPEEDUP&nbsp;<span className="text-[#22c55e] tabular-nums">{SPEEDUP}×</span>
        </span>
        <span className="ml-auto">SLOWMO&nbsp;{SLOWMO}×</span>
      </footer>
    </div>
  )
}

interface ColumnProps {
  spec: PipelineSpec
  runId: number
  playing: boolean
  wallMs: number
  reduced: boolean
}

function PipelineColumn({ spec, runId, playing, wallMs, reduced }: ColumnProps) {
  return (
    <div className="rounded-xl border border-border bg-surface p-4">
      <header className="mb-3 flex items-center justify-between">
        <div>
          <div
            className="font-mono text-[10px] uppercase tracking-widest"
            style={{ color: spec.accent }}
          >
            {spec.label}
          </div>
          <div className="mt-0.5 font-mono text-[10px] text-dim">{spec.sublabel}</div>
        </div>
        <div className="font-mono text-xs tabular-nums" style={{ color: spec.accent }}>
          {spec.totalMs}ms
        </div>
      </header>

      <div className="relative space-y-1.5">
        {spec.phases.map((ph, i) => (
          <PhaseRail
            key={`${runId}-${ph.id}`}
            phase={ph}
            totalMs={spec.totalMs}
            wallMs={wallMs}
            playing={playing}
            reduced={reduced}
            delayIndex={i}
          />
        ))}
      </div>
    </div>
  )
}

interface PhaseRailProps {
  phase: PipelineSpec['phases'][number]
  totalMs: number
  wallMs: number
  playing: boolean
  reduced: boolean
  delayIndex: number
}

function PhaseRail({ phase, totalMs, wallMs, playing, reduced, delayIndex }: PhaseRailProps) {
  const leftPct = (phase.startMs / totalMs) * 100
  const widthPct = (phase.durationMs / totalMs) * 100

  const statusColor =
    phase.status === 'ok' ? '#22c55e' : phase.status === 'warn' ? '#f5a623' : '#ef4444'

  return (
    <div className="grid grid-cols-[128px_1fr_54px] items-center gap-3">
      <span className="truncate font-mono text-[10px] text-muted">{phase.label}</span>

      <div className="relative h-3 rounded-sm bg-bg">
        <span className="absolute inset-0 rounded-sm ring-1 ring-inset ring-[#141418]" />

        <motion.span
          key={`bar-${delayIndex}`}
          initial={{ width: 0 }}
          animate={{ width: playing ? `${widthPct}%` : 0 }}
          transition={{
            duration: playing && !reduced ? wallMs / 1000 : 0,
            ease: [0.22, 1, 0.36, 1],
          }}
          className="absolute inset-y-0 left-0 rounded-sm"
          style={{
            marginLeft: `${leftPct}%`,
            background: `linear-gradient(90deg, ${statusColor}22, ${statusColor})`,
            maxWidth: `${100 - leftPct}%`,
          }}
        />

        {phase.startMs > 0 && (
          <span className="absolute inset-y-0 w-px bg-border" style={{ left: `${leftPct}%` }} />
        )}
      </div>

      <span
        className="text-right font-mono text-[10px] tabular-nums"
        style={{ color: statusColor }}
      >
        {phase.durationMs}ms
      </span>
    </div>
  )
}
EOF

# ─── ONTOLOGY: SECTION ───────────────────────────────────────────────────────
cat > src/components/ontology/ontology-section.tsx << 'EOF'
'use client'

import { motion } from 'framer-motion'
import { OntologyGraph } from './ontology-graph'
import { PipelineLineage } from './pipeline-lineage'
import { stagger, fadeUp } from '@/components/shared/motion-variants'

export function OntologySection() {
  return (
    <section id="ontology" className="border-b border-border">
      <div className="mx-auto max-w-7xl px-4 py-20 md:px-6">
        <motion.header
          initial="hidden"
          whileInView="show"
          viewport={{ once: true, margin: '-80px' }}
          variants={stagger(0.06)}
          className="mb-10 max-w-3xl"
        >
          <motion.p
            variants={fadeUp}
            className="inline-flex items-center gap-2 rounded-full border border-border bg-surface px-3 py-1 font-mono text-[10px] uppercase tracking-[0.2em] text-orange"
          >
            <span className="h-1.5 w-1.5 rounded-full bg-orange" />
            System Ontology &amp; Lineage
          </motion.p>

          <motion.h2
            variants={fadeUp}
            className="mt-4 text-balance text-3xl font-semibold leading-tight tracking-tight md:text-4xl"
          >
            Interactive architecture mapping and execution lineage.
          </motion.h2>

          <motion.p
            variants={fadeUp}
            className="mt-3 max-w-2xl text-sm leading-relaxed text-[#a0a0ab] md:text-base"
          >
            Explore how Aurexis decouples legacy monolithic infrastructure into dynamic,
            high-speed edge API nodes.
          </motion.p>
        </motion.header>

        <div className="grid gap-6">
          <OntologyGraph />
          <PipelineLineage />
        </div>
      </div>
    </section>
  )
}
EOF

# ─── PROOF: BEFORE/AFTER SLIDER ──────────────────────────────────────────────
cat > src/components/proof/before-after-slider.tsx << 'EOF'
'use client'

import { useCallback, useEffect, useRef, useState } from 'react'
import { useReducedMotion } from '@/hooks/use-reduced-motion'
import { LedReadout } from '@/components/industrial/led-readout'

const SNAP = [0, 25, 50, 75, 100]

export function BeforeAfterSlider() {
  const reduced = useReducedMotion()
  const wrapRef = useRef<HTMLDivElement>(null)
  const [pos, setPos] = useState(50)
  const targetRef = useRef(50)
  const rafRef = useRef<number>()
  const [dragging, setDragging] = useState(false)

  const clamp = (v: number) => Math.max(0, Math.min(100, v))

  const update = useCallback((clientX: number) => {
    const el = wrapRef.current
    if (!el) return
    const r = el.getBoundingClientRect()
    const raw = ((clientX - r.left) / r.width) * 100
    targetRef.current = clamp(raw)
  }, [])

  useEffect(() => {
    let last = performance.now()
    const loop = (now: number) => {
      const dt = Math.min(0.05, (now - last) / 1000)
      last = now
      const t = targetRef.current
      const k = reduced ? 1 : 1 - Math.exp(-14 * dt * Math.PI * 2 * 0.08)
      setPos((p) => p + (t - p) * Math.min(1, k))
      rafRef.current = requestAnimationFrame(loop)
    }
    rafRef.current = requestAnimationFrame(loop)
    return () => {
      if (rafRef.current) cancelAnimationFrame(rafRef.current)
    }
  }, [reduced])

  const onDown = (e: React.PointerEvent) => {
    setDragging(true)
    ;(e.target as Element).setPointerCapture?.(e.pointerId)
    update(e.clientX)
  }
  const onMove = (e: React.PointerEvent) => {
    if (dragging) update(e.clientX)
  }
  const onUp = (e: React.PointerEvent) => {
    setDragging(false)
    ;(e.target as Element).releasePointerCapture?.(e.pointerId)
    const nearest = SNAP.reduce((a, b) =>
      Math.abs(b - targetRef.current) < Math.abs(a - targetRef.current) ? b : a,
    )
    targetRef.current = nearest
  }

  const onKey = (e: React.KeyboardEvent) => {
    if (e.key === 'ArrowLeft') {
      e.preventDefault()
      targetRef.current = clamp(targetRef.current - 5)
    }
    if (e.key === 'ArrowRight') {
      e.preventDefault()
      targetRef.current = clamp(targetRef.current + 5)
    }
    if (e.key === 'Home') {
      e.preventDefault()
      targetRef.current = 0
    }
    if (e.key === 'End') {
      e.preventDefault()
      targetRef.current = 100
    }
  }

  return (
    <div className="rounded-2xl border border-border bg-bg p-5">
      <header className="mb-4 flex items-center justify-between gap-3">
        <div>
          <div className="font-mono text-[10px] uppercase tracking-widest text-muted">
            DRAG · COMPARE
          </div>
          <h3 className="mt-1 text-lg font-medium tracking-tight">Legacy vs. Aurexis</h3>
        </div>
        <div className="hidden md:block">
          <LedReadout value={`${Math.round(pos)}%`} label="SPLIT" px={2} />
        </div>
      </header>

      <div
        ref={wrapRef}
        className="relative h-[280px] select-none overflow-hidden rounded-xl border border-border bg-[#040406] touch-none"
      >
        <Pane variant="after" />

        <div
          className="absolute inset-0"
          style={{ clipPath: `inset(0 ${100 - pos}% 0 0)` }}
        >
          <Pane variant="before" />
        </div>

        <div
          className="absolute inset-y-0 z-20 w-px cursor-ew-resize bg-cyan"
          style={{ left: `${pos}%` }}
          onPointerDown={onDown}
          onPointerMove={onMove}
          onPointerUp={onUp}
          onPointerCancel={onUp}
          role="slider"
          aria-label="Legacy to Aurexis split"
          aria-valuemin={0}
          aria-valuemax={100}
          aria-valuenow={Math.round(pos)}
          tabIndex={0}
          onKeyDown={onKey}
        >
          <div className="absolute left-1/2 top-1/2 grid h-9 w-9 -translate-x-1/2 -translate-y-1/2 place-items-center rounded-full border border-cyan bg-bg shadow-[0_0_18px_rgba(53,230,242,0.5)]">
            <span className="font-mono text-[11px] text-cyan">⇄</span>
          </div>
        </div>

        <span className="pointer-events-none absolute left-3 top-3 z-10 rounded-sm bg-bg/80 px-2 py-0.5 font-mono text-[9px] uppercase tracking-widest text-[#ef4444]">
          Legacy · TTFB 980ms
        </span>
        <span className="pointer-events-none absolute right-3 top-3 z-10 rounded-sm bg-bg/80 px-2 py-0.5 font-mono text-[9px] uppercase tracking-widest text-cyan">
          Aurexis · TTFB 38ms
        </span>
      </div>

      <footer className="mt-3 flex items-center justify-between font-mono text-[10px] uppercase tracking-widest text-dim">
        <span>
          Δ SPEED <span className="text-[#22c55e]">25.8×</span>
        </span>
        <span>SNAP 25%</span>
      </footer>
    </div>
  )
}

function Pane({ variant }: { variant: 'before' | 'after' }) {
  const isAfter = variant === 'after'
  const accent = isAfter ? '#35e6f2' : '#ef4444'
  const rows = 14

  return (
    <div
      className="absolute inset-0"
      style={{
        background: isAfter
          ? 'radial-gradient(120% 90% at 70% 30%, #0b1c20 0%, #040406 60%)'
          : 'radial-gradient(120% 90% at 30% 30%, #1c0d0d 0%, #040406 60%)',
      }}
    >
      <div className="absolute inset-0 p-5">
        <div className="mb-4 h-3 w-24 rounded-sm" style={{ background: `${accent}22` }} />
        <div className="mb-2 h-6 w-3/4 rounded-sm" style={{ background: `${accent}33` }} />
        <div className="mb-6 h-3 w-1/2 rounded-sm" style={{ background: `${accent}1a` }} />
        <div className="grid grid-cols-3 gap-3">
          {Array.from({ length: rows }).map((_, i) => (
            <div
              key={i}
              className="h-3 rounded-sm"
              style={{
                background: `${accent}${isAfter ? '18' : '12'}`,
                width: `${40 + ((i * 37) % 55)}%`,
              }}
            />
          ))}
        </div>
      </div>

      {!isAfter && (
        <div className="absolute bottom-3 left-3 right-3 h-1 overflow-hidden rounded-full bg-border">
          <div className="h-full w-1/3 bg-[#ef4444]" />
        </div>
      )}
    </div>
  )
}
EOF

# ─── PROOF: CODE SAMPLES DATA ────────────────────────────────────────────────
cat > src/data/code-samples.ts << 'EOF'
export interface CodeSample {
  id: string
  title: string
  filename: string
  language: 'tsx' | 'ts'
  source: string
}

export const CODE_SAMPLES: CodeSample[] = [
  {
    id: 'edge-route',
    title: 'Edge API route',
    filename: 'app/api/events/route.ts',
    language: 'ts',
    source: `import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { cache } from '@/lib/cache'

const Query = z.object({
  tenant: z.string().min(1),
  limit: z.coerce.number().int().min(1).max(500).default(50),
})

export const runtime = 'edge'

export async function GET(req: NextRequest) {
  const url = new URL(req.url)
  const parsed = Query.safeParse(Object.fromEntries(url.searchParams))
  if (!parsed.success) {
    return NextResponse.json({ error: parsed.error.flatten() }, { status: 400 })
  }
  const key = \`events:\${parsed.data.tenant}:\${parsed.data.limit}\`
  const hit = await cache.get(key)
  if (hit) return NextResponse.json(hit, { headers: { 'x-cache': 'HIT' } })

  const rows = await db.events.list(parsed.data)
  await cache.set(key, rows, { swr: 300 })
  return NextResponse.json(rows, { headers: { 'x-cache': 'MISS' } })
}`,
  },
  {
    id: 'rsc-stream',
    title: 'Streaming RSC shell',
    filename: 'app/dashboard/page.tsx',
    language: 'tsx',
    source: `import { Suspense } from 'react'
import { Skeleton } from '@/components/ui/skeleton'
import { ActivityFeed } from './activity-feed'
import { Metrics } from './metrics'

export const revalidate = 30

export default function Dashboard() {
  return (
    <main className="grid gap-6 p-6">
      <h1 className="text-2xl font-semibold">Dashboard</h1>

      <Suspense fallback={<Skeleton className="h-40" />}>
        <Metrics />
      </Suspense>

      <Suspense fallback={<Skeleton className="h-64" />}>
        <ActivityFeed />
      </Suspense>
    </main>
  )
}`,
  },
]
EOF

# ─── PROOF: CODE SPLIT VIEW ──────────────────────────────────────────────────
cat > src/components/proof/code-split-view.tsx << 'EOF'
'use client'

import { useState } from 'react'
import { Highlight, themes } from 'prism-react-renderer'
import { motion, AnimatePresence } from 'framer-motion'
import { Copy, Check, Code2, X } from 'lucide-react'
import { CODE_SAMPLES } from '@/data/code-samples'
import { spring } from '@/components/shared/motion-variants'
import { useAudioHaptics } from '@/hooks/use-audio-haptics'

export function CodeSplitView() {
  const haptics = useAudioHaptics()
  const [openId, setOpenId] = useState<string | null>(null)
  const active = CODE_SAMPLES.find((s) => s.id === openId) ?? null

  const open = (id: string) => {
    haptics.click()
    setOpenId(id)
  }
  const close = () => {
    haptics.click()
    setOpenId(null)
  }

  return (
    <section className="border-b border-border">
      <div className="mx-auto max-w-7xl px-4 py-20 md:px-6">
        <header className="mb-10 max-w-2xl">
          <p className="font-mono text-[11px] uppercase tracking-[0.2em] text-orange">
            Inspect Element
          </p>
          <h2 className="mt-3 text-3xl font-semibold tracking-tight md:text-4xl">
            Every claim ships with source.
          </h2>
          <p className="mt-3 text-sm text-[#a0a0ab] md:text-base">
            We don't hide behind slides. Open the file, read the code, ship it yourself.
          </p>
        </header>

        <div className="grid gap-4 md:grid-cols-2">
          {CODE_SAMPLES.map((s) => (
            <motion.button
              key={s.id}
              onClick={() => open(s.id)}
              whileHover={{ y: -2 }}
              transition={spring}
              data-analytics={`inspect-${s.id}`}
              className="group flex items-start gap-4 rounded-xl border border-border bg-surface p-5 text-left transition-colors hover:border-[#2a2a32]"
            >
              <span className="mt-0.5 grid h-8 w-8 shrink-0 place-items-center rounded-md border border-border bg-bg text-cyan">
                <Code2 className="h-4 w-4" />
              </span>
              <span className="min-w-0 flex-1">
                <span className="block text-sm font-medium text-fg">{s.title}</span>
                <span className="mt-1 block font-mono text-[10px] text-dim">{s.filename}</span>
              </span>
              <span className="font-mono text-[10px] uppercase tracking-widest text-cyan opacity-0 transition-opacity group-hover:opacity-100">
                INSPECT ↗
              </span>
            </motion.button>
          ))}
        </div>
      </div>

      <AnimatePresence>
        {active && (
          <motion.div
            role="dialog"
            aria-modal="true"
            aria-labelledby={`inspect-${active.id}-title`}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.14 }}
            className="fixed inset-0 z-50 grid place-items-center bg-bg/80 p-4 backdrop-blur-sm"
            onClick={close}
          >
            <motion.div
              initial={{ opacity: 0, y: 8, scale: 0.98 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: 8, scale: 0.98 }}
              transition={spring}
              onClick={(e) => e.stopPropagation()}
              className="w-[min(94vw,880px)] overflow-hidden rounded-xl border border-border bg-surface shadow-[0_32px_96px_-12px_rgba(0,0,0,0.85)]"
            >
              <CodeHeader
                title={active.title}
                filename={active.filename}
                source={active.source}
                onClose={close}
              />
              <Highlight code={active.source} language={active.language} theme={themes.vsDark}>
                {({ className, style, tokens, getLineProps, getTokenProps }) => (
                  <pre
                    className={`${className} max-h-[70vh] overflow-auto p-4 font-mono text-[12px] leading-relaxed`}
                    style={{ ...style, background: '#050507' }}
                  >
                    {tokens.map((line, i) => (
                      <div key={i} {...getLineProps({ line })} className="table-row">
                        <span className="table-cell select-none pr-4 text-right text-[#3a3a42]">
                          {i + 1}
                        </span>
                        <span className="table-cell">
                          {line.map((token, k) => (
                            <span key={k} {...getTokenProps({ token })} />
                          ))}
                        </span>
                      </div>
                    ))}
                  </pre>
                )}
              </Highlight>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </section>
  )
}

function CodeHeader({
  title,
  filename,
  source,
  onClose,
}: {
  title: string
  filename: string
  source: string
  onClose: () => void
}) {
  const [copied, setCopied] = useState(false)
  const copy = async () => {
    try {
      await navigator.clipboard.writeText(source)
      setCopied(true)
      setTimeout(() => setCopied(false), 1400)
    } catch {}
  }

  return (
    <header className="flex items-center justify-between gap-3 border-b border-border px-4 py-3">
      <div className="flex items-center gap-3">
        <span className="flex gap-1" aria-hidden="true">
          <span className="h-2.5 w-2.5 rounded-full bg-[#3a3a42]" />
          <span className="h-2.5 w-2.5 rounded-full bg-[#3a3a42]" />
          <span className="h-2.5 w-2.5 rounded-full bg-cyan/70" />
        </span>
        <span className="font-mono text-[11px] text-[#c9c9d1]">{filename}</span>
      </div>
      <div className="flex items-center gap-2">
        <button
          onClick={copy}
          aria-label="Copy source"
          className="inline-flex items-center gap-1.5 rounded-md border border-border px-2 py-1 font-mono text-[10px] uppercase tracking-widest text-muted transition-colors hover:border-[#2a2a32] hover:text-fg"
        >
          {copied ? <Check className="h-3 w-3 text-[#22c55e]" /> : <Copy className="h-3 w-3" />}
          {copied ? 'Copied' : 'Copy'}
        </button>
        <button
          onClick={onClose}
          aria-label="Close"
          className="grid h-7 w-7 place-items-center rounded-md border border-border text-muted transition-colors hover:text-fg"
        >
          <X className="h-3.5 w-3.5" />
        </button>
      </div>
    </header>
  )
}
EOF

# ─── PROOF: ROI CALCULATOR ───────────────────────────────────────────────────
cat > src/components/proof/roi-calculator.tsx << 'EOF'
'use client'

import { useMemo, useState } from 'react'
import { RotaryKnob } from '@/components/industrial/rotary-knob'
import { MechanicalToggle } from '@/components/industrial/mechanical-toggle'
import { LedReadout } from '@/components/industrial/led-readout'
import { BlueprintOverlay } from '@/components/industrial/blueprint-overlay'
import { computeROI, formatUSD, type ROIInput } from '@/lib/roi'
import { useAnimatedNumber } from '@/hooks/use-animated-number'

const DEFAULT_INPUT: ROIInput = {
  monthlyTraffic: 180000,
  conversionRate: 0.024,
  avgOrderValue: 1200,
  legacyTtiMs: 980,
  aurexisTtiMs: 140,
  manualHoursPerMonth: 120,
  loadedHourlyRate: 145,
}

export function RoiCalculator() {
  const [input, setInput] = useState<ROIInput>(DEFAULT_INPUT)
  const [compare, setCompare] = useState(true)

  const out = useMemo(() => computeROI(input), [input])

  const set = <K extends keyof ROIInput>(key: K, v: ROIInput[K]) =>
    setInput((p) => ({ ...p, [key]: v }))

  const annual = useAnimatedNumber(out.annualTotal, 900)

  return (
    <section id="roi" className="border-b border-border">
      <div className="mx-auto max-w-7xl px-4 py-20 md:px-6">
        <header className="mb-10 max-w-2xl">
          <p className="font-mono text-[11px] uppercase tracking-[0.2em] text-orange">
            ROI Console · v3.14
          </p>
          <h2 className="mt-3 text-3xl font-semibold tracking-tight md:text-4xl">
            Turn latency into revenue. Do the math.
          </h2>
          <p className="mt-3 text-sm text-[#a0a0ab] md:text-base">
            Model your recovery curve with real numbers. All formulas are open — see the
            constants below.
          </p>
        </header>

        <div className="grid gap-6 lg:grid-cols-[1.2fr_1fr]">
          <div className="relative rounded-2xl border border-border bg-surface p-6">
            <BlueprintOverlay
              title="INPUT RANGE"
              anchor="tr"
              specs={[
                { label: 'TRAFFIC', value: input.monthlyTraffic.toLocaleString() },
                { label: 'CVR', value: `${(input.conversionRate * 100).toFixed(2)}%` },
                { label: 'AOV', value: formatUSD(input.avgOrderValue) },
              ]}
            />

            <h3 className="mb-6 font-mono text-[10px] uppercase tracking-widest text-muted">
              INPUTS
            </h3>

            <div className="grid gap-6 sm:grid-cols-2">
              <Field label="Monthly traffic">
                <input
                  type="range"
                  min={10000}
                  max={2000000}
                  step={10000}
                  value={input.monthlyTraffic}
                  onChange={(e) => set('monthlyTraffic', Number(e.target.value))}
                  className="w-full accent-cyan"
                  aria-label="Monthly traffic"
                />
                <Readout>{input.monthlyTraffic.toLocaleString()}</Readout>
              </Field>

              <Field label="Conversion rate">
                <input
                  type="range"
                  min={0.002}
                  max={0.12}
                  step={0.001}
                  value={input.conversionRate}
                  onChange={(e) => set('conversionRate', Number(e.target.value))}
                  className="w-full accent-cyan"
                  aria-label="Conversion rate"
                />
                <Readout>{(input.conversionRate * 100).toFixed(2)}%</Readout>
              </Field>

              <Field label="Avg order value">
                <input
                  type="range"
                  min={20}
                  max={10000}
                  step={10}
                  value={input.avgOrderValue}
                  onChange={(e) => set('avgOrderValue', Number(e.target.value))}
                  className="w-full accent-cyan"
                  aria-label="Average order value"
                />
                <Readout>{formatUSD(input.avgOrderValue)}</Readout>
              </Field>

              <Field label="Manual hours / month">
                <input
                  type="range"
                  min={0}
                  max={800}
                  step={5}
                  value={input.manualHoursPerMonth}
                  onChange={(e) => set('manualHoursPerMonth', Number(e.target.value))}
                  className="w-full accent-cyan"
                  aria-label="Manual hours per month"
                />
                <Readout>{input.manualHoursPerMonth} h</Readout>
              </Field>
            </div>

            <div className="mt-8 grid grid-cols-2 gap-6 border-t border-border pt-6 sm:grid-cols-3">
              <div className="col-span-2 flex items-center justify-center sm:col-span-1">
                <RotaryKnob
                  label="LEGACY TTI"
                  value={input.legacyTtiMs}
                  onChange={(v) => set('legacyTtiMs', v)}
                  format={(v) => `${v}ms`}
                  spec={{ min: 200, max: 3000, step: 10, thetaMin: -135, thetaMax: 135 }}
                  accent="#ef4444"
                />
              </div>
              <div className="col-span-2 flex items-center justify-center sm:col-span-1">
                <RotaryKnob
                  label="AUREXIS TTI"
                  value={input.aurexisTtiMs}
                  onChange={(v) => set('aurexisTtiMs', v)}
                  format={(v) => `${v}ms`}
                  spec={{ min: 40, max: 500, step: 5, thetaMin: -135, thetaMax: 135 }}
                  accent="#35e6f2"
                />
              </div>
              <div className="col-span-2 flex items-center sm:col-span-1">
                <MechanicalToggle
                  checked={compare}
                  onChange={setCompare}
                  label="ANIMATE OUTPUT"
                  hint="Smooth counter rollup"
                />
              </div>
            </div>
          </div>

          <div className="relative flex flex-col gap-4">
            <div className="rounded-2xl border border-border bg-surface p-6">
              <h3 className="mb-5 font-mono text-[10px] uppercase tracking-widest text-muted">
                PROJECTED RECOVERY · 12 MO
              </h3>

              <div className="mb-6">
                <div className="font-mono text-4xl font-semibold tabular-nums text-cyan md:text-5xl">
                  {compare ? formatUSD(annual) : formatUSD(out.annualTotal)}
                </div>
                <div className="mt-1 font-mono text-[10px] uppercase tracking-widest text-dim">
                  estimated annual recovered value
                </div>
              </div>

              <dl className="space-y-3 border-t border-border pt-5 font-mono text-xs">
                <Row k="Δ TTI" v={`${out.deltaTtiMs} ms`} />
                <Row
                  k="CONVERSION LIFT"
                  v={`${(out.conversionLift * 100).toFixed(2)}%`}
                  accent="#22c55e"
                />
                <Row k="MONTHLY REVENUE" v={formatUSD(out.monthlyRecovered)} />
                <Row k="MONTHLY SAVINGS" v={formatUSD(out.monthlySavings)} />
                <Row k="IMPLEMENTATION" v={formatUSD(out.implementationCost)} muted />
                <Row
                  k="ROI MULTIPLE"
                  v={`${out.roiMultiplier.toFixed(2)}×`}
                  accent={out.roiMultiplier >= 2 ? '#22c55e' : '#f5a623'}
                  bold
                />
              </dl>
            </div>

            <div className="flex justify-center gap-4 rounded-2xl border border-border bg-[#040406] p-5">
              <LedReadout value={out.deltaTtiMs} label="Δ ms" px={2} accent="#35e6f2" />
              <LedReadout
                value={`${(out.conversionLift * 100).toFixed(1)}`}
                label="LIFT %"
                px={2}
                accent="#22c55e"
              />
              <LedReadout
                value={out.roiMultiplier.toFixed(1)}
                label="ROI ×"
                px={2}
                accent="#f5a623"
              />
            </div>

            <p className="px-2 font-mono text-[9px] uppercase leading-relaxed tracking-widest text-dim">
              MODEL: L(Δt) = 0.14 · (1 − e^(−Δt/900)). REVENUE = TRAFFIC · CVR · AOV · LIFT.
              SAVINGS = HOURS · RATE. FIGURES ARE PROJECTIONS, NOT GUARANTEES.
            </p>
          </div>
        </div>
      </div>
    </section>
  )
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className="mb-2 block font-mono text-[10px] uppercase tracking-widest text-muted">
        {label}
      </span>
      {children}
    </label>
  )
}

function Readout({ children }: { children: React.ReactNode }) {
  return (
    <span className="mt-1.5 block font-mono text-xs tabular-nums text-fg">{children}</span>
  )
}

function Row({
  k,
  v,
  accent,
  muted,
  bold,
}: {
  k: string
  v: string
  accent?: string
  muted?: boolean
  bold?: boolean
}) {
  return (
    <div className="flex items-center justify-between gap-3">
      <dt className={`uppercase tracking-widest ${muted ? 'text-dim' : 'text-muted'}`}>{k}</dt>
      <dd
        className={`tabular-nums ${bold ? 'font-semibold' : ''}`}
        style={{ color: muted ? '#5a5a64' : accent ?? '#f5f5f7' }}
      >
        {v}
      </dd>
    </div>
  )
}
EOF

# ─── APP: FINAL PAGE ─────────────────────────────────────────────────────────
cat > src/app/page.tsx << 'EOF'
import { SiteHeader } from '@/components/layout/site-header'
import { CommandPalette } from '@/components/layout/command-palette'
import { TelemetryTicker } from '@/components/layout/telemetry-ticker'
import { HeroSection } from '@/components/hero/hero-section'
import { BentoGrid } from '@/components/bento/bento-grid'
import { IsometricCarousel } from '@/components/velocity/isometric-carousel'
import { OntologySection } from '@/components/ontology/ontology-section'
import { BeforeAfterSlider } from '@/components/proof/before-after-slider'
import { CodeSplitView } from '@/components/proof/code-split-view'
import { RoiCalculator } from '@/components/proof/roi-calculator'

export default function HomePage() {
  return (
    <>
      <SiteHeader />
      <CommandPalette />
      <TelemetryTicker />
      <main>
        <HeroSection />
        <BentoGrid />
        <IsometricCarousel />
        <OntologySection />

        <section id="metrics" className="border-b border-border">
          <div className="mx-auto max-w-7xl px-4 py-20 md:px-6">
            <header className="mb-8 max-w-2xl">
              <p className="font-mono text-[11px] uppercase tracking-[0.2em] text-orange">
                Proof · Drag to compare
              </p>
              <h2 className="mt-3 text-3xl font-semibold tracking-tight md:text-4xl">
                Slow vs. instant. Your call.
              </h2>
            </header>
            <BeforeAfterSlider />
          </div>
        </section>

        <CodeSplitView />
        <RoiCalculator />
      </main>

      <footer id="book" className="border-t border-border py-10">
        <div className="mx-auto flex max-w-7xl flex-col items-center justify-between gap-4 px-4 font-mono text-[10px] uppercase tracking-widest text-dim md:flex-row md:px-6">
          <span>© Aurexis Systems Inc. — MMXXVI</span>
          <span>BUILD 3.14.2 · EDGE · 6 REGIONS</span>
        </div>
      </footer>
    </>
  )
}
EOF

echo ""
echo "==> Done. Files written:"
find src/components/velocity src/components/ontology src/components/industrial src/components/proof src/components/ui -type f 2>/dev/null | sort
echo ""
echo "==> Advanced components: $(find src/components/velocity src/components/ontology src/components/industrial src/components/proof src/components/ui -type f 2>/dev/null | wc -l)"
echo ""
echo "==> ALL SCRIPTS COMPLETE. Next: git pull, then run all four scripts in order."
