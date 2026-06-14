import json
import os
from typing import Optional
from urllib.parse import quote, urlparse

import httpx
from bs4 import BeautifulSoup
from dotenv import load_dotenv
from fastapi import FastAPI
from pydantic import BaseModel, HttpUrl

load_dotenv()

app = FastAPI(title="CU RATOR API")


class AnalyzeRequest(BaseModel):
    url: HttpUrl
    manualCategory: Optional[str] = None
    categories: list[str] = []


class AnalyzeResponse(BaseModel):
    url: str
    platform: str
    title: str
    category: str
    tags: list[str]
    summary: str
    thumbnailURL: Optional[str] = None
    sourceNote: str
    requiresManualCategory: bool


DEFAULT_CATEGORIES = ["가볼 곳", "사고 싶은 것", "스타일 참고", "따라 해볼 것", "공부/정보", "레퍼런스", "다시 볼 것"]


@app.get("/health")
async def health():
    return {"ok": True}


@app.post("/analyze", response_model=AnalyzeResponse)
async def analyze(payload: AnalyzeRequest):
    url = str(payload.url)
    platform = detect_platform(url)
    categories = normalize_categories(payload.categories)

    if platform == "Instagram":
        category = payload.manualCategory if payload.manualCategory in categories else categories[0]
        return AnalyzeResponse(
            url=url,
            platform=platform,
            title="Instagram 콘텐츠",
            category=category,
            tags=["Instagram", category],
            summary="Instagram은 외부 메타데이터 접근이 제한되어 사용자가 선택한 카테고리로 저장합니다.",
            thumbnailURL=None,
            sourceNote="Manual category",
            requiresManualCategory=True,
        )

    metadata = await fetch_metadata(url, platform)
    classification = await classify_with_ai(metadata, platform, categories)

    return AnalyzeResponse(
        url=url,
        platform=platform,
        title=metadata.get("title") or fallback_title(url, platform),
        category=classification["category"],
        tags=classification["tags"],
        summary=classification["summary"],
        thumbnailURL=metadata.get("thumbnail"),
        sourceNote=metadata.get("source_note") or "Metadata",
        requiresManualCategory=False,
    )


def detect_platform(url: str) -> str:
    host = urlparse(url).netloc.lower()

    if "youtube.com" in host or "youtu.be" in host:
        return "YouTube"
    if "instagram.com" in host:
        return "Instagram"
    if "blog" in host or "naver.com" in host or "tistory.com" in host or "medium.com" in host:
        return "Blog"
    return "Web"


async def fetch_metadata(url: str, platform: str) -> dict:
    if platform == "YouTube":
        youtube = await fetch_youtube_oembed(url)
        if youtube:
            return youtube

    og = await fetch_open_graph(url)
    if og:
        return og

    return {
        "title": fallback_title(url, platform),
        "description": "",
        "thumbnail": None,
        "source_note": "Fallback metadata",
    }


async def fetch_youtube_oembed(url: str) -> dict:
    endpoint = "https://www.youtube.com/oembed"
    try:
        async with httpx.AsyncClient(timeout=8.0, follow_redirects=True) as client:
            response = await client.get(endpoint, params={"url": url, "format": "json"})
            response.raise_for_status()
            data = response.json()
            return {
                "title": data.get("title", ""),
                "description": data.get("author_name", ""),
                "thumbnail": data.get("thumbnail_url"),
                "source_note": "YouTube oEmbed",
            }
    except Exception:
        return {}


async def fetch_open_graph(url: str) -> dict:
    opengraph_io = await fetch_opengraph_io(url)
    if opengraph_io:
        return opengraph_io

    return await fetch_open_graph_from_html(url)


async def fetch_opengraph_io(url: str) -> dict:
    api_key = os.getenv("OPEN_GRAPH_API_KEY")
    if not api_key:
        return {}

    endpoint = f"https://opengraph.io/api/1.1/site/{quote(url, safe='')}"
    try:
        async with httpx.AsyncClient(timeout=10.0, follow_redirects=True) as client:
            response = await client.get(
                endpoint,
                params={
                    "app_id": api_key,
                    "cache_ok": "true",
                    "use_proxy": "true",
                },
            )
            response.raise_for_status()
            data = response.json()
            graph = first_graph(data, ["hybridGraph", "openGraph", "htmlInferred"])
            image = graph.get("image") or graph.get("imageSecureUrl") or graph.get("imageUrl")
            return {
                "title": graph.get("title", ""),
                "description": graph.get("description", ""),
                "thumbnail": normalize_image_url(image),
                "source_note": "OpenGraph.io",
            }
    except Exception:
        return {}


