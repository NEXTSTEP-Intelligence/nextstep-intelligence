from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from contextlib import asynccontextmanager
import os

from routers import leads, scraper, reports, settings
from services.scraper_service import run_scraper

load_dotenv()
scheduler = AsyncIOScheduler()

@asynccontextmanager
async def lifespan(app: FastAPI):
    scheduler.add_job(run_scraper, 'cron', minute=0, id='hourly_scrape')
    scheduler.start()
    print("Scheduler startet – scraper hver time")
    yield
    scheduler.shutdown()

app = FastAPI(title="NEXTSTEP Intelligence API", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

app.include_router(leads.router)
app.include_router(scraper.router)
app.include_router(reports.router)
app.include_router(settings.router)

@app.get("/health")
def health():
    return {"status": "ok", "service": "NEXTSTEP Intelligence"}
