#!/usr/bin/env bash
set -euo pipefail
echo "==> Bootstrapping Next.js project config..."

mkdir -p public src/app src/lib src/styles

cat > package.json << 'EOF'
{
  "name": "aurexis-systems",
  "version": "0.1.0",
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
    "@hookform/resolvers": "^3.9.1",
    "@radix-ui/react-dialog": "^1.1.2",
    "@radix-ui/react-slider": "^1.2.1",
    "@radix-ui/react-slot": "^1.1.0",
    "@radix-ui/react-switch": "^1.1.1",
    "@radix-ui/react-tabs": "^1.1.1",
    "@radix-ui/react-toggle-group": "^1.1.0",
    "@radix-ui/react-tooltip": "^1.1.4",
    "@radix-ui/react-visually-hidden": "^1.1.0",
    "class-variance-authority": "^0.7.1",
    "clsx": "^2.1.1",
    "cmdk": "^1.0.4",
    "embla-carousel-react": "^8.5.1",
    "framer-motion": "^11.11.17",
    "lucide-react": "^0.468.0",
    "next": "14.2.15",
    "prism-react-renderer": "^2.4.0",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "react-hook-form": "^7.54.2",
    "sonner": "^1.7.0",
    "tailwind-merge": "^2.5.5",
    "tailwindcss-animate": "^1.0.7",
    "zod": "^3.23.8",
    "zustand": "^5.0.1"
  },
  "devDependencies": {
    "@types/node": "^22.10.1",
    "@types/react": "^18.3.12",
    "@types/react-dom": "^18.3.1",
    "autoprefixer": "^10.4.20",
    "eslint": "^8.57.1",
    "eslint-config-next": "14.2.15",
    "postcss": "^8.4.49",
    "prettier": "^3.4.1",
    "prettier-plugin-tailwindcss": "^0.6.9",
    "tailwindcss": "^3.4.14",
    "typescript": "^5.7.2"
  }
}
EOF

cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
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
EOF

cat > next.config.mjs << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
}

export default nextConfig
EOF

cat > postcss.config.mjs << 'EOF'
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

cat > .eslintrc.json << 'EOF'
{
  "extends": ["next/core-web-vitals"]
}
EOF

cat > .gitignore << 'EOF'
/node_modules
/.next
/out
/build
.DS_Store
*.pem
.env
.env*.local
.vercel
*.tsbuildinfo
next-env.d.ts
EOF

echo ""
echo "==> Bootstrap config files written:"
ls package.json tsconfig.json next.config.mjs postcss.config.mjs .eslintrc.json .gitignore
echo ""
echo "==> Now run: npm install"
