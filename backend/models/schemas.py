from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class CareData(BaseModel):
    soil: str = "Well-draining"
    sunlight: str = "Full sun"
    water: str = "Moderate"
    ph: str = "6.0–7.0"
    temperature: str = "15–30°C"


class UsesData(BaseModel):
    medicinal: Optional[str] = None
    culinary: Optional[str] = None
    cosmetic: Optional[str] = None
    industrial: Optional[str] = None
    is_toxic: bool = False


class PlantResponse(BaseModel):
    id: str
    scientific_name: str
    common_name: str
    family: str
    description: str
    confidence: float
    image_url: Optional[str] = None
    emoji: str = "🌿"
    care_data: CareData
    uses: UsesData
    iucn_status: Optional[str] = None
    region_pills: List[str] = []
    potd_date: Optional[str] = None
    habitat: Optional[str] = None
    height: Optional[str] = None
    bloom_season: Optional[str] = None
    climate: Optional[str] = None
    cultural_significance: Optional[str] = None
    fun_facts: List[str] = []
    distribution_countries: List[str] = []


class ErrorResponse(BaseModel):
    error: str
    message: str
    detail: Optional[str] = None
