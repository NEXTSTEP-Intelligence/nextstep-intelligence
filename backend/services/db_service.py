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

async def get_leads(module: str = None, limit: int = 20, sort: str = "score") -> list:
    client = get_client()
    if not client:
        return []
    try:
        sort_column = "created_at" if sort == "date" else "stars" if sort == "stars" else "score"
        query = client.table("leads").select("*").order(sort_column, desc=True).limit(limit)
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

async def toggle_star(lead_id: str, currently_starred: bool) -> dict:
    client = get_client()
    if not client:
        return {"stars": 0, "starred": False}
    try:
        result = client.table("leads").select("stars").eq("id", lead_id).execute()
        if not result.data:
            return {"stars": 0, "starred": False}
        current = result.data[0].get("stars", 0) or 0
        if currently_starred:
            new_stars = max(0, current - 1)
            starred = False
        else:
            new_stars = current + 1
            starred = True
        client.table("leads").update({"stars": new_stars}).eq("id", lead_id).execute()
        return {"stars": new_stars, "starred": starred}
    except Exception as e:
        print(f"Toggle star fejl: {e}")
        return {"stars": 0, "starred": False}

async def reset_all_stars() -> bool:
    client = get_client()
    if not client:
        return False
    try:
        client.table("leads").update({"stars": 0}).neq("stars", -1).execute()
        return True
    except Exception as e:
        print(f"Reset stars fejl: {e}")
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

async def get_report_emails() -> list:
    client = get_client()
    if not client:
        return []
    try:
        result = client.table("settings").select("value").eq("key", "report_emails").execute()
        if result.data:
            import json
            return json.loads(result.data[0]["value"])
        return []
    except Exception as e:
        print(f"Get emails fejl: {e}")
        return []

async def save_report_emails(emails: list) -> bool:
    client = get_client()
    if not client:
        return False
    try:
        import json
        existing = client.table("settings").select("key").eq("key", "report_emails").execute()
        if existing.data:
            client.table("settings").update({"value": json.dumps(emails)}).eq("key", "report_emails").execute()
        else:
            client.table("settings").insert({"key": "report_emails", "value": json.dumps(emails)}).execute()
        return True
    except Exception as e:
        print(f"Save emails fejl: {e}")
        return False
