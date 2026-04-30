'use client'
import { useState, useEffect } from 'react'

type Props = {
  leadId: string
  initialStars: number
  onToggle?: (stars: number, starred: boolean) => void
}

export default function StarButton({ leadId, initialStars, onToggle }: Props) {
  const [stars, setStars] = useState(initialStars || 0)
  const [starred, setStarred] = useState(false)
  const [loading, setLoading] = useState(false)
  const [animating, setAnimating] = useState(false)

  useEffect(() => {
    const hasStarred = localStorage.getItem(`star_${leadId}`) === 'true'
    setStarred(hasStarred)
  }, [leadId])

  const handleToggle = async (e: React.MouseEvent) => {
    e.stopPropagation()
    if (loading) return
    setLoading(true)
    setAnimating(true)
    setTimeout(() => setAnimating(false), 300)
    try {
      const res = await fetch(`/api/leads/${leadId}/star`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ currently_starred: starred }),
      })
      const data = await res.json()
      setStars(data.stars)
      setStarred(data.starred)
      localStorage.setItem(`star_${leadId}`, data.starred ? 'true' : 'false')
      onToggle?.(data.stars, data.starred)
    } catch {
      console.error('Star toggle fejl')
    } finally {
      setLoading(false)
    }
  }

  return (
    <button
      onClick={handleToggle}
      disabled={loading}
      title={starred ? 'Fjern stjernemarkeringen' : 'Stjernemarkér dette lead'}
      style={{
        border: 'none',
        background: starred ? 'var(--gold-bg)' : 'transparent',
        cursor: loading ? 'default' : 'pointer',
        display: 'flex', alignItems: 'center', gap: 4,
        padding: '4px 8px', borderRadius: 6,
        transition: 'all 0.15s',
        color: starred ? '#b8963e' : 'var(--ink-3)',
      }}
    >
      <span style={{
        fontSize: 16,
        transition: 'transform 0.2s',
        transform: animating ? 'scale(1.5)' : 'scale(1)',
        display: 'inline-block',
      }}>
        {starred ? '★' : '☆'}
      </span>
      {stars > 0 && (
        <span style={{ fontSize: 11, fontWeight: 600, color: '#b8963e' }}>{stars}</span>
      )}
    </button>
  )
}
