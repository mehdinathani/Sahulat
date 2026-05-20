"""Parse natural-language time preferences (English / Urdu / Roman Urdu) into a
concrete UTC datetime. Returns (datetime, human_label) — both are best-effort.

Used by booking_service to honour the user's requested slot instead of defaulting
to "now". Pure stdlib so it works in any deployment.
"""
from __future__ import annotations

from datetime import datetime, timedelta, time
from typing import Optional, Tuple
import re


# Approximate hour of day for vague time-of-day phrases.
_TIME_OF_DAY = {
    "morning": 10,
    "subah": 10,
    "fajr": 7,
    "noon": 12,
    "dopahar": 13,
    "afternoon": 15,
    "evening": 18,
    "shaam": 18,
    "maghrib": 19,
    "night": 21,
    "raat": 21,
}

# Day offsets (relative to today, local interpretation of "today" = utcnow date).
_DAY_OFFSETS = {
    "today": 0,
    "aaj": 0,
    "tonight": 0,
    "tomorrow": 1,
    "kal": 1,  # "kal" can mean yesterday OR tomorrow — we assume future for bookings
    "kal subah": 1,
    "day after tomorrow": 2,
    "parson": 2,
}


def parse_time_preference(
    time_preference: Optional[str],
    now: Optional[datetime] = None,
) -> Tuple[datetime, str]:
    """Return (scheduled_datetime_utc, human_label).

    Falls back to "now + 1 hour" if the phrase cannot be interpreted, so a booking
    is never silently set to the past.
    """
    now = now or datetime.utcnow()
    if not time_preference:
        scheduled = now + timedelta(hours=1)
        return scheduled, scheduled.strftime("%a %d %b, %I:%M %p UTC")

    text = time_preference.strip().lower()

    # Day offset
    day_offset = 0
    for phrase, offset in sorted(_DAY_OFFSETS.items(), key=lambda kv: -len(kv[0])):
        if phrase in text:
            day_offset = offset
            break

    # Explicit clock time, e.g. "10am", "10:30 pm", "17:00"
    hour: Optional[int] = None
    minute = 0
    clock = re.search(r"(\d{1,2})(?::(\d{2}))?\s*(am|pm)?", text)
    if clock:
        h = int(clock.group(1))
        m = int(clock.group(2)) if clock.group(2) else 0
        ampm = clock.group(3)
        if ampm == "pm" and h < 12:
            h += 12
        elif ampm == "am" and h == 12:
            h = 0
        if 0 <= h <= 23 and 0 <= m <= 59:
            hour, minute = h, m

    # Fall back to fuzzy time-of-day if no explicit clock
    if hour is None:
        for phrase, h in _TIME_OF_DAY.items():
            if phrase in text:
                hour = h
                break

    if hour is None:
        # Couldn't parse a time; use "morning of the requested day" as a safe default
        hour = 10

    scheduled_date = (now + timedelta(days=day_offset)).date()
    scheduled = datetime.combine(scheduled_date, time(hour=hour, minute=minute))

    # If user said "today" but the resolved time is already in the past, push forward
    if day_offset == 0 and scheduled < now:
        scheduled = now + timedelta(hours=1)

    label = scheduled.strftime("%a %d %b, %I:%M %p UTC")
    return scheduled, label
