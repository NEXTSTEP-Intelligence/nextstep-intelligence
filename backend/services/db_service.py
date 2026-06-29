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

async def get_leads(module: str = None, limit: int = 25, sort: str = "score", days: int = None) -> list:
    client = get_client()
    if not client:
        return []
    try:
        from datetime import datetime, timedelta, timezone
        sort_column = "created_at" if sort == "date" else "stars" if sort == "stars" else "score"
        effective_limit = 50 if days and days >= 30 else limit
        query = client.table("leads").select("*").gte("score", 38).order(sort_column, desc=True).limit(effective_limit)
        if module:
            query = query.eq("module", module)
        if days:
            since = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat()
            query = query.gte("created_at", since)
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

async def cleanup_old_leads() -> int:
    client = get_client()
    if not client:
        return 0
    try:
        from datetime import datetime, timedelta, timezone
        cutoff = (datetime.now(timezone.utc) - timedelta(days=90)).isoformat()
        result = client.table("leads").delete().lt("created_at", cutoff).eq("stars", 0).execute()
        count = len(result.data) if result.data else 0
        print(f"Oprydning: {count} leads ældre end 90 dage slettet")
        return count
    except Exception as e:
        print(f"Oprydning fejl: {e}")
        return 0


async def search_guldkatalog(query_text: str, match_count: int = 4) -> list:
    """Søg i Guldkataloget via embedding-similaritet."""
    client = get_client()
    if not client:
        return []
    try:
        import httpx
        openai_key = os.getenv("OPENAI_API_KEY", "")
        if not openai_key:
            return []
        async with httpx.AsyncClient(timeout=5.0) as http:
            resp = await http.post(
                "https://api.openai.com/v1/embeddings",
                headers={"Authorization": f"Bearer {openai_key}", "Content-Type": "application/json"},
                json={"input": query_text[:8000], "model": "text-embedding-3-small"}
            )
        if resp.status_code != 200:
            return []
        embedding = resp.json()["data"][0]["embedding"]
        result = client.rpc("search_guldkatalog", {
            "query_embedding": embedding,
            "match_count": match_count,
            "min_similarity": 0.45
        }).execute()
        return result.data or []
    except Exception as e:
        print(f"RAG søgefejl: {e}")
        return []

async def find_similar_leads(entity: str, sector: str, days: int = 365) -> list:
    """Find tidligere leads med samme entity eller sektor – til historisk kontekst."""
    client = get_client()
    if not client:
        return []
    try:
        from datetime import datetime, timedelta, timezone
        since = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat()
        results = []
        if entity:
            r = client.table("leads").select("title, entity, sector, score, created_at") \
                .ilike("entity", f"%{entity}%") \
                .gte("created_at", since) \
                .order("created_at", desc=True) \
                .limit(3).execute()
            results.extend(r.data or [])
        if len(results) < 2 and sector:
            primary_sector = sector.split("/")[0].strip()
            r = client.table("leads").select("title, entity, sector, score, created_at") \
                .ilike("sector", f"%{primary_sector}%") \
                .gte("created_at", since) \
                .order("score", desc=True) \
                .limit(3).execute()
            for item in (r.data or []):
                if not any(x.get("title") == item.get("title") for x in results):
                    results.append(item)
        return results[:4]
    except Exception as e:
        print(f"Find similar leads fejl: {e}")
        return []

async def find_existing_lead(entity: str, days: int = 30) -> dict | None:
    client = get_client()
    if not client or not entity:
        return None
    try:
        from datetime import datetime, timedelta, timezone
        since = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat()
        result = client.table("leads").select("*") \
            .ilike("entity", f"%{entity}%") \
            .gte("created_at", since) \
            .order("score", desc=True) \
            .limit(1) \
            .execute()
        return result.data[0] if result.data else None
    except Exception as e:
        print(f"Find entity fejl: {e}")
        return None

async def update_lead(lead_id: str, updates: dict) -> bool:
    client = get_client()
    if not client:
        return False
    try:
        from datetime import datetime, timezone
        updates["updated_at"] = datetime.now(timezone.utc).isoformat()
        client.table("leads").update(updates).eq("id", lead_id).execute()
        return True
    except Exception as e:
        print(f"Update lead fejl: {e}")
        return False
