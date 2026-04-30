#!/bin/bash
cd ~/nextstep-intelligence
echo "NEXTSTEP Intelligence – opretter alle filer..."

# ─── GITIGNORE ───
cat > .gitignore << 'EOF'
node_modules/
__pycache__/
*.pyc
.venv/
venv/
.env
.env.local
.env.production
.next/
dist/
build/
.DS_Store
*.log
.vscode/
.idea/
EOF
echo "✓ .gitignore"

# ─── README ───
cat > README.md << 'EOF'
# NEXTSTEP Intelligence · Scout NS

Intern AI-drevet nyhedsscreening og lead-genereringsplatform.

## Struktur
nextstep-intelligence/
├── frontend/     # Next.js dashboard
└── backend/      # Python FastAPI + AI-analyse

## Kom i gang

### Frontend
cd frontend
cp .env.example .env.local
npm install
npm run dev
# Åbn http://localhost:3000

### Backend
cd backend
cp .env.example .env
pip install -r requirements.txt
uvicorn main:app --reload --port 8000

## Moduler
- Public Affairs – kommercielle virksomheder med PA-behov
- Velfærd – kommuner/organisationer med latente problemer

## Rapporter
- Mandag kl. 10:00
- Torsdag kl. 08:30
EOF
echo "✓ README.md"

# ─── FRONTEND ───

cat > frontend/next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: `${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000'}/:path*`,
      },
    ]
  },
}
module.exports = nextConfig
EOF
echo "✓ frontend/next.config.js"

cat > frontend/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "es5",
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
    "paths": { "@/*": ["./*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx"],
  "exclude": ["node_modules"]
}
EOF
echo "✓ frontend/tsconfig.json"

cat > frontend/.env.example << 'EOF'
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_ACCESS_PASSWORD=nextstep2026
EOF
echo "✓ frontend/.env.example"

mkdir -p frontend/app frontend/components

cat > frontend/app/globals.css << 'EOF'
* { box-sizing: border-box; margin: 0; padding: 0; }
:root {
  --bg: #f7f5f0;
  --surface: #ffffff;
  --ink: #1a1a1a;
  --ink-2: #555555;
  --ink-3: #999999;
  --divider: rgba(0,0,0,0.07);
  --pa: #1a1a1a;
  --pa-border: #1a1a1a;
  --vel: #2a7d5f;
  --vel-bg: #edf5f1;
  --vel-border: #2a7d5f;
  --gold: #b8963e;
  --gold-bg: #f9f3e8;
  --radius-sm: 8px;
  --radius-md: 12px;
  --radius-lg: 14px;
  --radius-xl: 16px;
}
html, body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  background: var(--bg);
  color: var(--ink);
  min-height: 100vh;
  -webkit-font-smoothing: antialiased;
}
button { font-family: inherit; cursor: pointer; }
a { text-decoration: none; color: inherit; }
EOF
echo "✓ frontend/app/globals.css"

cat > frontend/app/layout.tsx << 'EOF'
import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'NEXTSTEP Intelligence',
  description: 'Scout NS · Intern lead-platform',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="da">
      <body>{children}</body>
    </html>
  )
}
EOF
echo "✓ frontend/app/layout.tsx"

cat > frontend/app/page.tsx << 'EOF'
'use client'
import { useState } from 'react'
import { useRouter } from 'next/navigation'

