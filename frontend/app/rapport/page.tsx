'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { Lead } from '@/app/dashboard/page'

function getWeekNumber(d: Date) {
  const date = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
  date.setUTCDate(date.getUTCDate() + 4 - (date.getUTCDay() || 7))
  const yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1))
  return Math.ceil((((date.getTime() - yearStart.getTime()) / 86400000) + 1) / 7)
}

function getDayLabel(d: Date): string {
  const day = d.getDay()
  if (day === 1) return 'Mandag'
  if (day === 4) return 'Torsdag'
  return d.toLocaleDateString('da-DK', { weekday: 'long' }).replace(/^\w/, c => c.toUpperCase())
}

const SECTORS = [
  { key: 'sundhed', label: 'Sundhed', color: '#2a9d8f' },
  { key: 'fødevarer', label: 'Fødevarer', color: '#5c8a2a' },
  { key: 'energi', label: 'Energi', color: '#e9c46a' },
  { key: 'klima', label: 'Klima', color: '#2a6b7d' },
  { key: 'by og bolig', label: 'By og Bolig', color: '#9b5de5' },
  { key: 'beskæftigelse', label: 'Beskæftigelse', color: '#c77dff' },
  { key: 'sikkerhed', label: 'Sikkerhed', color: '#e76f51' },
]

function RadarChart({ leads }: { leads: Lead[] }) {
  const counts: Record<string, number> = {}
  SECTORS.forEach(s => { counts[s.key] = 0 })

  leads.forEach(lead => {
    const sector = (lead.sector || '').toLowerCase()
    SECTORS.forEach(s => {
      if (sector.includes(s.key) || sector.includes(s.label.toLowerCase())) {
        counts[s.key]++
      }
    })
  })

  const max = Math.max(...Object.values(counts), 1)
  const n = SECTORS.length
  const cx = 185, cy = 140, r = 100

  const angleOf = (i: number) => (Math.PI * 2 * i / n) - Math.PI / 2

  const gridLevels = [0.25, 0.5, 0.75, 1.0]
  const axisPoints = SECTORS.map((_, i) => ({
    x: cx + r * Math.cos(angleOf(i)),
    y: cy + r * Math.sin(angleOf(i)),
  }))

  const dataPoints = SECTORS.map((s, i) => {
    const val = Math.max(counts[s.key] / max, 0.05)
    return {
      x: cx + r * val * Math.cos(angleOf(i)),
      y: cy + r * val * Math.sin(angleOf(i)),
    }
  })

  const dataPath = dataPoints.map((p, i) => `${i === 0 ? 'M' : 'L'} ${p.x} ${p.y}`).join(' ') + ' Z'

  return (
    <svg viewBox="0 0 370 280" style={{ width: '100%', maxWidth: 370 }}>
      {/* Grid circles */}
      {gridLevels.map((level, li) => (
        <polygon
          key={li}
          points={SECTORS.map((_, i) => {
            const x = cx + r * level * Math.cos(angleOf(i))
            const y = cy + r * level * Math.sin(angleOf(i))
            return `${x},${y}`
          }).join(' ')}
          fill="none"
          stroke="rgba(255,255,255,0.08)"
          strokeWidth="1"
        />
      ))}

      {/* Axes */}
      {axisPoints.map((pt, i) => (
        <line key={i} x1={cx} y1={cy} x2={pt.x} y2={pt.y} stroke="rgba(255,255,255,0.1)" strokeWidth="1" />
      ))}

      {/* Data shape */}
      <path d={dataPath} fill="rgba(184,150,62,0.25)" stroke="#b8963e" strokeWidth="2" />

      {/* Data points */}
      {dataPoints.map((pt, i) => (
        <circle key={i} cx={pt.x} cy={pt.y} r={counts[SECTORS[i].key] > 0 ? 4 : 2}
          fill={counts[SECTORS[i].key] > 0 ? SECTORS[i].color : 'rgba(255,255,255,0.2)'}
        />
      ))}

      {/* Labels */}
      {SECTORS.map((s, i) => {
        const angle = angleOf(i)
        const labelR = r + 22
        const lx = cx + labelR * Math.cos(angle)
        const ly = cy + labelR * Math.sin(angle)
        const anchor = lx < cx - 10 ? 'end' : lx > cx + 10 ? 'start' : 'middle'
        return (
          <g key={i}>
            <text x={lx} y={ly - 3} textAnchor={anchor} fontSize="8.5" fontWeight="600"
              fill={counts[s.key] > 0 ? s.color : 'rgba(255,255,255,0.3)'}>
              {s.label}
            </text>
            {counts[s.key] > 0 && (
              <text x={lx} y={ly + 9} textAnchor={anchor} fontSize="8" fill="rgba(255,255,255,0.5)">
                {counts[s.key]} lead{counts[s.key] !== 1 ? 's' : ''}
              </text>
            )}
          </g>
        )
      })}

      {/* Center dot */}
      <circle cx={cx} cy={cy} r={3} fill="rgba(255,255,255,0.3)" />
    </svg>
  )
}

