#!/usr/bin/env bash
set -euo pipefail
echo "==> Writing state, hooks, math, and data layers..."

mkdir -p src/types src/store src/hooks src/lib src/data

# ─── TYPES ────────────────────────────────────────────────────────────────────
cat > src/types/ui.ts << 'EOF'
export type Mode = 'executive' | 'engineer'

export interface Incident {
  id: string
  severity: 'info' | 'warn' | 'critical'
  region: string
  message: string
  startedAt: number
}

export interface TelemetrySnapshot {
  uptime: number
  p95LatencyMs: number
  requestsPerSec: number
  incidents: Incident[]
  tick: number
}
EOF

cat > src/types/ontology.ts << 'EOF'
export type NodeKind = 'source' | 'ingest' | 'compute' | 'api' | 'render' | 'observe'

export interface OntologyNode {
  id: string
  label: string
  short: string
  kind: NodeKind
  summary: string
  spec: Record<string, string>
}

export interface OntologyEdge {
  from: string
  to: string
  load: number
}

export interface NodePosition {
  x: number
  y: number
  layer: number
}

export interface BezierPoints {
  p0: { x: number; y: number }
  p1: { x: number; y: number }
  p2: { x: number; y: number }
  p3: { x: number; y: number }
}
EOF

# ─── STORES (Zustand) ─────────────────────────────────────────────────────────
cat > src/store/use-mode-store.ts << 'EOF'
'use client'

import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'
import type { Mode } from '@/types/ui'

interface ModeState {
  mode: Mode
  setMode: (mode: Mode) => void
  toggle: () => void
}

export const useModeStore = create<ModeState>()(
  persist(
    (set, get) => ({
      mode: 'executive',
      setMode: (mode) => set({ mode }),
      toggle: () => set({ mode: get().mode === 'executive' ? 'engineer' : 'executive' }),
    }),
    {
      name: 'aurexis.mode',
      storage: createJSONStorage(() => localStorage),
      skipHydration: true,
    },
  ),
)

export const selectIsEngineer = (s: ModeState) => s.mode === 'engineer'
EOF

cat > src/store/use-ui-store.ts << 'EOF'
'use client'

import { create } from 'zustand'

interface UIState {
  paletteOpen: boolean
  inspectorOpenId: string | null
  activeBentoId: string | null
  carouselIndex: number
  setPaletteOpen: (open: boolean) => void
  toggleInspector: (id: string | null) => void
  setActiveBento: (id: string | null) => void
  setCarouselIndex: (i: number) => void
}

export const useUIStore = create<UIState>((set) => ({
  paletteOpen: false,
  inspectorOpenId: null,
  activeBentoId: null,
  carouselIndex: 0,
  setPaletteOpen: (paletteOpen) => set({ paletteOpen }),
  toggleInspector: (id) =>
    set((s) => ({ inspectorOpenId: s.inspectorOpenId === id ? null : id })),
  setActiveBento: (activeBentoId) => set({ activeBentoId }),
  setCarouselIndex: (carouselIndex) => set({ carouselIndex }),
}))
EOF

cat > src/store/use-audio-store.ts << 'EOF'
'use client'

import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'

interface AudioState {
  muted: boolean
  unlocked: boolean
  setMuted: (muted: boolean) => void
  unlock: () => void
}

export const useAudioStore = create<AudioState>()(
  persist(
    (set) => ({
      muted: true,
      unlocked: false,
      setMuted: (muted) => set({ muted }),
      unlock: () => set({ unlocked: true }),
    }),
    {
      name: 'aurexis.audio',
      storage: createJSONStorage(() => localStorage),
      skipHydration: true,
      partialize: (s) => ({ muted: s.muted }),
    },
  ),
)
EOF

cat > src/store/use-telemetry-store.ts << 'EOF'
'use client'

import { create } from 'zustand'
import type { TelemetrySnapshot, Incident } from '@/types/ui'

interface TelemetryState extends TelemetrySnapshot {
  setSnapshot: (s: Partial<TelemetrySnapshot>) => void
  pushIncident: (i: Incident) => void
}

export const useTelemetryStore = create<TelemetryState>((set) => ({
  uptime: 99.99,
  p95LatencyMs: 42,
  requestsPerSec: 12480,
  incidents: [],
  tick: 0,
  setSnapshot: (s) => set((prev) => ({ ...prev, ...s })),
  pushIncident: (i) =>
    set((prev) => ({ incidents: [i, ...prev.incidents].slice(0, 6) })),
}))
EOF

cat > src/store/use-command-store.ts << 'EOF'
'use client'

import { create } from 'zustand'

export interface CommandItem {
  id: string
  label: string
  group: 'Navigate' | 'Actions' | 'Modes'
  shortcut?: string
  perform: () => void
}

interface CommandState {
  items: CommandItem[]
  register: (items: CommandItem[]) => void
  clear: () => void
}

export const useCommandStore = create<CommandState>((set) => ({
  items: [],
  register: (items) => set({ items }),
  clear: () => set({ items: [] }),
}))
EOF

# ─── HOOKS ────────────────────────────────────────────────────────────────────
cat > src/hooks/use-mounted.ts << 'EOF'
'use client'

import { useEffect, useState } from 'react'

export function useMounted() {
  const [mounted, setMounted] = useState(false)
  useEffect(() => setMounted(true), [])
  return mounted
}
EOF

cat > src/hooks/use-reduced-motion.ts << 'EOF'
'use client'

import { useEffect, useState } from 'react'

export function useReducedMotion() {
  const [reduced, setReduced] = useState(false)
  useEffect(() => {
    const mq = window.matchMedia('(prefers-reduced-motion: reduce)')
    const onChange = () => setReduced(mq.matches)
    onChange()
    mq.addEventListener('change', onChange)
    return () => mq.removeEventListener('change', onChange)
  }, [])
  return reduced
}
EOF

