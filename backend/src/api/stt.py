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
from typing import Optional
from fastapi import APIRouter, UploadFile, File, HTTPException, Form
from pydantic import BaseModel

# Google Cloud Speech-to-Text
try:
    from google.cloud import speech_v1
    _STT_AVAILABLE = True
except ImportError:
    _STT_AVAILABLE = False

# Gemini API for Speech-to-Text
try:
    from google import genai
    from google.genai import types
    _GEMINI_STT_AVAILABLE = True
except ImportError:
    _GEMINI_STT_AVAILABLE = False

router = APIRouter()


class TranscriptResponse(BaseModel):
    transcript: str
    confidence: float = 1.0
    language: str = "en-US"
    source: str = "cloud_stt"  # "cloud_stt" | "mock" | "gemini_stt"


def _get_gemini_client():
    if not _GEMINI_STT_AVAILABLE:
        return None
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        return None
    try:
        return genai.Client(api_key=api_key)
    except Exception as e:
        print(f"Gemini Client initialization failed: {e}")
        return None


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
        print(f"Cloud STT client init failed: {e}")
        return None


@router.post("", response_model=TranscriptResponse)
async def speech_to_text(
    audio: UploadFile = File(...),
    language_code: Optional[str] = Form(None),
    preset: Optional[str] = Form(None),
):
    """
    Transcribe an uploaded audio file using Gemini API or Google Cloud Speech-to-Text.
    Falls back to a mock transcript if both live services fail or are unconfigured.
    """
    # Read uploaded bytes
    audio_bytes = await audio.read()
    
    if audio_bytes and len(audio_bytes) >= 1000:
        # 1. Try Gemini STT
        gemini_client = _get_gemini_client()
        if gemini_client:
            try:
                filename = (audio.filename or "audio.wav").lower()
                mime_type = audio.content_type or "audio/wav"
                if filename.endswith(".flac"):
                    mime_type = "audio/flac"
                elif filename.endswith((".ogg", ".opus")):
                    mime_type = "audio/ogg"
                elif filename.endswith(".mp3"):
                    mime_type = "audio/mp3"
                elif filename.endswith(".webm"):
                    mime_type = "audio/webm"
                elif filename.endswith(".wav"):
                    mime_type = "audio/wav"
                elif filename.endswith(".m4a"):
                    mime_type = "audio/m4a"
                elif filename.endswith(".pcm"):
                    mime_type = "audio/pcm"
                
                print(f"Attempting Gemini STT transcription. Filename: {filename}, Mimetype: {mime_type}")
                
                # Language hinting instructions for the prompt
                lang_hint = ""
                if language_code == "en-US":
                    lang_hint = " Please transcribe the audio in English."
                elif language_code == "ur-PK":
                    lang_hint = " Please transcribe the audio in Urdu (using Urdu Arabic script)."
                
                response = gemini_client.models.generate_content(
                    model="gemini-2.5-flash",
                    contents=[
                        f"Transcribe this audio clip precisely. Return ONLY the transcribed text, nothing else. Do not add explanations or formatting.{lang_hint}",
                        types.Part.from_bytes(
                            data=audio_bytes,
                            mime_type=mime_type
                        ),
                    ],
                )
                
                transcript_text = response.text.strip() if response.text else ""
                if transcript_text:
                    # Clean up backticks/markdown block if present
                    if transcript_text.startswith("```"):
                        lines = transcript_text.split("\n")
                        if len(lines) >= 3 and lines[0].startswith("```") and lines[-1] == "```":
                            transcript_text = "\n".join(lines[1:-1]).strip()
                    
                    print(f"Gemini STT transcription successful: '{transcript_text}'")
                    return TranscriptResponse(
                        transcript=transcript_text,
                        confidence=0.99,
                        language=language_code or "en-US",
                        source="gemini_stt",
                    )
            except Exception as e:
                print(f"Gemini STT recognition failed: {e}. Falling back to Cloud STT.")

        # 2. Try Google Cloud Speech-to-Text as backup
        client = _get_stt_client()
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

                # Determine language configuration
                target_lang = "en-US"
                alt_langs = ["ur-PK"]
                if language_code == "en-US":
                    target_lang = "en-US"
                    alt_langs = []
                elif language_code == "ur-PK":
                    target_lang = "ur-PK"
                    alt_langs = []

                config = speech_v1.RecognitionConfig(
                    encoding=encoding,
                    sample_rate_hertz=16000,
                    # Support selected constraints or English + Urdu bilingual detection
                    language_code=target_lang,
                    alternative_language_codes=alt_langs,
                    enable_automatic_punctuation=True,
                )
                audio_obj = speech_v1.RecognitionAudio(content=audio_bytes)
                response = client.recognize(config=config, audio=audio_obj)

                if response.results:
                    best = response.results[0].alternatives[0]
                    if best.transcript.strip():
                        print(f"Cloud STT transcription successful: '{best.transcript}'")
                        return TranscriptResponse(
                            transcript=best.transcript,
                            confidence=round(best.confidence, 3),
                            language=target_lang,
                            source="cloud_stt",
                        )
                print("Cloud STT returned no results (silent audio?), falling back to mock.")
            except Exception as e:
                print(f"Cloud STT recognition failed: {e}. Falling back to mock.")
    else:
        print("Empty audio bytes received. Skipping live STT and falling back to mock.")

    # ------------------------------------------------------------------ #
    # Mock fallback (no credentials / API error / silent audio)           #
    # ------------------------------------------------------------------ #
    print(f"Using mock STT transcript for demo. Language Code: {language_code}, Preset: {preset}")
    
    # Nested mapping structures for languages and presets
    presets_map = {
        "en-US": {
            "electrician": "I need a certified electrician to fix my living room wiring tomorrow morning.",
            "ac": "Can you book an AC repair technician? My air conditioner is not cooling properly.",
            "plumber": "Please find me a plumber to fix a water leakage in my kitchen pipeline.",
            "tutor": "I am looking for a physics home tutor for my 10th grade student in F-11."
        },
        "ur-PK": {
            "electrician": "مجھے اپنے گھر کے شارٹ سرکٹ کے لیے ایک الیکٹریشن کی ضرورت ہے۔",
            "ac": "براہ کرم اے سی سروس کے لیے کسی اچھے ٹیکنیشن کو بھیجیں۔",
            "plumber": "باھر کچن کے نلکے سے پانی ٹپک رہا ہے، کسی پلمبر کو بھیج دیں۔",
            "tutor": "مجھے دسویں جماعت کے بچے کو ریاضی پڑھانے کے لیے ہوم ٹیوٹر چاہیے۔"
        },
        "auto": {
            "electrician": "Mujhe G-13 mein electrician chahiye kal subah tak",
            "ac": "Mera AC thandi hawa nahi de raha, check karwane ke liye technician chahiye",
            "plumber": "Kitchen ka pipe leak ho raha hai, emergency plumber chahiye",
            "tutor": "Bachon ko math aur science parhane ke liye home tutor ki talaash hai"
        }
    }

    # Match language_code safely
    lang = language_code if language_code in presets_map else "auto"
    preset_key = preset if preset in presets_map[lang] else "electrician"
    
    mock_transcript = presets_map[lang][preset_key]
    
    return TranscriptResponse(
        transcript=mock_transcript,
        confidence=0.95,
        language=lang,
        source="mock",
    )
