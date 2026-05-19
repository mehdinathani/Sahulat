# Sahulat Oasis Design System

Earthy premium, trusted utility, and agentic precision for local service orchestration.

## Overview
Sahulat-AI is an agentic platform designed to bridge the gap between everyday households and local informal service providers (plumbers, electricians, tutors) in Pakistan. The design system, **Sahulat Oasis**, avoids generic corporate SaaS blue. Instead, it commits to a warm, organic, and highly trustworthy dark theme that blends the natural emerald greens and earthy clays of the local landscape with a modern, high-precision agentic workflow interface. 

This design utilizes glassmorphism, clear semantic indicators, rounded organic shapes, and structured data views to establish instant trust and high usability for users speaking English, Urdu, and Roman Urdu.

## Colors

- **Primary (Forest Emerald)** (`#0D9488`): The core brand color. Represents growth, trust, and community service. Used for primary buttons, active navigation, and brand elements.
- **Primary Glow** (`#14B8A6`): A brighter teal/emerald used for active statuses, hover states, and glowing accents.
- **Secondary (Clay Terracotta)** (`#C2410C`): The secondary accent. Represents manual craftsmanship, hands-on tools, and artisan energy. Used for price rates, key highlights, and ratings.
- **Background** (`#090D16`): The dark navy-slate backdrop. Provides high-contrast readability and a premium AI assistant aesthetic.
- **Surface** (`#111827`): Card backgrounds, list panels, modal bases, and text input fills.
- **Border** (`#1F2937`): Subtle separation lines and card borders.
- **Text Primary** (`#F9FAFB`): Near-white for clear readability.
- **Text Secondary** (`#9CA3AF`): Muted gray for metadata, descriptions, and secondary labels.
- **Success (Mint)** (`#10B981`): Used for booked statuses, successful transactions, and available states.
- **Warning (Amber)** (`#F59E0B`): Used for reminders, pending responses, and on-the-way states.
- **Error (Crimson)** (`#EF4444`): Used for cancellations, service unavailable states, and error alerts.

## Typography

- **Display & Headings**: Outfit (Google Fonts) — friendly, rounded, geometric sans-serif that feels clean and modern.
- **Body & Controls**: Plus Jakarta Sans (Google Fonts) — highly legible, clean neo-grotesque sans-serif with excellent Urdu/Roman Urdu script readability.

### Type Scale
- **Display Large**: Outfit 32px Bold (Tracking -0.02em, line height 1.2). Large titles, welcome screens.
- **Headline Medium**: Outfit 24px Bold (Tracking -0.01em, line height 1.25). Screen titles, section headers.
- **Title Large**: Outfit 18px SemiBold (line height 1.3). Card titles, major labels.
- **Body Large**: Plus Jakarta Sans 16px Regular (line height 1.5). Chat messages, agent explanations.
- **Body Medium**: Plus Jakarta Sans 14px Regular (line height 1.45). Metadata descriptions, provider details.
- **Label Small**: Plus Jakarta Sans 12px SemiBold (Tracking 0.05em, Uppercase). Badges, status chips, button labels.
- **Caption**: Plus Jakarta Sans 11px Medium (line height 1.3). Timestamps, fine details.

## Elevation & Glassmorphism
We embrace a modern, physical-digital hybrid design. Depth is achieved via transparency, borders, and light glow effects.
- **Standard Cards**: Surface background (`#111827`), 1px solid border (`#1F2937`), 16px border radius.
- **Glass Panel (Agent Reasoning/Modals)**: Semi-transparent backdrop (`#111827` with 70% opacity), 20px blur filter (`BackdropFilter`), 1px subtle glowing border (`#0D9488` with 20% opacity).
- **Hover/Active State**: Card shifts up 2px, border turns into Primary (`#0D9488` with 50% opacity), subtle shadow: `0px 10px 25px rgba(13, 148, 136, 0.1)`.

## Component Specifications

### 1. Chat Bubbles
- **User Bubble**: Primary Emerald background (`#0D9488`), white text, 16px corner radius, except bottom-right which is 4px.
- **Agent Bubble**: Surface background (`#111827`), border (`#1F2937`), white text, 16px corner radius, except bottom-left which is 4px. Incorporates a small green glowing dot in the header to indicate "Antigravity Orchestration Active".
- **Reasoning Panel**: Nested within the Agent's bubble or separate collapsible drawer. Uses a dark green container with transparent overlay, thin green border, showing a step-by-step trace of the AI agent's thoughts.

### 2. Provider Cards
- **Dimensions**: Width 280px, horizontal scrollable list.
- **Header**: Visual category banner with a linear gradient from Forest Emerald (`#0D9488`) to dark slate, featuring service-specific icons (plumbing, electrical, tutoring).
- **Body**: 16px padding. Title in Outfit 16px bold, star rating in Terracotta (`#C2410C`), distance and pricing clearly displayed side-by-side with high-contrast text.
- **Button**: Compact button, Primary Emerald bg, rounded 30px (pill) to feel clickable and friendly.

### 3. Suggested Action Chips
- Rounded 30px (pill shape), surface background (`#111827`), border (`#1F2937`), text in Primary Glow (`#14B8A6`). On hover, background shifts to Primary with 10% opacity.

### 4. Interactive Input Section
- Floating panel at the bottom with backdrop-blur. 
- Input box: Rounded 30px, surface background (`#111827`), placeholder text (`#9CA3AF`).
- Record Button: Glowing green pulse (`#0D9488`) when listening, turns solid red (`#EF4444`) with a white stop icon when recording.

### 5. Booking Status Badges
- **BOOKED**: Mint background (10% opacity), mint text (`#10B981`), mint border.
- **ON THE WAY**: Amber background (10% opacity), amber text (`#F59E0B`), amber border.
- **COMPLETED**: Green background (15% opacity), white text, green border.

## Do's and Don'ts

- **Do** prioritize Outfit for display text and Plus Jakarta Sans for body text to maintain the clean, premium feel.
- **Do** use Forest Emerald (`#0D9488`) for positive, high-importance interactive elements.
- **Do** show step-by-step Antigravity logs inside a distinct, green-tinted reasoning panel.
- **Do** use pill-shaped (30px) buttons and chips to maintain a friendly, accessible interface for local users.
- **Don't** use pure dark black (`#000000`) for surfaces — use the Slate Dark (`#090D16`) and Surface (`#111827`) levels.
- **Don't** use generic default blue or purple gradients.
- **Don't** hide provider distance and price; clarity and transparency are critical to establishing user trust in local services.