cat > src/hooks/use-media-query.ts << 'EOF'
'use client'

import { useEffect, useState } from 'react'

export function useMediaQuery(query: string) {
  const [matches, setMatches] = useState(false)
  useEffect(() => {
    const mq = window.matchMedia(query)
    const onChange = () => setMatches(mq.matches)
    onChange()
    mq.addEventListener('change', onChange)
    return () => mq.removeEventListener('change', onChange)
  }, [query])
  return matches
}
EOF

cat > src/hooks/use-keyboard-shortcut.ts << 'EOF'
'use client'

import { useEffect } from 'react'

export function useKeyboardShortcut(
  combo: { key: string; meta?: boolean; shift?: boolean },
  handler: () => void,
  deps: unknown[] = [],
) {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const metaOk = combo.meta ? e.metaKey || e.ctrlKey : true
      const shiftOk = combo.shift ? e.shiftKey : true
      if (e.key.toLowerCase() === combo.key.toLowerCase() && metaOk && shiftOk) {
        handler()
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps)
}
EOF

cat > src/hooks/use-element-size.ts << 'EOF'
'use client'

import { useEffect, useRef, useState } from 'react'

export function useElementSize<T extends HTMLElement>() {
  const ref = useRef<T>(null)
  const [size, setSize] = useState({ width: 0, height: 0 })
  useEffect(() => {
    const el = ref.current
    if (!el) return
    const ro = new ResizeObserver(([entry]) => {
      const { width, height } = entry.contentRect
      setSize({ width: Math.round(width), height: Math.round(height) })
    })
    ro.observe(el)
    return () => ro.disconnect()
  }, [])
  return [ref, size] as const
}
EOF

cat > src/hooks/use-animated-number.ts << 'EOF'
'use client'

import { useEffect, useRef, useState } from 'react'

function easeOutExpo(t: number): number {
  return t === 1 ? 1 : 1 - Math.pow(2, -10 * t)
}

export function useAnimatedNumber(to: number, durationMs = 1400) {
  const [value, setValue] = useState(0)
  const startRef = useRef<number | null>(null)
  const rafRef = useRef<number>()

  useEffect(() => {
    const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    if (reduced) {
      setValue(to)
      return
    }
    const step = (now: number) => {
      if (startRef.current === null) startRef.current = now
      const t = Math.min(1, (now - startRef.current) / durationMs)
      setValue(to * easeOutExpo(t))
      if (t < 1) rafRef.current = requestAnimationFrame(step)
    }
    rafRef.current = requestAnimationFrame(step)
    return () => {
      if (rafRef.current) cancelAnimationFrame(rafRef.current)
    }
  }, [to, durationMs])

  return value
}
EOF

# ─── MATH LIBRARIES ───────────────────────────────────────────────────────────
cat > src/lib/bezier.ts << 'EOF'
import type { BezierPoints } from '@/types/ontology'

export interface Pt {
  x: number
  y: number
}

export function bezierPoint(t: number, b: BezierPoints): Pt {
  const u = 1 - t
  const uu = u * u
  const tt = t * t
  return {
    x: uu * u * b.p0.x + 3 * uu * t * b.p1.x + 3 * u * tt * b.p2.x + tt * t * b.p3.x,
    y: uu * u * b.p0.y + 3 * uu * t * b.p1.y + 3 * u * tt * b.p2.y + tt * t * b.p3.y,
  }
}

export function bezierTangent(t: number, b: BezierPoints): Pt {
  const u = 1 - t
  return {
    x:
      3 * u * u * (b.p1.x - b.p0.x) +
      6 * u * t * (b.p2.x - b.p1.x) +
      3 * t * t * (b.p3.x - b.p2.x),
    y:
      3 * u * u * (b.p1.y - b.p0.y) +
      6 * u * t * (b.p2.y - b.p1.y) +
      3 * t * t * (b.p3.y - b.p2.y),
  }
}

export function bezierPath(b: BezierPoints): string {
  return `M ${b.p0.x.toFixed(2)} ${b.p0.y.toFixed(2)} C ${b.p1.x.toFixed(2)} ${b.p1.y.toFixed(2)}, ${b.p2.x.toFixed(2)} ${b.p2.y.toFixed(2)}, ${b.p3.x.toFixed(2)} ${b.p3.y.toFixed(2)}`
}
EOF

cat > src/lib/iso.ts << 'EOF'
const COS30 = Math.cos(Math.PI / 6)
const SIN30 = Math.sin(Math.PI / 6)

export interface Pt3 {
  x: number
  y: number
  z: number
}
export interface Pt2 {
  x: number
  y: number
}

export interface IsoView {
  scale: number
  cx: number
  cy: number
}

export function project(p: Pt3, { scale, cx, cy }: IsoView): Pt2 {
  return {
    x: cx + (p.x - p.y) * COS30 * scale,
    y: cy + ((p.x + p.y) * SIN30 - p.z) * scale,
  }
}

export function depthKey(p: Pt3): number {
  return p.x + p.y + p.z
}

export interface Mesh {
  vertices: Pt3[]
  edges: Array<[number, number]>
  highlight?: number[]
}

export function cube(cx: number, cy: number, cz: number, s: number): Mesh {
  const h = s / 2
  const v: Pt3[] = [
    { x: cx - h, y: cy - h, z: cz - h },
    { x: cx + h, y: cy - h, z: cz - h },
    { x: cx + h, y: cy + h, z: cz - h },
    { x: cx - h, y: cy + h, z: cz - h },
    { x: cx - h, y: cy - h, z: cz + h },
    { x: cx + h, y: cy - h, z: cz + h },
    { x: cx + h, y: cy + h, z: cz + h },
    { x: cx - h, y: cy + h, z: cz + h },
  ]
  const e: Array<[number, number]> = [
    [0, 1], [1, 2], [2, 3], [3, 0],
    [4, 5], [5, 6], [6, 7], [7, 4],
    [0, 4], [1, 5], [2, 6], [3, 7],
  ]
  return { vertices: v, edges: e }
}