export default function LoginPage() {
  const [password, setPassword] = useState('')
  const [error, setError] = useState(false)
  const [loading, setLoading] = useState(false)
  const router = useRouter()

  const handleLogin = async () => {
    setLoading(true)
    setError(false)
    const correct = process.env.NEXT_PUBLIC_ACCESS_PASSWORD || 'nextstep2026'
    if (password === correct) {
      localStorage.setItem('ns_auth', 'true')
      router.push('/dashboard')
    } else {
      setError(true)
      setLoading(false)
    }
  }

  return (
    <div style={{ minHeight: '100vh', background: 'var(--bg)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <div style={{ background: 'var(--surface)', borderRadius: 'var(--radius-xl)', padding: '48px 52px', width: '100%', maxWidth: 400, border: '1px solid rgba(0,0,0,0.06)' }}>
        <div style={{ marginBottom: 36, textAlign: 'center' }}>
          <div style={{ fontSize: 11, letterSpacing: '0.12em', color: 'var(--ink-3)', textTransform: 'uppercase', marginBottom: 6 }}>NEXTSTEP</div>
          <div style={{ fontSize: 26, fontWeight: 700, color: 'var(--ink)', letterSpacing: '-0.02em' }}>Intelligence</div>
          <div style={{ fontSize: 12, color: 'var(--ink-3)', marginTop: 4 }}>Scout NS · Internt system</div>
        </div>
        <div style={{ marginBottom: 14 }}>
          <input
            type="password"
            placeholder="Adgangskode"
            value={password}
            onChange={e => setPassword(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && handleLogin()}
            style={{ width: '100%', padding: '12px 16px', fontSize: 15, borderRadius: 'var(--radius-sm)', border: error ? '1px solid #e05252' : '1px solid rgba(0,0,0,0.12)', background: 'var(--bg)', color: 'var(--ink)', outline: 'none' }}
          />
          {error && <div style={{ fontSize: 12, color: '#e05252', marginTop: 8 }}>Forkert adgangskode. Prøv igen.</div>}
        </div>
        <button
          onClick={handleLogin}
          disabled={loading || !password}
          style={{ width: '100%', padding: '12px', fontSize: 14, fontWeight: 600, borderRadius: 'var(--radius-sm)', border: 'none', background: password ? 'var(--ink)' : 'rgba(0,0,0,0.08)', color: password ? '#fff' : 'var(--ink-3)' }}
        >
          {loading ? 'Logger ind...' : 'Log ind'}
        </button>
      </div>
    </div>
  )
}
EOF
echo "✓ frontend/app/page.tsx"

mkdir -p frontend/app/dashboard

cat > frontend/app/dashboard/page.tsx << 'EOF'
'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Sidebar from '@/components/Sidebar'
import LeadCard from '@/components/LeadCard'
import StatsRow from '@/components/StatsRow'
import ReviewBanner from '@/components/ReviewBanner'

export type Lead = {
  id: string
  title: string
  summary: string
  module: 'public_affairs' | 'velfaerd'
  opgave_type: 'Alliance' | 'Camp' | 'Entreprenør'
  sector: string
  source: string
  published_at: string
  score: number
  cvr_verified: boolean
  size_info: string
  stakeholders: { name: string; role: string }[]
  potential_partners: { name: string; role: string }[]
  gold_matches: { title: string; pct: number }[]
  opener: string
}

const DEMO_LEADS: Lead[] = [
  {
    id: '1',
    title: 'NKT A/S søger politisk opbakning til nyt datacenter i Silkeborg',
    summary: 'Virksomheden ønsker at bygge et 400 MW AI-datacenter men møder modstand fra lokalpolitikere om arealplanlægning og strømforsyning. Ingen intern PA-kapabilitet identificeret.',
    module: 'public_affairs', opgave_type: 'Alliance', sector: 'Energi',
    source: 'Berlingske', published_at: '29. apr', score: 9.2,
    cvr_verified: true, size_info: '2.800 ansatte',
    stakeholders: [
      { name: 'Energistyrelsen', role: 'Godkendelsesmyndighed, kan accelerere eller blokere' },
      { name: 'Silkeborg Kommune', role: 'Lokalplan skal ændres, borgmester skeptisk' },
      { name: 'Dansk Energi', role: 'Modsat interesse ift. storforbrugerprioritering' },
    ],
    potential_partners: [
      { name: 'Dansk Industri', role: 'Naturlig alliancepartner for storvirksomheders infrastrukturbehov' },
      { name: 'Midtjyske lokalpolitikere', role: 'Potentielle fortalere for regional vækst og arbejdspladser' },
    ],
    gold_matches: [{ title: 'Grøn Varme Alliancen', pct: 83 }],
    opener: 'Alliance-model med energiselskaber',
  },
  {
    id: '2',
    title: 'Vejle Kommune skal implementere ældrepleje-reform inden udgangen af 2026',
    summary: 'Kommunen er bagud på KLs benchmarks og har ingen intern kapacitet til at drive processen. Politisk pres fra regionsrådet øger urgency markant.',
    module: 'velfaerd', opgave_type: 'Camp', sector: 'Sundhed',
    source: 'Altinget', published_at: '28. apr', score: 8.7,
    cvr_verified: true, size_info: '115.000 borgere',
    stakeholders: [
      { name: 'KL', role: 'Offentliggør benchmark-rangering i juni, skaber politisk pres' },
      { name: 'Region Syddanmark', role: 'Har varslet overtagelse hvis kommunen ikke leverer' },
    ],
    potential_partners: [
      { name: 'FOA', role: 'Fagforening for plejepersonalet, afgørende for implementering' },
      { name: 'Ældre Sagen', role: 'Legitimerer løsningen hos borgerne og skaber folkelig opbakning' },
      { name: 'Dansk Sygeplejeråd', role: 'Faglig autoritet på kvalitetsstandarder i plejen' },
    ],
    gold_matches: [{ title: 'LOKK', pct: 79 }, { title: 'Beredskabsforbundet', pct: 71 }],
    opener: '100-dages forandringsmodel',
  },
]

function getWeekNumber(d: Date) {
  const date = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
  date.setUTCDate(date.getUTCDate() + 4 - (date.getUTCDay() || 7))
  const yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1))
  return Math.ceil((((date.getTime() - yearStart.getTime()) / 86400000) + 1) / 7)
}

export default function Dashboard() {
  const router = useRouter()
  const [leads, setLeads] = useState<Lead[]>(DEMO_LEADS)
  const [filter, setFilter] = useState('alle')
  const [activeModule, setActiveModule] = useState('alle')

  useEffect(() => {
    const auth = localStorage.getItem('ns_auth')
    if (!auth) { router.push('/'); return }
    fetch('/api/leads').then(r => r.json()).then(d => { if (d.leads?.length) setLeads(d.leads) }).catch(() => {})
  }, [])

  const filtered = leads.filter(l => {
    if (activeModule === 'pa') return l.module === 'public_affairs'
    if (activeModule === 'vel') return l.module === 'velfaerd'
    if (filter === 'rebizz') return l.gold_matches.length > 0
    if (filter !== 'alle') return l.opgave_type === filter
    return true
  })

  const now = new Date()
  const week = getWeekNumber(now)
  const pa = leads.filter(l => l.module === 'public_affairs').length
  const vel = leads.filter(l => l.module === 'velfaerd').length
  const rebizz = leads.filter(l => l.gold_matches.length > 0).length

  return (
    <div style={{ display: 'grid', gridTemplateColumns: '192px 1fr', minHeight: '100vh' }}>
      <Sidebar activeModule={activeModule} setActiveModule={setActiveModule} />
      <main style={{ padding: '28px 32px', background: 'var(--bg)' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 22 }}>
          <div>
            <h1 style={{ fontSize: 22, fontWeight: 700, letterSpacing: '-0.02em' }}>Uge {week} · {now.getFullYear()}</h1>
            <p style={{ fontSize: 12, color: 'var(--ink-3)', marginTop: 4 }}>Opdateret kl. {String(now.getHours()).padStart(2,'0')}:{String(now.getMinutes()).padStart(2,'0')} · Næste rapport torsdag kl. 08:30</p>
          </div>
          <button style={{ fontSize: 12, fontWeight: 500, padding: '8px 18px', borderRadius: 'var(--radius-sm)', border: '1px solid rgba(0,0,0,0.12)', background: 'var(--surface)', color: 'var(--ink)' }}>
            Generer rapport ↗
          </button>
        </div>
        <ReviewBanner />
        <StatsRow total={leads.length} pa={pa} vel={vel} rebizz={rebizz} />
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', margin: '18px 0' }}>
          {['alle', 'Alliance', 'Camp', 'Entreprenør', 'rebizz'].map(f => (
            <button key={f} onClick={() => setFilter(f)} style={{ fontSize: 12, padding: '5px 13px', borderRadius: 20, border: '1px solid rgba(0,0,0,0.1)', background: filter === f ? 'var(--ink)' : 'transparent', color: filter === f ? '#fff' : 'var(--ink-2)' }}>
              {f === 'alle' ? 'Alle' : f === 'rebizz' ? 'Rebizz' : f}
            </button>
          ))}
        </div>
        {filtered.map(lead => <LeadCard key={lead.id} lead={lead} />)}
        {filtered.length === 0 && <div style={{ textAlign: 'center', padding: 60, color: 'var(--ink-3)', fontSize: 14 }}>Ingen leads matcher filteret.</div>}
      </main>
    </div>
  )
}
EOF
echo "✓ frontend/app/dashboard/page.tsx"

cat > frontend/components/Sidebar.tsx << 'EOF'
'use client'
type Props = { activeModule: string; setActiveModule: (m: string) => void }
export default function Sidebar({ activeModule, setActiveModule }: Props) {
  const btn = (label: string, value: string, color?: string, small?: boolean) => {
    const active = activeModule === value
    return (
      <button onClick={() => setActiveModule(value)} style={{ width: '100%', textAlign: 'left', padding: small ? '6px 14px' : '7px 14px', borderRadius: 8, fontSize: small ? 12 : 13, border: 'none', background: active ? 'var(--ink)' : 'transparent', color: active ? '#fff' : color || 'var(--ink-3)', fontWeight: active ? 500 : 400, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 9 }}>
        {color && !active && <span style={{ width: 8, height: 8, borderRadius: '50%', background: color, flexShrink: 0, display: 'inline-block' }} />}
        {label}
      </button>
    )
  }
  return (
    <aside style={{ background: 'var(--surface)', padding: '22px 10px', display: 'flex', flexDirection: 'column', gap: 2, borderRight: '1px solid var(--divider)', minHeight: '100vh' }}>
      <div style={{ padding: '4px 14px 20px', marginBottom: 4 }}>
        <div style={{ fontSize: 10, letterSpacing: '0.12em', color: 'var(--ink-3)', textTransform: 'uppercase', marginBottom: 4 }}>NEXTSTEP</div>
        <div style={{ fontSize: 17, fontWeight: 700, color: 'var(--ink)', letterSpacing: '-0.02em' }}>Intelligence</div>
        <div style={{ fontSize: 10, color: 'var(--ink-3)', marginTop: 1 }}>Scout NS · v0.1</div>
      </div>
      <div style={{ fontSize: 10, letterSpacing: '0.09em', color: 'var(--ink-3)', textTransform: 'uppercase', padding: '0 14px', marginBottom: 3 }}>Overblik</div>
      {btn('Alle moduler', 'alle')}
      <div style={{ marginTop: 14, paddingTop: 12, borderTop: '1px solid var(--divider)' }}>
        <div style={{ fontSize: 10, letterSpacing: '0.09em', color: 'var(--ink-3)', textTransform: 'uppercase', padding: '0 14px', marginBottom: 3 }}>Moduler</div>
        {btn('Public Affairs', 'pa', 'var(--pa)')}
        {btn('Velfærd', 'vel', 'var(--vel)')}
        <button style={{ width: '100%', textAlign: 'left', padding: '7px 14px', borderRadius: 8, fontSize: 12, border: 'none', background: 'transparent', color: 'var(--ink-3)', fontStyle: 'italic', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 9 }}>
          <span style={{ width: 8, height: 8, borderRadius: '50%', border: '1px dashed #ccc', flexShrink: 0, display: 'inline-block' }} />+ Nyt modul
        </button>
      </div>
      <div style={{ marginTop: 14, paddingTop: 12, borderTop: '1px solid var(--divider)' }}>
        <div style={{ fontSize: 10, letterSpacing: '0.09em', color: 'var(--ink-3)', textTransform: 'uppercase', padding: '0 14px', marginBottom: 3 }}>Sektorer</div>
        {['Sundhed','Fødevarer','Energi & forsyning','Klima','Kommuner'].map(s => (
          <button key={s} style={{ width: '100%', textAlign: 'left', padding: '6px 14px', borderRadius: 8, fontSize: 12, border: 'none', background: 'transparent', color: 'var(--ink-3)', cursor: 'pointer' }}>{s}</button>
        ))}
        <button style={{ width: '100%', textAlign: 'left', padding: '6px 14px', borderRadius: 8, fontSize: 12, border: 'none', background: 'transparent', color: 'var(--ink-2)', cursor: 'pointer' }}>+ Tilføj sektor</button>
      </div>
      <div style={{ marginTop: 'auto', paddingTop: 12, borderTop: '1px solid var(--divider)' }}>
        {['Rapport-arkiv','Indstillinger'].map(s => (
          <button key={s} style={{ width: '100%', textAlign: 'left', padding: '7px 14px', borderRadius: 8, fontSize: 12, border: 'none', background: 'transparent', color: 'var(--ink-3)', cursor: 'pointer' }}>{s}</button>
        ))}
        <button style={{ width: '100%', textAlign: 'left', padding: '7px 14px', borderRadius: 8, fontSize: 12, border: 'none', background: 'transparent', color: 'var(--ink-2)', fontWeight: 500, cursor: 'pointer' }}>Afventer godkendelse (1)</button>
      </div>
    </aside>
  )
}
EOF
echo "✓ frontend/components/Sidebar.tsx"

cat > frontend/components/StatsRow.tsx << 'EOF'
type Props = { total: number; pa: number; vel: number; rebizz: number }
export default function StatsRow({ total, pa, vel, rebizz }: Props) {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 10, marginBottom: 4 }}>
      {[
        { label: 'Nye leads', value: total, sub: 'denne uge', valueColor: 'var(--ink)', dark: false, bg: 'var(--surface)' },
        { label: 'Public Affairs', value: pa, sub: 'Vækst + regulering', valueColor: '#fff', dark: true, bg: 'var(--ink)' },
        { label: 'Velfærd', value: vel, sub: 'Latente problemer', valueColor: '#fff', dark: true, bg: 'var(--vel)' },
        { label: 'Rebizz-matches', value: rebizz, sub: 'Guldkatalog-match', valueColor: 'var(--gold)', dark: false, bg: 'var(--surface)' },
      ].map(c => (
        <div key={c.label} style={{ background: c.bg, borderRadius: 'var(--radius-md)', padding: '13px 15px', border: c.dark ? 'none' : '1px solid rgba(0,0,0,0.06)' }}>
          <div style={{ fontSize: 11, color: c.dark ? 'rgba(255,255,255,0.45)' : 'var(--ink-3)', marginBottom: 5 }}>{c.label}</div>
          <div style={{ fontSize: 24, fontWeight: 700, color: c.valueColor }}>{c.value}</div>
          <div style={{ fontSize: 11, color: c.dark ? 'rgba(255,255,255,0.35)' : 'var(--ink-3)', marginTop: 3 }}>{c.sub}</div>
        </div>
      ))}
    </div>
  )
}
EOF
echo "✓ frontend/components/StatsRow.tsx"

