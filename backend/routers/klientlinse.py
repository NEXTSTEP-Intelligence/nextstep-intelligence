from fastapi import APIRouter
import asyncio
import uuid
from services.db_service import get_leads
from services.klientlinse_service import analyze_client_perspective

router = APIRouter(prefix="/klientlinse", tags=["klientlinse"])

# In-memory job store
jobs = {}

@router.post("/analyze")
async def analyze(body: dict):
    client_name = body.get("client_name", "").strip()
    if not client_name:
        return {"job_id": None, "status": "error"}
    
    job_id = str(uuid.uuid4())
    jobs[job_id] = {"status": "running", "leads": None}
    
    asyncio.create_task(run_analysis(job_id, client_name))
    
    return {"job_id": job_id, "status": "running"}

async def run_analysis(job_id: str, client_name: str):
    try:
        leads = await get_leads(limit=20, sort="score", days=7)
        if not leads:
            jobs[job_id] = {"status": "done", "leads": []}
            return
        result = await analyze_client_perspective(client_name, leads)
        jobs[job_id] = {"status": "done", "leads": result}
    except Exception as e:
        print(f"Job fejl: {e}")
        jobs[job_id] = {"status": "error", "leads": []}

@router.get("/status/{job_id}")
async def status(job_id: str):
    job = jobs.get(job_id)
    if not job:
        return {"status": "not_found", "leads": None}
    return job
