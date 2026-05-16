# Project Constitution: Sahulat-AI

**Version**: 1.1.0
**Ratification Date**: 2026-05-16
**Last Amended**: 2026-05-16

## Project Overview

**Sahulat-AI** is an Agentic AI system designed for the informal economy, automating the end-to-end lifecycle of service requests.

## Core Principles

### Principle 1: Agentic Orchestration Priority
**Google Antigravity MUST be the central orchestrator for all system logic.** 
- All multi-step reasoning, tool usage, and action execution must be handled via Antigravity.
- The backend should act primarily as a wrapper and data provider for the orchestrator.

### Principle 2: Agentic Traceability
**Mandatory visibility into agent reasoning.**
- All backend logic MUST expose its "thinking steps" (agent traces).
- The Flutter UI MUST display these traces to the user to provide transparency and meet hackathon scoring requirements (20% Agent Trace score).

### Principle 3: Clean & Action-Oriented UI
**Focus on automation over UI complexity.**
- Flutter UI MUST be clean and intuitive but simple.
- Priority is on demonstrating agentic automation and end-to-end simulation rather than complex visual features.

### Principle 4: Strict Action Simulation
**Clear separation between 'planning' and 'execution'.**
- The system MUST differentiate between the agent planning a booking and the actual simulation of that booking.
- Simulation MUST include state changes (e.g., updating a mock database, generating receipts).

### Principle 5: Data Privacy & Compliance
**Strict use of mock data.**
- Zero real PII (Personally Identifiable Information) allowed.
- All provider and user data used in demos MUST be synthetically generated.

### Principle 6: Multilingual Accessibility
**First-class support for Urdu and Roman Urdu.**
- Prompt designs and intent extraction logic MUST anticipate and handle inputs in English, Urdu, and Roman Urdu.

### Principle 7: MCP-First Development
**Leverage MCP servers for all specialized tasks to ensure accuracy and visual excellence.**
- **Documentation**: MUST use `context7` for up-to-date documentation on all libraries, frameworks, and APIs.
- **UI/UX Design**: MUST use `stitch` and `designmd` for generating and managing premium design systems and screens.
- **Agentic Skills**: MUST use `skills-mcp` to leverage and extend specialized agentic workflows.
- **Dart/Flutter**: MUST use `dart-mcp-server` for Dart and Flutter development tasks.

## Tech Stack Standards

- **Backend**: Python (FastAPI). MUST use strict typing and modular routing.
- **Frontend**: Flutter (Dart).
- **State/Database**: Firebase (or structured JSON files if APIs are latency-heavy for demos).
- **Orchestrator**: Google Antigravity.
- **Development Tools**: Mandatory usage of `context7`, `stitch`, `designmd`, `skills-mcp`, and `dart-mcp-server` MCP servers.

## Governance

### Amendment Procedure
Amendments to this constitution require a version bump and update to the `Last Amended` date.

### Versioning Policy
- **MAJOR**: Structural changes to core principles or tech stack.
- **MINOR**: Addition of new principles or significant guidance expansion.
- **PATCH**: Clarifications, formatting, or minor refinements.

### Compliance Review
Every implementation task MUST be validated against these principles during the `speckit.analyze` and `speckit.validate` phases.
