#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# aurexis-full-build.sh — Part 3 of 3
# Velocity · Ontology · Industrial · Proof · App
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

mkdir -p src/{app,styles}
mkdir -p src/components/{velocity,ontology,industrial,proof}

# ── Velocity components (2) ─────────────────────────────────────

cat > src/components/velocity/isometric-carousel.tsx << 'AUREXIS_EOF'
'use client';
import { useEffect, useRef, useState, useCallback } from 'react';
import { carouselSlides } from '@/data/carousel';
import { IsometricIllustration } from '@/components/velocity/isometric-illustration';
import { useUIStore } from '@/store/use-ui-store';
import { useReducedMotion } from '@/hooks/use-reduced-motion';
import { useAudioStore } from '@/store/use-audio-store';
import { playClick } from '@/lib/audio-engine';
import { Keycap } from '@/components/ui/keycap';
import { cn } from '@/lib/utils';
export function IsometricCarousel() {
  const { carouselIndex, setCarouselIndex } = useUIStore();
  const reduced = useReducedMotion();
  const { muted, unlock } = useAudioStore();
  const scrollRef = useRef<HTMLDivElement>(null);
  const slideRefs = useRef<(HTMLDivElement | null)[]>([]);
  const scrollToSlide = useCallback((index: number) => {
    const el = slideRefs.current[index];
    if (el && scrollRef.current) scrollRef.current.scrollTo({ left: el.offsetLeft, behavior: reduced ? 'auto' : 'smooth' });
    setCarouselIndex(index);
  }, [setCarouselIndex, reduced]);
  useEffect(() => {
    const observer = new IntersectionObserver((entries) => {
      for (const entry of entries) { if (entry.isIntersecting && entry.intersectionRatio > 0.5) { const index = Number(entry.target.getAttribute('data-index')); setCarouselIndex(index); } }
    }, { root: scrollRef.current, threshold: 0.5 });
    slideRefs.current.forEach((el) => { if (el) observer.observe(el); });
    return () => observer.disconnect();
  }, [setCarouselIndex]);
  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (e.key === 'ArrowRight') { e.preventDefault(); const next = Math.min(carouselIndex + 1, carouselSlides.length - 1); scrollToSlide(next); if (!muted) { unlock(); playClick(); } }
    else if (e.key === 'ArrowLeft') { e.preventDefault(); const prev = Math.max(carouselIndex - 1, 0); scrollToSlide(prev); if (!muted) { unlock(); playClick(); } }
  }, [carouselIndex, scrollToSlide, muted, unlock]);
  return (
    <section id="platform" className="py-20 md:py-28" aria-label="Platform capabilities">
      <div className="mx-auto max-w-7xl px-4 md:px-6">
        <div className="mb-8 flex items-end justify-between">
          <div className="flex flex-col gap-2"><span className="font-mono text-[0.6875rem] uppercase tracking-[0.2em] text-bronze">Platform</span><h2 className="text-headline text-fg">Isometric capability view</h2></div>
          <div className="hidden md:flex items-center gap-2"><Keycap>←</Keycap><Keycap>→</Keycap><span className="text-xs text-dim">navigate</span></div>
        </div>
        <div ref={scrollRef} onKeyDown={handleKeyDown} tabIndex={0} role="region" aria-label="Platform capabilities carousel" className="flex snap-x snap-mandatory gap-4 overflow-x-auto pb-4 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-bronze/40 rounded-lg">
          {carouselSlides.map((slide, index) => (
            <div key={slide.id} ref={(el) => { slideRefs.current[index] = el; }} data-index={index} className="snap-center shrink-0 w-[85%] md:w-[60%] lg:w-[45%]">
              <div className={cn('flex h-full flex-col gap-4 rounded-xl border border-border bg-surface p-6', carouselIndex === index && 'border-bronze/40')}>
                <IsometricIllustration sceneId={slide.id} className="h-40 w-full" />
                <span className="font-mono text-[0.6875rem] uppercase tracking-[0.2em] text-bronze">{slide.eyebrow}</span>
                <h3 className="text-lg font-semibold text-fg">{slide.title}</h3>
                <p className="text-sm text-muted">{slide.body}</p>
                <ul className="space-y-1.5">{slide.bullets.map((bullet) => (<li key={bullet} className="flex items-start gap-2 text-xs text-dim"><span className="mt-1 h-1 w-1 shrink-0 rounded-full bg-bronze" />{bullet}</li>))}</ul>
              </div>
            </div>
          ))}
        </div>
        <div className="mt-4 flex items-center justify-between">
          <div className="flex gap-1.5">{carouselSlides.map((_, i) => (<button key={i} type="button" onClick={() => scrollToSlide(i)} aria-label={`Go to slide ${i + 1}`} className={cn('h-1.5 rounded-full transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-bronze/40', carouselIndex === i ? 'w-6 bg-bronze' : 'w-1.5 bg-border hover:bg-bronze/40')} />))}</div>
        </div>
      </div>
    </section>
  );
}
AUREXIS_EOF

cat > src/components/velocity/isometric-illustration.tsx << 'AUREXIS_EOF'
'use client';
import { useMemo } from 'react';
import { engineeringScene, dashboardsScene, growthScene, platformScene, observabilityScene, type SceneCommand } from '@/lib/iso-scenes';
import { cn } from '@/lib/utils';
type IsometricIllustrationProps = { sceneId: string; className?: string };
function sceneForId(id: string): SceneCommand[] {
  const cellSize = 40;
  switch (id) { case 'engineering': return engineeringScene(cellSize); case 'dashboards': return dashboardsScene(cellSize); case 'growth': return growthScene(cellSize); case 'platform': return platformScene(cellSize); case 'observability': return observabilityScene(cellSize); default: return engineeringScene(cellSize); }
}
function commandToSvg(cmd: SceneCommand, key: number): React.ReactNode {
  switch (cmd.type) {
    case 'polygon': return <polygon key={key} points={cmd.points.map((p) => `${p.x},${p.y}`).join(' ')} fill={cmd.fill} stroke={cmd.stroke} strokeWidth={cmd.strokeWidth} opacity={cmd.opacity ?? 1} />;
    case 'line': return <line key={key} x1={cmd.from.x} y1={cmd.from.y} x2={cmd.to.x} y2={cmd.to.y} stroke={cmd.stroke} strokeWidth={cmd.strokeWidth} opacity={cmd.opacity ?? 1} />;
    case 'circle': return <circle key={key} cx={cmd.cx} cy={cmd.cy} r={cmd.r} fill={cmd.fill} stroke={cmd.stroke} strokeWidth={cmd.strokeWidth} />;
    case 'polyline': return <polyline key={key} points={cmd.points.map((p) => `${p.x},${p.y}`).join(' ')} stroke={cmd.stroke} strokeWidth={cmd.strokeWidth} fill={cmd.fill} opacity={cmd.opacity ?? 1} />;
    default: return null;
  }
}
export function IsometricIllustration({ sceneId, className }: IsometricIllustrationProps) {
  const commands = useMemo(() => sceneForId(sceneId), [sceneId]);
  return (<div className={cn('flex items-center justify-center rounded-lg border border-border bg-bg/50', className)}><svg viewBox="-80 -60 160 120" className="h-full w-full" role="img" aria-label={`Isometric illustration of ${sceneId}`}>{commands.map((cmd, i) => commandToSvg(cmd, i))}</svg></div>);
}
AUREXIS_EOF

