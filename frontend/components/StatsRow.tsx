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
