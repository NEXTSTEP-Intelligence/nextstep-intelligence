import feedparser
import anthropic
import json
import os
from datetime import datetime
from services.db_service import save_lead, article_exists

# Danske nyhedskilder - RSS feeds (Fase 1)
RSS_FEEDS = [
    {"name": "Altinget", "url": "https://www.altinget.dk/rss/altinget.rss"},
    {"name": "DR Nyheder", "url": "https://www.dr.dk/nyheder/service/feeds/allenyheder"},
    {"name": "Ritzau", "url": "https://ritzau.dk/feed/"},
    {"name": "Politiken", "url": "https://politiken.dk/rss/"},
    {"name": "Børsen", "url": "https://borsen.dk/rss"},
]

SECTORS = ["sundhed", "fødevarer", "energi", "forsyning", "klima", "kommuner", "velfærd", "regulering", "miljø", "sociale forhold"]

def get_anthropic_client():
    return anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

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
            print(f"Fejl ved hentning af {feed_info['name']}: {e}")

    for article in all_articles:
        lead = await analyze_article(article)
        if lead:
            await save_lead(lead)
            new_leads += 1

    print(f"Scraper færdig: {new_leads} nye leads fundet af {len(all_articles)} artikler")
    return new_leads

async def analyze_article(article: dict) -> dict | None:
    prompt = f"""Du er en strategisk analytiker for NEXTSTEP A/S – et dansk strategi- og innovationshus med speciale i Public Affairs og velfærdsforbedringer.

Analyser denne artikel og vurder om den indeholder et lead for NEXTSTEP.

ARTIKEL:
Kilde: {article['source']}
Titel: {article['title']}
Indhold: {article['summary'][:1000]}

NEXTSTEP arbejder med to moduler:
1. PUBLIC AFFAIRS: Virksomheder/organisationer der har brug for politisk dialog, reguleringsnavigation eller stakeholdermanagement. Minimum 50 ansatte eller 50+ mio. omsætning.
2. VELFÆRD: Kommuner, regioner eller organisationer der har et komplekst problem de ikke kan løse selv – fx reformimplementering, strategisk procesledelse.

Opgavetyper: Alliance (samle aktører), Camp (workshop/faciliteringsproces), Entreprenør (vi driver forandringen frem).

Svar KUN med JSON i dette format (eller null hvis ikke relevant):
{{
  "relevant": true/false,
  "title": "artikel-titel",
  "summary": "2-3 sætninger om situationen",
  "module": "public_affairs" eller "velfaerd",
  "opgave_type": "Alliance", "Camp" eller "Entreprenør",
  "sector": "primær sektor",
  "score": 0-100 (41-60=svagt lead, 61-80=godt lead, 81-100=stærkt lead. Returner kun relevant=true hvis score er over 40),
  "size_info": "antal ansatte eller borgere hvis nævnt",
  "stakeholders": [{{"name": "navn", "role": "rolle i sagen"}}],
  "potential_partners": [{{"name": "navn", "role": "hvorfor relevant"}}],
  "gold_matches": [],
  "opener": "konkret indgangsvinkel til første henvendelse"
}}"""

    try:
        client = get_anthropic_client()
        response = client.messages.create(
            model="claude-sonnet-4-6",
            max_tokens=1000,
            messages=[{"role": "user", "content": prompt}]
        )
        text = response.content[0].text.strip()
        if text.startswith("```"):
            text = text.split("```")[1]
            if text.startswith("json"):
                text = text[4:]
        try:
            data = json.loads(text)
        except Exception:
            return None
        if not data or not data.get("relevant"):
            return None
        data["url"] = article["url"]
        data["source"] = article["source"]
        data["published_at"] = article["published"]
        data["cvr_verified"] = False
        return data
    except Exception as e:
        print(f"Analyse fejl: {e}")
        return None