# ── Ontology components (6) ────────────────────────────────────

cat > src/components/ontology/ontology-section.tsx << 'AUREXIS_EOF'
'use client';
import { motion } from 'framer-motion';
import { OntologyGraph } from '@/components/ontology/ontology-graph';
import { PipelineLineage } from '@/components/ontology/pipeline-lineage';
import { fadeUpVariants, staggerContainer } from '@/components/shared/motion-variants';
import { useReducedMotion } from '@/hooks/use-reduced-motion';
export function OntologySection() {
  const reduced = useReducedMotion();
  return (
    <section id="ontology" className="py-20 md:py-28" aria-label="System ontology">
      <div className="mx-auto max-w-7xl px-4 md:px-6">
        <motion.div variants={reduced ? undefined : staggerContainer} initial="hidden" whileInView="visible" viewport={{ once: true, margin: '-80px' }} className="mb-10 flex flex-col gap-2">
          <motion.span variants={reduced ? undefined : fadeUpVariants} className="font-mono text-[0.6875rem] uppercase tracking-[0.2em] text-bronze">System Topology</motion.span>
          <motion.h2 variants={reduced ? undefined : fadeUpVariants} className="text-headline text-fg">Every component, visible and traceable.</motion.h2>
        </motion.div>
        <div className="flex flex-col gap-6"><OntologyGraph /><PipelineLineage /></div>
      </div>
    </section>
  );
}
AUREXIS_EOF

cat > src/components/ontology/ontology-graph.tsx << 'AUREXIS_EOF'
'use client';
import { useState, useMemo, useCallback } from 'react';
import { OntologyNode } from '@/components/ontology/ontology-node';
import { OntologyEdge } from '@/components/ontology/ontology-edge';
import { OntologySidePanel } from '@/components/ontology/ontology-side-panel';
import { ontologyGraph } from '@/data/ontology';
import { layoutOntology } from '@/lib/ontology-layout';
import { useUIStore } from '@/store/use-ui-store';
import { useReducedMotion } from '@/hooks/use-reduced-motion';
export function OntologyGraph() {
  const [hoveredNode, setHoveredNode] = useState<string | null>(null);
  const { inspectorOpenId, toggleInspector } = useUIStore();
  const reduced = useReducedMotion();
  const { nodes, edges } = useMemo(() => layoutOntology(ontologyGraph, 200, 160, 120), []);
  const connectedEdges = useMemo(() => {
    if (!hoveredNode) return new Set<string>();
    const set = new Set<string>();
    for (const edge of edges) { if (edge.from === hoveredNode || edge.to === hoveredNode) set.add(`${edge.from}-${edge.to}`); }
    return set;
  }, [hoveredNode, edges]);
  const connectedNodes = useMemo(() => {
    if (!hoveredNode) return null;
    const set = new Set<string>([hoveredNode]);
    for (const edge of edges) { if (edge.from === hoveredNode) set.add(edge.to); if (edge.to === hoveredNode) set.add(edge.from); }
    return set;
  }, [hoveredNode, edges]);
  const handleNodeClick = useCallback((id: string) => toggleInspector(id), [toggleInspector]);
  return (
    <div className="relative rounded-xl border border-border bg-surface p-4">
      <div className="mb-3 flex items-center justify-between">
        <span className="font-mono text-[0.6875rem] uppercase tracking-[0.2em] text-bronze">Ontology Graph</span>
        <span className="text-xs text-dim">{ontologyGraph.nodes.length} nodes · {ontologyGraph.edges.length} edges</span>
      </div>
      <div className="relative">
        <svg viewBox="0 0 400 320" className="w-full" role="img" aria-label="System ontology dependency graph">
          {edges.map((edge) => { const key = `${edge.from}-${edge.to}`; const isActive = connectedEdges.has(key); const isDimmed = hoveredNode !== null && !isActive; return <OntologyEdge key={key} edge={edge} active={isActive} dimmed={isDimmed} reduced={reduced} />; })}
          {nodes.map((node) => { const nodeData = ontologyGraph.nodes.find((n) => n.id === node.id); if (!nodeData) return null; const isDimmed = connectedNodes !== null && !connectedNodes.has(node.id); const isHovered = hoveredNode === node.id; return <OntologyNode key={node.id} node={node} data={nodeData} hovered={isHovered} dimmed={isDimmed} onHover={setHoveredNode} onClick={handleNodeClick} />; })}
        </svg>
      </div>
      <OntologySidePanel />
    </div>
  );
}
AUREXIS_EOF

cat > src/components/ontology/ontology-node.tsx << 'AUREXIS_EOF'
'use client';
import { motion } from 'framer-motion';
import type { LaidOutNode } from '@/lib/ontology-layout';
import type { OntologyNodeData } from '@/types/ontology';
import { useReducedMotion } from '@/hooks/use-reduced-motion';
type OntologyNodeProps = { node: LaidOutNode; data: OntologyNodeData; hovered: boolean; dimmed: boolean; onHover: (id: string | null) => void; onClick: (id: string) => void };
const typeColors: Record<OntologyNodeData['type'], string> = { service: '#87776C', database: '#B8935F', cache: '#87776C', queue: '#87776C', gateway: '#B8935F', worker: '#87776C' };
export function OntologyNode({ node, data, hovered, dimmed, onHover, onClick }: OntologyNodeProps) {
  const reduced = useReducedMotion();
  const color = typeColors[data.type];
  return (
    <motion.g onMouseEnter={() => onHover(node.id)} onMouseLeave={() => onHover(null)} onClick={() => onClick(node.id)} role="button" tabIndex={0} aria-label={`${data.label}: ${data.spec.summary}`} onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); onClick(node.id); } }} initial={false} animate={{ opacity: dimmed ? 0.3 : 1, scale: hovered ? 1.05 : 1 }} transition={reduced ? { duration: 0 } : { type: 'spring', stiffness: 400, damping: 30 }} style={{ cursor: 'pointer', transformOrigin: `${node.x}px ${node.y}px` }} className="focus-visible:outline-none">
      <circle cx={node.x} cy={node.y} r="18" fill="#1A1A1A" stroke={hovered ? color : '#626269'} strokeWidth={hovered ? 2 : 1} />
      <circle cx={node.x} cy={node.y} r="4" fill={color} />
      <text x={node.x} y={node.y + 32} textAnchor="middle" fontSize="8" className="font-mono" fill={hovered ? '#F5F5F5' : '#99999F'}>{data.label}</text>
    </motion.g>
  );
}
AUREXIS_EOF

