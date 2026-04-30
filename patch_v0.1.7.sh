#!/bin/bash
cd ~/nextstep-intelligence
echo "v0.1.7 – Rapport-side og flere nyhedskilder..."

# Opret rapport-side
mkdir -p frontend/app/rapport

cat > frontend/app/rapport/page.tsx << 'ENDOFFILE'
'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { Lead } from '@/app/dashboard/page'

function formatDate(str: string): string {
  try {
    const d = new Date(str)
    if (isNaN(d.getTime())) return str
    return d.toLocaleDateString('da-DK', { day: 'numeric', month: 'long', year: 'numeric' })
  } catch { return str }
}

function getWeekNumber(d: Date) {
  const date = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
  date.setUTCDate(date.getUTCDate() + 4 - (date.getUTCDay() || 7))
  const yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1))
  return Math.ceil((((date.getTime() - yearStart.getTime()) / 86400000) + 1) / 7)
}

const MC = {
  public_affairs: { border: '#1a1a1a', chip: '#1a1a1a', chipText: '#f5f0e8', label: 'Public Affairs' },
  velfaerd: { border: '#2a7d5f', chip: '#edf5f1', chipText: '#2a7d5f', label: 'Velfærd' },
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
      .then(d => {
        setLeads(d.leads || [])
        setLoading(false)
      })
      .catch(() => setLoading(false))
  }, [])

  const handleApprove = async () => {
    setSending(true)
    try {
      await fetch('/api/leads/reset-stars', { method: 'POST' })
      const keys = Object.keys(localStorage).filter(k => k.startsWith('star_'))
      keys.forEach(k => localStorage.removeItem(k))
      setSent(true)
    } catch {
      alert('Fejl – prøv igen')
    } finally {
      setSending(false)
    }
  }

  const starred = leads.filter(l => (l.stars || 0) > 0).sort((a, b) => (b.stars || 0) - (a.stars || 0))
  const rest = leads.filter(l => (l.stars || 0) === 0).slice(0, 5)
  const now = new Date()
  const week = getWeekNumber(now)

  return (
    <div style={{ minHeight: '100vh', background: 'var(--bg)', padding: '32px 0' }}>
      <div style={{ maxWidth: 780, margin: '0 auto', padding: '0 24px' }}>

        {/* Header */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 32, flexWrap: 'wrap', gap: 12 }}>
          <div>
            <div style={{ fontSize: 10, letterSpacing: '0.12em', color: 'var(--ink-3)', textTransform: 'uppercase', marginBottom: 4 }}>NEXTSTEP Intelligence · Scout NS</div>
            <h1 style={{ fontSize: 26, fontWeight: 700, letterSpacing: '-0.02em', color: 'var(--ink)' }}>
              Uge {week} · {now.getFullYear()}
            </h1>
            <div style={{ fontSize: 13, color: 'var(--ink-3)', marginTop: 4 }}>
              Genereret {now.toLocaleDateString('da-DK', { weekday: 'long', day: 'numeric', month: 'long' })} kl. {String(now.getHours()).padStart(2,'0')}:{String(now.getMinutes()).padStart(2,'0')}
            </div>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <button onClick={() => router.push('/dashboard')} style={{ fontSize: 12, padding: '8px 16px', borderRadius: 8, border: '1px solid rgba(0,0,0,0.12)', background: 'var(--surface)', color: 'var(--ink)', cursor: 'pointer' }}>
              ← Tilbage
            </button>
            <button onClick={() => window.print()} style={{ fontSize: 12, padding: '8px 16px', borderRadius: 8, border: '1px solid rgba(0,0,0,0.12)', background: 'var(--surface)', color: 'var(--ink)', cursor: 'pointer' }}>
              Print / PDF
            </button>
            {!sent ? (
              <button onClick={handleApprove} disabled={sending} style={{ fontSize: 12, fontWeight: 500, padding: '8px 18px', borderRadius: 8, border: 'none', background: 'var(--gold)', color: '#fff', cursor: 'pointer' }}>
                {sending ? 'Sender...' : 'Godkend og send ↗'}
              </button>
            ) : (
              <div style={{ fontSize: 12, fontWeight: 500, padding: '8px 18px', borderRadius: 8, background: 'var(--vel-bg)', color: 'var(--vel)', display: 'flex', alignItems: 'center' }}>
                ✓ Godkendt og sendt
              </div>
            )}
          </div>
        </div>

        {loading ? (
          <div style={{ textAlign: 'center', padding: 60, color: 'var(--ink-3)' }}>Henter leads...</div>
        ) : (
          <>
            {starred.length > 0 && (
              <div style={{ marginBottom: 32 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 16 }}>
                  <div style={{ height: 1, flex: 1, background: 'var(--divider)' }} />
                  <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--gold)' }}>★ Teamets prioriteter</div>
                  <div style={{ height: 1, flex: 1, background: 'var(--divider)' }} />
                </div>
                {starred.map(lead => <ReportCard key={lead.id} lead={lead} highlighted />)}
              </div>
            )}

            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 16 }}>
                <div style={{ height: 1, flex: 1, background: 'var(--divider)' }} />
                <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--ink-3)' }}>Øvrige top-leads</div>
                <div style={{ height: 1, flex: 1, background: 'var(--divider)' }} />
              </div>
              {rest.length > 0 ? rest.map(lead => <ReportCard key={lead.id} lead={lead} />) : (
                <div style={{ textAlign: 'center', padding: 32, color: 'var(--ink-3)', fontSize: 13 }}>Alle leads er stjernemarkeret denne uge.</div>
              )}
            </div>
          </>
        )}
      </div>
    </div>
  )
}

