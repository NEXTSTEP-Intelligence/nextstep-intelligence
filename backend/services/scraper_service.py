from datetime import datetime, timezone
import feedparser
import anthropic
import json
import os
from services.db_service import save_lead, article_exists, find_existing_lead, update_lead, find_similar_leads, search_guldkatalog
from services.cvr_service import lookup_cvr

# Danske nyhedskilder - RSS feeds
RSS_FEEDS = [
    # ── Nationale medier ──────────────────────────────────────────
    {"name": "Altinget", "url": "https://www.altinget.dk/rss/altinget.rss"},
    {"name": "Altinget Sundhed", "url": "https://www.altinget.dk/rss/sundhed.rss"},
    {"name": "Altinget Miljoe", "url": "https://www.altinget.dk/rss/miljoe.rss"},
    {"name": "Altinget Foedevarer", "url": "https://www.altinget.dk/rss/foedevarer.rss"},
    {"name": "Altinget Europa", "url": "https://www.altinget.dk/rss/europa.rss"},
    {"name": "Altinget Kommune", "url": "https://www.altinget.dk/rss/kommune.rss"},
    {"name": "Altinget Klima", "url": "https://www.altinget.dk/rss/klima.rss"},
    {"name": "Altinget Arbejdsmarked", "url": "https://www.altinget.dk/rss/arbejdsmarked.rss"},
    {"name": "Altinget Forsvaret", "url": "https://www.altinget.dk/rss/forsvaret.rss"},
    {"name": "DR Nyheder", "url": "https://www.dr.dk/nyheder/service/feeds/allenyheder"},
    {"name": "DR Politik", "url": "https://www.dr.dk/nyheder/service/feeds/politik"},
    {"name": "DR Penge", "url": "https://www.dr.dk/nyheder/service/feeds/penge"},
    {"name": "Politiken", "url": "https://politiken.dk/rss/"},
    {"name": "Boersen", "url": "https://borsen.dk/rss"},
    {"name": "Jyllands-Posten", "url": "https://jyllands-posten.dk/rss/"},
    {"name": "Information", "url": "https://www.information.dk/rss"},
    {"name": "Momentum", "url": "https://www.momentum.dk/feed/"},
    {"name": "Ingenioren", "url": "https://ing.dk/rss"},
    # ── Regionale dagblade ────────────────────────────────────────
    {"name": "Nordjyske", "url": "https://nordjyske.dk/rss/nyheder"},
    {"name": "JydskeVestkysten", "url": "https://www.jv.dk/rss/nyheder"},
    {"name": "Herning Folkeblad", "url": "https://www.herningfolkeblad.dk/rss"},
    {"name": "Viborg Stifts Folkeblad", "url": "https://www.viborg-folkeblad.dk/rss"},
    {"name": "Skive Folkeblad", "url": "https://www.skivefolkeblad.dk/rss"},
    {"name": "Horsens Folkeblad", "url": "https://hsfo.dk/rss"},
    {"name": "Aarhus Stiftstidende", "url": "https://www.stiften.dk/rss"},
    {"name": "Midtjyllands Avis", "url": "https://www.midtjyllandsavis.dk/rss"},
    {"name": "Vejle Amts Folkeblad", "url": "https://www.vejleonline.dk/rss"},
    {"name": "Fyens Stiftstidende", "url": "https://www.fyensstiftstidende.dk/rss"},
    {"name": "Fyns Amts Avis", "url": "https://www.fynsamtsavis.dk/rss"},
    {"name": "Bornholms Tidende", "url": "https://www.bornholmstidende.dk/rss"},
    {"name": "Sjaellands Nyheder", "url": "https://sn.dk/rss/nyheder"},
    {"name": "Lolland-Falsters Folketidende", "url": "https://www.folketidende.dk/rss"},
    {"name": "Dagbladet Holstebro-Struer", "url": "https://www.dagbladet-holstebro-struer.dk/rss"},
    {"name": "Ringkjoebing Amts Dagblad", "url": "https://www.ringkoebing-amts-dagblad.dk/rss"},
    {"name": "Thisted Dagblad", "url": "https://www.thisted-dagblad.dk/rss"},
    {"name": "Morsoe Folkeblad", "url": "https://www.morsoefolkeblad.dk/rss"},
    {"name": "Vesthimmerlands Avis", "url": "https://www.vesthimmerlandsavis.dk/rss"},
    {"name": "Frederiksborg Amts Avis", "url": "https://www.frederiksborgamtsavis.dk/rss"},
    {"name": "Kalundborg Folkeblad", "url": "https://www.kalundborg-folkeblad.dk/rss"},
    {"name": "Holbæk Amts Venstreblad", "url": "https://www.venstrebladet.dk/rss"},
    # ── TV-stationer ──────────────────────────────────────────────
    {"name": "TV2 Ostjylland", "url": "https://www.tv2ostjylland.dk/rss"},
    {"name": "TV Midtvest", "url": "https://www.tvmidtvest.dk/rss"},
    {"name": "TV2 Nord", "url": "https://www.tv2nord.dk/rss"},
    {"name": "TV2 Fyn", "url": "https://www.tv2fyn.dk/rss"},
    {"name": "TV2 Lorry", "url": "https://www.tv2lorry.dk/rss"},
    {"name": "TV Syd", "url": "https://www.tvsyd.dk/rss"},
    # ── Lokale ugeaviser ──────────────────────────────────────────
    {"name": "Herning Bladet", "url": "https://www.herningbladet.dk/rss"},
    {"name": "Holstebro Posten", "url": "https://www.holstebroposten.dk/rss"},
    {"name": "Ikast Avis", "url": "https://www.ikastavis.dk/rss"},
    {"name": "Ugeavisen Esbjerg", "url": "https://esbjerg.hveruge.dk/rss"},
    {"name": "Ugeavisen Varde", "url": "https://varde.hveruge.dk/rss"},
    {"name": "Randers Amts Avis", "url": "https://www.randersamtsavis.dk/rss"},
    {"name": "Djurslandsposten", "url": "https://www.djurslandsposten.dk/rss"},
    {"name": "Hedensted Avis", "url": "https://www.hedensted-avis.dk/rss"},
    {"name": "Odder Avis", "url": "https://www.internetavisen.dk/odder/rss"},
    {"name": "Uge-Bladet Skanderborg", "url": "https://www.uge-bladet.dk/rss"},
    {"name": "Ugeavisen Fredericia", "url": "https://www.ugeavisenfredericia.dk/rss"},
    {"name": "Kolding Ugeavis", "url": "https://www.koldingugeavis.dk/rss"},
    {"name": "Sønderborg Ugeavis", "url": "https://www.soenderborgugeavis.dk/rss"},
    {"name": "Aabenraa Ugeavis", "url": "https://aabenraa.bynet.dk/rss"},
    {"name": "Haderslev Ugeavis", "url": "https://www.haderslevugeavis.dk/rss"},
    {"name": "Lokalavisen Lemvig", "url": "https://www.lokalavisenlemvig.dk/rss"},
    {"name": "Lokalavisen Assens", "url": "https://www.lokalavisenassens.dk/rss"},
    {"name": "Lokalavisen Frederikshavn", "url": "https://lokalavisenfrederikshavn.dk/rss"},
    {"name": "Naestved Bladet", "url": "https://www.naestved-bladet.dk/rss"},
    {"name": "Roskilde Avis", "url": "https://www.roskildemediecenter.dk/rss"},
    {"name": "Frederiksvaerk Ugeblad", "url": "https://www.frederiksvaerkugeblad.dk/rss"},
    {"name": "Altinget Social", "url": "https://www.altinget.dk/rss/social.rss"},
    {"name": "Altinget Bolig", "url": "https://www.altinget.dk/rss/bolig.rss"},
    {"name": "Ugebrevet A4", "url": "https://www.ugebreveta4.dk/rss"},
    {"name": "KL Nyheder", "url": "https://www.kl.dk/rss"},
    {"name": "Danske Regioner", "url": "https://www.regioner.dk/rss"},
]

