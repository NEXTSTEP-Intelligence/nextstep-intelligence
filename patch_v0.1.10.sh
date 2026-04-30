#!/bin/bash
cd ~/nextstep-intelligence
echo "v0.1.10 – Logo fix, PDF-farver og ny tagline..."

python3.12 -c "
path = '/Users/rmk/nextstep-intelligence/frontend/app/rapport/page.tsx'
content = open(path).read()

# Fix logo – ingen stretch
content = content.replace(
    'style={{ height: 32, mixBlendMode: \'screen\', opacity: 0.92 }}',
    'style={{ height: 36, width: \'auto\', objectFit: \'contain\', mixBlendMode: \'screen\', opacity: 0.95 }}'
)

# Fix tagline
content = content.replace(
    '\"Kortlægger politiske bevægelser før de bliver nyheder\" — NEXTSTEP Public Affairs Intelligence ©',
    'Data-driven political intelligence — NEXTSTEP Public Affairs Intelligence ©'
)

# Fix print CSS – behold baggrunde i PDF
content = content.replace(
    '@media print {',
    '@media print { * { -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; color-adjust: exact !important; }'
)

# Fix rapport-wrap baggrund i print
content = content.replace(
    '.rapport-wrap { min-height: 100vh; background: #f2f0eb; padding: 32px 0; }',
    '.rapport-wrap { min-height: 100vh; background: #f2f0eb; padding: 32px 0; } @media print { .rapport-wrap { padding: 0 !important; background: #f2f0eb !important; } .no-print { display: none !important; } }'
)

open(path, 'w').write(content)
print('✓ rapport/page.tsx – logo, PDF-farver og tagline')
"

echo ""
echo "✅ v0.1.10 klar!"