function ReportCard({ lead, highlighted }: { lead: Lead; highlighted?: boolean }) {
  const mc = MC[lead.module] || MC.public_affairs
  const OC: Record<string, {bg:string;color:string}> = {
    Alliance: { bg: '#f9f3e8', color: '#b8963e' },
    Camp: { bg: '#ede8f5', color: '#5c3d99' },
    'Entreprenør': { bg: '#fdeee8', color: '#a0430a' },
  }
  const oc = OC[lead.opgave_type] || { bg: '#f0f0f0', color: '#666' }

  return (
    <div style={{
      background: 'var(--surface)',
      borderRadius: 12,
      padding: '18px 20px',
      marginBottom: 10,
      border: highlighted ? '1px solid rgba(184,150,62,0.3)' : '1px solid rgba(0,0,0,0.06)',
      borderLeftWidth: 3,
      borderLeftColor: mc.border,
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 16 }}>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', gap: 5, flexWrap: 'wrap', alignItems: 'center', marginBottom: 8 }}>
            <span style={{ fontSize: 10, fontWeight: 500, padding: '2px 8px', borderRadius: 20, background: mc.chip, color: mc.chipText }}>{mc.label}</span>
            <span style={{ fontSize: 10, fontWeight: 500, padding: '2px 8px', borderRadius: 20, background: oc.bg, color: oc.color }}>{lead.opgave_type}</span>
            <span style={{ fontSize: 10, fontWeight: 500, padding: '2px 8px', borderRadius: 20, background: 'rgba(0,0,0,0.05)', color: 'var(--ink-2)' }}>{lead.sector}</span>
            <span style={{ fontSize: 10, color: 'var(--ink-3)' }}>{lead.source} · {lead.published_at}</span>
            {(lead.stars || 0) > 0 && (
              <span style={{ fontSize: 10, color: '#b8963e', fontWeight: 600 }}>★ {lead.stars}</span>
            )}
          </div>
          <div style={{ fontSize: 14, fontWeight: 600, color: 'var(--ink)', marginBottom: 6, letterSpacing: '-0.01em' }}>{lead.title}</div>
          <div style={{ fontSize: 13, color: 'var(--ink-2)', lineHeight: 1.6, marginBottom: 10 }}>{lead.summary}</div>

          {lead.stakeholders?.length > 0 && (
            <div style={{ marginBottom: 8 }}>
              <div style={{ fontSize: 10, fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--ink-3)', marginBottom: 5 }}>Centrale interessenter</div>
              {lead.stakeholders.slice(0, 3).map((s, i) => (
                <div key={i} style={{ fontSize: 12, color: 'var(--ink-2)', padding: '1px 0' }}>
                  <strong style={{ color: 'var(--ink)', fontWeight: 500 }}>{s.name}</strong> — {s.role}
                </div>
              ))}
            </div>
          )}

          {lead.potential_partners?.length > 0 && (
            <div style={{ marginBottom: 8 }}>
              <div style={{ fontSize: 10, fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', color: '#b8963e', marginBottom: 5 }}>Potentielle medspillere</div>
              {lead.potential_partners.slice(0, 2).map((p, i) => (
                <div key={i} style={{ fontSize: 12, color: 'var(--ink-2)', padding: '1px 0' }}>
                  <strong style={{ color: 'var(--ink)', fontWeight: 500 }}>{p.name}</strong> — {p.role}
                </div>
              ))}
            </div>
          )}

          <div style={{ fontSize: 12, color: 'var(--ink-3)', borderTop: '1px solid var(--divider)', paddingTop: 8, marginTop: 8 }}>
            Vej ind: <span style={{ color: 'var(--ink)', fontWeight: 500 }}>{lead.opener}</span>
          </div>
        </div>
        <div style={{ textAlign: 'right', flexShrink: 0 }}>
          <div style={{ fontSize: 10, color: 'var(--ink-3)', textTransform: 'uppercase', letterSpacing: '0.06em' }}>Score</div>
          <div style={{ fontSize: 24, fontWeight: 700, color: mc.border, letterSpacing: '-0.02em' }}>{lead.score}</div>
          {lead.cvr_verified && <div style={{ fontSize: 10, color: 'var(--ink-3)', marginTop: 2 }}>CVR ✓</div>}
        </div>
      </div>
    </div>
  )
}
ENDOFFILE
echo "✓ rapport/page.tsx"

# Opdater ReviewBanner til at linke til rapport-siden
cat > frontend/components/ReviewBanner.tsx << 'ENDOFFILE'
'use client'
import { useRouter } from 'next/navigation'

export default function ReviewBanner() {
  const router = useRouter()

  return (
    <div style={{
      background: 'var(--gold-bg)',
      border: '1px solid rgba(184,150,62,0.25)',
      borderRadius: 'var(--radius-md)',
      padding: '12px 18px',
      display: 'flex', alignItems: 'center',
      justifyContent: 'space-between',
      gap: 14, marginBottom: 20,
    }}>
      <div>
        <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--ink)' }}>Ugerapport klar til review</div>
        <div style={{ fontSize: 11, color: 'var(--ink-2)', marginTop: 2 }}>
          Afventer godkendelse fra Claus eller Rasmus · Stjerner nulstilles ved godkendelse
        </div>
      </div>
      <button onClick={() => router.push('/rapport')} style={{
        fontSize: 12, fontWeight: 500, padding: '7px 18px',
        borderRadius: 8, border: 'none',
        background: 'var(--gold)', color: '#fff',
        cursor: 'pointer', whiteSpace: 'nowrap',
      }}>
        Se &amp; godkend
      </button>
    </div>
  )
}
ENDOFFILE
echo "✓ ReviewBanner.tsx – link til rapport-side"

# Tilføj flere nyhedskilder i scraperen
python3.12 -c "
path = '/Users/rmk/nextstep-intelligence/backend/services/scraper_service.py'
content = open(path).read()
old = '''RSS_FEEDS = [
    {\"name\": \"Altinget\", \"url\": \"https://www.altinget.dk/rss/altinget.rss\"},
    {\"name\": \"DR Nyheder\", \"url\": \"https://www.dr.dk/nyheder/service/feeds/allenyheder\"},
    {\"name\": \"Politiken\", \"url\": \"https://politiken.dk/rss/\"},
]'''
new = '''RSS_FEEDS = [
    {\"name\": \"Altinget\", \"url\": \"https://www.altinget.dk/rss/altinget.rss\"},
    {\"name\": \"Altinget Sundhed\", \"url\": \"https://www.altinget.dk/rss/sundhed.rss\"},
    {\"name\": \"Altinget Miljoe\", \"url\": \"https://www.altinget.dk/rss/miljoe.rss\"},
    {\"name\": \"Altinget Foedevarer\", \"url\": \"https://www.altinget.dk/rss/foedevarer.rss\"},
    {\"name\": \"DR Nyheder\", \"url\": \"https://www.dr.dk/nyheder/service/feeds/allenyheder\"},
    {\"name\": \"DR Politik\", \"url\": \"https://www.dr.dk/nyheder/service/feeds/politik\"},
    {\"name\": \"Politiken\", \"url\": \"https://politiken.dk/rss/\"},
    {\"name\": \"Boersen\", \"url\": \"https://borsen.dk/rss\"},
    {\"name\": \"Momentum\", \"url\": \"https://www.momentum.dk/feed/\"},
]'''
content = content.replace(old, new)
open(path, 'w').write(content)
print('✓ scraper_service.py – 9 nyhedskilder')
"

echo ""
echo "✅ v0.1.7 klar!"