cat > src/components/ontology/ontology-edge.tsx << 'AUREXIS_EOF'
'use client';
import type { LaidOutEdge } from '@/lib/ontology-layout';
import type { Point } from '@/lib/bezier';
export function OntologyEdge({ edge, active, dimmed, reduced }: { edge: LaidOutEdge; active: boolean; dimmed: boolean; reduced: boolean }) {
  const from: Point = { x: edge.fromPoint.x, y: edge.fromPoint.y };
  const to: Point = { x: edge.toPoint.x, y: edge.toPoint.y };
  const midX = (from.x + to.x) / 2; const midY = (from.y + to.y) / 2 - 15;
  const stroke = active ? '#87776C' : '#626269';
  const opacity = dimmed ? 0.15 : active ? 0.8 : 0.35;
  const strokeWidth = active ? 1.5 : 1;
  return (
    <g>
      <path d={`M ${from.x} ${from.y} Q ${midX} ${midY}, ${to.x} ${to.y}`} fill="none" stroke={stroke} strokeWidth={strokeWidth} opacity={opacity} />
      {active && !reduced && (<circle r="2" fill="#87776C" opacity={opacity}><animateMotion dur="1.5s" repeatCount="indefinite" path={`M ${from.x} ${from.y} Q ${midX} ${midY}, ${to.x} ${to.y}`} /></circle>)}
    </g>
  );
}
AUREXIS_EOF

cat > src/components/ontology/ontology-side-panel.tsx << 'AUREXIS_EOF'
'use client';
import { motion, AnimatePresence } from 'framer-motion';
import { X } from 'lucide-react';
import { useUIStore } from '@/store/use-ui-store';
import { useModeStore } from '@/store/use-mode-store';
import { ontologyGraph } from '@/data/ontology';
import { slideInRightVariants, spring } from '@/components/shared/motion-variants';
import { useReducedMotion } from '@/hooks/use-reduced-motion';
import { cn } from '@/lib/utils';
export function OntologySidePanel() {
  const { inspectorOpenId, toggleInspector } = useUIStore();
  const { mode } = useModeStore();
  const reduced = useReducedMotion();
  const node = ontologyGraph.nodes.find((n) => n.id === inspectorOpenId);
  return (
    <AnimatePresence>
      {node && (
        <motion.div variants={reduced ? undefined : slideInRightVariants} initial="hidden" animate="visible" exit={{ opacity: 0, x: 24, transition: { duration: 0.2 } }} transition={spring} className="absolute right-0 top-0 h-full w-64 rounded-xl border border-border bg-bg/95 p-4">
          <div className="mb-3 flex items-center justify-between">
            <span className="font-mono text-[0.6875rem] uppercase tracking-[0.2em] text-bronze">{node.type}</span>
            <button type="button" onClick={() => toggleInspector(node.id)} className="rounded-md p-1 text-dim hover:text-fg focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-bronze/40" aria-label="Close panel"><X className="h-3.5 w-3.5" /></button>
          </div>
          <h3 className="text-sm font-semibold text-fg">{node.label}</h3>
          {mode === 'executive' ? (<p className="mt-2 text-xs text-muted">{node.spec.summary}</p>) : (<table className="mt-3 w-full text-xs"><tbody>{node.spec.rows.map((row, i) => (<tr key={i} className={cn(i % 2 === 0 ? 'bg-surface/50' : '')}><td className="px-2 py-1 font-mono text-dim">{row.label}</td><td className="px-2 py-1 font-mono text-fg">{row.value}</td></tr>))}</tbody></table>)}
        </motion.div>
      )}
    </AnimatePresence>
  );
}
AUREXIS_EOF

cat > src/components/ontology/pipeline-lineage.tsx << 'AUREXIS_EOF'
'use client';
import { useState, useCallback } from 'react';
import { Play } from 'lucide-react';
import { legacyPipeline, aurexisPipeline, speedupFactor } from '@/data/pipeline';
import { useReducedMotion } from '@/hooks/use-reduced-motion';
import { cn } from '@/lib/utils';
export function PipelineLineage() {
  const [running, setRunning] = useState(false);
  const [progress, setProgress] = useState(0);
  const reduced = useReducedMotion();
  const speedup = speedupFactor(legacyPipeline.totalMs, aurexisPipeline.totalMs);
  const runTrace = useCallback(() => {
    setRunning(true); setProgress(0);
    if (reduced) { setProgress(1); setRunning(false); return; }
    const duration = 2000; const start = performance.now();
    const tick = (now: number) => { const elapsed = now - start; const t = Math.min(elapsed / duration, 1); setProgress(t); if (t < 1) requestAnimationFrame(tick); else setRunning(false); };
    requestAnimationFrame(tick);
  }, [reduced]);
  const maxMs = Math.max(legacyPipeline.totalMs, aurexisPipeline.totalMs);
  return (
    <div className="rounded-xl border border-border bg-surface p-4">
      <div className="mb-4 flex items-center justify-between">
        <div className="flex flex-col gap-1"><span className="font-mono text-[0.6875rem] uppercase tracking-[0.2em] text-bronze">Pipeline Lineage Trace</span><span className="text-xs text-dim">Legacy {legacyPipeline.totalMs}ms vs Aurexis {aurexisPipeline.totalMs}ms</span></div>
        <button type="button" onClick={runTrace} disabled={running} className="inline-flex items-center gap-1.5 rounded-lg border border-bronze/30 bg-bronze/10 px-3 py-1.5 text-sm font-medium text-bronze transition-colors hover:bg-bronze/20 disabled:opacity-40 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-bronze/40"><Play className="h-3.5 w-3.5" aria-hidden="true" />Run trace</button>
      </div>
      <div className="flex flex-col gap-6">
        {[{ pipeline: legacyPipeline, label: 'Legacy', color: '#E5484D' }, { pipeline: aurexisPipeline, label: 'Aurexis', color: '#87776C' }].map(({ pipeline, label, color }) => (
          <div key={pipeline.id} className="flex flex-col gap-2">
            <div className="flex items-center justify-between"><span className="text-xs font-medium text-fg">{label}</span><span className="font-mono text-xs text-dim">{pipeline.totalMs}ms total</span></div>
            <div className="relative h-8 overflow-hidden rounded-lg border border-border bg-bg/50">
              {pipeline.phases.map((phase) => {
                const phaseWidth = (phase.durationMs / maxMs) * 100 * progress;
                const phaseOffset = (phase.startMs / maxMs) * 100 * progress;
                return (<div key={phase.id} className={cn('absolute top-0 h-full flex items-center justify-center border-r border-bg/50 overflow-hidden')} style={{ left: `${phaseOffset}%`, width: `${phaseWidth}%`, backgroundColor: color, opacity: 0.7, transition: reduced ? 'none' : 'width 0.05s linear, left 0.05s linear' }}>{phaseWidth > 8 && <span className="truncate px-1 text-[0.625rem] font-mono text-bg">{phase.label}</span>}</div>);
              })}
            </div>
          </div>
        ))}
      </div>
      <div className="mt-4 flex items-center justify-between border-t border-border pt-3"><span className="text-xs text-muted">Speedup factor</span><span className="font-mono text-sm font-semibold text-bronze">{speedup.toFixed(1)}x</span></div>
    </div>
  );
}
AUREXIS_EOF

