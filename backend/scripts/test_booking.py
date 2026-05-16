import asyncio
import sys
import os

# Add src to path
sys.path.append(os.path.join(os.path.dirname(__file__), ".."))

from src.services.orchestrator import orchestrator

async def test_booking():
    print("Testing booking 'Arshad Electrics'...")
    response = await orchestrator.process_request("Book Arshad Electrics")
    print(f"Content: {response.content.encode('utf-8', errors='ignore').decode('utf-8')}")
    
    print("\n--- Trace ---")
    for t in response.trace:
        print(f"[{t.step}] {t.thought}")
        if t.observation:
            print(f"  Obs: {t.observation}")

if __name__ == "__main__":
    asyncio.run(test_booking())