export function grid(n: number, spacing: number): Mesh {
  const v: Pt3[] = []
  const e: Array<[number, number]> = []
  const half = (n * spacing) / 2
  for (let i = 0; i <= n; i++) {
    v.push({ x: -half + i * spacing, y: -half, z: 0 })
    v.push({ x: -half + i * spacing, y: half, z: 0 })
    v.push({ x: -half, y: -half + i * spacing, z: 0 })
    v.push({ x: half, y: -half + i * spacing, z: 0 })
  }
  for (let i = 0; i < v.length; i += 2) {
    e.push([i, i + 1], [i + 2, i + 3])
  }
  return { vertices: v, edges: e }
}

export function ring(cx: number, cy: number, cz: number, r: number, segments = 16): Mesh {
  const v: Pt3[] = []
  const e: Array<[number, number]> = []
  for (let i = 0; i < segments; i++) {
    const t = (i / segments) * Math.PI * 2
    v.push({ x: cx + Math.cos(t) * r, y: cy + Math.sin(t) * r, z: cz })
  }
  for (let i = 0; i < segments; i++) e.push([i, (i + 1) % segments])
  return { vertices: v, edges: e }
}

export function cylinder(
  cx: number,
  cy: number,
  z0: number,
  z1: number,
  r: number,
  seg = 16,
): Mesh {
  const v: Pt3[] = []
  const e: Array<[number, number]> = []
  for (let i = 0; i < seg; i++) {
    const t = (i / seg) * Math.PI * 2
    const x = cx + Math.cos(t) * r
    const y = cy + Math.sin(t) * r
    v.push({ x, y, z: z0 })
    v.push({ x, y, z: z1 })
  }
  for (let i = 0; i < seg; i++) {
    const a = i * 2
    const b = a + 1
    const na = ((i + 1) % seg) * 2
    const nb = na + 1
    e.push([a, na], [b, nb], [a, b])
  }
  return { vertices: v, edges: e }
}

export function merge(...meshes: Mesh[]): Mesh {
  const out: Mesh = { vertices: [], edges: [], highlight: [] }
  for (const m of meshes) {
    const offset = out.vertices.length
    out.vertices.push(...m.vertices)
    for (const [a, b] of m.edges) out.edges.push([a + offset, b + offset])
    if (m.highlight) for (const i of m.highlight) out.highlight!.push(i + offset)
  }
  return out
}

export interface Scene {
  mesh: Mesh
  focal: Pt3
}
EOF

cat > src/lib/iso-scenes.ts << 'EOF'
import { cube, grid, cylinder, ring, merge, type Scene } from './iso'

export function sceneStack(): Scene {
  const s = 46
  const gap = 4
  const a = cube(0, 0, s / 2, s)
  const b = cube(0, 0, s / 2 + s + gap, s)
  const c = cube(0, 0, s / 2 + (s + gap) * 2, s)
  const g = grid(4, 34)
  return { mesh: merge(g, a, b, c), focal: { x: 0, y: 0, z: s / 2 + s + gap } }
}

export function scenePipeline(): Scene {
  const z0 = 0
  const z1 = 40
  const r = 12
  const lanes = [-38, 0, 38]
  const pipes = lanes.map((y) => cylinder(0, y, z0, z1, r, 20))
  const boxes = lanes.map((y) => cube(28, y, z1, 20))
  const g = grid(5, 30)
  return { mesh: merge(g, ...pipes, ...boxes), focal: { x: 0, y: 0, z: z1 } }
}

export function sceneRamp(): Scene {
  const step = 26
  const cubes = Array.from({ length: 5 }, (_, i) =>
    cube(i * step - step * 2, 0, (i + 1) * step * 0.5, step * 0.6),
  )
  const g = grid(6, step)
  return { mesh: merge(g, ...cubes), focal: { x: 2 * step, y: 0, z: 3 * step * 0.5 } }
}

export function sceneMesh(): Scene {
  const pts = [
    { x: -40, y: -40, z: 20 },
    { x: 40, y: -40, z: 20 },
    { x: 40, y: 40, z: 20 },
    { x: -40, y: 40, z: 20 },
    { x: 0, y: 0, z: 60 },
  ]
  const size = 18
  const cubes = pts.map((p) => cube(p.x, p.y, p.z, size))
  const base = merge(...cubes)
  const links: Array<[number, number]> = [
    [0, 1], [1, 2], [2, 3], [3, 0], [0, 4], [1, 4], [2, 4], [3, 4],
  ]
  const v: typeof base.vertices = []
  const e: Array<[number, number]> = []
  for (const [a, b] of links) {
    const i = v.length
    v.push(pts[a]!, pts[b]!)
    e.push([i, i + 1])
  }
  return { mesh: merge(base, { vertices: v, edges: e }), focal: { x: 0, y: 0, z: 60 } }
}

export function sceneLens(): Scene {
  const c = cylinder(0, 0, 0, 26, 46, 32)
  const r1 = ring(0, 0, 34, 40, 32)
  const r2 = ring(0, 0, 46, 30, 32)
  const r3 = ring(0, 0, 58, 20, 32)
  const eye = cube(0, 0, 74, 14)
  return { mesh: merge(c, r1, r2, r3, eye), focal: { x: 0, y: 0, z: 74 } }
}

export const SCENES = {
  stack: sceneStack,
  pipeline: scenePipeline,
  ramp: sceneRamp,
  mesh: sceneMesh,
  lens: sceneLens,
} as const

export type SceneId = keyof typeof SCENES
EOF

cat > src/lib/ontology-layout.ts << 'EOF'
import type {
  OntologyNode,
  OntologyEdge,
  NodePosition,
  BezierPoints,
} from '@/types/ontology'

