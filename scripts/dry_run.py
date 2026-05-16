import requests
import time
import json
import os

API_BASE_URL = "http://localhost:8000/api"

def run_dry_run():
    print("Starting Sahulat-AI Dry Run Sequence...")
    print("-" * 50)

    # 1. Clear previous logs
    print("Clearing previous logs...")
    requests.delete(f"{API_BASE_URL}/logs")

    # 2. Simulate User Chat Request
    print("\n[Step 1] Sending natural language request for a plumber...")
    chat_payload = {
        "content": "I need a plumber urgently in Gulberg Lahore",
        "role": "user"
    }
    
    try:
        response = requests.post(f"{API_BASE_URL}/chat", json=chat_payload)
        response.raise_for_status()
        chat_data = response.json()
        print(f"\nResponse from Orchestrator:\n{chat_data.get('content')}")
        
        providers = chat_data.get('providers', [])
        if not providers:
            print("\nNo providers found. Ensure seed data is loaded.")
            return

        best_provider = providers[0]
        print(f"\nMatched Provider: {best_provider['name']} (Rating: {best_provider['rating']})")

        # 3. Simulate Booking Confirmation
        print(f"\n[Step 2] Simulating booking confirmation for {best_provider['name']}...")
        booking_payload = {
            "id": "mock_booking_123",
            "provider_id": best_provider['id'],
            "user_id": "user_123",
            "service_type": "plumber",
            "status": "BOOKED"
        }
        
        booking_response = requests.post(f"{API_BASE_URL}/booking/confirm", json=booking_payload)
        booking_response.raise_for_status()
        print(f"Booking Confirmed: {booking_response.json()}")

        # Also trigger the "Book" text to chat to trigger follow up simulation trace
        print(f"\n[Step 3] Simulating 'Book' command to Orchestrator to generate final trace...")
        book_command_payload = {
            "content": f"Book {best_provider['name']}",
            "role": "user"
        }
        requests.post(f"{API_BASE_URL}/chat", json=book_command_payload)

        # 4. Wait for follow-up background task
        print("\n[Step 4] Waiting 6 seconds for background follow-up automation...")
        time.sleep(6)

        # 5. Retrieve Logs
        print("\n[Step 5] Retrieving Agentic Execution Traces...")
        logs_response = requests.get(f"{API_BASE_URL}/logs")
        logs_response.raise_for_status()
        
        logs_data = logs_response.json()
        
        # 6. Save to file
        os.makedirs("logs", exist_ok=True)
        output_file = "logs/dry_run_output.json"
        with open(output_file, "w") as f:
            json.dump(logs_data, f, indent=2)
            
        print(f"\nDry run completed successfully! Logs saved to {output_file}")
        print("-" * 50)
        
        # Print a snippet of the logs
        traces = logs_data.get("logs", [])
        if traces:
            print("\nCaptured Traces Summary:")
            for log in traces:
                print(f"\nRequest: {log['request']}")
                for trace in log['response'].get('trace', []):
                    print(f"  -> [{trace['step']}] {trace['thought']}")

    except Exception as e:
        print(f"Error during dry run: {e}")

if __name__ == "__main__":
    run_dry_run()