SECTORS = ["sundhed", "fødevarer", "energi", "forsyning", "klima", "kommuner", "velfærd", "regulering", "miljø", "sociale forhold"]

def get_anthropic_client():
    return anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

async def run_scraper() -> int:
    new_leads = 0
    all_articles = []
    seen_urls = set()

    for feed_info in RSS_FEEDS:
        try:
            feed = feedparser.parse(feed_info["url"])
            for entry in feed.entries[:5]:
                article = {
                    "title": entry.get("title", ""),
                    "summary": entry.get("summary", entry.get("description", "")),
                    "url": entry.get("link", ""),
                    "source": feed_info["name"],
                    "published": entry.get("published", str(datetime.now())),
                    "published_parsed": entry.get("published_parsed", None),
                }
                if article["title"] and article["url"] not in seen_urls and not await article_exists(article["url"]):
                    all_articles.append(article)
                    seen_urls.add(article["url"])
        except Exception as e:
            print(f"Fejl ved hentning af {feed_info['name']}: {e}")

    # Analyser i batches af 8 for at tvinge relativ scoring
    BATCH_SIZE = 15
    for batch_start in range(0, len(all_articles), BATCH_SIZE):
        batch = all_articles[batch_start:batch_start + BATCH_SIZE]
        print(f"Analyserer batch {batch_start//BATCH_SIZE + 1} ({len(batch)} artikler)...")
        leads = await analyze_articles_batch(batch)
        for lead in leads:
            if not lead or not lead.get("relevant"):
                continue
            if lead.get("score", 0) < 38:
                continue
            entity = lead.get("entity", "")
            existing = await find_existing_lead(entity) if entity else None
            if existing:
                if (existing.get("update_count") or 0) >= 3:
                    continue
                new_score = max(existing.get("score", 0), lead.get("score", 0))
                update_count = (existing.get("update_count") or 0) + 1
                await update_lead(existing["id"], {
                    "score": new_score,
                    "update_count": update_count,
                    "summary": lead.get("summary", existing.get("summary", "")),
                    "opener": lead.get("opener", existing.get("opener", "")),
                })
                print(f"Opdateret: {entity} (#{update_count})")
            else:
                cvr = await lookup_cvr(entity)
                lead["cvr_verified"] = cvr.get("cvr_verified", False)
                if cvr.get("size_info"):
                    lead["size_info"] = cvr.get("size_info")
                if cvr.get("public"):
                    lead["size_info"] = "Offentlig instans"
                await save_lead(lead)
                new_leads += 1

    print(f"Scraper færdig: {new_leads} nye leads fundet af {len(all_articles)} artikler")
    return new_leads

