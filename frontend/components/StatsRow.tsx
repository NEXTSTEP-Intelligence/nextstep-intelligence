'use client'

type Props = { total: number; pa: number; vel: number; rebizz: number; onDaysChange: (days: number) => void; activeDays: number; totalByDays?: Record<number, number> }

export default function StatsRow({ total, pa, vel, rebizz, onDaysChange, activeDays, totalByDays = {} }: Props) {
  const MAX_LEADS = 25
  return (
    <div style={{ marginBottom: 4 }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 10, marginBottom: 8 }}>
        {/* Leads-boks med X/50 indikator */}
        <div style={{ background: 'var(--surface)', borderRadius: 'var(--radius-md)', padding: '13px 15px', border: '1px solid rgba(0,0,0,0.06)' }}>
          <div style={{ fontSize: 11, color: 'var(--ink-3)', marginBottom: 5 }}>Leads</div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
            <div style={{ fontSize: 24, fontWeight: 700, color: 'var(--ink)' }}>{total}</div>
            <div style={{ fontSize: 12, color: 'var(--ink-3)', fontWeight: 400 }}>/ {MAX_LEADS}</div>
          </div>
        </div>
        {[
          { label: 'Public Affairs', value: pa, valueColor: '#fff', dark: true, bg: 'var(--ink)' },
          { label: 'Velfærd', value: vel, valueColor: '#fff', dark: true, bg: 'var(--vel)' },
          { label: 'Rebizz-matches', value: rebizz, valueColor: 'var(--gold)', dark: false, bg: 'var(--surface)' },
        ].map(c => (
          <div key={c.label} style={{ background: c.bg, borderRadius: 'var(--radius-md)', padding: '13px 15px', border: c.dark ? 'none' : '1px solid rgba(0,0,0,0.06)' }}>
            <div style={{ fontSize: 11, color: c.dark ? 'rgba(255,255,255,0.45)' : 'var(--ink-3)', marginBottom: 5 }}>{c.label}</div>
            <div style={{ fontSize: 24, fontWeight: 700, color: c.valueColor }}>{c.value}</div>
          </div>
        ))}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
        <span style={{ fontSize: 11, color: 'var(--ink-3)' }}>Viser:</span>
        {[
          { days: 7, label: '7 dage' },
          { days: 30, label: '30 dage' },
        ].map(o => (
          <button key={o.days} onClick={() => onDaysChange(o.days)} style={{
            fontSize: 11, padding: '3px 10px', borderRadius: 20, cursor: 'pointer',
            border: '1px solid rgba(0,0,0,0.1)',
            background: activeDays === o.days ? 'var(--ink)' : 'transparent',
            color: activeDays === o.days ? '#fff' : 'var(--ink-2)',
            display: 'flex', alignItems: 'center', gap: 5,
          }}>
            {o.label}
            {totalByDays[o.days] !== undefined && (
              <span style={{ fontSize: 10, background: activeDays === o.days ? 'rgba(255,255,255,0.25)' : 'rgba(0,0,0,0.07)', borderRadius: 10, padding: '1px 6px' }}>
                {totalByDays[o.days]}
              </span>
            )}
          </button>
        ))}
      </div>
    </div>
  )
}
