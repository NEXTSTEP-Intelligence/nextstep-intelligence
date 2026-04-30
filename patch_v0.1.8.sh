#!/bin/bash
cd ~/nextstep-intelligence
echo "v0.1.8 – Premium rapport + hexagon + email-indstillinger..."

# Kopiér logo til frontend/public
mkdir -p frontend/public
cp ~/nextstep-intelligence/frontend/public/nextstep-logo.png frontend/public/nextstep-logo.png 2>/dev/null || echo "Logo skal kopieres manuelt til frontend/public/"

# Opret rapport-siden med premium design
mkdir -p frontend/app/rapport

cat > frontend/app/rapport/page.tsx << 'ENDOFFILE'
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
  { key: 'sundhed', label: 'Sundhed', color: '#2a7d5f' },
  { key: 'fødevarer', label: 'Fødevarer', color: '#5c8a2a' },
  { key: 'energi', label: 'Energi', color: '#b8963e' },
  { key: 'klima', label: 'Klima', color: '#2a6b7d' },
  { key: 'kommuner', label: 'Kommuner', color: '#5c3d99' },
  { key: 'sikkerhed', label: 'Sikkerhed', color: '#a0430a' },
  { key: 'eu', label: 'EU/Reg.', color: '#185fa5' },
  { key: 'økonomi', label: 'Økonomi', color: '#7d2a4a' },
]