async def get_starred_examples() -> str:
    from services.db_service import get_leads
    try:
        leads = await get_leads(sort="stars", limit=3)
        starred = [l for l in leads if (l.get("stars") or 0) > 0]
        if not starred:
            return ""
        examples = "\n".join([f'- "{l["title"]}" (score {l["score"]}, sektor: {l["sector"]})' for l in starred])
        return f"\n  TEAMET HAR STJERNEMARKERET disse leads som værdifulde:\n{examples}\n  Leads der ligner disse bør scores højere.\n"
    except:
        return ""


async def analyze_articles_batch(articles: list) -> list:
    """Analyser en batch af artikler på én gang og tving relativ scoring."""
    if not articles:
        return []

    starred_context = await get_starred_examples()

    # Byg RAG-kontekst for hele batchen
    rag_context = ""
    for i, article in enumerate(articles):
        rag_query = f"{article.get('title', '')} {article.get('summary', '')[:200]}"
        matches = await search_guldkatalog(rag_query, match_count=2)
        if matches:
            rag_context += f"\nArtikel {i+1} relevante NEXTSTEP-erfaringer:\n"
            for m in matches:
                source_label = "Aktuel kunde" if m.get("source_type") == "aktuel_kunde" else "Tidligere case"
                rag_context += f"  [{source_label}]: {m.get('content', '')[:150]}...\n"

    articles_text = ""
    for i, article in enumerate(articles):
        articles_text += f"""
ARTIKEL {i+1}:
Kilde: {article['source']}
Titel: {article['title']}
Indhold: {article.get('summary', '')[:400]}
"""

    prompt = f"""Du er en strategisk analytiker for NEXTSTEP A/S – et dansk strategi- og innovationshus med speciale i Public Affairs og velfærdsforbedringer.

Analyser disse {len(articles)} artikler og vurder hvilke der er leads for NEXTSTEP.

{articles_text}

NEXTSTEP-BAGGRUNDSVIDEN fra vores Guldkatalog og aktuelle kunder (brug til at forstå hvad NEXTSTEP kan):
{rag_context if rag_context else "Ingen specifik kontekst fundet."}

NEXTSTEP arbejder med:
1. PUBLIC AFFAIRS: Virksomheder/organisationer der har brug for politisk dialog, reguleringsnavigation eller stakeholdermanagement.
2. VELFÆRD: Kommuner, regioner eller organisationer med komplekse problemer de ikke kan løse selv.

Opgavetyper: Alliance (samle aktører), Camp (workshop/faciliteringsproces), Entreprenør (vi driver forandringen frem).

SCORING – TÆNK SOM EN EKSPERT DER RANGORDNER:
Før du scorer, skal du rangordne alle artiklerne fra bedst til dårligst. Den bedste artikel får den højeste score, den dårligste den laveste. Spredningen SKAL være mindst 25 points fra højeste til laveste relevante artikel.

Regler:
- MAX 2 artikler må have samme score i hele batchen – og kun hvis de er næsten identiske i relevans
- Artikler rangeret #1 og #2 skal have mindst 3 points forskel. #2 og #3 mindst 2 points. Osv.
- Store virksomheder med intern PA (Novo, FLSmidth, Mærsk, DSV, Nordea) scorer ALDRIG over 40
- SMV uden PA + akut politisk pres + navngiven beslutningstager = 70-85
- Generiske nyheder uden klar aktør = 38-50
- Irrelevante artikler = 0-37, relevant: false
- IKKE relevant: rene nationale partipolitiske nyheder om regeringsdannelse eller koalitionsforhandlinger. Lokale politiske beslutninger er relevante.
{starred_context}
Svar med JSON-array – ét objekt per artikel i samme rækkefølge som artiklerne ovenfor:
[
  {{
    "artikel_nr": 1,
    "relevant": true/false,
    "title": "artikel-titel",
    "summary": "2-3 sætninger om situationen og NEXTSTEPs mulighed",
    "module": "public_affairs" eller "velfaerd",
    "opgave_type": "Alliance", "Camp" eller "Entreprenør",
    "sector": "SUNDHED / Psykiatri osv.",
    "score": 0-100,
    "entity": "primær virksomhed eller organisation",
    "size_info": "antal ansatte hvis nævnt",
    "stakeholders": [{{"name": "navn", "role": "rolle"}}],
    "potential_partners": [{{"name": "navn", "role": "hvorfor relevant"}}],
    "gold_matches": [],
    "opener": "Intern analyse til NEXTSTEP-teamet – MAX 2 sætninger. Hvad kan NEXTSTEP tilbyde og hvem kontaktes. Aldrig sælgende sprog."
  }}
]"""

    try:
        client = get_anthropic_client()
        static_part = prompt[:prompt.index("ARTIKEL 1:")]
        dynamic_part = prompt[prompt.index("ARTIKEL 1:"):]

        response = client.messages.create(
            model="claude-sonnet-4-6",
            max_tokens=2500,
            messages=[{
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": static_part,
                        "cache_control": {"type": "ephemeral"}
                    },
                    {
                        "type": "text",
                        "text": dynamic_part
                    }
                ]
            }]
        )
        text = response.content[0].text.strip()
        if text.startswith("```"):
            text = text.split("```")[1]
            if text.startswith("json"):
                text = text[4:]
        text = text.rstrip("`").strip()
        results = json.loads(text)
        if not isinstance(results, list):
            return []
        output = []
        for item in results:
            nr = item.get("artikel_nr", 1) - 1
            if 0 <= nr < len(articles):
                article = articles[nr]
                item.pop("artikel_nr", None)
                item["url"] = article["url"]
                item["source"] = article["source"]
                item["published_at"] = article["published"]
                item["cvr_verified"] = False
                output.append(item)
        return output
    except Exception as e:
        print(f"Batch analyse fejl: {e}")
        return []