export function computeLayers(
  nodeIds: string[],
  edges: OntologyEdge[],
): Map<string, number> {
  const preds = new Map<string, string[]>()
  for (const id of nodeIds) preds.set(id, [])
  for (const e of edges) preds.get(e.to)?.push(e.from)

  const depth = new Map<string, number>()
  const visiting = new Set<string>()

  const visit = (id: string): number => {
    const cached = depth.get(id)
    if (cached !== undefined) return cached
    if (visiting.has(id)) return 0
    visiting.add(id)
    const ps = preds.get(id) ?? []
    const d = ps.length === 0 ? 0 : 1 + Math.max(...ps.map(visit))
    visiting.delete(id)
    depth.set(id, d)
    return d
  }
  for (const id of nodeIds) visit(id)
  return depth
}

export interface LayoutOptions {
  width: number
  height: number
  vertical?: boolean
}

export function layoutArc(
  nodes: OntologyNode[],
  edges: OntologyEdge[],
  { width, height, vertical = false }: LayoutOptions,
): Map<string, NodePosition> {
  const out = new Map<string, NodePosition>()
  const depth = computeLayers(nodes.map((n) => n.id), edges)
  const maxLayer = Math.max(0, ...depth.values())

  if (vertical || width < 640) {
    const cx = width / 2
    const padY = 44
    for (const n of nodes) {
      const d = depth.get(n.id) ?? 0
      const t = maxLayer === 0 ? 0.5 : d / maxLayer
      out.set(n.id, { x: cx, y: padY + t * (height - padY * 2), layer: d })
    }
    return out
  }

  const cx = width / 2
  const cy = height * 0.7
  const R = Math.min(width * 0.4, height * 0.72)
  const SQUASH = 0.62

  for (const n of nodes) {
    const d = depth.get(n.id) ?? 0
    const t = maxLayer === 0 ? 0.5 : d / maxLayer
    const theta = Math.PI + t * Math.PI
    out.set(n.id, { x: cx + R * Math.cos(theta), y: cy + R * Math.sin(theta) * SQUASH, layer: d })
  }
  return out
}

export function edgeControlPoints(
  from: NodePosition,
  to: NodePosition,
  vertical: boolean,
): BezierPoints {
  const p0 = { x: from.x, y: from.y }
  const p3 = { x: to.x, y: to.y }
  const layerGap = Math.abs(to.layer - from.layer)
  const isSkip = layerGap > 1

  if (vertical) {
    const dy = p3.y - p0.y
    const lift = isSkip ? 46 : 0
    return {
      p0, p3,
      p1: { x: p0.x + lift, y: p0.y + dy * 0.5 },
      p2: { x: p3.x + lift, y: p3.y - dy * 0.5 },
    }
  }

  const dx = p3.x - p0.x
  const lift = isSkip ? -Math.min(90, 22 * layerGap) : 0
  return {
    p0, p3,
    p1: { x: p0.x + dx * 0.5, y: p0.y + lift },
    p2: { x: p3.x - dx * 0.5, y: p3.y + lift },
  }
}
EOF

cat > src/lib/roi.ts << 'EOF'
export interface ROIInput {
  monthlyTraffic: number
  conversionRate: number
  avgOrderValue: number
  legacyTtiMs: number
  aurexisTtiMs: number
  manualHoursPerMonth: number
  loadedHourlyRate: number
}

export interface ROIOutput {
  deltaTtiMs: number
  conversionLift: number
  monthlyRecovered: number
  monthlySavings: number
  monthlyTotal: number
  annualTotal: number
  roiMultiplier: number
  implementationCost: number
}

const L_MAX = 0.14
const TAU_MS = 900
const BASE_IMPLEMENTATION_COST = 45000

export function computeROI(input: ROIInput): ROIOutput {
  const deltaTtiMs = Math.max(0, input.legacyTtiMs - input.aurexisTtiMs)
  const conversionLift = L_MAX * (1 - Math.exp(-deltaTtiMs / TAU_MS))
  const monthlyRecovered =
    input.monthlyTraffic * input.conversionRate * input.avgOrderValue * conversionLift
  const monthlySavings = input.manualHoursPerMonth * input.loadedHourlyRate
  const monthlyTotal = monthlyRecovered + monthlySavings
  const annualTotal = monthlyTotal * 12
  const roiMultiplier = annualTotal / BASE_IMPLEMENTATION_COST
  return {
    deltaTtiMs,
    conversionLift,
    monthlyRecovered,
    monthlySavings,
    monthlyTotal,
    annualTotal,
    roiMultiplier,
    implementationCost: BASE_IMPLEMENTATION_COST,
  }
}

export function formatUSD(n: number): string {
  return n.toLocaleString('en-US', {
    style: 'currency',
    currency: 'USD',
    maximumFractionDigits: 0,
  })
}
EOF

cat > src/lib/knob-math.ts << 'EOF'
export interface KnobSpec {
  min: number
  max: number
  step: number
  thetaMin: number
  thetaMax: number
}

export const DEFAULT_KNOB: KnobSpec = {
  min: 0,
  max: 100,
  step: 1,
  thetaMin: -135,
  thetaMax: 135,
}

export function clamp(v: number, lo: number, hi: number): number {
  return Math.max(lo, Math.min(hi, v))
}

export function valueToAngle(v: number, s: KnobSpec): number {
  const t = (v - s.min) / (s.max - s.min)
  return s.thetaMin + t * (s.thetaMax - s.thetaMin)
}

export function angleToValue(theta: number, s: KnobSpec): number {
  const clamped = clamp(theta, s.thetaMin, s.thetaMax)
  const t = (clamped - s.thetaMin) / (s.thetaMax - s.thetaMin)
  const raw = s.min + t * (s.max - s.min)
  const snapped = s.min + Math.round((raw - s.min) / s.step) * s.step
  return clamp(snapped, s.min, s.max)
}

