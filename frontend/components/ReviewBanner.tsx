'use client'
import { useRouter } from 'next/navigation'
import { useEffect, useState } from 'react'

function getNextSendTime(): Date {
  const now = new Date()
  const day = now.getDay() // 0=søn, 1=man, ..., 4=tor
  const candidates: Date[] = []

  // Mandag kl. 10:00
  const mon = new Date(now)
  mon.setDate(now.getDate() + ((1 - day + 7) % 7))
  mon.setHours(10, 0, 0, 0)
  if (mon > now) candidates.push(new Date(mon))

  // Torsdag kl. 08:30
  const thu = new Date(now)
  thu.setDate(now.getDate() + ((4 - day + 7) % 7))
  thu.setHours(8, 30, 0, 0)
  if (thu > now) candidates.push(new Date(thu))

  // Hvis ingen i denne uge, næste mandag
  if (candidates.length === 0) {
    mon.setDate(mon.getDate() + 7)
    candidates.push(mon)
  }

  return candidates.sort((a, b) => a.getTime() - b.getTime())[0]
}

export default function ReviewBanner() {
  const router = useRouter()
  const [visible, setVisible] = useState(false)

  useEffect(() => {
    // Banneret er skjult indtil næste planlagte udsendelsestidspunkt
    const hideUntil = localStorage.getItem('rapport_hide_until')
    if (hideUntil) {
      const hideTime = new Date(hideUntil)
      if (new Date() < hideTime) {
        setVisible(false)
        return
      }
    }
    setVisible(true)
  }, [])

  if (!visible) return null

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
          Afventer godkendelse fra Claus eller Rasmus
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