# ── Industrial components (4) ──────────────────────────────────

cat > src/components/industrial/rotary-knob.tsx << 'AUREXIS_EOF'
'use client';
import { useKnobDrag } from '@/hooks/use-knob-drag';
import { useAudioStore } from '@/store/use-audio-store';
import { playClick } from '@/lib/audio-engine';
import { useReducedMotion } from '@/hooks/use-reduced-motion';
import { cn } from '@/lib/utils';
type RotaryKnobProps = { label: string; min: number; max: number; step: number; initialValue: number; unit?: string; onChange: (value: number) => void; className?: string };
export function RotaryKnob({ label, min, max, step, initialValue, unit, onChange, className }: RotaryKnobProps) {
  const { muted, unlock } = useAudioStore();
  const reduced = useReducedMotion();
  const { angle, value, onPointerDown, onPointerMove, onPointerUp, onKeyDown } = useKnobDrag({ min, max, step, initialValue, onChange: (v) => { if (!muted) { unlock(); playClick(); } onChange(v); } });
  const radius = 28; const cx = 36; const cy = 36;
  return (
    <div className={cn('flex flex-col items-center gap-2', className)}>
      <div className="relative">
        <svg width="72" height="72" viewBox="0 0 72 72">
          <circle cx={cx} cy={cy} r={radius} fill="#1A1A1A" stroke="#626269" strokeWidth="1" />
          <circle cx={cx} cy={cy} r={radius - 4} fill="none" stroke="#090909" strokeWidth="2" />
          {Array.from({ length: 11 }).map((_, i) => {
            const tickAngle = -135 + (i / 10) * 270;
            const rad = (tickAngle * Math.PI) / 180;
            const x1 = cx + Math.cos(rad - Math.PI / 2) * (radius - 2); const y1 = cy + Math.sin(rad - Math.PI / 2) * (radius - 2);
            const x2 = cx + Math.cos(rad - Math.PI / 2) * (radius - 6); const y2 = cy + Math.sin(rad - Math.PI / 2) * (radius - 6);
            const isActive = tickAngle <= angle;
            return <line key={i} x1={x1} y1={y1} x2={x2} y2={y2} stroke={isActive ? '#87776C' : '#626269'} strokeWidth="1" opacity={isActive ? 0.8 : 0.3} />;
          })}
          <g transform={`rotate(${angle} ${cx} ${cy})`} onPointerDown={onPointerDown} onPointerMove={onPointerMove} onPointerUp={onPointerUp} onKeyDown={onKeyDown} role="slider" tabIndex={0} aria-valuenow={value} aria-valuemin={min} aria-valuemax={max} aria-label={label} className="cursor-grab active:cursor-grabbing focus-visible:outline-none" style={{ touchAction: 'none' }}>
            <circle cx={cx} cy={cy} r={radius - 8} fill="#222222" stroke="#87776C" strokeWidth="0.5" />
            <line x1={cx} y1={cy - (radius - 10)} x2={cx} y2={cy - 4} stroke="#87776C" strokeWidth="2" strokeLinecap="round" />
            <circle cx={cx} cy={cy} r="2" fill="#87776C" />
          </g>
        </svg>
      </div>
      <div className="flex flex-col items-center gap-0.5"><span className="font-mono text-[0.6875rem] uppercase tracking-[0.2em] text-dim">{label}</span><span className="font-mono text-sm font-medium text-fg">{value.toFixed(0)}{unit}</span></div>
    </div>
  );
}
AUREXIS_EOF

cat > src/components/industrial/mechanical-toggle.tsx << 'AUREXIS_EOF'
'use client';
import { motion } from 'framer-motion';
import { useAudioStore } from '@/store/use-audio-store';
import { playToggle } from '@/lib/audio-engine';
import { useReducedMotion } from '@/hooks/use-reduced-motion';
import { cn } from '@/lib/utils';
type MechanicalToggleProps = { label: string; checked: boolean; onChange: (checked: boolean) => void; className?: string };
export function MechanicalToggle({ label, checked, onChange, className }: MechanicalToggleProps) {
  const { muted, unlock } = useAudioStore();
  const reduced = useReducedMotion();
  const handleClick = () => { if (!muted) { unlock(); playToggle(); } onChange(!checked); };
  return (
    <div className={cn('flex items-center gap-3', className)}>
      <button type="button" role="switch" aria-checked={checked} aria-label={label} onClick={handleClick} className={cn('relative inline-flex h-7 w-12 items-center rounded-full border transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-bronze/40', checked ? 'border-bronze/40 bg-bronze/20' : 'border-border bg-surface')}>
        <motion.span className={cn('inline-block h-5 w-5 rounded-full', checked ? 'bg-bronze' : 'bg-dim')} animate={{ x: checked ? 24 : 2 }} transition={reduced ? { duration: 0 } : { type: 'spring', stiffness: 400, damping: 30 }} />
      </button>
      <span className="text-sm text-muted">{label}</span>
    </div>
  );
}
AUREXIS_EOF

