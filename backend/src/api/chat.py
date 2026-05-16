from fastapi import APIRouter, HTTPException, BackgroundTasks
from ..models.schemas import ChatMessage, ChatResponse, AgentTrace
from ..services.nlp_service import nlp_service
from ..services.orchestrator import orchestrator
from ..services.logger import trace_logger
from datetime import datetime

router = APIRouter()

@router.post("", response_model=ChatResponse)
async def chat(message: ChatMessage, background_tasks: BackgroundTasks):
    """
    Endpoint for natural language service requests.
    """
    try:
        # Delegate entirely to the orchestrator for end-to-end agentic processing
        response = await orchestrator.process_request(message.content, background_tasks)
        
        # Log the execution traces
        trace_logger.log_trace(message.content, response.dict())
        
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