function HexGrid({ leads }: { leads: Lead[] }) {
  const counts: Record<string, number> = {}
  SECTORS.forEach(s => { counts[s.key] = 0 })
  leads.forEach(lead => {
    const sector = (lead.sector || '').toLowerCase()
    SECTORS.forEach(s => {
      if (sector.includes(s.key) || sector.includes(s.label.toLowerCase())) {
        counts[s.key]++
      }
    })
    if (Object.values(counts).every(v => v === 0)) counts['økonomi']++
  })
  const max = Math.max(...Object.values(counts), 1)

  const hexPath = (cx: number, cy: number, r: number) => {
    const pts = []
    for (let i = 0; i < 6; i++) {
      const angle = (Math.PI / 180) * (60 * i - 30)
      pts.push(`${cx + r * Math.cos(angle)},${cy + r * Math.sin(angle)}`)
    }
    return pts.join(' ')
  }

  const positions = [
    { x: 80, y: 50 }, { x: 150, y: 50 }, { x: 220, y: 50 }, { x: 290, y: 50 },
    { x: 115, y: 100 }, { x: 185, y: 100 }, { x: 255, y: 100 }, { x: 325, y: 100 },
  ]

  return (
    <svg viewBox="0 0 400 145" style={{ width: '100%', maxWidth: 420 }}>
      {SECTORS.map((s, i) => {
        const pos = positions[i]
        const intensity = counts[s.key] / max
        const r = 32
        return (
          <g key={s.key}>
            <polygon
              points={hexPath(pos.x, pos.y, r)}
              fill={intensity > 0 ? s.color : '#f0f0f0'}
              opacity={intensity > 0 ? 0.15 + intensity * 0.75 : 1}
              stroke={intensity > 0 ? s.color : '#ddd'}
              strokeWidth="1.5"
            />
            <text x={pos.x} y={pos.y - 6} textAnchor="middle" fontSize="9" fontWeight="600" fill={intensity > 0 ? s.color : '#aaa'}>
              {s.label}
            </text>
            {counts[s.key] > 0 && (
              <text x={pos.x} y={pos.y + 10} textAnchor="middle" fontSize="13" fontWeight="700" fill={s.color}>
                {counts[s.key]}
              </text>
            )}
          </g>
        )
      })}
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

  useEffect(() => {
    const auth = localStorage.getItem('ns_auth')
    if (!auth) { router.push('/'); return }
    fetch('/api/leads?limit=20&sort=stars')
      .then(r => r.json())
      .then(d => { setLeads(d.leads || []); setLoading(false) })
      .catch(() => setLoading(false))
  }, [])

  const handleApprove = async () => {
    setSending(true)
    try {
      await fetch('/api/leads/reset-stars', { method: 'POST' })
      Object.keys(localStorage).filter(k => k.startsWith('star_')).forEach(k => localStorage.removeItem(k))
      setSent(true)
    } catch { alert('Fejl – prøv igen') }
    finally { setSending(false) }
  }

  const now = new Date()
  const week = getWeekNumber(now)
  const dayLabel = getDayLabel(now)
  const starred = leads.filter(l => (l.stars || 0) > 0).sort((a, b) => (b.stars || 0) - (a.stars || 0))
  const topLeads = leads.filter(l => (l.stars || 0) === 0).slice(0, starred.length > 0 ? 4 : 6)
  const allDisplayed = [...starred, ...topLeads]
  const totalLeads = leads.length

  return (
    <>
      <style>{`
        @media print {
          .no-print { display: none !important; }
          body { background: white !important; }
          .rapport-page { padding: 0 !important; }
        }
        .rapport-page { min-height: 100vh; background: #f7f5f0; }
      `}</style>

      <div className="rapport-page" style={{ padding: '32px 0' }}>
        <div style={{ maxWidth: 720, margin: '0 auto', padding: '0 24px' }}>

          {/* Topbar */}
          <div className="no-print" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24, flexWrap: 'wrap', gap: 8 }}>
            <button onClick={() => router.push('/dashboard')} style={{ fontSize: 12, padding: '7px 14px', borderRadius: 8, border: '1px solid rgba(0,0,0,0.12)', background: 'white', color: '#1a1a1a', cursor: 'pointer' }}>
              ← Dashboard
            </button>
            <div style={{ display: 'flex', gap: 8 }}>
              <button onClick={() => window.print()} style={{ fontSize: 12, padding: '7px 14px', borderRadius: 8, border: '1px solid rgba(0,0,0,0.12)', background: 'white', color: '#1a1a1a', cursor: 'pointer' }}>
                Print / PDF
              </button>
              {!sent ? (
                <button onClick={handleApprove} disabled={sending} style={{ fontSize: 12, fontWeight: 600, padding: '7px 18px', borderRadius: 8, border: 'none', background: '#b8963e', color: 'white', cursor: 'pointer' }}>
                  {sending ? 'Sender...' : 'Godkend og send ↗'}
                </button>
              ) : (
                <div style={{ fontSize: 12, fontWeight: 500, padding: '7px 18px', borderRadius: 8, background: '#edf5f1', color: '#2a7d5f' }}>✓ Sendt</div>
              )}
            </div>
          </div>

          {/* Rapport-dokument */}
          <div style={{ background: 'white', borderRadius: 16, overflow: 'hidden', boxShadow: '0 2px 24px rgba(0,0,0,0.07)' }}>

            {/* Header */}
            <div style={{ background: '#0d1b2e', padding: '32px 40px 28px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 24 }}>
                <img src="/nextstep-logo.png" alt="NEXTSTEP" style={{ height: 36, filter: 'brightness(0) invert(1)', opacity: 0.95 }} />
                <div style={{ textAlign: 'right' }}>
                  <div style={{ fontSize: 10, letterSpacing: '0.14em', color: 'rgba(255,255,255,0.45)', textTransform: 'uppercase', marginBottom: 3 }}>Intelligence Rapport</div>
                  <div style={{ fontSize: 18, fontWeight: 700, color: 'white', letterSpacing: '-0.01em' }}>
                    {dayLabel} · Uge {week} · {now.getFullYear()}
                  </div>
                </div>
              </div>
              <div style={{ height: '1px', background: 'rgba(255,255,255,0.1)', marginBottom: 20 }} />
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', flexWrap: 'wrap', gap: 16 }}>
                <div>
                  <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.4)', marginBottom: 6, letterSpacing: '0.06em', textTransform: 'uppercase' }}>Ugens nyhedsbevægelse</div>
                  <HexGrid leads={leads} />
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div style={{ fontSize: 42, fontWeight: 700, color: 'white', lineHeight: 1 }}>{totalLeads}</div>
                  <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.45)', marginTop: 4 }}>leads identificeret</div>
                  {starred.length > 0 && (
                    <div style={{ fontSize: 11, color: '#b8963e', marginTop: 8, fontWeight: 500 }}>★ {starred.length} teamprioritet{starred.length !== 1 ? 'er' : ''}</div>
                  )}
                </div>
              </div>
            </div>

            {/* Leads */}
            <div style={{ padding: '32px 40px' }}>
              {loading ? (
                <div style={{ textAlign: 'center', padding: 40, color: '#999' }}>Henter leads...</div>
              ) : (
                <>
                  {starred.length > 0 && (
                    <>
                      <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: '0.12em', textTransform: 'uppercase', color: '#b8963e', marginBottom: 14 }}>★ Teamets prioriteter</div>
                      {starred.map(lead => <CompactLead key={lead.id} lead={lead} priority />)}
                      <div style={{ height: 1, background: '#f0f0f0', margin: '24px 0' }} />
                    </>
                  )}
                  <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: '0.12em', textTransform: 'uppercase', color: '#999', marginBottom: 14 }}>
                    {starred.length > 0 ? 'Øvrige top-leads' : 'Ugens top-leads'}
                  </div>
                  {topLeads.map(lead => <CompactLead key={lead.id} lead={lead} />)}
                </>
              )}

              {/* Footer */}
              <div style={{ marginTop: 32, paddingTop: 20, borderTop: '1px solid #f0f0f0', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 10 }}>
                <div style={{ fontSize: 11, color: '#aaa' }}>
                  NEXTSTEP Intelligence · Scout NS · Genereret {now.toLocaleDateString('da-DK', { day: 'numeric', month: 'long', year: 'numeric' })}
                </div>
                <a href="https://nextstep-intelligence-production-54dc.up.railway.app/dashboard" style={{ fontSize: 11, fontWeight: 600, color: '#1a1a1a', textDecoration: 'none', padding: '6px 14px', borderRadius: 6, border: '1px solid #e0e0e0' }}>
                  Se alle leads på platformen →
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  )
}