cat > src/components/industrial/led-readout.tsx << 'AUREXIS_EOF'
'use client';
import { useMemo } from 'react';
import { textToDotMatrix, dotMatrixWidth } from '@/lib/dot-matrix-font';
import { cn } from '@/lib/utils';
type LedReadoutProps = { value: string; label?: string; className?: string; pxSize?: number; gapPx?: number };
export function LedReadout({ value, label, className, pxSize = 2, gapPx = 1 }: LedReadoutProps) {
  const chars = useMemo(() => textToDotMatrix(value), [value]);
  const charWidth = 5 * pxSize + gapPx;
  const width = value.length * charWidth - (value.length > 0 ? gapPx : 0);
  const height = 7 * pxSize + (gapPx > 0 ? 6 * gapPx : 0);
  return (
    <div className={cn('flex flex-col gap-1', className)}>
      {label && <span className="font-mono text-[0.6875rem] uppercase tracking-[0.2em] text-dim">{label}</span>}
      <svg width={Math.max(width, 1)} height={height} viewBox={`0 0 ${Math.max(width, 1)} ${height}`} className="overflow-visible" role="img" aria-label={`LED readout: ${value}`}>
        {chars.map((char, charIndex) => {
          const xOffset = charIndex * charWidth;
          return char.rows.map((row, rowIndex) => Array.from({ length: 5 }).map((_, colIndex) => {
            const bit = (row >> (4 - colIndex)) & 1;
            if (!bit) return null;
            const x = xOffset + colIndex * pxSize;
            const y = rowIndex * (pxSize + (gapPx > 0 ? gapPx : 0));
            return <rect key={`${charIndex}-${rowIndex}-${colIndex}`} x={x} y={y} width={pxSize} height={pxSize} rx={pxSize * 0.2} fill="#87776C" opacity={0.9} />;
          }));
        })}
      </svg>
    </div>
  );
}
AUREXIS_EOF

cat > src/components/industrial/blueprint-overlay.tsx << 'AUREXIS_EOF'
'use client';
import { useModeStore } from '@/store/use-mode-store';
import { cn } from '@/lib/utils';
type BlueprintOverlayProps = { specs: { label: string; value: string }[]; className?: string };
export function BlueprintOverlay({ specs, className }: BlueprintOverlayProps) {
  const { mode } = useModeStore();
  if (mode !== 'engineer') return null;
  return (<div className={cn('absolute inset-0 pointer-events-none rounded-xl', className)}><div className="absolute inset-0 rounded-xl border border-dashed border-bronze/15" />{specs.map((spec, i) => (<div key={spec.label} className="absolute font-mono text-[0.625rem] uppercase tracking-widest text-bronze/60" style={{ top: `${8 + i * 16}px`, left: '8px' }}><span className="text-dim">{spec.label}:</span> {spec.value}</div>))}</div>);
}
AUREXIS_EOF

# ── Proof components (3) ───────────────────────────────────────

cat > src/components/proof/before-after-slider.tsx << 'AUREXIS_EOF'
'use client';
import { useCallback, useEffect, useRef, useState } from 'react';
export function BeforeAfterSlider() {
  const [position, setPosition] = useState(50);
  const [dragging, setDragging] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);
  const snapPoints = [0, 25, 50, 75, 100];
  const snap = useCallback((pos: number) => { let closest = snapPoints[0]!; let minDist = Infinity; for (const point of snapPoints) { const dist = Math.abs(pos - point); if (dist < minDist) { minDist = dist; closest = point; } } return closest; }, []);
  const updateFromPointer = useCallback((clientX: number) => { const container = containerRef.current; if (!container) return; const rect = container.getBoundingClientRect(); const pct = ((clientX - rect.left) / rect.width) * 100; setPosition(Math.max(0, Math.min(100, pct))); }, []);
  useEffect(() => { if (!dragging) setPosition((prev) => snap(prev)); }, [dragging, snap]);
  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (e.key === 'ArrowLeft') { e.preventDefault(); setPosition((prev) => { const current = snap(prev); const idx = snapPoints.indexOf(current); return snapPoints[Math.max(0, idx - 1)] ?? 0; }); }
    else if (e.key === 'ArrowRight') { e.preventDefault(); setPosition((prev) => { const current = snap(prev); const idx = snapPoints.indexOf(current); return snapPoints[Math.min(snapPoints.length - 1, idx + 1)] ?? 100; }); }
  }, [snap]);
  return (
    <div className="rounded-xl border border-border bg-surface p-4">
      <div className="mb-3 flex items-center justify-between"><span className="font-mono text-[0.6875rem] uppercase tracking-[0.2em] text-bronze">Before / After</span><span className="text-xs text-dim">Drag to compare · snaps to 25%</span></div>
      <div ref={containerRef} className="relative h-48 overflow-hidden rounded-lg border border-border" onPointerDown={(e) => { setDragging(true); (e.target as HTMLElement).setPointerCapture(e.pointerId); updateFromPointer(e.clientX); }} onPointerMove={(e) => { if (dragging) updateFromPointer(e.clientX); }} onPointerUp={(e) => { setDragging(false); (e.target as HTMLElement).releasePointerCapture(e.pointerId); }}>
        <div className="absolute inset-0 flex">
          <div className="h-full bg-danger/5 border-r border-danger/20" style={{ width: `${position}%` }}>
            <div className="flex h-full flex-col justify-center p-4"><span className="font-mono text-[0.6875rem] uppercase tracking-widest text-danger/60">Legacy</span><div className="mt-2 space-y-1.5">{[0, 1, 2].map((i) => (<div key={i} className="h-3 rounded-sm bg-danger/15" style={{ width: `${60 + i * 10}%` }} />))}</div><span className="mt-2 font-mono text-xs text-danger/50">LCP: 2.8s</span></div>
          </div>
          <div className="h-full flex-1 bg-bronze/5">
            <div className="flex h-full flex-col justify-center p-4"><span className="font-mono text-[0.6875rem] uppercase tracking-widest text-bronze/80">Aurexis</span><div className="mt-2 space-y-1.5">{[0, 1, 2].map((i) => (<div key={i} className="h-3 rounded-sm bg-bronze/15" style={{ width: `${40 + i * 8}%` }} />))}</div><span className="mt-2 font-mono text-xs text-bronze">LCP: 0.9s</span></div>
          </div>
        </div>
        <div className="absolute top-0 bottom-0 w-0.5 bg-bronze" style={{ left: `${position}%` }} role="slider" aria-valuenow={Math.round(position)} aria-valuemin={0} aria-valuemax={100} aria-label="Before and after comparison position" tabIndex={0} onKeyDown={handleKeyDown}>
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 h-8 w-8 rounded-full border border-bronze bg-bg flex items-center justify-center"><div className="flex gap-0.5"><span className="text-[0.625rem] text-bronze">{'<'}</span><span className="text-[0.625rem] text-bronze">{'>'}</span></div></div>
        </div>
      </div>
    </div>
  );
}
AUREXIS_EOF