async def analyze_article(article: dict) -> dict | None:
    starred_context = await get_starred_examples()

    # Hent historisk kontekst – tidligere leads om samme emne
    # Vi bruger entity fra titlen som foreløbig søgning
    title_words = article.get('title', '')
    similar = await find_similar_leads(entity=title_words[:50], sector="", days=365)
    historical_context = ""
    if similar:
        historical_context = "\n\nHISTORISK KONTEKST – tidligere leads på samme emne/aktør:\n"
        for s in similar:
            try:
                dato = datetime.fromisoformat(s['created_at'].replace('Z', '+00:00'))
                dage = (datetime.now(timezone.utc) - dato).days
                historical_context += f"- \"{s['title']}\" ({dage} dage siden, score {s['score']}, {s['sector']})\n"
            except:
                historical_context += f"- \"{s['title']}\" (score {s['score']})\n"
        historical_context += "Brug denne kontekst i 'opener' hvis det er relevant – fx 'Dette er anden gang på X måneder at dette emne er på dagsordenen'.\n"

    # Hent relevante cases fra Guldkataloget via RAG
    rag_query = f"{article.get('title', '')} {article.get('summary', '')[:300]}"
    guldkatalog_matches = await search_guldkatalog(rag_query, match_count=4)
    guldkatalog_context = ""
    if guldkatalog_matches:
        guldkatalog_context = "\n\nNEXTSTEP GULDKATALOG – relevante cases og erfaringer:\n"
        for match in guldkatalog_matches:
            source_label = "Aktuel kunde" if match.get("source_type") == "aktuel_kunde" else "Tidligere case"
            content_preview = match.get("content", "")[:200]
            guldkatalog_context += f"[{source_label} – {match.get('filename', '')}]: {content_preview}...\n\n"
        guldkatalog_context += "Brug ovenstående cases aktivt i 'opener' – fx 'NEXTSTEP har erfaring med lignende situationer fra [case]' eller 'Vi arbejder allerede med [aktuel kunde] om dette område'.\n"

    prompt = f"""Du er en strategisk analytiker for NEXTSTEP A/S – et dansk strategi- og innovationshus med speciale i Public Affairs og velfærdsforbedringer.

Analyser denne artikel og vurder om den indeholder et lead for NEXTSTEP.

ARTIKEL:
Kilde: {article['source']}
Titel: {article['title']}
Indhold: {article['summary'][:1000]}
{historical_context}{guldkatalog_context}
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
  "sector": "primær sektor OG fokusområde fra denne struktur: SUNDHED (Psykiatri / Ældre / Trivsel), FØDEVARER (Skolemad / Økologi), ENERGI (Geotermi / Fjernvarme / Vand), KLIMA (Fiskeri), BY OG BOLIG (Urban Rigger / Trivsel), BESKÆFTIGELSE, SIKKERHED (Beredskab). Skriv fx: SUNDHED / Psykiatri eller ENERGI / Fjernvarme. Et lead kan have flere sektorer adskilt med komma.",
  {starred_context}"score": 0-100. Vær meget differentieret og kritisk i din scoring. Brug hele skalaen.
  NEXTSTEP arbejder primært med SMV'er (10-500 ansatte) der IKKE har intern PA- eller kommunikationskapacitet. Store virksomheder som Novo Nordisk, FLSmidth, Mærsk, DSV og andre med egne kommunikations- eller PA-afdelinger scorer LAVT – de har ikke brug for os.
  90-100: Ekstraordinært lead. SMV (10-500 ansatte) UDEN intern PA-kapabilitet, akut politisk pres eller lovgivning på vej, klart handlingsvindue NU og identificerbar beslutningstager.
  75-89: Stærkt lead. Relevant SMV eller brancheorganisation med konkret politisk situation der kræver handling inden for 1-3 måneder.
  60-74: Godt lead. Relevant emne og aktør men handlingsvinduet er uklart eller aktøren er svær at identificere præcist.
  41-59: Svagt lead. Relevant emne men stor virksomhed med intern PA, for generisk situation eller ingen klar indgang for NEXTSTEP.
  0-40: Ikke relevant – store virksomheder med intern PA, rent nyhedsstof uden handlingsvindue, eller emner uden for NEXTSTEPs sektorer.
  KRITISK VIGTIGT FOR SCORING: Hvert lead skal have sin helt egen unikke score. Tænk på det som en eksaminator der bedømmer individuelle opgaver – ingen to studerende får præcis samme karakter medmindre de har lavet nøjagtigt det samme. Vej hvert lead på dets egne specifikke meritter: styrken af det politiske handlingsvindue, aktørens størrelse og PA-kapacitet, timing og konkrethed. En forskel på bare 1-2 point er bedre end identiske scores.",
  "entity": "primær virksomhed eller organisation (kun ét navn)",
  "size_info": "antal ansatte eller borgere hvis nævnt",
  "stakeholders": [{{"name": "navn", "role": "rolle i sagen"}}],
  "potential_partners": [{{"name": "navn", "role": "hvorfor relevant"}}],
  "gold_matches": [],
  "opener": "Intern analyse til NEXTSTEP-teamet – IKKE et pitch. Beskriv hvad NEXTSTEP konkret kan tilbyde baseret på historisk erfaring, hvem der er rette kontakt og hvorfor timingen er god. Skriv som intern note, aldrig sælgende sprog."
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