function CompactLead({ lead, priority }: { lead: Lead; priority?: boolean }) {
  const mc = MC[lead.module] || MC.public_affairs
  const OC: Record<string, string> = {
    Alliance: '#b8963e', Camp: '#5c3d99', 'Entreprenør': '#a0430a',
  }
  const typeColor = OC[lead.opgave_type] || '#666'

  return (
    <div style={{
      padding: '14px 0',
      borderBottom: '1px solid #f5f5f5',
      display: 'flex', gap: 16, alignItems: 'flex-start',
    }}>
      <div style={{ width: 3, borderRadius: 2, background: mc.color, alignSelf: 'stretch', flexShrink: 0, minHeight: 40 }} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', gap: 6, alignItems: 'center', marginBottom: 5, flexWrap: 'wrap' }}>
          <span style={{ fontSize: 9, fontWeight: 600, padding: '2px 7px', borderRadius: 20, background: mc.color, color: 'white', letterSpacing: '0.04em' }}>{mc.label}</span>
          <span style={{ fontSize: 9, fontWeight: 500, color: typeColor }}>{lead.opgave_type}</span>
          <span style={{ fontSize: 9, color: '#bbb' }}>·</span>
          <span style={{ fontSize: 9, color: '#aaa' }}>{lead.sector}</span>
          <span style={{ fontSize: 9, color: '#bbb' }}>·</span>
          <span style={{ fontSize: 9, color: '#aaa' }}>{lead.source} · {lead.published_at}</span>
          {priority && (lead.stars || 0) > 0 && <span style={{ fontSize: 9, color: '#b8963e', fontWeight: 600 }}>★ {lead.stars}</span>}
        </div>
        <div style={{ fontSize: 13, fontWeight: 600, color: '#1a1a1a', marginBottom: 4, letterSpacing: '-0.01em', lineHeight: 1.35 }}>{lead.title}</div>
        <div style={{ fontSize: 12, color: '#666', lineHeight: 1.55, marginBottom: 6 }}>
          {lead.summary?.length > 160 ? lead.summary.slice(0, 160) + '...' : lead.summary}
        </div>
        <div style={{ fontSize: 11, color: '#888' }}>
          Vej ind: <span style={{ color: '#1a1a1a', fontWeight: 500 }}>{lead.opener}</span>
        </div>
      </div>
      <div style={{ textAlign: 'right', flexShrink: 0 }}>
        <div style={{ fontSize: 9, color: '#bbb', textTransform: 'uppercase', letterSpacing: '0.06em' }}>Score</div>
        <div style={{ fontSize: 20, fontWeight: 700, color: mc.color, letterSpacing: '-0.02em' }}>{lead.score}</div>
      </div>
    </div>
  )
}
ENDOFFILE
echo "✓ rapport/page.tsx – premium design"