async def fetch_open_graph_from_html(url: str) -> dict:
    try:
        async with httpx.AsyncClient(timeout=8.0, follow_redirects=True) as client:
            response = await client.get(url, headers={"User-Agent": "CURatorBot/0.1"})
            response.raise_for_status()
            soup = BeautifulSoup(response.text, "html.parser")
            return {
                "title": meta_content(soup, "og:title") or (soup.title.string.strip() if soup.title and soup.title.string else ""),
                "description": meta_content(soup, "og:description") or meta_name_content(soup, "description"),
                "thumbnail": meta_content(soup, "og:image"),
                "source_note": "Open Graph",
            }
    except Exception:
        return {}


def first_graph(data: dict, keys: list[str]) -> dict:
    for key in keys:
        graph = data.get(key)
        if isinstance(graph, dict) and graph:
            return graph
    return {}


def normalize_image_url(image: object) -> Optional[str]:
    if isinstance(image, str):
        return image
    if isinstance(image, dict):
        url = image.get("url") or image.get("secure_url")
        return url if isinstance(url, str) else None
    return None


def meta_content(soup: BeautifulSoup, property_name: str) -> str:
    tag = soup.find("meta", property=property_name)
    return tag.get("content", "").strip() if tag else ""


def meta_name_content(soup: BeautifulSoup, name: str) -> str:
    tag = soup.find("meta", attrs={"name": name})
    return tag.get("content", "").strip() if tag else ""


async def classify_with_ai(metadata: dict, platform: str, categories: list[str]) -> dict:
    api_key = os.getenv("OPENAI_API_KEY")
    title = metadata.get("title") or ""
    description = metadata.get("description") or ""

    if not api_key:
        return classify_locally(title, description, platform, categories)

    try:
        from openai import AsyncOpenAI

        client = AsyncOpenAI(api_key=api_key)
        model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
        prompt = {
            "platform": platform,
            "title": title,
            "description": description,
            "existing_categories": categories,
            "instruction": "Return JSON with category, tags, summary. First infer the content topic freely. category should be a concise Korean category name based on the topic. If an existing category is an excellent fit, reuse its exact name. Otherwise suggest a new concise category. tags must be short Korean strings.",
        }
        response = await client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": "You classify saved content for a Korean iOS app."},
                {"role": "user", "content": json.dumps(prompt, ensure_ascii=False)},
            ],
            response_format={"type": "json_object"},
        )
        parsed = json.loads(response.choices[0].message.content or "{}")
        category = parsed.get("category") if isinstance(parsed.get("category"), str) and parsed.get("category").strip() else categories[0]
        category = category.strip()[:24]
        tags = parsed.get("tags") if isinstance(parsed.get("tags"), list) else [platform, category]
        summary = parsed.get("summary") or "나중에 다시 보기 위해 저장한 콘텐츠입니다."
        return {"category": category, "tags": tags[:5], "summary": summary}
    except Exception:
        return classify_locally(title, description, platform, categories)


def classify_locally(title: str, description: str, platform: str, categories: list[str]) -> dict:
    text = f"{title} {description}".lower()

    direct_match = match_category_name(text, categories)
    category = direct_match or categories[0]

    return {
        "category": category,
        "tags": [platform, category],
        "summary": description[:80] if description else "카테고리 이름과 콘텐츠 정보를 기준으로 임시 분류했어요.",
    }


def match_category_name(text: str, categories: list[str]) -> Optional[str]:
    for category in categories:
        normalized = category.strip().lower()
        if not normalized:
            continue
        if normalized in text:
            return category

        tokens = [token for token in normalized.replace("/", " ").replace(",", " ").split() if len(token) >= 2]
        if any(token in text for token in tokens):
            return category

    return None


def normalize_categories(categories: list[str]) -> list[str]:
    cleaned = []
    for category in categories:
        name = category.strip()
        if name and name not in cleaned:
            cleaned.append(name)
    return cleaned or DEFAULT_CATEGORIES


def fallback_title(url: str, platform: str) -> str:
    host = urlparse(url).netloc.replace("www.", "")
    if platform == "YouTube":
        return "YouTube 영상"
    if platform == "Blog":
        return host or "Blog 콘텐츠"
    return host or "Web 콘텐츠"
