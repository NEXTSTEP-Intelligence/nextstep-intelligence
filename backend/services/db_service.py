import os
from supabase import create_client, Client

_client: Client | None = None

def get_client() -> Client:
    global _client
    if not _client:
        url = os.getenv("SUPABASE_URL")
        key = os.getenv("SUPABASE_KEY")
        if url and key:
            _client = create_client(url, key)
    return _client

async def get_leads(module: str = None, limit: int = 20) -> list:
    client = get_client()
    if not client:
        return []
    try:
        query = client.table("leads").select("*").order("score", desc=True).limit(limit)
        if module:
            query = query.eq("module", module)
        return (query.execute()).data or []
    except Exception as e:
        print(f"DB fejl: {e}")
        return []

async def save_lead(lead: dict) -> bool:
    client = get_client()
    if not client:
        return False
    try:
        client.table("leads").insert(lead).execute()
        return True
    except Exception as e:
        print(f"Gem fejl: {e}")
        return False

async def article_exists(url: str) -> bool:
    client = get_client()
    if not client:
        return False
    try:
        result = client.table("leads").select("id").eq("url", url).execute()
        return len(result.data) > 0
    except:
        return False

async def increment_stars(lead_id: str) -> int:
    client = get_client()
    if not client:
        return 0
    try:
        result = client.table("leads").select("stars").eq("id", lead_id).execute()
        current = result.data[0].get("stars", 0) if result.data else 0
        new_stars = current + 1
        client.table("leads").update({"stars": new_stars}).eq("id", lead_id).execute()
        return new_stars
    except Exception as e:
        print(f"Star fejl: {e}")
        return 0