# Opret email-indstillinger side
mkdir -p frontend/app/indstillinger

cat > frontend/app/indstillinger/page.tsx << 'ENDOFFILE'
'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'

export default function IndstillingerPage() {
  const router = useRouter()
  const [emails, setEmails] = useState<string[]>([])
  const [newEmail, setNewEmail] = useState('')
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [saved, setSaved] = useState(false)

  useEffect(() => {
    const auth = localStorage.getItem('ns_auth')
    if (!auth) { router.push('/'); return }
    fetch('/api/settings/emails')
      .then(r => r.json())
      .then(d => { setEmails(d.emails || []); setLoading(false) })
      .catch(() => { setEmails(['rasmus@nextstep.one']); setLoading(false) })
  }, [])

  const addEmail = () => {
    if (!newEmail || !newEmail.includes('@')) return
    if (emails.includes(newEmail)) return
    setEmails([...emails, newEmail])
    setNewEmail('')
  }

  const removeEmail = (email: string) => {
    setEmails(emails.filter(e => e !== email))
  }

  const saveEmails = async () => {
    setSaving(true)
    try {
      await fetch('/api/settings/emails', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ emails }),
      })
      setSaved(true)
      setTimeout(() => setSaved(false), 2000)
    } catch { alert('Fejl – prøv igen') }
    finally { setSaving(false) }
  }

  return (
    <div style={{ minHeight: '100vh', background: 'var(--bg)', padding: '32px' }}>
      <div style={{ maxWidth: 560, margin: '0 auto' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 32 }}>
          <button onClick={() => router.push('/dashboard')} style={{ fontSize: 12, padding: '7px 14px', borderRadius: 8, border: '1px solid rgba(0,0,0,0.12)', background: 'var(--surface)', color: 'var(--ink)', cursor: 'pointer' }}>
            ← Dashboard
          </button>
          <h1 style={{ fontSize: 20, fontWeight: 700, letterSpacing: '-0.02em' }}>Indstillinger</h1>
        </div>

        <div style={{ background: 'var(--surface)', borderRadius: 14, padding: '24px 28px', border: '1px solid rgba(0,0,0,0.06)' }}>
          <h2 style={{ fontSize: 15, fontWeight: 600, marginBottom: 6 }}>Rapport-modtagere</h2>
          <p style={{ fontSize: 12, color: 'var(--ink-3)', marginBottom: 20 }}>
            Disse e-mailadresser modtager mandags- og torsdagsrapporten automatisk.
          </p>

          {loading ? (
            <div style={{ color: 'var(--ink-3)', fontSize: 13 }}>Henter...</div>
          ) : (
            <>
              <div style={{ marginBottom: 16 }}>
                {emails.map(email => (
                  <div key={email} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 14px', background: 'var(--bg)', borderRadius: 8, marginBottom: 6 }}>
                    <span style={{ fontSize: 13, color: 'var(--ink)' }}>{email}</span>
                    <button onClick={() => removeEmail(email)} style={{ fontSize: 12, color: 'var(--ink-3)', border: 'none', background: 'none', cursor: 'pointer', padding: '2px 6px' }}>
                      ✕
                    </button>
                  </div>
                ))}
              </div>

              <div style={{ display: 'flex', gap: 8, marginBottom: 20 }}>
                <input
                  type="email"
                  placeholder="navn@nextstep.one"
                  value={newEmail}
                  onChange={e => setNewEmail(e.target.value)}
                  onKeyDown={e => e.key === 'Enter' && addEmail()}
                  style={{ flex: 1, padding: '9px 13px', fontSize: 13, borderRadius: 8, border: '1px solid rgba(0,0,0,0.12)', background: 'var(--bg)', color: 'var(--ink)', outline: 'none' }}
                />
                <button onClick={addEmail} disabled={!newEmail || !newEmail.includes('@')} style={{ fontSize: 12, fontWeight: 500, padding: '9px 16px', borderRadius: 8, border: 'none', background: newEmail.includes('@') ? 'var(--ink)' : 'rgba(0,0,0,0.08)', color: newEmail.includes('@') ? '#fff' : 'var(--ink-3)', cursor: 'pointer' }}>
                  Tilføj
                </button>
              </div>

              <button onClick={saveEmails} disabled={saving} style={{ width: '100%', fontSize: 13, fontWeight: 600, padding: '11px', borderRadius: 8, border: 'none', background: saved ? '#edf5f1' : 'var(--ink)', color: saved ? '#2a7d5f' : '#fff', cursor: 'pointer' }}>
                {saving ? 'Gemmer...' : saved ? '✓ Gemt' : 'Gem ændringer'}
              </button>
            </>
          )}
        </div>
      </div>
    </div>
  )
}
ENDOFFILE
echo "✓ indstillinger/page.tsx – email-liste"

