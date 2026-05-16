import datetime
from typing import List, Dict, Any

class TraceLogger:
    def __init__(self):
        self.logs = []

    def log_trace(self, request: str, response_data: Dict[str, Any]):
        log_entry = {
            "timestamp": datetime.datetime.utcnow().isoformat(),
            "request": request,
            "response": response_data
        }
        self.logs.append(log_entry)
        
    def get_logs(self) -> List[Dict[str, Any]]:
        return self.logs
        
    def clear_logs(self):
        self.logs = []

trace_logger = TraceLogger()
