#!/usr/bin/env bash
set -euo pipefail
echo "==> Writing Aurexis foundation layer..."

mkdir -p src/app src/lib src/styles

cat > tailwind.config.ts << 'EOF'
import type { Config } from 'tailwindcss'

const config: Config = {
  darkMode: 'class',
  content: ['./src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        bg:      '#08080a',
        surface: '#0b0b0e',
        border:  '#1c1c22',
        fg:      '#f5f5f7',
        muted:   '#8a8a94',
        dim:     '#5a5a64',
        orange:  '#ff5b1f',
        cyan:    '#35e6f2',
      },
      fontFamily: {
        sans: ['var(--font-sans)', 'ui-sans-serif', 'system-ui'],
        mono: ['var(--font-mono)', 'ui-monospace', 'monospace'],
      },
    },
  },
  plugins: [],
}
export default config
EOF

cat > .env.example << 'EOF'
NEXT_PUBLIC_SITE_URL=http://localhost:3000
EOF

cat > .prettierrc << 'EOF'
{
  "singleQuote": true,
  "semi": false,
  "trailingComma": "all",
  "printWidth": 100,
  "tabWidth": 2
}
EOF

cat > src/lib/utils.ts << 'EOF'
import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
EOF

cat > src/styles/fonts.ts << 'EOF'
import { Inter, JetBrains_Mono } from 'next/font/google'

export const sans = Inter({
  subsets: ['latin'],
  variable: '--font-sans',
  display: 'swap',
})

export const mono = JetBrains_Mono({
  subsets: ['latin'],
  variable: '--font-mono',
  display: 'swap',
})
EOF

cat > src/lib/seo.ts << 'EOF'
import type { Metadata } from 'next'

export const siteUrl =
  process.env.NEXT_PUBLIC_SITE_URL ?? 'https://aurexis.systems'

export function buildMetadata(overrides: Partial<Metadata> = {}): Metadata {
  return {
    metadataBase: new URL(siteUrl),
    title: {
      default: 'Aurexis Systems Inc. — Elite Digital Engineering',
      template: '%s · Aurexis Systems',
    },
    description:
      'We remove technical bottlenecks so companies can scale revenue and operations effortlessly.',
    openGraph: {
      type: 'website',
      url: siteUrl,
      siteName: 'Aurexis Systems Inc.',
    },
    twitter: { card: 'summary_large_image' },
    robots: { index: true, follow: true },
    ...overrides,
  }
}
EOF

cat > src/app/globals.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  --bg: #08080a;
  --border: #1c1c22;
  --fg: #f5f5f7;
  --muted: #8a8a94;
  --orange: #ff5b1f;
  --cyan: #35e6f2;
}

html, body {
  background: var(--bg);
  color: var(--fg);
  -webkit-font-smoothing: antialiased;
  text-rendering: optimizeLegibility;
}

::selection { background: var(--cyan); color: var(--bg); }

:focus-visible {
  outline: 2px solid var(--cyan);
  outline-offset: 2px;
  border-radius: 4px;
}

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.001ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.001ms !important;
  }
}
EOF

cat > src/app/providers.tsx << 'EOF'
'use client'

import { type ReactNode } from 'react'
import { TooltipProvider } from '@radix-ui/react-tooltip'

export function Providers({ children }: { children: ReactNode }) {
  return (
    <TooltipProvider delayDuration={150} skipDelayDuration={300}>
      {children}
    </TooltipProvider>
  )
}
EOF

cat > src/app/layout.tsx << 'EOF'
import type { Metadata, Viewport } from 'next'
import { sans, mono } from '@/styles/fonts'
import { Providers } from './providers'
import { buildMetadata } from '@/lib/seo'
import './globals.css'

export const metadata: Metadata = buildMetadata()

export const viewport: Viewport = {
  themeColor: '#08080a',
  colorScheme: 'dark',
  width: 'device-width',
  initialScale: 1,
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${sans.variable} ${mono.variable} dark`} suppressHydrationWarning>
      <body className="min-h-dvh bg-bg font-sans text-fg antialiased">
        <a
          href="#main"
          className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-[9999] focus:rounded focus:bg-surface focus:px-3 focus:py-2 focus:text-sm focus:ring-2 focus:ring-cyan"
        >
          Skip to content
        </a>
        <Providers>
          <div id="main">{children}</div>
        </Providers>
      </body>
    </html>
  )
}
EOF

cat > src/app/page.tsx << 'EOF'
export default function Home() {
  return (
    <main className="mx-auto flex min-h-dvh max-w-5xl flex-col justify-center px-6">
      <p className="mb-3 font-mono text-[11px] uppercase tracking-[0.2em] text-orange">
        Aurexis Systems Inc. — Build 3.14.2
      </p>
      <h1 className="text-balance text-5xl font-semibold leading-[1.05] tracking-tight md:text-6xl">
        We remove technical bottlenecks so companies scale revenue and operations{' '}
        <span className="text-muted">effortlessly.</span>
      </h1>
      <p className="mt-6 max-w-xl text-base text-muted md:text-lg">
        Bootstrap OK. Full system coming online.
      </p>
      <div className="mt-8 flex gap-3">
        <span className="rounded-full bg-orange px-4 py-2 text-sm font-medium text-bg">
          Boot successful
        </span>
        <span className="rounded-full border border-border px-4 py-2 font-mono text-xs text-muted">
          v0.1.0
        </span>
      </div>
    </main>
  )
}
EOF

rm -f public/next.svg public/vercel.svg 2>/dev/null || true

echo ""
echo "==> Done. Files written:"
find src tailwind.config.ts .prettierrc .env.example -type f | sort
echo ""
echo "==> Total files: $(find src -type f | wc -l)"
echo ""
echo "==> Next: run setup-02-state.sh"
