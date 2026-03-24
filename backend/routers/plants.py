import os
from datetime import date
from fastapi import APIRouter, HTTPException
from typing import Optional
from supabase import create_client, Client

router = APIRouter(prefix="/plants", tags=["plants"])

SUPABASE_URL = os.environ.get("SUPABASE_URL", "")
SUPABASE_SERVICE_KEY = os.environ.get("SUPABASE_SERVICE_KEY", "")


def get_supabase() -> Client:
    return create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)


@router.get("/potd")
async def plant_of_day():
    """Fetch the plant whose potd_date matches today. Falls back to most recently added."""
    supabase = get_supabase()
    today = date.today().isoformat()

    result = supabase.table("plants").select("*").eq("potd_date", today).limit(1).execute()
    if result.data:
        return result.data[0]

    # Fallback: return the most recently upserted plant
    fallback = (
        supabase.table("plants")
        .select("*")
        .order("created_at", desc=True)
        .limit(1)
        .execute()
    )
    if fallback.data:
        return fallback.data[0]

    raise HTTPException(status_code=404, detail="No plant of the day found")


@router.get("/search")
async def search_plants(q: Optional[str] = None, limit: int = 50):
    """Full-text search over common_name, scientific_name, family."""
    supabase = get_supabase()

    if q:
        # ilike search across multiple columns
        result = (
            supabase.table("plants")
            .select("*")
            .or_(
                f"common_name.ilike.%{q}%,"
                f"scientific_name.ilike.%{q}%,"
                f"family.ilike.%{q}%"
            )
            .order("common_name")
            .limit(limit)
            .execute()
        )
    else:
        result = (
            supabase.table("plants")
            .select("*")
            .order("common_name")
            .limit(limit)
            .execute()
        )

    return {"results": result.data or []}


@router.get("/all")
async def get_all_plants(limit: int = 100):
    """Return all plants for the Encyclopedia screen."""
    supabase = get_supabase()
    result = (
        supabase.table("plants")
        .select("*")
        .order("common_name")
        .limit(limit)
        .execute()
    )
    return {"results": result.data or []}


@router.get("/{plant_id}")
async def get_plant(plant_id: str):
    """Fetch a single plant by ID."""
    supabase = get_supabase()
    result = (
        supabase.table("plants")
        .select("*")
        .eq("id", plant_id)
        .single()
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=404, detail="Plant not found")
    return result.data
