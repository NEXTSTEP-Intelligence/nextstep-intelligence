'use client'
import { useState } from 'react'

type Props = {
  leadId: string
  initialStars: number
  onStarred?: (stars: number) => void
}

export default function StarButton({ leadId, initialStars, onStarred }: Props) {
  const [stars, setStars] = useState(initialStars || 0)
  const [loading, setLoading] = useState(false)
  const [starred, setStarred] = useState(false)

  const handleStar = async (e: React.MouseEvent) => {
    e.stopPropagation()
    if (loading) return
    setLoading(true)
    try {
      const res = await fetch(`/api/leads/${leadId}/star`, { method: 'POST' })
      const data = await res.json()
      setStars(data.stars)
      setStarred(true)
      onStarred?.(data.stars)
      setTimeout(() => setStarred(false), 1500)
    } catch {
      console.error('Star fejl')
    } finally {
      setLoading(false)
    }
  }

  return (
    <button
      onClick={handleStar}
      disabled={loading}
      title="Stjernemarkér dette lead"
      style={{
        border: 'none',
        background: 'none',
        cursor: loading ? 'default' : 'pointer',
        display: 'flex',
        alignItems: 'center',
        gap: 4,
        padding: '4px 6px',
        borderRadius: 6,
        transition: 'background 0.15s',
        color: stars > 0 ? '#b8963e' : 'var(--ink-3)',
      }}
    >
      <span style={{ fontSize: 16, transition: 'transform 0.2s', transform: starred ? 'scale(1.4)' : 'scale(1)' }}>
        {stars > 0 ? '★' : '☆'}
      </span>
      {stars > 0 && (
        <span style={{ fontSize: 11, fontWeight: 600, color: '#b8963e' }}>{stars}</span>
      )}
    </button>
  )
}
