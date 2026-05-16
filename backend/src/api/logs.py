from fastapi import APIRouter
from ..services.logger import trace_logger

router = APIRouter()

@router.get("/")
async def get_logs():
    """
    Retrieve execution traces and logs for the admin view / dry run verification.
    """
    return {"logs": trace_logger.get_logs()}

@router.delete("/")
async def clear_logs():
    """
    Clear all execution traces and logs.
    """
    trace_logger.clear_logs()
    return {"status": "cleared"}
