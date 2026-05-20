'use client'
import { useState, useEffect } from 'react'
type Props = {
  onActivate: (clientName: string) => void
  onDeactivate: () => void
  onLoading?: () => void
  isAnalyzing?: boolean
}

export default function KlientlinseBar({ onActivate, onDeactivate, onLoading, isAnalyzing }: Props) {
  const [clientName, setClientName] = useState('')
  const [active, setActive] = useState(false)
  const [activeClient, setActiveClient] = useState('')
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    const saved = sessionStorage.getItem('klientlinse_client')
    if (saved) {
      setActiveClient(saved)
      setClientName(saved)
      setActive(true)
    }
  }, [])

  const handleActivate = async () => {
    if (!clientName.trim()) return
    setLoading(true)
    sessionStorage.setItem('klientlinse_client', clientName)
    setActive(true)
    setActiveClient(clientName)
    onActivate(clientName)
    // Loading forbliver true indtil isAnalyzing prop sættes til false udefra
  }

  const handleDeactivate = () => {
    sessionStorage.removeItem('klientlinse_client')
    window.location.reload()
  }

  const showLoading = loading || isAnalyzing

  return (
    <div style={{
      background: active ? '#0d1b2e' : 'var(--surface)',
      border: active ? '1px solid rgba(184,150,62,0.3)' : '1px solid rgba(0,0,0,0.08)',
      borderRadius: 'var(--radius-md)',
      padding: '12px 16px',
      marginBottom: 16,
      transition: 'all 0.2s',
    }}>
      {active ? (
        <div>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: 10 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <div>
                <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.4)', letterSpacing: '0.08em', textTransform: 'uppercase' }}>Klientlinse aktiv</div>
                <div style={{ fontSize: 14, fontWeight: 600, color: '#e8d08a' }}>{activeClient}</div>
              </div>
            </div>
            <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
              {showLoading ? (
                <span style={{ fontSize: 11, color: '#e8d08a', fontStyle: 'italic', opacity: 0.8 }}>
                  ⏳ Analyserer leads med NEXTSTEP Intelligence AI...
                </span>
              ) : (
                <span style={{ fontSize: 11, color: 'rgba(255,255,255,0.3)', fontStyle: 'italic' }}>
                  Leads er re-rangeret fra {activeClient}s perspektiv
                </span>
              )}
              <button onClick={handleDeactivate} style={{ fontSize: 11, padding: '5px 12px', borderRadius: 6, border: '1px solid rgba(255,255,255,0.15)', background: 'transparent', color: 'rgba(255,255,255,0.5)', cursor: 'pointer' }}>
                Nulstil
              </button>
            </div>
          </div>
          {showLoading && (
            <div style={{ marginTop: 10, height: 3, borderRadius: 2, background: 'rgba(255,255,255,0.08)', overflow: 'hidden' }}>
              <style>{\`
                @keyframes kl-scan {
                  0% { transform: translateX(-100%); }
                  100% { transform: translateX(400%); }
                }
              \`}</style>
              <div style={{
                height: '100%', width: '25%',
                background: 'linear-gradient(90deg, transparent, #e8d08a, transparent)',
                animation: 'kl-scan 1.4s ease-in-out infinite',
              }} />
            </div>
          )}
        </div>
      ) : (
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, flexWrap: 'wrap' }}>
          <span style={{ fontSize: 11, fontWeight: 500, color: 'var(--ink-2)', whiteSpace: 'nowrap' }}>Klientlinse</span>
          <input
            type="text"
            placeholder="Skriv et firmanavn, fx Novo Nordisk..."
            value={clientName}
            onChange={e => setClientName(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && handleActivate()}
            style={{ flex: 1, minWidth: 200, padding: '7px 12px', fontSize: 12, borderRadius: 6, border: '1px solid rgba(0,0,0,0.1)', background: 'var(--bg)', color: 'var(--ink)', outline: 'none' }}
          />
          <button
            onClick={handleActivate}
            disabled={loading || !clientName.trim()}
            style={{ fontSize: 12, fontWeight: 500, padding: '7px 16px', borderRadius: 6, border: 'none', background: clientName.trim() ? '#0d1b2e' : 'rgba(0,0,0,0.06)', color: clientName.trim() ? '#e8d08a' : 'var(--ink-3)', cursor: clientName.trim() ? 'pointer' : 'default', whiteSpace: 'nowrap' }}
          >
            {loading ? '⏳ Analyserer leads med NEXTSTEP Intelligence AI...' : 'Tag deres briller på →'}
          </button>
        </div>
      )}
    </div>
  )
}
