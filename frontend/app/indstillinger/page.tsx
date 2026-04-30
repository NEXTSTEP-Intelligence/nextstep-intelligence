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
