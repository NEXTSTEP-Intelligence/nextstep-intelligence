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
  url: string
  score: number
  cvr_verified: boolean
  size_info: string
  stakeholders: { name: string; role: string }[]
  potential_partners: { name: string; role: string }[]
  gold_matches: { title: string; pct: number }[]
  opener: string
  stars: number
}

const DEMO_LEADS: Lead[] = [
  {
    id: '1',
    url: '',
    stars: 0,
    title: 'NKT A/S søger politisk opbakning til nyt datacenter i Silkeborg',
    summary: 'Virksomheden ønsker at bygge et 400 MW AI-datacenter men møder modstand fra lokalpolitikere om arealplanlægning og strømforsyning. Ingen intern PA-kapabilitet identificeret.',
    module: 'public_affairs', opgave_type: 'Alliance', sector: 'Energi',
    source: 'Berlingske', published_at: '29. apr', score: 9.2,
    cvr_verified: true, size_info: '2.800 ansatte',
    stakeholders: [
      { name: 'Energistyrelsen', role: 'Godkendelsesmyndighed, kan accelerere eller blokere' },
      { name: 'Silkeborg Kommune', role: 'Lokalplan skal ændres, borgmester skeptisk' },
    ],
    potential_partners: [
      { name: 'Dansk Industri', role: 'Naturlig alliancepartner for storvirksomheders infrastrukturbehov' },
    ],
    gold_matches: [{ title: 'Grøn Varme Alliancen', pct: 83 }],
    opener: 'Alliance-model med energiselskaber',
  },
  {
    id: '2',
    url: '',
    stars: 0,
    title: 'Vejle Kommune skal implementere ældrepleje-reform inden udgangen af 2026',
    summary: 'Kommunen er bagud på KLs benchmarks og har ingen intern kapacitet til at drive processen.',
    module: 'velfaerd', opgave_type: 'Camp', sector: 'Sundhed',
    source: 'Altinget', published_at: '28. apr', score: 8.7,
    cvr_verified: true, size_info: '115.000 borgere',
    stakeholders: [
      { name: 'KL', role: 'Offentliggør benchmark-rangering i juni, skaber politisk pres' },
    ],
    potential_partners: [
      { name: 'FOA', role: 'Fagforening for plejepersonalet, afgørende for implementering' },
      { name: 'Ældre Sagen', role: 'Legitimerer løsningen hos borgerne' },
    ],
    gold_matches: [{ title: 'LOKK', pct: 79 }],
    opener: '100-dages forandringsmodel',
  },
]

function getWeekNumber(d: Date) {
  const date = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
  date.setUTCDate(date.getUTCDate() + 4 - (date.getUTCDay() || 7))
  const yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1))
  return Math.ceil((((date.getTime() - yearStart.getTime()) / 86400000) + 1) / 7)
}

function formatDate(str: string): string {
  try {
    const d = new Date(str)
    if (isNaN(d.getTime())) return str
    return d.toLocaleDateString('da-DK', { day: 'numeric', month: 'short' })
  } catch { return str }
}

export default function Dashboard() {
  const router = useRouter()
  const [leads, setLeads] = useState<Lead[]>(DEMO_LEADS)
  const [filter, setFilter] = useState('alle')
  const [activeModule, setActiveModule] = useState('alle')

  useEffect(() => {
    const auth = localStorage.getItem('ns_auth')
    if (!auth) { router.push('/'); return }
    fetch('/api/leads').then(r => r.json()).then(d => {
      if (d.leads?.length) setLeads(d.leads)
    }).catch(() => {})
  }, [])

  const filtered = leads.filter(l => {
    if (activeModule === 'pa') return l.module === 'public_affairs'
    if (activeModule === 'vel') return l.module === 'velfaerd'
    if (filter === 'rebizz') return l.gold_matches?.length > 0
    if (filter !== 'alle') return l.opgave_type === filter
    return true
  })

  const now = new Date()
  const week = getWeekNumber(now)
  const pa = leads.filter(l => l.module === 'public_affairs').length
  const vel = leads.filter(l => l.module === 'velfaerd').length
  const rebizz = leads.filter(l => l.gold_matches?.length > 0).length

  const leadsWithFormattedDates = filtered.map(l => ({
    ...l,
    published_at: formatDate(l.published_at),
  }))

  return (
    <>
      <style>{`
        .ns-layout { display: grid; grid-template-columns: 192px 1fr; min-height: 100vh; }
        .ns-main { padding: 28px 32px; background: var(--bg); }
        @media (max-width: 768px) {
          .ns-layout { grid-template-columns: 1fr; }
          .ns-main { padding: 72px 14px 24px; }
        }
      `}</style>
      <div className="ns-layout">
        <Sidebar activeModule={activeModule} setActiveModule={setActiveModule} />
        <main className="ns-main">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 20, flexWrap: 'wrap', gap: 10 }}>
            <div>
              <h1 style={{ fontSize: 22, fontWeight: 700, letterSpacing: '-0.02em' }}>Uge {week} · {now.getFullYear()}</h1>
              <p style={{ fontSize: 12, color: 'var(--ink-3)', marginTop: 4 }}>
                Opdateret kl. {String(now.getHours()).padStart(2,'0')}:{String(now.getMinutes()).padStart(2,'0')} · Næste rapport torsdag kl. 08:30
              </p>
            </div>
            <button style={{ fontSize: 12, fontWeight: 500, padding: '8px 18px', borderRadius: 'var(--radius-sm)', border: '1px solid rgba(0,0,0,0.12)', background: 'var(--surface)', color: 'var(--ink)', whiteSpace: 'nowrap' }}>
              Generer rapport ↗
            </button>
          </div>
          <ReviewBanner />
          <StatsRow total={leads.length} pa={pa} vel={vel} rebizz={rebizz} />
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', margin: '18px 0' }}>
            {['alle', 'Alliance', 'Camp', 'Entreprenør', 'rebizz'].map(f => (
              <button key={f} onClick={() => setFilter(f)} style={{
                fontSize: 12, padding: '5px 13px', borderRadius: 20,
                border: '1px solid rgba(0,0,0,0.1)',
                background: filter === f ? 'var(--ink)' : 'transparent',
                color: filter === f ? '#fff' : 'var(--ink-2)',
                cursor: 'pointer',
              }}>
                {f === 'alle' ? 'Alle' : f === 'rebizz' ? 'Rebizz' : f}
              </button>
            ))}
          </div>
          {leadsWithFormattedDates.map(lead => <LeadCard key={lead.id} lead={lead} />)}
          {filtered.length === 0 && <div style={{ textAlign: 'center', padding: 60, color: 'var(--ink-3)', fontSize: 14 }}>Ingen leads matcher filteret.</div>}
        </main>
      </div>
    </>
  )
}
