"""
Speech-to-Text endpoint using Google Cloud Speech-to-Text API.

POST /api/stt
  - Accepts: multipart/form-data with field "audio" (WAV/FLAC/OGG/M4A/MP4)
  - Returns: {"transcript": str, "confidence": float, "language": str}

Design notes:
  - Uses synchronous recognize() for short audio clips (< 60s), which is
    the typical voice query length for this app.
  - Falls back to a mock transcript if the Cloud STT client is unavailable
    (e.g., missing credentials) so the demo works without full GCP setup.
  - The transcript is returned as plain text; the Flutter client passes it
    directly into the /api/chat endpoint as if the user typed it.
"""

import os
import tempfile
from fastapi import APIRouter, UploadFile, File, HTTPException
from pydantic import BaseModel

# Google Cloud Speech-to-Text
try:
    from google.cloud import speech_v1
    _STT_AVAILABLE = True
except ImportError:
    _STT_AVAILABLE = False

router = APIRouter()


class TranscriptResponse(BaseModel):
    transcript: str
    confidence: float = 1.0
    language: str = "en-US"
    source: str = "cloud_stt"  # "cloud_stt" | "mock"


def _get_stt_client():
    """Return a Speech client, or None if credentials aren't configured."""
    if not _STT_AVAILABLE:
        return None
    try:
        # Respect GOOGLE_APPLICATION_CREDENTIALS or default service account
        creds_path = os.getenv(
            "GOOGLE_APPLICATION_CREDENTIALS",
            os.path.join(os.path.dirname(__file__), "..", "..", "..", "service-account.json"),
        )
        if os.path.exists(creds_path):
            os.environ.setdefault("GOOGLE_APPLICATION_CREDENTIALS", creds_path)
        return speech_v1.SpeechClient()
    except Exception as e:
        print(f"⚠️  Cloud STT client init failed: {e}")
        return None


@router.post("/stt", response_model=TranscriptResponse)
async def speech_to_text(audio: UploadFile = File(...)):
    """
    Transcribe an uploaded audio file using Google Cloud Speech-to-Text.

    Supported formats: FLAC, WAV (LINEAR16), OGG_OPUS, MP3, WEBM_OPUS.
    Audio should be mono, 16 kHz for best results (auto-detected otherwise).
    """
    # Read uploaded bytes
    audio_bytes = await audio.read()
    if not audio_bytes:
        raise HTTPException(status_code=400, detail="Empty audio file received.")

    client = _get_stt_client()

    # ------------------------------------------------------------------ #
    # Live Cloud STT path                                                 #
    # ------------------------------------------------------------------ #
    if client:
        try:
            # Auto-detect encoding from filename extension
            filename = (audio.filename or "audio.wav").lower()
            if filename.endswith(".flac"):
                encoding = speech_v1.RecognitionConfig.AudioEncoding.FLAC
            elif filename.endswith((".ogg", ".opus")):
                encoding = speech_v1.RecognitionConfig.AudioEncoding.OGG_OPUS
            elif filename.endswith(".mp3"):
                encoding = speech_v1.RecognitionConfig.AudioEncoding.MP3
            elif filename.endswith(".webm"):
                encoding = speech_v1.RecognitionConfig.AudioEncoding.WEBM_OPUS
            else:
                # Default to LINEAR16 WAV
                encoding = speech_v1.RecognitionConfig.AudioEncoding.LINEAR16

            config = speech_v1.RecognitionConfig(
                encoding=encoding,
                sample_rate_hertz=16000,
                # Support English + Urdu for our multilingual users
                language_code="en-US",
                alternative_language_codes=["ur-PK"],
                enable_automatic_punctuation=True,
            )
            audio_obj = speech_v1.RecognitionAudio(content=audio_bytes)
            response = client.recognize(config=config, audio=audio_obj)

            if response.results:
                best = response.results[0].alternatives[0]
                return TranscriptResponse(
                    transcript=best.transcript,
                    confidence=round(best.confidence, 3),
                    language="en-US",
                    source="cloud_stt",
                )
            else:
                return TranscriptResponse(
                    transcript="",
                    confidence=0.0,
                    language="en-US",
                    source="cloud_stt",
                )
        except Exception as e:
            print(f"⚠️  Cloud STT recognition failed: {e}. Falling back to mock.")

    # ------------------------------------------------------------------ #
    # Mock fallback (no credentials / API error)                          #
    # ------------------------------------------------------------------ #
    print("ℹ️  Using mock STT transcript for demo.")
    mock_transcript = "Mujhe G-13 mein electrician chahiye kal subah tak"
    return TranscriptResponse(
        transcript=mock_transcript,
        confidence=0.95,
        language="roman_ur",
        source="mock",
    )