cat > src/components/proof/code-split-view.tsx << 'AUREXIS_EOF'
'use client';
import { useState, useCallback, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Code2, Copy, Check, X } from 'lucide-react';
import { codeSamples } from '@/data/code-samples';
import { useReducedMotion } from '@/hooks/use-reduced-motion';
import { cn } from '@/lib/utils';
function highlightTypeScript(source: string): React.ReactNode {
  const tokens = source.split(/(\s+|[(){}[\];,=<>:])/);
  const keywords = new Set(['import','export','from','return','const','let','var','function','async','await','if','else','new','default','type','interface','extends','implements','class','public','private','protected','readonly','static','void','never','undefined','null','true','false','as','in','of','for','while','throw','try','catch','finally']);
  return tokens.map((token, i) => {
    if (keywords.has(token.trim())) return <span key={i} className="text-bronze">{token}</span>;
    if (/^['"`].*['"`]$/.test(token)) return <span key={i} className="text-gold">{token}</span>;
    if (/^\d+$/.test(token.trim())) return <span key={i} className="text-bronze">{token}</span>;
    if (/^[A-Z][a-zA-Z0-9]*$/.test(token.trim())) return <span key={i} className="text-gold">{token}</span>;
    return <span key={i} className="text-muted">{token}</span>;
  });
}
export function CodeSplitView() {
  const [activeId, setActiveId] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);
  const reduced = useReducedMotion();
  const activeSample = codeSamples.find((s) => s.id === activeId);
  const handleCopy = useCallback(async () => { if (!activeSample) return; try { await navigator.clipboard.writeText(activeSample.source); setCopied(true); setTimeout(() => setCopied(false), 2000); } catch { setCopied(false); } }, [activeSample]);
  useEffect(() => { if (!activeId) return; const handler = (e: KeyboardEvent) => { if (e.key === 'Escape') setActiveId(null); }; window.addEventListener('keydown', handler); return () => window.removeEventListener('keydown', handler); }, [activeId]);
  return (
    <div className="rounded-xl border border-border bg-surface p-4">
      <div className="mb-3 flex items-center justify-between"><span className="font-mono text-[0.6875rem] uppercase tracking-[0.2em] text-bronze">Inspect Element</span><span className="text-xs text-dim">Click a card to view source</span></div>
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        {codeSamples.map((sample) => (<button key={sample.id} type="button" onClick={() => setActiveId(sample.id)} className={cn('flex flex-col gap-2 rounded-lg border border-border bg-bg/50 p-4 text-left transition-colors hover:border-bronze/40 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-bronze/40')}><div className="flex items-center gap-2"><Code2 className="h-4 w-4 text-bronze" aria-hidden="true" /><span className="text-sm font-medium text-fg">{sample.label}</span></div><span className="font-mono text-xs text-dim">{sample.filename}</span><p className="text-xs text-muted">{sample.description}</p></button>))}
      </div>
      <AnimatePresence>
        {activeSample && (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.15 }} className="fixed inset-0 z-[100] flex items-center justify-center p-4" role="dialog" aria-modal="true" aria-label={`Source code: ${activeSample.filename}`} onClick={() => setActiveId(null)}>
            <div className="absolute inset-0 bg-black/60" />
            <motion.div initial={reduced ? undefined : { opacity: 0, scale: 0.98, y: -8 }} animate={reduced ? undefined : { opacity: 1, scale: 1, y: 0 }} exit={reduced ? undefined : { opacity: 0, scale: 0.98, y: -8 }} transition={{ type: 'spring', stiffness: 400, damping: 30 }} className={cn('relative w-full max-w-2xl overflow-hidden rounded-xl bg-[#1A1A1A]/40 backdrop-blur-xl border border-white/10 shadow-[0_8px_32px_0_rgba(0,0,0,0.37)]')} onClick={(e) => e.stopPropagation()}>
              <div className="flex items-center justify-between border-b border-border px-4 py-3"><span className="font-mono text-sm text-fg">{activeSample.filename}</span><div className="flex items-center gap-2"><button type="button" onClick={handleCopy} className="rounded-md border border-border px-2 py-1 text-xs text-muted hover:text-fg transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-bronze/40" aria-label="Copy code to clipboard">{copied ? <Check className="h-3.5 w-3.5 text-bronze" /> : <Copy className="h-3.5 w-3.5" />}</button><button type="button" onClick={() => setActiveId(null)} className="rounded-md p-1 text-dim hover:text-fg focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-bronze/40" aria-label="Close dialog"><X className="h-4 w-4" /></button></div></div>
              <pre className="max-h-[60vh] overflow-auto p-4 text-xs leading-relaxed"><code className="font-mono">{highlightTypeScript(activeSample.source)}</code></pre>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
AUREXIS_EOF

cat > src/components/proof/roi-calculator.tsx << 'AUREXIS_EOF'
'use client';
import { useState, useMemo } from 'react';
import { RotaryKnob } from '@/components/industrial/rotary-knob';
import { MechanicalToggle } from '@/components/industrial/mechanical-toggle';
import { LedReadout } from '@/components/industrial/led-readout';
import { conversionLift, annualTotal, roiMultiple } from '@/lib/roi';
import { cn } from '@/lib/utils';
export function RoiCalculator() {
  const [traffic, setTraffic] = useState(50000);
  const [conversionRate, setConversionRate] = useState(2.5);
  const [aov, setAov] = useState(120);
  const [hours, setHours] = useState(40);
  const [legacyTti, setLegacyTti] = useState(2000);
  const [aurexisTti, setAurexisTti] = useState(120);
  const [animateOutput, setAnimateOutput] = useState(false);
  const { lift, annual, roi } = useMemo(() => {
    const liftVal = conversionLift(legacyTti, aurexisTti);
    const annualVal = annualTotal(traffic, conversionRate / 100, aov, legacyTti, aurexisTti, hours, 150);
    const roiVal = roiMultiple(annualVal, 120000);
    return { lift: liftVal, annual: annualVal, roi: roiVal };
  }, [traffic, conversionRate, aov, legacyTti, aurexisTti, hours]);
  return (
    <div className={cn('rounded-xl border border-border bg-surface p-4 md:p-6', animateOutput && 'transition-shadow')}>
      <div className="mb-4 flex items-center justify-between">
        <div className="flex flex-col gap-1"><span className="font-mono text-[0.6875rem] uppercase tracking-[0.2em] text-bronze">ROI Calculator</span><span className="text-xs text-dim">Published formula: L(delta t) = 0.14 * (1 - e^(-delta t/900))</span></div>
        <MechanicalToggle label="Animate" checked={animateOutput} onChange={setAnimateOutput} />
      </div>
      <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
        <div className="flex flex-col gap-4">
          <div className="space-y-3"><label className="flex items-center justify-between text-sm"><span className="text-muted">Monthly traffic</span><span className="font-mono text-fg">{traffic.toLocaleString()}</span></label><input type="range" min="1000" max="500000" step="1000" value={traffic} onChange={(e) => setTraffic(Number(e.target.value))} className="w-full accent-bronze" aria-label="Monthly traffic" /></div>
          <div className="space-y-3"><label className="flex items-center justify-between text-sm"><span className="text-muted">Conversion rate (%)</span><span className="font-mono text-fg">{conversionRate.toFixed(1)}%</span></label><input type="range" min="0.5" max="15" step="0.1" value={conversionRate} onChange={(e) => setConversionRate(Number(e.target.value))} className="w-full accent-bronze" aria-label="Conversion rate" /></div>
          <div className="space-y-3"><label className="flex items-center justify-between text-sm"><span className="text-muted">Average order value</span><span className="font-mono text-fg">${aov}</span></label><input type="range" min="20" max="2000" step="5" value={aov} onChange={(e) => setAov(Number(e.target.value))} className="w-full accent-bronze" aria-label="Average order value" /></div>
          <div className="space-y-3"><label className="flex items-center justify-between text-sm"><span className="text-muted">Manual hours / month</span><span className="font-mono text-fg">{hours}h</span></label><input type="range" min="0" max="200" step="1" value={hours} onChange={(e) => setHours(Number(e.target.value))} className="w-full accent-bronze" aria-label="Manual hours per month" /></div>
        </div>
        <div className="flex flex-col items-center justify-center gap-6">
          <div className="flex gap-6"><RotaryKnob label="Legacy TTI" min={200} max={3000} step={50} initialValue={legacyTti} unit="ms" onChange={setLegacyTti} /><RotaryKnob label="Aurexis TTI" min={40} max={500} step={10} initialValue={aurexisTti} unit="ms" onChange={setAurexisTti} /></div>
          <div className="grid grid-cols-3 gap-4 w-full"><LedReadout label="D-MS" value={(legacyTti - aurexisTti).toFixed(0)} pxSize={2} gapPx={1} /><LedReadout label="LIFT" value={`${(lift * 100).toFixed(1)}%`} pxSize={1} gapPx={0} /><LedReadout label="ROI" value={`${roi.toFixed(1)}X`} pxSize={2} gapPx={1} /></div>
          <div className="w-full rounded-lg border border-border bg-bg/50 p-3"><div className="flex items-center justify-between"><span className="text-xs text-muted">Annual total</span><span className="font-mono text-lg font-semibold text-bronze">${annual.toLocaleString(undefined, { maximumFractionDigits: 0 })}</span></div></div>
        </div>
      </div>
    </div>
  );
}
AUREXIS_EOF

# ── App files (5) ──────────────────────────────────────────────

cat > src/styles/fonts.ts << 'AUREXIS_EOF'
import { Inter, JetBrains_Mono } from 'next/font/google';
export const inter = Inter({ subsets: ['latin'], variable: '--font-inter', display: 'swap' });
export const jetbrainsMono = JetBrains_Mono({ subsets: ['latin'], variable: '--font-jetbrains', display: 'swap' });
AUREXIS_EOF

cat > src/app/globals.css << 'AUREXIS_EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  * { border-color: rgba(255, 255, 255, 0.10); }
  html { scroll-behavior: smooth; }
  body {
    background-color: #090909;
    color: #F5F5F5;
    font-family: var(--font-inter), system-ui, sans-serif;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
  }
  ::selection { background-color: rgba(135, 119, 108, 0.3); color: #F5F5F5; }
  ::-webkit-scrollbar { width: 6px; height: 6px; }
  ::-webkit-scrollbar-track { background: #090909; }
  ::-webkit-scrollbar-thumb { background: #1A1A1A; border-radius: 3px; }
  ::-webkit-scrollbar-thumb:hover { background: #222222; }
  :focus-visible { outline: 2px solid rgba(135, 119, 108, 0.5); outline-offset: 2px; }
}

@layer components {
  .skip-link {
    position: absolute; top: -100px; left: 0; z-index: 100;
    padding: 0.5rem 1rem; background-color: #1A1A1A; color: #F5F5F5;
    border: 1px solid rgba(135, 119, 108, 0.4); border-radius: 0 0 6px 0;
    transition: top 0.2s ease;
  }
  .skip-link:focus { top: 0; }
}

@layer utilities {
  @keyframes text-shimmer { 0% { background-position: 200% 0; } 100% { background-position: -200% 0; } }
  .animate-text-shimmer { animation: text-shimmer 2s linear infinite; }
  @keyframes border-beam-rotate { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
  .animate-border-beam-rotate { animation: border-beam-rotate 2s linear infinite; }
  .text-shimmer-bg {
    background-image: linear-gradient(90deg, #626269 0%, #87776C 25%, #F5F5F5 50%, #87776C 75%, #626269 100%);
    background-size: 200% 100%;
    background-clip: text;
    -webkit-background-clip: text;
    color: transparent;
  }
}

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
AUREXIS_EOF

cat > src/app/providers.tsx << 'AUREXIS_EOF'
'use client';
import { useEffect, type ReactNode } from 'react';
import { useModeStore } from '@/store/use-mode-store';
import { useAudioStore } from '@/store/use-audio-store';
import { useCommandStore } from '@/store/use-command-store';
export function Providers({ children }: { children: ReactNode }) {
  const { unlock } = useAudioStore();
  const { register } = useCommandStore();
  useEffect(() => { useModeStore.persist.rehydrate(); }, []);
  useEffect(() => {
    const handleFirstGesture = () => { unlock(); window.removeEventListener('pointerdown', handleFirstGesture); window.removeEventListener('keydown', handleFirstGesture); };
    window.addEventListener('pointerdown', handleFirstGesture);
    window.addEventListener('keydown', handleFirstGesture);
    return () => { window.removeEventListener('pointerdown', handleFirstGesture); window.removeEventListener('keydown', handleFirstGesture); };
  }, [unlock]);
  useEffect(() => {
    register({ id: 'toggle-mode', label: 'Toggle Executive/Engineer mode', group: 'System', keywords: 'mode toggle engineer executive', action: () => useModeStore.getState().toggle() });
    register({ id: 'go-services', label: 'Go to Services', group: 'Navigation', action: () => { document.getElementById('services')?.scrollIntoView({ behavior: 'smooth' }); } });
    register({ id: 'go-platform', label: 'Go to Platform', group: 'Navigation', action: () => { document.getElementById('platform')?.scrollIntoView({ behavior: 'smooth' }); } });
    register({ id: 'go-proof', label: 'Go to Proof', group: 'Navigation', action: () => { document.getElementById('proof')?.scrollIntoView({ behavior: 'smooth' }); } });
  }, [register]);
  return <>{children}</>;
}
AUREXIS_EOF

cat > src/app/layout.tsx << 'AUREXIS_EOF'
import type { Metadata } from 'next';
import { inter, jetbrainsMono } from '@/styles/fonts';
import { createMetadata } from '@/lib/seo';
import './globals.css';
export const metadata: Metadata = createMetadata();
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${inter.variable} ${jetbrainsMono.variable}`}>
      <body className="bg-bg text-fg antialiased">
        <a href="#main" className="skip-link">Skip to content</a>
        {children}
      </body>
    </html>
  );
}
AUREXIS_EOF

cat > src/app/page.tsx << 'AUREXIS_EOF'
import { Providers } from '@/app/providers';
import { SiteHeader } from '@/components/layout/site-header';
import { TelemetryTicker } from '@/components/layout/telemetry-ticker';
import { CommandPalette } from '@/components/layout/command-palette';
import { ScrollProgress } from '@/components/ui/scroll-progress';
import { HeroSection } from '@/components/hero/hero-section';
import { BentoGrid } from '@/components/bento/bento-grid';
import { IsometricCarousel } from '@/components/velocity/isometric-carousel';
import { OntologySection } from '@/components/ontology/ontology-section';
import { BeforeAfterSlider } from '@/components/proof/before-after-slider';
import { CodeSplitView } from '@/components/proof/code-split-view';
import { RoiCalculator } from '@/components/proof/roi-calculator';
import { FooterClock } from '@/components/layout/footer-clock';
import type { Metadata } from 'next';
export const metadata: Metadata = {
  title: 'Aurexis Systems Inc. — Digital Engineering',
  description: 'Elite digital engineering partner for SaaS and fast-scaling tech companies. We remove technical bottlenecks so companies scale revenue and operations without friction.',
};
export default function HomePage() {
  return (
    <Providers>
      <ScrollProgress />
      <SiteHeader />
      <TelemetryTicker />
      <CommandPalette />
      <main id="main">
        <HeroSection />
        <BentoGrid />
        <IsometricCarousel />
        <OntologySection />
        <section id="proof" className="py-20 md:py-28" aria-label="Proof">
          <div className="mx-auto max-w-7xl px-4 md:px-6">
            <div className="mb-10 flex flex-col gap-2">
              <span className="font-mono text-[0.6875rem] uppercase tracking-[0.2em] text-bronze">Proof</span>
              <h2 className="text-headline text-fg">Numbers, not promises.</h2>
            </div>
            <div className="flex flex-col gap-6">
              <BeforeAfterSlider />
              <CodeSplitView />
              <RoiCalculator />
            </div>
          </div>
        </section>
        <footer id="contact" className="border-t border-border py-12">
          <div className="mx-auto max-w-7xl px-4 md:px-6">
            <div className="grid grid-cols-2 gap-8 md:grid-cols-4">
              <div className="flex flex-col gap-2">
                <span className="font-mono text-sm font-semibold text-fg">AUREXIS</span>
                <span className="text-xs text-dim">Systems Inc.</span>
                <p className="mt-2 text-xs text-muted max-w-[200px]">Digital engineering partner for SaaS and fast-scaling tech companies.</p>
              </div>
              <div className="flex flex-col gap-2">
                <span className="font-mono text-[0.6875rem] uppercase tracking-widest text-dim">Site</span>
                <a href="#services" className="text-sm text-muted hover:text-fg transition-colors">Services</a>
                <a href="#platform" className="text-sm text-muted hover:text-fg transition-colors">Platform</a>
                <a href="#proof" className="text-sm text-muted hover:text-fg transition-colors">Proof</a>
              </div>
              <div className="flex flex-col gap-2">
                <span className="font-mono text-[0.6875rem] uppercase tracking-widest text-dim">Legal</span>
                <a href="/privacy" className="text-sm text-muted hover:text-fg transition-colors">Privacy</a>
                <a href="/terms" className="text-sm text-muted hover:text-fg transition-colors">Terms</a>
                <a href="/security" className="text-sm text-muted hover:text-fg transition-colors">Security</a>
              </div>
              <div className="flex flex-col gap-2">
                <span className="font-mono text-[0.6875rem] uppercase tracking-widest text-dim">Cape Town</span>
                <FooterClock />
                <span className="font-mono text-[0.6875rem] uppercase tracking-widest text-dim">GMT+2</span>
              </div>
            </div>
            <div className="mt-8 flex items-center justify-between border-t border-border pt-4">
              <span className="text-xs text-dim">© {new Date().getFullYear()} Aurexis Systems Inc.</span>
              <span className="font-mono text-[0.6875rem] uppercase tracking-widest text-dim">Built with Next.js · TypeScript · Tailwind</span>
            </div>
          </div>
        </footer>
      </main>
    </Providers>
  );
}
AUREXIS_EOF

echo "Part 3 complete: Velocity, Ontology, Industrial, Proof, App"
echo "══════════════════════════════════════════════════════════════"
echo "All 86 files written. Next steps:"
echo "  npm install"
echo "  npm run dev"
echo "══════════════════════════════════════════════════════════════"
