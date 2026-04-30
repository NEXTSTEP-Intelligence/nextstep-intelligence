
'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Sidebar from '@/components/Sidebar'
import LeadCard from '@/components/LeadCard'
import StatsRow from '@/components/StatsRow'
import ReviewBanner from '@/components/ReviewBanner'
import KlientlinseBar from '@/components/KlientlinseBar'

function getNextRapport(): string {
  const now = new Date()
  const day = now.getDay()
  const hour = now.getHours()
  if (day === 1 && hour < 10) return 'Mandagsrapport sendes om lidt'
  if (day === 4 && hour < 8) return 'Torsdagsrapport sendes om lidt'
  if (day >= 1 && day <= 3) return 'Næste rapport torsdag kl. 08:30'
  return 'Næste rapport mandag kl. 10:00'
}


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
  stars: number
  update_count?: number
  entity?: string
  client_score?: number
  client_opener?: string
  client_relevance?: string
  cvr_verified: boolean
  size_info: string
  stakeholders: { name: string; role: string }[]
  potential_partners: { name: string; role: string }[]
  gold_matches: { title: string; pct: number }[]
  opener: string
}

const DEMO_LEADS: Lead[] = [
  {
    id: '1', url: '', stars: 0,
    title: 'NKT A/S søger politisk opbakning til nyt datacenter i Silkeborg',
    summary: 'Virksomheden ønsker at bygge et 400 MW AI-datacenter men møder modstand fra lokalpolitikere om arealplanlægning og strømforsyning.',
    module: 'public_affairs', opgave_type: 'Alliance', sector: 'Energi',
    source: 'Berlingske', published_at: '29. apr', score: 82,
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
    id: '2', url: '', stars: 0,
    title: 'Vejle Kommune skal implementere ældrepleje-reform inden udgangen af 2026',
    summary: 'Kommunen er bagud på KLs benchmarks og har ingen intern kapacitet til at drive processen.',
    module: 'velfaerd', opgave_type: 'Camp', sector: 'Sundhed',
    source: 'Altinget', published_at: '28. apr', score: 74,
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
  const [sort, setSort] = useState('score')
  const [activeModule, setActiveModule] = useState('alle')
  const [activeDays, setActiveDays] = useState(7)
  const [clientLeads, setClientLeads] = useState<Lead[] | null>(null)
  const [clientName, setClientName] = useState('')
  const [clientLoading, setClientLoading] = useState(false)

  const fetchLeads = (sortBy: string) => {
    fetch(`/api/leads?sort=${sortBy}&days=${activeDays}`).then(r => r.json()).then(d => {
      if (d.leads?.length) {
        setLeads(d.leads)
        // Hvis klientlinse er aktiv, re-analyser med nye leads
        const savedClient = localStorage.getItem('klientlinse_client')
        if (savedClient) {
          fetch('/api/klientlinse/analyze', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ client_name: savedClient }),
          }).then(r => r.json()).then(d => {
            if (d.leads?.length) setClientLeads(d.leads)
          }).catch(() => {})
        }
      }
    }).catch(() => {})
  }

  useEffect(() => {
    const auth = localStorage.getItem('ns_auth')
    if (!auth) { router.push('/'); return }
    fetchLeads(sort)
    // Gendan klientlinse hvis gemt
    const savedClient = localStorage.getItem('klientlinse_client')
    if (savedClient) {
      setClientName(savedClient)
      fetch('/api/klientlinse/analyze', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ client_name: savedClient }),
      }).then(r => r.json()).then(d => {
        if (d.leads?.length) setClientLeads(d.leads)
      }).catch(() => {})
    }
  }, [])

  const handleDays = (d: number) => {
    setActiveDays(d)
    fetch(`/api/leads?sort=${sort}&days=${d}`).then(r => r.json()).then(data => {
      if (data.leads?.length) setLeads(data.leads)
      else setLeads([])
    }).catch(() => {})
  }

  const handleSort = (s: string) => {
    setSort(s)
    fetchLeads(s)
  }

  const displayLeads = clientLeads || leads
  const filtered = displayLeads.filter(l => {
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
                Opdateret kl. {String(now.getHours()).padStart(2,'0')}:{String(now.getMinutes()).padStart(2,'0')} · {`${getNextRapport()}`}
              </p>
            </div>
            <button onClick={() => router.push('/rapport')} style={{ fontSize: 12, fontWeight: 500, padding: '8px 18px', borderRadius: 'var(--radius-sm)', border: '1px solid rgba(0,0,0,0.12)', background: 'var(--surface)', color: 'var(--ink)', whiteSpace: 'nowrap', cursor: 'pointer' }}>
              Generer rapport ↗
            </button>
          </div>

          <ReviewBanner />
          <KlientlinseBar
            onActivate={(name, leads) => { setClientName(name); setClientLeads(leads); setClientLoading(false) }}
            onDeactivate={() => { setClientName(''); setClientLeads(null); setClientLoading(false) }}
            onLoading={() => setClientLoading(true)}
          />
          <StatsRow total={leads.length} pa={pa} vel={vel} rebizz={rebizz} onDaysChange={handleDays} activeDays={activeDays} />

          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', margin: '18px 0 10px', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
              {['alle', 'Alliance', 'Camp', 'Entreprenør', 'rebizz'].map(f => (
                <button key={f} onClick={() => setFilter(f)} style={{
                  fontSize: 12, padding: '5px 13px', borderRadius: 20, cursor: 'pointer',
                  border: '1px solid rgba(0,0,0,0.1)',
                  background: filter === f ? 'var(--ink)' : 'transparent',
                  color: filter === f ? '#fff' : 'var(--ink-2)',
                }}>
                  {f === 'alle' ? 'Alle' : f === 'rebizz' ? 'Rebizz' : f}
                </button>
              ))}
            </div>
            <div style={{ display: 'flex', gap: 4, alignItems: 'center' }}>
              <span style={{ fontSize: 11, color: 'var(--ink-3)', marginRight: 4 }}>Sorter:</span>
              {[
                { key: 'score', label: 'Relevans' },
                { key: 'date', label: 'Nyeste' },
                { key: 'stars', label: '★ Stjerner' },
              ].map(s => (
                <button key={s.key} onClick={() => handleSort(s.key)} style={{
                  fontSize: 11, padding: '4px 10px', borderRadius: 20, cursor: 'pointer',
                  border: '1px solid rgba(0,0,0,0.1)',
                  background: sort === s.key ? 'var(--ink)' : 'transparent',
                  color: sort === s.key ? '#fff' : 'var(--ink-2)',
                }}>
                  {s.label}
                </button>
              ))}
            </div>
          </div>

          {clientLoading ? (
            <div style={{ textAlign: 'center', padding: 40, color: 'var(--ink-3)', fontSize: 13 }}>⏳ Analyserer leads fra {clientName}s perspektiv...</div>
          ) : leadsWithFormattedDates.map(lead => <LeadCard key={lead.id} lead={lead} />)}
          {filtered.length === 0 && <div style={{ textAlign: 'center', padding: 60, color: 'var(--ink-3)', fontSize: 14 }}>Ingen leads matcher filteret.</div>}
        </main>
      </div>
    </>
  )
}