export function tipPoint(cx: number, cy: number, r: number, thetaDeg: number) {
  const rad = (thetaDeg - 90) * (Math.PI / 180)
  return { x: cx + Math.cos(rad) * r, y: cy + Math.sin(rad) * r }
}

export function pointToAngle(cx: number, cy: number, px: number, py: number): number {
  return (Math.atan2(py - cy, px - cx) * 180) / Math.PI + 90
}
EOF

cat > src/lib/dot-matrix-font.ts << 'EOF'
const GLYPHS: Record<string, number[]> = {
  '0': [0b01110, 0b10001, 0b10011, 0b10101, 0b11001, 0b10001, 0b01110],
  '1': [0b00100, 0b01100, 0b00100, 0b00100, 0b00100, 0b00100, 0b01110],
  '2': [0b01110, 0b10001, 0b00001, 0b00010, 0b00100, 0b01000, 0b11111],
  '3': [0b11111, 0b00010, 0b00100, 0b00010, 0b00001, 0b10001, 0b01110],
  '4': [0b00010, 0b00110, 0b01010, 0b10010, 0b11111, 0b00010, 0b00010],
  '5': [0b11111, 0b10000, 0b11110, 0b00001, 0b00001, 0b10001, 0b01110],
  '6': [0b00110, 0b01000, 0b10000, 0b11110, 0b10001, 0b10001, 0b01110],
  '7': [0b11111, 0b00001, 0b00010, 0b00100, 0b01000, 0b01000, 0b01000],
  '8': [0b01110, 0b10001, 0b10001, 0b01110, 0b10001, 0b10001, 0b01110],
  '9': [0b01110, 0b10001, 0b10001, 0b01111, 0b00001, 0b00010, 0b01100],
  '.': [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b01100, 0b01100],
  ':': [0b00000, 0b01100, 0b01100, 0b00000, 0b01100, 0b01100, 0b00000],
  '-': [0b00000, 0b00000, 0b00000, 0b11111, 0b00000, 0b00000, 0b00000],
  ' ': [0, 0, 0, 0, 0, 0, 0],
  A: [0b01110, 0b10001, 0b10001, 0b11111, 0b10001, 0b10001, 0b10001],
  B: [0b11110, 0b10001, 0b10001, 0b11110, 0b10001, 0b10001, 0b11110],
  C: [0b01110, 0b10001, 0b10000, 0b10000, 0b10000, 0b10001, 0b01110],
  D: [0b11110, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b11110],
  E: [0b11111, 0b10000, 0b10000, 0b11110, 0b10000, 0b10000, 0b11111],
  F: [0b11111, 0b10000, 0b10000, 0b11110, 0b10000, 0b10000, 0b10000],
  H: [0b10001, 0b10001, 0b10001, 0b11111, 0b10001, 0b10001, 0b10001],
  L: [0b10000, 0b10000, 0b10000, 0b10000, 0b10000, 0b10000, 0b11111],
  N: [0b10001, 0b11001, 0b10101, 0b10011, 0b10001, 0b10001, 0b10001],
  O: [0b01110, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01110],
  P: [0b11110, 0b10001, 0b10001, 0b11110, 0b10000, 0b10000, 0b10000],
  R: [0b11110, 0b10001, 0b10001, 0b11110, 0b10100, 0b10010, 0b10001],
  S: [0b01111, 0b10000, 0b10000, 0b01110, 0b00001, 0b00001, 0b11110],
  T: [0b11111, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100],
  U: [0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01110],
  W: [0b10001, 0b10001, 0b10001, 0b10101, 0b10101, 0b11011, 0b10001],
  Y: [0b10001, 0b10001, 0b01010, 0b00100, 0b00100, 0b00100, 0b00100],
  '%': [0b11001, 0b11010, 0b00010, 0b00100, 0b01000, 0b01011, 0b10011],
  '+': [0b00000, 0b00100, 0b00100, 0b11111, 0b00100, 0b00100, 0b00000],
  '/': [0b00001, 0b00010, 0b00010, 0b00100, 0b01000, 0b01000, 0b10000],
  '>': [0b10000, 0b01000, 0b00100, 0b00010, 0b00100, 0b01000, 0b10000],
}

export const GLYPH_W = 5
export const GLYPH_H = 7

export function glyph(ch: string): number[] {
  return GLYPHS[ch.toUpperCase()] ?? GLYPHS[' ']!
}

export function textWidth(text: string, px: number, gap = 1): number {
  if (text.length === 0) return 0
  return text.length * GLYPH_W * px + (text.length - 1) * gap * px
}
EOF

cat > src/lib/audio-engine.ts << 'EOF'
'use client'

let ctx: AudioContext | null = null

function getCtx(): AudioContext | null {
  if (typeof window === 'undefined') return null
  if (ctx) return ctx
  const C = window.AudioContext || (window as any).webkitAudioContext
  if (!C) return null
  ctx = new C()
  return ctx
}

export async function ensureRunning(): Promise<boolean> {
  const c = getCtx()
  if (!c) return false
  if (c.state === 'suspended') {
    try {
      await c.resume()
    } catch {
      return false
    }
  }
  return c.state === 'running'
}

function envBlip(
  c: AudioContext,
  type: OscillatorType,
  freq: number,
  durMs: number,
  gainPeak = 0.06,
) {
  const now = c.currentTime
  const osc = c.createOscillator()
  const g = c.createGain()
  osc.type = type
  osc.frequency.setValueAtTime(freq, now)
  g.gain.setValueAtTime(0.0001, now)
  g.gain.linearRampToValueAtTime(gainPeak, now + 0.004)
  g.gain.exponentialRampToValueAtTime(0.0001, now + durMs / 1000)
  osc.connect(g).connect(c.destination)
  osc.start(now)
  osc.stop(now + durMs / 1000 + 0.02)
}

