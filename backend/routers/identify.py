import os
import uuid
import logging
import httpx
from fastapi import APIRouter, File, Form, UploadFile, HTTPException, Header
from typing import List, Optional
from supabase import create_client, Client

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/identify", tags=["identify"])

PLANTNET_API_KEY = os.environ.get("PLANTNET_API_KEY", "")
SUPABASE_URL = os.environ.get("SUPABASE_URL", "")
SUPABASE_SERVICE_KEY = os.environ.get("SUPABASE_SERVICE_KEY", "")

ORGAN_MAP = {
    "leaf": "leaf",
    "flower": "flower",
    "bark": "bark",
    "full": "auto",
}

CARE_DEFAULTS = {
    "soil": "Well-draining loamy soil",
    "sunlight": "Full sun to partial shade",
    "water": "Moderate — water when top inch is dry",
    "ph": "6.0–7.0",
    "temperature": "15–30°C",
}


def get_supabase() -> Client:
    return create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)


@router.post("")
async def identify_plant(
    files: List[UploadFile] = File(...),
    organ: str = Form("leaf"),
    authorization: Optional[str] = Header(None),
):
    try:
        # ── 1. Call Pl@ntNet ──────────────────────────────────────────────────
        plantnet_organ = ORGAN_MAP.get(organ, "auto")
        plantnet_url = "https://my-api.plantnet.org/v2/identify/all"

        image_bytes_list = []
        for f in files:
            content = await f.read()
            image_bytes_list.append((f.filename or "image.jpg", content, f.content_type or "image/jpeg"))

        async with httpx.AsyncClient(timeout=60) as client:
            pn_files = [
                ("images", (name, data, ctype))
                for name, data, ctype in image_bytes_list
            ]
            pn_data = [("organs", plantnet_organ)] * len(files)

            pn_resp = await client.post(
                plantnet_url,
                params={"api-key": PLANTNET_API_KEY, "lang": "en"},
                files=pn_files,
                data=pn_data,
            )

        if pn_resp.status_code != 200:
            raise HTTPException(status_code=502, detail=f"PlantNet error: {pn_resp.text}")

        pn_data_json = pn_resp.json()
        results = pn_data_json.get("results", [])
        if not results:
            return {"error": "low_confidence", "message": "Could not identify — try multi-angle"}

        top = results[0]
        confidence = top.get("score", 0.0)

        if confidence < 0.20:
            return {"error": "low_confidence", "message": "Could not identify — try multi-angle"}

        species = top.get("species", {})
        scientific_name = species.get("scientificNameWithoutAuthor", "Unknown")
        common_names = species.get("commonNames", [])
        common_name = common_names[0] if common_names else scientific_name
        family = species.get("family", {}).get("scientificNameWithoutAuthor", "Unknown")

        # ── 2. Wikipedia summary ──────────────────────────────────────────────
        description = ""
        thumbnail_url = None
        wiki_slug = scientific_name.replace(" ", "_")
        async with httpx.AsyncClient(timeout=10) as client:
            wiki_resp = await client.get(
                f"https://en.wikipedia.org/api/rest_v1/page/summary/{wiki_slug}"
            )
            if wiki_resp.status_code == 200:
                wiki_json = wiki_resp.json()
                description = wiki_json.get("extract", "")
                thumbnail_url = wiki_json.get("thumbnail", {}).get("source")

        # ── 3. GBIF care data ─────────────────────────────────────────────────
        care_data = dict(CARE_DEFAULTS)
        fun_facts: list[str] = []
        distribution_countries: list[str] = []
        iucn_status = None

        try:
            async with httpx.AsyncClient(timeout=10) as client:
                gbif_resp = await client.get(
                    "https://api.gbif.org/v1/species/match",
                    params={"name": scientific_name, "verbose": "false"},
                )
                if gbif_resp.status_code == 200:
                    gbif_json = gbif_resp.json()
                    if gbif_json.get("kingdom"):
                        fun_facts.append(f"Kingdom: {gbif_json['kingdom']}")
                    if gbif_json.get("order"):
                        fun_facts.append(f"Order: {gbif_json['order']}")
        except Exception:
            pass  # GBIF is best-effort

        # ── 4. Upload image to Supabase Storage ───────────────────────────────
        image_url = None
        supabase = get_supabase()
        if image_bytes_list:
            img_name = f"{uuid.uuid4()}.jpg"
            first_img_bytes = image_bytes_list[0][1]
            try:
                upload_resp = supabase.storage.from_("plant-images").upload(
                    img_name, first_img_bytes, {"content-type": "image/jpeg"}
                )
                image_url = supabase.storage.from_("plant-images").get_public_url(img_name)
            except Exception:
                image_url = thumbnail_url  # fallback to Wikipedia thumbnail

        # ── 5. Upsert plant into DB ───────────────────────────────────────────
        plant_payload = {
            "scientific_name": scientific_name,
            "common_name": common_name,
            "family": family,
            "description": description,
            "care_data": care_data,
            "uses": {"is_toxic": False},
            "iucn_status": iucn_status,
            "region_pills": [],
            "emoji": "🌿",
        }
        plant_result = supabase.table("plants").upsert(
            plant_payload, on_conflict="scientific_name"
        ).execute()
        plant_id = plant_result.data[0]["id"] if plant_result.data else str(uuid.uuid4())

        # ── 6. Insert scan record ─────────────────────────────────────────────
        user_id = None
        if authorization and authorization.startswith("Bearer "):
            token = authorization.removeprefix("Bearer ")
            try:
                user_resp = supabase.auth.get_user(token)
                user_id = user_resp.user.id if user_resp.user else None
            except Exception:
                pass

        if user_id:
            supabase.table("scans").insert({
                "user_id": user_id,
                "plant_id": plant_id,
                "image_url": image_url,
                "confidence": confidence,
                "scan_mode": organ,
            }).execute()

        # ── 7. Return assembled plant profile ─────────────────────────────────
        return {
            "id": plant_id,
            "scientific_name": scientific_name,
            "common_name": common_name,
            "family": family,
            "description": description,
            "confidence": confidence,
            "image_url": image_url,
            "emoji": "🌿",
            "care_data": care_data,
            "uses": {"is_toxic": False},
            "iucn_status": iucn_status,
            "region_pills": [],
            "fun_facts": fun_facts,
            "distribution_countries": distribution_countries,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.exception("identify_plant failed")
        return {"error": "identify_failed", "detail": str(e)}