# Tilføj settings endpoints i backend
cat > backend/routers/settings.py << 'ENDOFFILE'
from fastapi import APIRouter
from services.db_service import get_report_emails, save_report_emails

router = APIRouter(prefix="/settings", tags=["settings"])

@router.get("/emails")
async def get_emails():
    emails = await get_report_emails()
    return {"emails": emails}

@router.post("/emails")
async def update_emails(body: dict):
    emails = body.get("emails", [])
    await save_report_emails(emails)
    return {"status": "ok", "emails": emails}
ENDOFFILE
echo "✓ backend/routers/settings.py"

# Tilføj settings funktioner i db_service
python3.12 -c "
path = '/Users/rmk/nextstep-intelligence/backend/services/db_service.py'
content = open(path).read()
addition = '''
async def get_report_emails() -> list:
    client = get_client()
    if not client:
        return []
    try:
        result = client.table(\"settings\").select(\"value\").eq(\"key\", \"report_emails\").execute()
        if result.data:
            import json
            return json.loads(result.data[0][\"value\"])
        return []
    except Exception as e:
        print(f\"Get emails fejl: {e}\")
        return []

async def save_report_emails(emails: list) -> bool:
    client = get_client()
    if not client:
        return False
    try:
        import json
        existing = client.table(\"settings\").select(\"key\").eq(\"key\", \"report_emails\").execute()
        if existing.data:
            client.table(\"settings\").update({\"value\": json.dumps(emails)}).eq(\"key\", \"report_emails\").execute()
        else:
            client.table(\"settings\").insert({\"key\": \"report_emails\", \"value\": json.dumps(emails)}).execute()
        return True
    except Exception as e:
        print(f\"Save emails fejl: {e}\")
        return False
'''
open(path, 'w').write(content + addition)
print('✓ db_service.py – email settings')
"

# Opdater main.py til at inkludere settings router
python3.12 -c "
path = '/Users/rmk/nextstep-intelligence/backend/main.py'
content = open(path).read()
content = content.replace(
    'from routers import leads, scraper, reports',
    'from routers import leads, scraper, reports, settings'
)
content = content.replace(
    'app.include_router(reports.router)',
    'app.include_router(reports.router)\napp.include_router(settings.router)'
)
open(path, 'w').write(content)
print('✓ main.py – settings router tilføjet')
"

# Opdater Sidebar til at linke til indstillinger
python3.12 -c "
path = '/Users/rmk/nextstep-intelligence/frontend/components/Sidebar.tsx'
content = open(path).read()
content = content.replace(
    \"['Rapport-arkiv','Indstillinger'].map(s => (\",
    \"['Rapport-arkiv'].map(s => (\"
)
open(path, 'w').write(content)
print('✓ Sidebar – Indstillinger som separat link')
"

# Opret settings tabel i Supabase via SQL – vis instruktion
echo ""
echo "⚠️  Kør denne SQL i Supabase SQL Editor:"
echo "create table if not exists settings (key text primary key, value text);"
echo "grant select, insert, update on public.settings to anon;"
echo "grant select, insert, update on public.settings to authenticated;"
echo ""
echo "✅ v0.1.8 klar – husk logo og Supabase SQL!"
