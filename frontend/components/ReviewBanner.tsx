'use client'
import { useRouter } from 'next/navigation'
import { useEffect, useState } from 'react'

function getNextSendTime(): Date {
  const now = new Date()
  const day = now.getDay()
  const candidates: Date[] = []

  const mon = new Date(now)
  mon.setDate(now.getDate() + ((1 - day + 7) % 7))
  mon.setHours(10, 0, 0, 0)
  if (mon > now) candidates.push(mon)

  const thu = new Date(now)
  thu.setDate(now.getDate() + ((4 - day + 7) % 7))
  thu.setHours(8, 30, 0, 0)
  if (thu > now) candidates.push(thu)

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
    const sentAt = sessionStorage.getItem('rapport_sent_at')
    if (sentAt) {
      const nextSend = getNextSendTime()
      const sentTime = new Date(sentAt)
      const prevSend = new Date(nextSend.getTime() - 7 * 24 * 60 * 60 * 1000)
      if (sentTime > prevSend) {
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
