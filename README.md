# Sahulat-AI Orchestrator

## Project Overview
Sahulat-AI is an intelligent, agent-driven service matching and booking platform designed to bridge the gap between users and local service providers (e.g., electricians, plumbers, AC technicians) in the informal economy. By leveraging advanced natural language processing, Sahulat-AI allows users to simply describe their problem in everyday language (including English, Urdu, or Roman Urdu). The platform's AI agent then automatically extracts the intent, discovers and ranks the best available providers based on distance and ratings, and facilitates instant booking and follow-up automation.

This project was built for the Google AI Hackathon to demonstrate the power of agentic workflows and action simulation in real-world, high-impact scenarios.

## Architecture Overview
The Sahulat-AI architecture is built on a modern, decoupled stack designed for speed, scalability, and clear separation of concerns:

- **Backend (FastAPI)**: Serves as the high-performance API gateway and houses the core AI orchestration logic. It exposes clean RESTful endpoints (`/chat`, `/booking`, `/logs`) that the frontend consumes.
- **Frontend (Flutter)**: A cross-platform mobile application providing a premium, interactive chat interface. It utilizes a striking "glassmorphism" dark-tech theme, featuring custom components like the `ProviderCard` for rich recommendations and an `AgentBrainConsole` to visualize the AI's internal reasoning.
- **Database (Mock Firebase)**: To comply with the hackathon's action simulation and data privacy requirements, we implemented a `MockFirestoreClient`. This provides persistent local storage (`mock_db.json`) that mimics Firestore's document-based structure without requiring live cloud deployment or exposing real PII.

## How Google Antigravity is Used
At the heart of Sahulat-AI is the `Orchestrator`, built to demonstrate true agentic behavior inspired by Google Antigravity patterns. Rather than a simple prompt-response loop, the Orchestrator executes a robust, multi-step reasoning pipeline:

1. **Natural Language Understanding**: The agent first analyzes the user's input to extract the core intent (service type, location, urgency).
2. **Provider Discovery & Matching**: The agent actively queries the local database to find matching providers, acting on the extracted intent.
3. **Reasoning & Recommendation**: The agent ranks the discovered providers based on proximity and user ratings, formulating a natural language recommendation.
4. **Action Simulation (Booking & Follow-up)**: Upon user confirmation, the agent executes state-changing actions—creating a booking and scheduling asynchronous follow-up notifications.

Crucially, every step of this process generates **Agentic Traces** (thought, action, observation). These traces are streamed to the Flutter frontend and displayed in the "Agent Brain Console", providing total transparency into how the AI plans and executes its tasks.

## Production Setup & Firebase Integration
While Sahulat-AI uses a `MockFirestoreClient` for local development, you can connect it to a real Google Cloud/Firebase environment for production.
To resolve the "Default credentials not found" warning during initialization:

1. **Service Account JSON**: Download your Firebase Admin SDK service account key.
2. **Environment Variable**: Set the `GOOGLE_APPLICATION_CREDENTIALS` environment variable to point to your JSON key, or explicitly set it in your `.env` file via `FIREBASE_SERVICE_ACCOUNT`.
3. **Google ADC**: If deploying to Google Cloud (Cloud Run, Compute Engine), use Application Default Credentials (ADC) by running:
   ```bash
   gcloud auth application-default login
   ```
   This ensures secure and automatic authentication without hardcoding keys.

## Tools & APIs Used
- **Google Gemini 1.5 Flash (via `google-generativeai`)**: Powers the `NLPService` for fast, accurate intent extraction and handles multilingual inputs gracefully.
- **FastAPI BackgroundTasks**: Used to simulate real-world asynchronous operations, such as delayed SMS follow-up reminders.
- **Flutter Markdown & Google Fonts**: Utilized in the frontend to render rich text responses and the highly-styled, tech-forward Agent Brain console.

## Assumptions & Limitations
- **Simulated Delays**: Background tasks (like follow-up notifications) use artificial delays (e.g., `asyncio.sleep`) to simulate real-world processing times for the sake of the demo video.
- **Mock Data**: All user, provider, and booking data is entirely mocked and stored locally in a JSON file. No real Personally Identifiable Information (PII) is collected or processed.
- **Authentication**: User authentication is bypassed for the MVP; the system assumes a default logged-in user to focus the demo purely on the agentic booking flow.
- **Location Services**: Geographic distance calculations are approximated based on predefined regional zones rather than live GPS coordinates.