export function click(gain = 0.06) {
  const c = getCtx()
  if (!c || c.state !== 'running') return
  envBlip(c, 'square', 620, 26, gain)
}

export function toggle(on: boolean) {
  const c = getCtx()
  if (!c || c.state !== 'running') return
  const now = c.currentTime
  const osc = c.createOscillator()
  const g = c.createGain()
  osc.type = 'triangle'
  osc.frequency.setValueAtTime(on ? 720 : 480, now)
  osc.frequency.exponentialRampToValueAtTime(on ? 1180 : 320, now + 0.05)
  g.gain.setValueAtTime(0.0001, now)
  g.gain.linearRampToValueAtTime(0.05, now + 0.006)
  g.gain.exponentialRampToValueAtTime(0.0001, now + 0.06)
  osc.connect(g).connect(c.destination)
  osc.start(now)
  osc.stop(now + 0.09)
}

export function detent() {
  const c = getCtx()
  if (!c || c.state !== 'running') return
  envBlip(c, 'triangle', 1400, 10, 0.035)
}
EOF

cat > src/lib/logs.ts << 'EOF'
export type LogLevel = 'INFO' | 'DEBUG' | 'OK' | 'WARN' | 'ERR'

export interface LogLine {
  id: number
  t: number
  level: LogLevel
  src: string
  msg: string
}

const SOURCES = [
  'edge/iad',
  'edge/fra',
  'edge/sin',
  'pipe/xform',
  'cache/l2',
  'api/v4',
  'otel/emit',
]

interface Template {
  level: LogLevel
  src?: string
  msg: (n: number) => string
}

const TEMPLATES: Template[] = [
  { level: 'INFO', src: 'edge/iad', msg: (n) => `ingress batch=${n} bytes=${(n * 37 + 512) % 4096}` },
  { level: 'OK', src: 'cache/l2', msg: (n) => `HIT key=usr:${(n * 17) % 99999} ttl=298s` },
  { level: 'DEBUG', src: 'pipe/xform', msg: (n) => `columnar stage=${n % 4} rows=${(n * 211) % 8192}` },
  { level: 'INFO', src: 'api/v4', msg: (n) => `query id=q${(n * 101) % 9999} persisted=true` },
  { level: 'OK', src: 'edge/fra', msg: (n) => `deploy canary r=${((n * 41) % 100).toFixed(2)}%` },
  { level: 'WARN', src: 'cache/l2', msg: (n) => `MISS key=usr:${(n * 23) % 99999} falling back to L3` },
  { level: 'INFO', src: 'otel/emit', msg: (n) => `span trace=${n.toString(16)} dur=${(n % 42) + 3}ms` },
  { level: 'DEBUG', src: 'edge/sin', msg: () => `handshake complete proto=h3` },
  { level: 'ERR', src: 'api/v4', msg: (n) => `upstream 504 id=r${n} retrying in 40ms` },
]

export function makeLine(n: number): LogLine {
  const tpl = TEMPLATES[n % TEMPLATES.length]!
  const src = tpl.src ?? SOURCES[n % SOURCES.length]!
  return { id: n, t: Date.now(), level: tpl.level, src, msg: tpl.msg(n) }
}
EOF

# ─── DATA ─────────────────────────────────────────────────────────────────────
cat > src/data/navigation.ts << 'EOF'
export interface NavItem {
  id: string
  label: string
  href: string
  group: 'Navigate' | 'Services' | 'Proof'
  shortcut?: string
}

export const NAV_ITEMS: NavItem[] = [
  { id: 'services', label: 'Services', href: '#services', group: 'Navigate', shortcut: 'S' },
  { id: 'platform', label: 'Platform', href: '#platform', group: 'Navigate' },
  { id: 'metrics', label: 'Metrics', href: '#metrics', group: 'Proof' },
  { id: 'ontology', label: 'System Map', href: '#ontology', group: 'Proof' },
  { id: 'roi', label: 'ROI Calculator', href: '#roi', group: 'Proof', shortcut: 'R' },
  { id: 'book', label: 'Book a Call', href: '#book', group: 'Navigate', shortcut: 'B' },
]
EOF

cat > src/data/telemetry.ts << 'EOF'
import type { Incident } from '@/types/ui'

export interface RegionNode {
  id: string
  label: string
  lat: number
  lng: number
  load: number
}

export const REGION_NODES: RegionNode[] = [
  { id: 'iad', label: 'us-east-1', lat: 38.95, lng: -77.45, load: 0.82 },
  { id: 'sfo', label: 'us-west-1', lat: 37.77, lng: -122.42, load: 0.61 },
  { id: 'fra', label: 'eu-central', lat: 50.11, lng: 8.68, load: 0.74 },
  { id: 'sin', label: 'ap-south-1', lat: 1.35, lng: 103.82, load: 0.55 },
  { id: 'syd', label: 'ap-southeast', lat: -33.87, lng: 151.21, load: 0.42 },
  { id: 'gru', label: 'sa-east-1', lat: -23.55, lng: -46.63, load: 0.31 },
]

export const SEED_INCIDENTS: Incident[] = [
  { id: 'inc-0', severity: 'info', region: 'iad', message: 'Canary deploy complete — v3.14.2', startedAt: 0 },
]

export function deriveLatency(rps: number, a = 18, b = 22, c = 9000): number {
  return Math.round(a + b * Math.log(1 + rps / c))
}
EOF

cat > src/data/services.ts << 'EOF'
export interface ServiceCell {
  id: string
  span: 'lg' | 'md' | 'sm'
  eyebrow: string
  title: string
  body: string
  spec: { execMs: number; bundleKb: number; lhScore: number }
  code?: string
  kind?: 'default' | 'node-flow' | 'terminal'
}

