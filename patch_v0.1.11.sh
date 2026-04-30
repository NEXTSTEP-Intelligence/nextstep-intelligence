#!/bin/bash
cd ~/nextstep-intelligence
echo "v0.1.11 – Fjerner misvisende subtekster fra stats-kort..."

python3.12 -c "
path = '/Users/rmk/nextstep-intelligence/frontend/components/StatsRow.tsx'
content = open(path).read()
content = content.replace(\"sub: 'Vækst + regulering'\", \"sub: ''\")
content = content.replace(\"sub: 'Latente problemer'\", \"sub: ''\")
content = content.replace(\"sub: 'Guldkatalog-match'\", \"sub: ''\")
open(path, 'w').write(content)
print('✓ StatsRow.tsx – subtekster fjernet')
"

echo ""
echo "✅ v0.1.11 klar!"
