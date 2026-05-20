import asyncio
import sys
import os

sys.stdout.reconfigure(encoding='utf-8')
sys.stderr.reconfigure(encoding='utf-8')

# Add src to path
sys.path.append(os.path.join(os.path.dirname(__file__), ".."))

from src.services.orchestrator import orchestrator

async def test_orchestrator():
    # Test with an electrician request
    print("Testing 'Need an electrician'...")
    response = await orchestrator.process_request("Need an electrician")
    print(f"Content: {response.content}")
    print(f"Providers found: {len(response.providers) if response.providers else 0}")
    if response.providers:
        for p in response.providers:
            print(f" - {p['name']} (Rating: {p['rating']}, Distance: {p['distance']})")
    
    print("\n--- Trace ---")
    for t in response.trace:
        print(f"[{t.step}] {t.thought}")
        if t.observation:
            print(f"  Obs: {t.observation}")

if __name__ == "__main__":
    asyncio.run(test_orchestrator())
