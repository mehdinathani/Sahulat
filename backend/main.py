import sys
sys.stdout.reconfigure(encoding='utf-8')
sys.stderr.reconfigure(encoding='utf-8')

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import os
from dotenv import load_dotenv
load_dotenv()
# Add src package to path for local imports
sys.path.append(os.path.abspath(os.path.dirname(__file__)))
from src.api.routes import router as api_router

app = FastAPI(
    title="Sahulat-AI Orchestrator",
    description="Agentic AI system for the informal economy",
    version="0.1.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API routes
app.include_router(api_router, prefix="/api")

@app.get("/")
async def root():
    return {"message": "Sahulat-AI Orchestrator API is running"}

@app.post("/seed")
async def seed_database():
    """Seed the Firestore database with mock providers (one-time use)."""
    try:
        from scripts.seed_providers import seed_providers
        seed_providers()
        return {"status": "success", "message": "Database seeded with demo providers"}
    except Exception as e:
        return {"status": "error", "message": str(e)}

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)
