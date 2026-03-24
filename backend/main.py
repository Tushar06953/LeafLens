from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import identify, plants

app = FastAPI(title="LeafLens API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(identify.router)
app.include_router(plants.router)


@app.get("/")
def health():
    return {"status": "ok"}
