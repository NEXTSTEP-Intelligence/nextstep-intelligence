from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from contextlib import asynccontextmanager
import os

from routers import leads, scraper, reports, settings, klientlinse, mail
from services.scraper_service import run_scraper
from services.mail_service import send_approval_request
from services.db_service import cleanup_old_leads

load_dotenv()
scheduler = AsyncIOScheduler(timezone="Europe/Copenhagen")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Scraper hver time
    scheduler.add_job(run_scraper, 'cron', minute=0, id='hourly_scrape')
    # Godkendelses-mail mandag kl. 10:00
    scheduler.add_job(send_approval_request, 'cron', day_of_week='mon', hour=10, minute=0, id='monday_approval')
    # Godkendelses-mail torsdag kl. 08:30
    scheduler.add_job(send_approval_request, 'cron', day_of_week='thu', hour=8, minute=30, id='thursday_approval')
    # Oprydning af leads ældre end 90 dage kl. 03:00 hver nat
    scheduler.add_job(cleanup_old_leads, 'cron', hour=3, minute=0, id='daily_cleanup')
    scheduler.start()
    print("Scheduler startet – scraper hver time, godkendelsesmail man 10:00 og tor 08:30, oprydning kl. 03:00")
    yield
    scheduler.shutdown()

app = FastAPI(title="NEXTSTEP Intelligence API", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

app.include_router(leads.router)
app.include_router(scraper.router)
app.include_router(reports.router)
app.include_router(settings.router)
app.include_router(klientlinse.router)
app.include_router(mail.router)

@app.get("/health")
def health():
    return {"status": "ok", "service": "NEXTSTEP Intelligence"}