cat > frontend/components/ReviewBanner.tsx << 'EOF'
export default function ReviewBanner() {
  return (
    <div style={{ background: 'var(--gold-bg)', border: '1px solid rgba(184,150,62,0.25)', borderRadius: 'var(--radius-md)', padding: '12px 18px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 14, marginBottom: 20 }}>
      <div>
        <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--ink)' }}>Torsdagsrapport klar til review</div>
        <div style={{ fontSize: 11, color: 'var(--ink-2)', marginTop: 2 }}>4 leads · Afventer godkendelse af Rasmus eller direktøren inden udsendelse</div>
      </div>
      <button style={{ fontSize: 12, fontWeight: 500, padding: '7px 18px', borderRadius: 8, border: 'none', background: 'var(--gold)', color: '#fff', cursor: 'pointer', whiteSpace: 'nowrap' }}>
        Se &amp; godkend
      </button>
    </div>
  )
}
EOF
echo "✓ frontend/components/ReviewBanner.tsx"

cat > frontend/components/LeadCard.tsx << 'EOF'
import { Lead } from '@/app/dashboard/page'
type Props = { lead: Lead }
const MC = {
  public_affairs: { border: 'var(--pa)', chip: '#1a1a1a', chipText: '#f5f0e8', score: 'var(--pa)', sbg: '#f5f3ef', slabel: '#666', dot: '#1a1a1a' },
  velfaerd: { border: 'var(--vel)', chip: 'var(--vel-bg)', chipText: 'var(--vel)', score: 'var(--vel)', sbg: 'var(--vel-bg)', slabel: 'var(--vel)', dot: 'var(--vel)' },
}
const OC: Record<string, {bg:string;color:string}> = {
  Alliance: { bg: '#f9f3e8', color: '#b8963e' },
  Camp: { bg: '#ede8f5', color: '#5c3d99' },
  'Entreprenør': { bg: '#fdeee8', color: '#a0430a' },
}
export default function LeadCard({ lead }: Props) {
  const mc = MC[lead.module]
  const oc = OC[lead.opgave_type] || { bg: '#f0f0f0', color: '#666' }
  const moduleLabel = lead.module === 'public_affairs' ? 'Public Affairs' : 'Velfærd'
  const Dot = ({ color }: { color: string }) => <span style={{ width: 4, height: 4, borderRadius: '50%', background: color, flexShrink: 0, marginTop: 6, display: 'inline-block' }} />
  return (
    <div style={{ background: 'var(--surface)', borderRadius: 'var(--radius-lg)', padding: '1.2rem 1.35rem', marginBottom: 10, border: '1px solid rgba(0,0,0,0.06)', borderLeftWidth: 3, borderLeftColor: mc.border }}>
      <div style={{ display: 'flex', gap: 16, alignItems: 'flex-start' }}>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', alignItems: 'center', marginBottom: 8 }}>
            <span style={{ fontSize: 11, fontWeight: 500, padding: '3px 10px', borderRadius: 20, background: mc.chip, color: mc.chipText }}>{moduleLabel}</span>
            <span style={{ fontSize: 11, fontWeight: 500, padding: '3px 10px', borderRadius: 20, background: oc.bg, color: oc.color }}>{lead.opgave_type}</span>
            <span style={{ fontSize: 11, fontWeight: 500, padding: '3px 10px', borderRadius: 20, background: 'rgba(0,0,0,0.05)', color: 'var(--ink-2)' }}>{lead.sector}</span>
            <span style={{ fontSize: 11, color: 'var(--ink-3)' }}>{lead.source} · {lead.published_at}</span>
          </div>
          <h2 style={{ fontSize: 14, fontWeight: 600, color: 'var(--ink)', marginBottom: 5, letterSpacing: '-0.01em', lineHeight: 1.4 }}>{lead.title}</h2>
          <p style={{ fontSize: 13, color: 'var(--ink-2)', lineHeight: 1.6, marginBottom: 11 }}>{lead.summary}</p>
          <div style={{ background: mc.sbg, borderRadius: 10, padding: '10px 13px', marginBottom: 10 }}>
            <div style={{ fontSize: 10, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: mc.slabel, marginBottom: 7 }}>Centrale interessenter</div>
            {lead.stakeholders.map((s, i) => (
              <div key={i} style={{ display: 'flex', gap: 7, fontSize: 12, color: 'var(--ink-2)', lineHeight: 1.5, padding: '2px 0' }}>
                <Dot color={mc.dot} /><span><strong style={{ color: 'var(--ink)', fontWeight: 500 }}>{s.name}</strong> — {s.role}</span>
              </div>
            ))}
          </div>
          {lead.potential_partners.length > 0 && (
            <div style={{ background: 'rgba(184,150,62,0.07)', borderRadius: 10, padding: '10px 13px', marginBottom: 10 }}>
              <div style={{ fontSize: 10, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: 'var(--gold)', marginBottom: 7 }}>Potentielle medspillere</div>
              {lead.potential_partners.map((p, i) => (
                <div key={i} style={{ display: 'flex', gap: 7, fontSize: 12, color: 'var(--ink-2)', lineHeight: 1.5, padding: '2px 0' }}>
                  <Dot color="var(--gold)" /><span><strong style={{ color: 'var(--ink)', fontWeight: 500 }}>{p.name}</strong> — {p.role}</span>
                </div>
              ))}
            </div>
          )}
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 14, alignItems: 'center' }}>
            {lead.gold_matches.length > 0 && (
              <div style={{ fontSize: 12, color: 'var(--ink-3)' }}>Guldkatalog:{' '}
                {lead.gold_matches.map((m, i) => <span key={i}><span style={{ color: 'var(--gold)', fontWeight: 500 }}>{m.title} ({m.pct}%)</span>{i < lead.gold_matches.length - 1 ? ' · ' : ''}</span>)}
              </div>
            )}
            <div style={{ fontSize: 12, color: 'var(--ink-3)' }}>Åbner: <span style={{ color: 'var(--ink)', fontWeight: 500 }}>{lead.opener}</span></div>
          </div>
        </div>
        <div style={{ textAlign: 'right', flexShrink: 0, minWidth: 64 }}>
          <div style={{ fontSize: 10, color: 'var(--ink-3)', marginBottom: 4, textTransform: 'uppercase', letterSpacing: '0.07em' }}>Score</div>
          <div style={{ fontSize: 28, fontWeight: 700, color: mc.score, letterSpacing: '-0.03em' }}>{lead.score}</div>
          <div style={{ fontSize: 10, color: 'var(--ink-3)', marginTop: 5, lineHeight: 1.6 }}>{lead.size_info}<br />{lead.cvr_verified ? 'CVR ✓' : ''}</div>
        </div>
      </div>
    </div>
  )
}
EOF
echo "✓ frontend/components/LeadCard.tsx"

