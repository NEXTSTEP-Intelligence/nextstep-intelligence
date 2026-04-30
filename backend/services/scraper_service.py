import feedparser
import anthropic
import json
import os
from datetime import datetime
from services.db_service import save_lead, article_exists

RSS_FEEDS = [
    {"name": "Altinget", "url": "https://www.altinget.dk/rss/altinget.rss"},
    {"name": "DR Nyheder", "url": "https://www.dr.dk/nyheder/service/feeds/allenyheder"},
    {"name": "Politiken", "url": "https://politiken.dk/rss/"},
]

client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

async def run_scraper() -> int:
    new_leads = 0
    all_articles = []
    for feed_info in RSS_FEEDS:
        try:
            feed = feedparser.parse(feed_info["url"])
            for entry in feed.entries[:20]:
                article = {
                    "title": entry.get("title", ""),
                    "summary": entry.get("summary", entry.get("description", "")),
                    "url": entry.get("link", ""),
                    "source": feed_info["name"],
                    "published": entry.get("published", str(datetime.now())),
                }
                if article["title"] and not await article_exists(article["url"]):
                    all_articles.append(article)
        except Exception as e:
            print(f"Fejl ved {feed_info['name']}: {e}")

    for article in all_articles:
        lead = await analyze_article(article)
        if lead:
            await save_lead(lead)
            new_leads += 1

    print(f"Scraper færdig: {new_leads} nye leads af {len(all_articles)} artikler")
    return new_leads

async def analyze_article(article: dict) -> dict | None:
    prompt = f"""Du er strategisk analytiker for NEXTSTEP A/S – dansk strategi- og innovationshus med speciale i Public Affairs og velfærdsforbedringer.

Analyser denne artikel og vurder om den indeholder et lead for NEXTSTEP.

ARTIKEL:
Kilde: {article['source']}
Titel: {article['title']}
Indhold: {article['summary'][:1000]}

NEXTSTEP arbejder med to moduler:
1. PUBLIC AFFAIRS: Virksomheder/organisationer der har brug for politisk dialog eller reguleringsnavigation. Minimum 50 ansatte.
2. VELFÆRD: Kommuner/regioner/organisationer med komplekse problemer de ikke kan løse selv.

Opgavetyper: Alliance, Camp, Entreprenør.

Svar KUN med JSON eller null:
{{
  "relevant": true/false,
  "title": "titel",
  "summary": "2-3 sætninger",
  "module": "public_affairs" eller "velfaerd",
  "opgave_type": "Alliance", "Camp" eller "Entreprenør",
  "sector": "sektor",
  "score": 1-10,
  "size_info": "størrelse",
  "stakeholders": [{{"name": "navn", "role": "rolle"}}],
  "potential_partners": [{{"name": "navn", "role": "hvorfor relevant"}}],
  "gold_matches": [],
  "opener": "konkret indgangsvinkel"
}}"""

    try:
        response = client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=1000,
            messages=[{"role": "user", "content": prompt}]
        )
        text = response.content[0].text.strip()
        if "```" in text:
            text = text.split("```")[1]
            if text.startswith("json"):
                text = text[4:]
        data = json.loads(text)
        if not data.get("relevant"):
            return None
        data.update({"url": article["url"], "source": article["source"], "published_at": article["published"], "cvr_verified": False})
        return data
    except Exception as e:
        print(f"Analyse fejl: {e}")
        return None