export const SERVICE_CELLS: ServiceCell[] = [
  {
    id: 'engineering',
    span: 'lg',
    eyebrow: 'Pillar 01',
    title: 'Engineering & Upgrades',
    body: 'Next.js migrations, bespoke MVPs, and legacy modernization with zero-downtime cutovers.',
    spec: { execMs: 42, bundleKb: 87, lhScore: 99 },
    code: `export async function upgrade(input: LegacyApp) {\n  const plan = await analyze(input)\n  return migrate(plan, { strategy: 'zero-downtime' })\n}`,
  },
  {
    id: 'dashboards',
    span: 'md',
    eyebrow: 'Pillar 02',
    title: 'Dashboards & Automation',
    body: 'Typed API pipelines and bespoke data surfaces that surface the signal, not the noise.',
    spec: { execMs: 38, bundleKb: 64, lhScore: 100 },
    code: `const pipe = createPipeline<Event>()\n  .source(kafka('events'))\n  .map(enrich)\n  .sink(warehouse)`,
  },
  {
    id: 'growth',
    span: 'md',
    eyebrow: 'Pillar 03',
    title: 'Growth & Technical SEO',
    body: 'Edge-rendered, Core-Web-Vitals-clean architecture that converts as fast as it loads.',
    spec: { execMs: 29, bundleKb: 52, lhScore: 100 },
    code: `export const metadata = buildMetadata({\n  title: 'Aurexis',\n  og: true,\n})`,
  },
  {
    id: 'node-flow',
    span: 'md',
    eyebrow: 'Runtime',
    title: 'API traffic flow',
    body: 'Live request path across four processing stages.',
    spec: { execMs: 8, bundleKb: 0, lhScore: 100 },
    kind: 'node-flow',
  },
  {
    id: 'terminal',
    span: 'lg',
    eyebrow: 'Observability',
    title: 'Edge logs, live',
    body: 'Streaming operational diagnostic log.',
    spec: { execMs: 3, bundleKb: 0, lhScore: 100 },
    kind: 'terminal',
  },
]
EOF

cat > src/data/carousel.ts << 'EOF'
import type { SceneId } from '@/lib/iso-scenes'

export interface CarouselSlide {
  id: string
  eyebrow: string
  title: string
  body: string
  bullets: string[]
  scene: SceneId
  accent: string
  code: string
}

export const CAROUSEL_SLIDES: CarouselSlide[] = [
  {
    id: 'engineering',
    eyebrow: 'Pillar 01',
    title: 'Engineering & Upgrades',
    body: 'Legacy systems replaced with typed, tested, edge-ready architecture — without a rewrite from scratch.',
    bullets: ['Incremental strangler-fig migration', 'Zero-downtime cutover', 'Typed end-to-end'],
    scene: 'stack',
    accent: '#ff5b1f',
    code: `export const route = createEdgeRoute({\n  cache: 'swr-300',\n  validate: schema,\n})`,
  },
  {
    id: 'dashboards',
    eyebrow: 'Pillar 02',
    title: 'Dashboards & Automation',
    body: 'Event-driven pipelines and bespoke data surfaces that surface signal — not another chart no one reads.',
    bullets: ['Streaming & batch in one model', 'Columnar transforms', 'Composable widgets'],
    scene: 'pipeline',
    accent: '#35e6f2',
    code: `pipe.source(kafka('events'))\n  .map(enrich)\n  .sink(warehouse)`,
  },
  {
    id: 'growth',
    eyebrow: 'Pillar 03',
    title: 'Growth & Technical SEO',
    body: 'Core-Web-Vitals-clean, edge-rendered pages that convert as fast as they load.',
    bullets: ['Streaming RSC', 'Persisted queries', 'Edge-cached HTML'],
    scene: 'ramp',
    accent: '#22c55e',
    code: `export const dynamic = 'force-static'\nexport const revalidate = 60`,
  },
  {
    id: 'platform',
    eyebrow: 'Platform',
    title: 'Multi-region edge runtime',
    body: 'Six continents, one deploy. Failover that no customer ever notices.',
    bullets: ['99.99% SLA', 'Regional failover', 'Deterministic cold starts'],
    scene: 'mesh',
    accent: '#a78bfa',
    code: `edge.deploy({\n  regions: ['iad','sfo','fra','sin','syd','gru'],\n})`,
  },
  {
    id: 'observe',
    eyebrow: 'Observability',
    title: 'Telemetry you can read at 3am',
    body: 'Traces, metrics, and logs unified at the edge — sampled, cardinality-bounded, alertable.',
    bullets: ['Head + tail sampling', 'OTLP-native', 'SLO as code'],
    scene: 'lens',
    accent: '#f5a623',
    code: `otel.start({ sample: 'head+tail', slo: 'p95<45ms' })`,
  },
]
EOF

cat > src/data/ontology.ts << 'EOF'
import type { OntologyNode, OntologyEdge, NodeKind } from '@/types/ontology'

export const KIND_COLOR: Record<NodeKind, string> = {
  source: '#f5a623',
  ingest: '#ff5b1f',
  compute: '#35e6f2',
  api: '#a78bfa',
  render: '#22c55e',
  observe: '#8a8a94',
}

