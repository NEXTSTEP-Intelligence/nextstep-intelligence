from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from contextlib import asynccontextmanager
import os

from routers import leads, scraper, reports, settings, klientlinse, mail
from services.scraper_service import run_scraper
from services.mail_service import send_report_to_team
from services.db_service import cleanup_old_leads

load_dotenv()
scheduler = AsyncIOScheduler(timezone="Europe/Copenhagen")

async def maybe_send_missed_approval():
    """Send godkendelsesmail hvis den blev misset pga. deploy."""
    try:
        from datetime import datetime, timezone, timedelta
        from supabase import create_client
        import os
        client = create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_KEY"))
        now = datetime.now(timezone(timedelta(hours=2)))  # Copenhagen
        weekday = now.weekday()  # 0=mon, 3=thu
        hour = now.hour
        minute = now.minute

        # Tjek om vi er på en rapport-dag og forbi sendetidspunktet
        is_monday_after = weekday == 0 and (hour > 8 or (hour == 8 and minute >= 30))
        is_thursday_after = weekday == 3 and (hour > 8 or (hour == 8 and minute >= 30))

        if not (is_monday_after or is_thursday_after):
            return

        # Tjek om mailen allerede er sendt i dag
        today = now.date().isoformat()
        result = client.table("mail_log").select("id").gte("sent_at", today).eq("mail_type", "rapport").execute()
        if result.data:
            print("Rapport allerede sendt i dag – springer over")
            return

        print("Misset rapport opdaget – sender nu...")
        await send_report_to_team()
        client.table("mail_log").insert({"mail_type": "rapport"}).execute()
    except Exception as e:
        print(f"maybe_send_missed_approval fejl: {e}")

async def log_approval_sent():
    """Log at godkendelsesmail er sendt."""
    try:
        from supabase import create_client
        import os
        client = create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_KEY"))
        client.table("mail_log").insert({"mail_type": "approval"}).execute()
    except Exception as e:
        print(f"log_approval_sent fejl: {e}")

async def send_rapport_and_log():
    from services.mail_service import send_report_to_team as _send
    from supabase import create_client
    import os
    await _send()
    try:
        client = create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_KEY"))
        client.table("mail_log").insert({"mail_type": "rapport"}).execute()
    except Exception as e:
        print(f"mail_log fejl: {e}")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Scraper hver time
    scheduler.add_job(run_scraper, 'cron', minute=0, id='hourly_scrape')
    # Rapport mandag kl. 10:00
    scheduler.add_job(send_rapport_and_log, 'cron', day_of_week='mon', hour=8, minute=30, id='monday_rapport')
    # Rapport torsdag kl. 08:30
    scheduler.add_job(send_rapport_and_log, 'cron', day_of_week='thu', hour=8, minute=30, id='thursday_rapport')
    # Oprydning af leads ældre end 90 dage kl. 03:00 hver nat
    scheduler.add_job(cleanup_old_leads, 'cron', hour=3, minute=0, id='daily_cleanup')
    scheduler.start()
    # Tjek om vi missede en mail pga. deploy
    await maybe_send_missed_approval()
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
