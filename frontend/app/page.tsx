'use client'
import { useState, Suspense } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'

function LoginForm() {
  const [password, setPassword] = useState('')
  const [error, setError] = useState(false)
  const [loading, setLoading] = useState(false)
  const router = useRouter()
  const searchParams = useSearchParams()

  const handleLogin = async () => {
    setLoading(true)
    setError(false)
    const correct = process.env.NEXT_PUBLIC_ACCESS_PASSWORD || 'nextstep2026'
    if (password === correct) {
      sessionStorage.setItem('ns_auth', 'true')
      const redirect = searchParams.get('redirect') || '/dashboard'
      router.push(redirect)
    } else {
      setError(true)
      setLoading(false)
    }
  }

  return (
    <div style={{ background: 'var(--surface)', borderRadius: 'var(--radius-xl)', padding: '48px 52px', width: '100%', maxWidth: 400, border: '1px solid rgba(0,0,0,0.06)' }}>
      <div style={{ marginBottom: 36, textAlign: 'center' }}>
        <div style={{ fontSize: 11, letterSpacing: '0.12em', color: 'var(--ink-3)', textTransform: 'uppercase', marginBottom: 6 }}>NEXTSTEP</div>
        <div style={{ fontSize: 26, fontWeight: 700, color: 'var(--ink)', letterSpacing: '-0.02em' }}>Intelligence</div>
        <div style={{ fontSize: 12, color: 'var(--ink-3)', marginTop: 4 }}>Scout NS · Internt system</div>
      </div>
      <div style={{ marginBottom: 14 }}>
        <input
          type="password"
          placeholder="Adgangskode"
          value={password}
          onChange={e => setPassword(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && handleLogin()}
          style={{ width: '100%', padding: '12px 16px', fontSize: 15, borderRadius: 'var(--radius-sm)', border: error ? '1px solid #e05252' : '1px solid rgba(0,0,0,0.12)', background: 'var(--bg)', color: 'var(--ink)', outline: 'none' }}
        />
        {error && <div style={{ fontSize: 12, color: '#e05252', marginTop: 8 }}>Forkert adgangskode. Prøv igen.</div>}
      </div>
      <button
        onClick={handleLogin}
        disabled={loading || !password}
        style={{ width: '100%', padding: '12px', fontSize: 14, fontWeight: 600, borderRadius: 'var(--radius-sm)', border: 'none', background: password ? 'var(--ink)' : 'rgba(0,0,0,0.08)', color: password ? '#fff' : 'var(--ink-3)' }}
      >
        {loading ? 'Logger ind...' : 'Log ind'}
      </button>
    </div>
  )
}

export default function LoginPage() {
  return (
    <div style={{ minHeight: '100vh', background: 'var(--bg)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <Suspense fallback={<div />}>
        <LoginForm />
      </Suspense>
    </div>
  )
}