const MC = {
  public_affairs: { color: '#1a1a1a', label: 'Public Affairs' },
  velfaerd: { color: '#2a7d5f', label: 'Velfærd' },
}

export default function RapportPage() {
  const router = useRouter()
  const [leads, setLeads] = useState<Lead[]>([])
  const [loading, setLoading] = useState(true)
  const [sending, setSending] = useState(false)
  const [sent, setSent] = useState(false)
  const [clientName, setClientName] = useState('')

  useEffect(() => {
    const auth = sessionStorage.getItem('ns_auth')
    if (!auth) { router.push('/'); return }
    const savedClient = sessionStorage.getItem('klientlinse_client')
    if (savedClient) {
      setClientName(savedClient)
      fetch('https://nextstep-intelligence-production.up.railway.app/klientlinse/analyze', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ client_name: savedClient }),
      }).then(r => r.json()).then(async d => {
        const jobId = d.job_id
        if (!jobId) { setLoading(false); return }
        const poll = async () => {
          const r = await fetch(`https://nextstep-intelligence-production.up.railway.app/klientlinse/status/${jobId}`)
          const data = await r.json()
          if (data.status === 'done' && data.leads?.length) {
            setLeads(data.leads)
            setLoading(false)
          } else if (data.status === 'running') {
            setTimeout(poll, 2000)
          } else {
            setLoading(false)
          }
        }
        setTimeout(poll, 2000)
      }).catch(() => setLoading(false))
    } else {
      fetch('/api/leads?limit=20&sort=score')
        .then(r => r.json())
        .then(d => { setLeads(d.leads || []); setLoading(false) })
        .catch(() => setLoading(false))
    }
  }, [])

  const handleApprove = async () => {
    setSending(true)
    try {
      const res = await fetch('https://nextstep-intelligence-production.up.railway.app/mail/godkend-og-send', { method: 'POST' })
      const data = await res.json()
      if (data.status === 'sent') {
        Object.keys(localStorage).filter(k => k.startsWith('star_')).forEach(k => localStorage.removeItem(k))
        setSent(true)
      } else {
        alert('Noget gik galt – prøv igen')
      }
    } catch { alert('Fejl – prøv igen') }
    finally { setSending(false) }
  }

  const now = new Date()
  const week = getWeekNumber(now)
  const dayLabel = getDayLabel(now)
  const starred = leads.filter(l => (l.stars || 0) > 0).sort((a, b) => (b.stars || 0) - (a.stars || 0))
  const topLeads = clientName
    ? leads.slice(0, 6)
    : leads.filter(l => (l.stars || 0) === 0).slice(0, starred.length > 0 ? 4 : 6)

  const [showPin, setShowPin] = useState(false)
  const [pin, setPin] = useState('')
  const [pinError, setPinError] = useState(false)

  const handlePinSubmit = () => {
    if (pin === '3250') {
      setShowPin(false)
      setPin('')
      setPinError(false)
      handleApprove()
    } else {
      setPinError(true)
      setPin('')
    }
  }

  return (
    <>
      {showPin && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <div style={{ background: 'white', borderRadius: 12, padding: '28px 32px', width: 280, boxShadow: '0 8px 40px rgba(0,0,0,0.2)' }}>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#0d1b2e', marginBottom: 6 }}>Godkend rapport</div>
            <div style={{ fontSize: 12, color: '#888', marginBottom: 16 }}>Indtast PIN-kode for at sende rapporten til teamet</div>
            <input
              type="password"
              value={pin}
              onChange={e => { setPin(e.target.value); setPinError(false) }}
              onKeyDown={e => e.key === 'Enter' && handlePinSubmit()}
              placeholder="PIN-kode"
              autoFocus
              style={{ width: '100%', padding: '9px 12px', fontSize: 16, borderRadius: 8, border: pinError ? '1.5px solid #e74c3c' : '1.5px solid #e0ddd8', outline: 'none', marginBottom: pinError ? 6 : 16, boxSizing: 'border-box', letterSpacing: '0.3em' }}
            />
            {pinError && <div style={{ fontSize: 11, color: '#e74c3c', marginBottom: 12 }}>Forkert PIN-kode</div>}
            <div style={{ display: 'flex', gap: 8 }}>
              <button onClick={() => { setShowPin(false); setPin(''); setPinError(false) }} style={{ flex: 1, padding: '8px', borderRadius: 8, border: '1px solid #e0ddd8', background: 'white', color: '#666', fontSize: 12, cursor: 'pointer' }}>
                Annuller
              </button>
              <button onClick={handlePinSubmit} style={{ flex: 1, padding: '8px', borderRadius: 8, border: 'none', background: '#b8963e', color: 'white', fontSize: 12, fontWeight: 600, cursor: 'pointer' }}>
                Send ↗
              </button>
            </div>
          </div>
        </div>
      )}
      <style>{`
        @media print { * { -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; color-adjust: exact !important; }
          .no-print { display: none !important; }
          body { background: white !important; }
        }
        .rapport-wrap { min-height: 100vh; background: #f2f0eb; padding: 32px 0; } @media print { .rapport-wrap { padding: 0 !important; background: #f2f0eb !important; } .no-print { display: none !important; } }
      `}</style>

      <div className="rapport-wrap">
        <div style={{ maxWidth: 740, margin: '0 auto', padding: '0 24px' }}>

          {/* Topbar */}
          <div className="no-print" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20, flexWrap: 'wrap', gap: 8 }}>
            <button onClick={() => router.push('/dashboard')} style={{ fontSize: 12, padding: '7px 14px', borderRadius: 8, border: '1px solid rgba(0,0,0,0.12)', background: 'white', color: '#1a1a1a', cursor: 'pointer' }}>
              ← Dashboard
            </button>
            <div style={{ display: 'flex', gap: 8 }}>
              <button onClick={() => window.print()} style={{ fontSize: 12, padding: '7px 14px', borderRadius: 8, border: '1px solid rgba(0,0,0,0.12)', background: 'white', color: '#1a1a1a', cursor: 'pointer' }}>
                Print / PDF
              </button>
              {!clientName && (!sent ? (
                <button onClick={() => setShowPin(true)} disabled={sending} style={{ fontSize: 12, fontWeight: 600, padding: '7px 18px', borderRadius: 8, border: 'none', background: '#b8963e', color: 'white', cursor: 'pointer' }}>
                  {sending ? 'Sender...' : 'Godkend og send ↗'}
                </button>
              ) : (
                <div style={{ fontSize: 12, fontWeight: 500, padding: '7px 18px', borderRadius: 8, background: '#edf5f1', color: '#2a7d5f' }}>✓ Sendt</div>
              ))}
            </div>
          </div>

          {/* Dokument */}
          <div style={{ background: 'white', borderRadius: 16, overflow: 'hidden', boxShadow: '0 4px 32px rgba(0,0,0,0.09)' }}>

            {/* Header – mørk */}
            <div style={{ background: 'linear-gradient(135deg, #0d1b2e 0%, #1a2f4a 100%)', padding: '36px 44px 32px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 6 }}>
                {/* Logo – mix-blend-mode gør hvid transparent på mørk baggrund */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                  <img
                    src="/nextstep-logo.png"
                    alt="NEXTSTEP"
                    style={{ height: 36, width: 'auto', objectFit: 'contain', mixBlendMode: 'screen', opacity: 0.95 }}
                  />
                  <div style={{ fontSize: 9, letterSpacing: '0.18em', color: 'rgba(255,255,255,0.35)', textTransform: 'uppercase', marginTop: 6 }}>
                    <span style={{display:"block"}}>PUBLIC AFFAIRS</span><span style={{display:"block"}}>INTELLIGENCE</span>
                  </div>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div style={{ fontSize: 9, letterSpacing: '0.14em', color: 'rgba(255,255,255,0.35)', textTransform: 'uppercase', marginBottom: 4 }}>
                    Politisk Radar · Fortrolig
                  </div>
                  <div style={{ fontSize: 20, fontWeight: 700, color: 'white', letterSpacing: '-0.01em' }}>
                    {dayLabel} · Uge {week} · {now.getFullYear()}
                  </div>
                  <div style={{ fontSize: 10, color: 'rgba(255,255,255,0.3)', marginTop: 3 }}>
                    Scout NS · AI-assisteret nyhedsanalyse
                  </div>
                  {clientName && <div style={{ fontSize: 11, color: '#c47a7a', marginTop: 6, fontWeight: 600 }}>Klientperspektiv: {clientName}</div>}
                </div>
              </div>

              <div style={{ height: 1, background: 'rgba(255,255,255,0.08)', margin: '20px 0' }} />

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 20 }}>
                <div>
                  <div style={{ fontSize: 9, letterSpacing: '0.12em', color: 'rgba(255,255,255,0.35)', textTransform: 'uppercase', marginBottom: 10 }}>
                    Politisk aktivitetskort · Uge {week}
                  </div>
                  <RadarChart leads={leads} />
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div style={{ fontSize: 52, fontWeight: 800, color: 'white', lineHeight: 1, letterSpacing: '-0.03em' }}>{leads.length}</div>
                  <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.4)', marginTop: 4 }}>leads identificeret</div>
                  <div style={{ marginTop: 16, display: 'flex', flexDirection: 'column', gap: 4, alignItems: 'flex-end' }}>
                    <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.35)' }}>
                      <span style={{ color: '#b8963e', fontWeight: 600 }}>{leads.filter(l => l.module === 'public_affairs').length}</span> Public Affairs
                    </div>
                    <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.35)' }}>
                      <span style={{ color: '#2a9d8f', fontWeight: 600 }}>{leads.filter(l => l.module === 'velfaerd').length}</span> Velfærd
                    </div>
                    {!clientName && starred.length > 0 && (
                      <div style={{ fontSize: 11, color: '#b8963e', fontWeight: 600, marginTop: 4 }}>
                        ★ {starred.length} teamprioritet{starred.length !== 1 ? 'er' : ''}
                      </div>
                    )}
                  </div>
                </div>
              </div>

              {/* Tagline */}
              <div style={{ marginTop: 20, paddingTop: 16, borderTop: '1px solid rgba(255,255,255,0.07)', fontSize: 11, color: 'rgba(255,255,255,0.25)', fontStyle: 'italic', letterSpacing: '0.02em' }}>
                Data-driven political intelligence — NEXTSTEP Public Affairs Intelligence ©
              </div>
            </div>

            {/* Leads sektion */}
            <div style={{ padding: '32px 44px' }}>
              {loading ? (
                <div style={{ textAlign: 'center', padding: 40, color: '#999' }}>Henter leads...</div>
              ) : (
                <>
                  {!clientName && starred.length > 0 && (
                    <>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 18 }}>
                        <div style={{ height: 1, flex: 1, background: '#f0ede8' }} />
                        <div style={{ fontSize: 9, fontWeight: 700, letterSpacing: '0.14em', textTransform: 'uppercase', color: '#b8963e' }}>★ Teamets prioriteter</div>
                        <div style={{ height: 1, flex: 1, background: '#f0ede8' }} />
                      </div>
                      {starred.map(lead => <CompactLead key={lead.id} lead={lead} priority />)}
                      <div style={{ height: 1, background: '#f5f3f0', margin: '24px 0' }} />
                    </>
                  )}

                  <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 18 }}>
                    <div style={{ height: 1, flex: 1, background: '#f0ede8' }} />
                    <div style={{ fontSize: 9, fontWeight: 700, letterSpacing: '0.14em', textTransform: 'uppercase', color: '#aaa' }}>
                      {clientName ? 'Klientprioriterede leads' : starred.length > 0 ? 'Øvrige aktuelle leads' : 'Aktuelle top-leads'}
                    </div>
                    <div style={{ height: 1, flex: 1, background: '#f0ede8' }} />
                  </div>
                  {topLeads.map(lead => <CompactLead key={lead.id} lead={lead} clientName={clientName} />)}
                </>
              )}

              {/* Footer */}
              <div style={{ marginTop: 36, paddingTop: 20, borderTop: '1px solid #f0ede8' }}>
                <div style={{ fontSize: 10, color: '#bbb', letterSpacing: '0.02em' }}>
                  NEXTSTEP Public Affairs Intelligence © · Scout NS · {now.toLocaleDateString('da-DK', { day: 'numeric', month: 'long', year: 'numeric' })}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  )
}

