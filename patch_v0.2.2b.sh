#!/bin/bash
cd ~/nextstep-intelligence
echo "v0.2.2b – CVR badge..."

python3.12 - << 'PYEOF'
# Fix LeadCard CVR badge
path = '/Users/rmk/nextstep-intelligence/frontend/components/LeadCard.tsx'
content = open(path).read()

# Find og erstat CVR tekst
old = "{lead.size_info}{lead.cvr_verified ? ' · CVR ✓' : ''}"
new = """{lead.size_info}{lead.size_info === 'Offentlig instans' ? '' : lead.cvr_verified ? ' · CVR ✓' : ''}"""
content = content.replace(old, new)

# Erstat score badge område
old2 = "<div style={{ fontSize: 10, color: 'var(--ink-3)', marginTop: 5, lineHeight: 1.6 }}>{lead.size_info}<br />{lead.cvr_verified ? 'CVR ✓' : ''}</div>"
new2 = """<div style={{ fontSize: 10, color: 'var(--ink-3)', marginTop: 5, lineHeight: 1.6 }}>
          {lead.size_info && <div>{lead.size_info}</div>}
          {lead.size_info === 'Offentlig instans'
            ? <span style={{fontSize:9,padding:'2px 7px',borderRadius:20,background:'#e6f1fb',color:'#185fa5',fontWeight:600,display:'inline-block',marginTop:3}}>Offentlig</span>
            : lead.cvr_verified
            ? <span style={{fontSize:9,padding:'2px 7px',borderRadius:20,background:'#edf5f1',color:'#2a7d5f',fontWeight:600,display:'inline-block',marginTop:3}}>CVR ✓</span>
            : null}
        </div>"""
content = content.replace(old2, new2)

open(path, 'w').write(content)
print('✓ LeadCard.tsx – CVR badges')
PYEOF

echo "✅ Færdig!"