export const ONTOLOGY_NODES: OntologyNode[] = [
  {
    id: 'legacy-db',
    label: 'Legacy Database / Core',
    short: 'Legacy DB',
    kind: 'source',
    summary: 'Monolithic RDBMS. Contended reads, untyped access layer.',
    spec: {
      ENGINE: 'PostgreSQL 11 (EOL)',
      CONNECTIONS: '480 / 500 pooled',
      READ_P99_MS: '980',
      REPLICATION_LAG_MS: '12,400',
      SCHEMA_VERSION: 'v3.1.7',
    },
  },
  {
    id: 'edge-ingest',
    label: 'Aurexis Ingestion Edge',
    short: 'Ingestion',
    kind: 'ingest',
    summary: 'Typed edge ingest with schema validation and dedupe.',
    spec: {
      RUNTIME: 'edge-isolate / wasm',
      REGIONS: '6',
      THROUGHPUT_RPS: '12,480',
      VALIDATION: 'zod v3.23 (compiled)',
      DEDUPE: 'bloom-64k @ 0.001 FPR',
      P95_INGEST_MS: '3',
    },
  },
  {
    id: 'transform-cache',
    label: 'Transform & Cache Pipeline',
    short: 'Transform',
    kind: 'compute',
    summary: 'Columnar transforms + tiered cache with stale-while-revalidate.',
    spec: {
      CACHE_TIERS: 'L1 mem · L2 redis · L3 r2',
      CACHE_HIT_RATIO: '99.4%',
      TRANSFORM: 'SIMD columnar',
      SWR_WINDOW_S: '300',
      INVALIDATION: 'event-sourced',
      COLD_START_MS: '9',
    },
  },
  {
    id: 'edge-api',
    label: 'GraphQL / REST Edge API',
    short: 'Edge API',
    kind: 'api',
    summary: 'Unified API surface, persisted queries, no over-fetch.',
    spec: {
      PROTOCOL: 'GraphQL-over-HTTP + REST',
      PERSISTED_QUERIES: 'enabled',
      LATENCY_P95_MS: '12',
      RATE_LIMIT: 'token-bucket',
      AUTH: 'jwt + rotating keys',
      SCHEMA_STITCHING: 'federated v2',
    },
  },
  {
    id: 'next-ssr',
    label: 'Next.js SSR Frontend',
    short: 'Next.js',
    kind: 'render',
    summary: 'Streaming RSC shell, partial hydration, edge-rendered.',
    spec: {
      RUNTIME: 'Next.js 14 · App Router',
      RENDERING: 'streaming RSC',
      TTFB_P95_MS: '38',
      LCP_P75_MS: '1240',
      CLS: '0.02',
      INP_P75_MS: '88',
    },
  },
  {
    id: 'telemetry',
    label: 'Analytics & Telemetry',
    short: 'Telemetry',
    kind: 'observe',
    summary: 'Trace, metric, log — sampled at the edge, no client agents.',
    spec: {
      PIPELINE: 'OTLP → ClickHouse',
      SAMPLING: 'head 5% + tail error',
      RETENTION_DAYS: '45',
      TRACE_CARDINALITY: 'bounded',
      ALERT_SLO: '99.95% / 30d',
      DASHBOARDS: 'as-code',
    },
  },
]

export const ONTOLOGY_EDGES: OntologyEdge[] = [
  { from: 'legacy-db', to: 'edge-ingest', load: 0.9 },
  { from: 'edge-ingest', to: 'transform-cache', load: 0.9 },
  { from: 'transform-cache', to: 'edge-api', load: 0.85 },
  { from: 'edge-api', to: 'next-ssr', load: 0.8 },
  { from: 'edge-ingest', to: 'telemetry', load: 0.25 },
  { from: 'transform-cache', to: 'telemetry', load: 0.35 },
  { from: 'edge-api', to: 'telemetry', load: 0.5 },
  { from: 'next-ssr', to: 'telemetry', load: 0.4 },
]
EOF

cat > src/data/pipeline.ts << 'EOF'
export interface PipelinePhase {
  id: string
  label: string
  startMs: number
  durationMs: number
  status: 'ok' | 'warn' | 'error'
  branch: string
}

export interface PipelineSpec {
  id: 'legacy' | 'aurexis'
  label: string
  sublabel: string
  totalMs: number
  phases: PipelinePhase[]
  accent: string
}

export const LEGACY_PIPELINE: PipelineSpec = {
  id: 'legacy',
  label: 'Legacy Serial',
  sublabel: 'Blocking · cold-start · N+1',
  accent: '#ef4444',
  totalMs: 1430,
  phases: [
    { id: 'cold-boot', label: 'Cold boot', startMs: 0, durationMs: 210, status: 'warn', branch: 'a' },
    { id: 'n1-query', label: 'N+1 query fan-out', startMs: 210, durationMs: 380, status: 'error', branch: 'a' },
    { id: 'blocking-render', label: 'Blocking server render', startMs: 590, durationMs: 420, status: 'warn', branch: 'a' },
    { id: 'hydration-drift', label: 'Hydration mismatch', startMs: 1010, durationMs: 180, status: 'error', branch: 'a' },
    { id: 'client-refetch', label: 'Client re-fetch', startMs: 1190, durationMs: 240, status: 'warn', branch: 'a' },
  ],
}

export const AUREXIS_PIPELINE: PipelineSpec = {
  id: 'aurexis',
  label: 'Aurexis Edge',
  sublabel: 'Parallel · cache-first · streaming',
  accent: '#35e6f2',
  totalMs: 42,
  phases: [
    { id: 'handshake', label: 'Edge handshake', startMs: 0, durationMs: 8, status: 'ok', branch: 'a' },
    { id: 'cache-lookup', label: 'L1→L3 cache', startMs: 8, durationMs: 4, status: 'ok', branch: 'b' },
    { id: 'api-parallel', label: 'Edge API (par.)', startMs: 8, durationMs: 11, status: 'ok', branch: 'c' },
    { id: 'telemetry-par', label: 'Telemetry emit', startMs: 8, durationMs: 6, status: 'ok', branch: 'd' },
    { id: 'stream-ssr', label: 'Stream SSR', startMs: 19, durationMs: 14, status: 'ok', branch: 'a' },
    { id: 'hydrate', label: 'Hydrate (partial)', startMs: 33, durationMs: 9, status: 'ok', branch: 'a' },
  ],
}
EOF

echo ""
echo "==> Done. Files written:"
find src/types src/store src/hooks src/lib src/data -type f | sort
echo ""
echo "==> Total files: $(find src/types src/store src/hooks src/lib src/data -type f | wc -l)"
echo ""
echo "==> Next: commit this, then continue with setup-03 and setup-04."