function CompactLead({ lead, priority, clientName }: { lead: Lead; priority?: boolean; clientName?: string }) {
  const mc = MC[lead.module] || MC.public_affairs
  const OC: Record<string, string> = {
    Alliance: '#b8963e', Camp: '#5c3d99', 'Entreprenør': '#a0430a',
  }
  const typeColor = OC[lead.opgave_type] || '#888'

  return (
    <div style={{ padding: '16px 0', borderBottom: '1px solid #f5f3f0', display: 'flex', gap: 16, alignItems: 'flex-start' }}>
      <div style={{ width: 3, borderRadius: 2, background: mc.color, alignSelf: 'stretch', flexShrink: 0, minHeight: 44 }} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', gap: 5, alignItems: 'center', marginBottom: 6, flexWrap: 'wrap' }}>
          <span style={{ fontSize: 9, fontWeight: 700, padding: '2px 7px', borderRadius: 20, background: mc.color === '#1a1a1a' ? '#1a1a1a' : '#edf5f1', color: mc.color === '#1a1a1a' ? 'white' : mc.color, letterSpacing: '0.04em' }}>{mc.label}</span>
          <span style={{ fontSize: 9, fontWeight: 500, color: typeColor }}>{lead.opgave_type}</span>
          <span style={{ fontSize: 9, color: '#ccc' }}>·</span>
          <span style={{ fontSize: 9, color: '#bbb' }}>{lead.sector}</span>
          <span style={{ fontSize: 9, color: '#ccc' }}>·</span>
          <span style={{ fontSize: 9, color: '#bbb' }}>{lead.source} · {lead.published_at}</span>
          {priority && !clientName && (lead.stars || 0) > 0 && <span style={{ fontSize: 9, color: '#b8963e', fontWeight: 700 }}>★ {lead.stars}</span>}
        </div>
        <div style={{ fontSize: 13, fontWeight: 700, color: '#0d1b2e', marginBottom: 5, letterSpacing: '-0.01em', lineHeight: 1.35 }}>{lead.title}</div>
        <div style={{ fontSize: 12, color: '#666', lineHeight: 1.6, marginBottom: 6 }}>
          {lead.summary?.length > 140 ? lead.summary.slice(0, 140) + '...' : lead.summary}
        </div>
        <div style={{ fontSize: 11, color: '#999', borderLeft: '2px solid #e8d08a', paddingLeft: 8 }}>
          <span style={{ color: '#b8963e', fontWeight: 600 }}>Vej ind:</span>{' '}
          <span style={{ color: '#333' }}>{(lead as any).client_opener ? ((lead as any).client_opener.length > 120 ? (lead as any).client_opener.slice(0, 120) + '...' : (lead as any).client_opener) : (lead.opener?.length > 120 ? lead.opener.slice(0, 120) + '...' : lead.opener)}</span>
        </div>
      </div>
      <div style={{ textAlign: 'right', flexShrink: 0 }}>
        <div style={{ fontSize: 8, color: '#ccc', textTransform: 'uppercase', letterSpacing: '0.08em' }}>Score</div>
        <div style={{ fontSize: 22, fontWeight: 800, color: (lead as any).client_score ? '#c47a7a' : '#0d1b2e', letterSpacing: '-0.02em' }}>{(lead as any).client_score || lead.score}</div>
      </div>
    </div>
  )
}
