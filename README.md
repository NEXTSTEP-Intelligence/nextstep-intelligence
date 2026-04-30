# NEXTSTEP Intelligence · Scout NS

Intern AI-drevet nyhedsscreening og lead-genereringsplatform.

## Struktur
nextstep-intelligence/
├── frontend/     # Next.js dashboard
└── backend/      # Python FastAPI + AI-analyse

## Kom i gang

### Frontend
cd frontend
cp .env.example .env.local
npm install
npm run dev
# Åbn http://localhost:3000

### Backend
cd backend
cp .env.example .env
pip install -r requirements.txt
uvicorn main:app --reload --port 8000

## Moduler
- Public Affairs – kommercielle virksomheder med PA-behov
- Velfærd – kommuner/organisationer med latente problemer

## Rapporter
- Mandag kl. 10:00
- Torsdag kl. 08:30