# ─── BACKEND ───

cat > backend/requirements.txt << 'EOF'
fastapi==0.111.0
uvicorn==0.29.0
httpx==0.27.0
feedparser==6.0.11
anthropic==0.25.0
supabase==2.4.6
python-dotenv==1.0.1
apscheduler==3.10.4
resend==2.0.0
pydantic==2.7.1
EOF
echo "✓ backend/requirements.txt"

cat > backend/.env.example << 'EOF'
ANTHROPIC_API_KEY=sk-ant-...
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_KEY=eyJ...
RESEND_API_KEY=re_...
REPORT_RECIPIENTS=rasmus@nextstep.one,direktor@nextstep.one
ACCESS_PASSWORD=nextstep2026
EOF
echo "✓ backend/.env.example"

cat > backend/main.py << 'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from contextlib import asynccontextmanager
import os

from routers import leads, scraper, reports
from services.scraper_service import run_scraper

load_dotenv()
scheduler = AsyncIOScheduler()

@asynccontextmanager
async def lifespan(app: FastAPI):
    scheduler.add_job(run_scraper, 'cron', minute=0, id='hourly_scrape')
    scheduler.start()
    print("Scheduler startet – scraper hver time")
    yield
    scheduler.shutdown()

app = FastAPI(title="NEXTSTEP Intelligence API", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

app.include_router(leads.router)
app.include_router(scraper.router)
app.include_router(reports.router)

@app.get("/health")
def health():
    return {"status": "ok", "service": "NEXTSTEP Intelligence"}
EOF
echo "✓ backend/main.py"

touch backend/routers/__init__.py
touch backend/services/__init__.py

cat > backend/routers/leads.py << 'EOF'
from fastapi import APIRouter
from services.db_service import get_leads
router = APIRouter(prefix="/leads", tags=["leads"])

@router.get("")
async def list_leads(module: str = None, limit: int = 20):
    leads = await get_leads(module=module, limit=limit)
    return {"leads": leads}
EOF
echo "✓ backend/routers/leads.py"

cat > backend/routers/scraper.py << 'EOF'
from fastapi import APIRouter
from services.scraper_service import run_scraper
router = APIRouter(prefix="/scraper", tags=["scraper"])

@router.post("/run")
async def trigger_scraper():
    result = await run_scraper()
    return {"status": "done", "new_leads": result}
EOF
echo "✓ backend/routers/scraper.py"

cat > backend/routers/reports.py << 'EOF'
from fastapi import APIRouter
from services.report_service import generate_report
router = APIRouter(prefix="/reports", tags=["reports"])

@router.post("/generate")
async def trigger_report(period: str = "week"):
    result = await generate_report(period=period)
    return {"status": "generated", "report_id": result}
EOF
echo "✓ backend/routers/reports.py"

cat > backend/services/db_service.py << 'EOF'
import os
from supabase import create_client, Client

_client: Client | None = None

def get_client() -> Client:
    global _client
    if not _client:
        url = os.getenv("SUPABASE_URL")
        key = os.getenv("SUPABASE_KEY")
        if url and key:
            _client = create_client(url, key)
    return _client

async def get_leads(module: str = None, limit: int = 20) -> list:
    client = get_client()
    if not client:
        return []
    try:
        query = client.table("leads").select("*").order("score", desc=True).limit(limit)
        if module:
            query = query.eq("module", module)
        return (query.execute()).data or []
    except Exception as e:
        print(f"DB fejl: {e}")
        return []

async def save_lead(lead: dict) -> bool:
    client = get_client()
    if not client:
        return False
    try:
        client.table("leads").insert(lead).execute()
        return True
    except Exception as e:
        print(f"Gem fejl: {e}")
        return False

async def article_exists(url: str) -> bool:
    client = get_client()
    if not client:
        return False
    try:
        result = client.table("leads").select("id").eq("url", url).execute()
        return len(result.data) > 0
    except:
        return False
EOF
echo "✓ backend/services/db_service.py"

cat > backend/services/scraper_service.py << 'EOF'
import feedparser
import anthropic
import json
import os
from datetime import datetime
from services.db_service import save_lead, article_exists

RSS_FEEDS = [
    {"name": "Altinget", "url": "https://www.altinget.dk/rss/altinget.rss"},
    {"name": "DR Nyheder", "url": "https://www.dr.dk/nyheder/service/feeds/allenyheder"},
    {"name": "Politiken", "url": "https://politiken.dk/rss/"},
]

client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

async def run_scraper() -> int:
    new_leads = 0
    all_articles = []
    for feed_info in RSS_FEEDS:
        try:
            feed = feedparser.parse(feed_info["url"])
            for entry in feed.entries[:20]:
                article = {
                    "title": entry.get("title", ""),
                    "summary": entry.get("summary", entry.get("description", "")),
                    "url": entry.get("link", ""),
                    "source": feed_info["name"],
                    "published": entry.get("published", str(datetime.now())),
                }
                if article["title"] and not await article_exists(article["url"]):
                    all_articles.append(article)
        except Exception as e:
            print(f"Fejl ved {feed_info['name']}: {e}")

    for article in all_articles:
        lead = await analyze_article(article)
        if lead:
            await save_lead(lead)
            new_leads += 1

    print(f"Scraper færdig: {new_leads} nye leads af {len(all_articles)} artikler")
    return new_leads

async def analyze_article(article: dict) -> dict | None:
    prompt = f"""Du er strategisk analytiker for NEXTSTEP A/S – dansk strategi- og innovationshus med speciale i Public Affairs og velfærdsforbedringer.

Analyser denne artikel og vurder om den indeholder et lead for NEXTSTEP.

ARTIKEL:
Kilde: {article['source']}
Titel: {article['title']}
Indhold: {article['summary'][:1000]}

NEXTSTEP arbejder med to moduler:
1. PUBLIC AFFAIRS: Virksomheder/organisationer der har brug for politisk dialog eller reguleringsnavigation. Minimum 50 ansatte.
2. VELFÆRD: Kommuner/regioner/organisationer med komplekse problemer de ikke kan løse selv.

Opgavetyper: Alliance, Camp, Entreprenør.

Svar KUN med JSON eller null:
{{
  "relevant": true/false,
  "title": "titel",
  "summary": "2-3 sætninger",
  "module": "public_affairs" eller "velfaerd",
  "opgave_type": "Alliance", "Camp" eller "Entreprenør",
  "sector": "sektor",
  "score": 1-10,
  "size_info": "størrelse",
  "stakeholders": [{{"name": "navn", "role": "rolle"}}],
  "potential_partners": [{{"name": "navn", "role": "hvorfor relevant"}}],
  "gold_matches": [],
  "opener": "konkret indgangsvinkel"
}}"""

    try:
        response = client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=1000,
            messages=[{"role": "user", "content": prompt}]
        )
        text = response.content[0].text.strip()
        if "```" in text:
            text = text.split("```")[1]
            if text.startswith("json"):
                text = text[4:]
        data = json.loads(text)
        if not data.get("relevant"):
            return None
        data.update({"url": article["url"], "source": article["source"], "published_at": article["published"], "cvr_verified": False})
        return data
    except Exception as e:
        print(f"Analyse fejl: {e}")
        return None
EOF
echo "✓ backend/services/scraper_service.py"

cat > backend/services/report_service.py << 'EOF'
import os
import anthropic
from services.db_service import get_leads

client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

async def generate_report(period: str = "week") -> str:
    leads = await get_leads(limit=10)
    if not leads:
        return "no_leads"
    leads_text = "\n\n".join([
        f"LEAD {i+1}: {l.get('title')}\nModul: {l.get('module')}\nScore: {l.get('score')}\nÅbner: {l.get('opener')}"
        for i, l in enumerate(leads)
    ])
    prompt = f"""Skriv en kort professionel mandagsrapport på dansk for NEXTSTEP A/S baseret på ugens leads.
Tone: direkte, handlingsorienteret. Start med 3-4 sætningers opsummering, list derefter de vigtigste leads med anbefalet handling.

LEADS:
{leads_text}"""

    response = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=1000,
        messages=[{"role": "user", "content": prompt}]
    )
    report_id = f"report_{period}_{os.urandom(4).hex()}"
    print(f"Rapport genereret: {report_id}")
    return report_id
EOF
echo "✓ backend/services/report_service.py"

echo ""
echo "✅ Alle filer oprettet. Kodebasen er klar!"
