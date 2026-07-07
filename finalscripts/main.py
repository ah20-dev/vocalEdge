import os
import tempfile
import asyncio
import json
from typing import Optional

from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.responses import JSONResponse
from fastapi.encoders import jsonable_encoder
from fastapi.middleware.cors import CORSMiddleware  # <--- NEW IMPORT

from speech_to_text import analyze_audio_file
from prosody import analyze_prosody

from supabase import create_client, Client
from pydub import AudioSegment  # <-- Added for MP3 conversion

# -----------------------------
# Supabase setup (use hardcoded values for testing)
# -----------------------------

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# -----------------------------
# FastAPI app
# -----------------------------
app = FastAPI(title="Speech & Prosody Analysis API (Improved)")

# --- CORS Configuration ---
origins = [
    "*"
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],  # Allows POST, GET, etc.
    allow_headers=["*"],  # Allows Content-Type and other standard headers
)
# --------------------------

# Helper to run blocking functions in thread pool
async def run_blocking(fn, *args, **kwargs):
    loop = asyncio.get_running_loop()
    return await loop.run_in_executor(None, lambda: fn(*args, **kwargs))

# -----------------------------
# MP3 Conversion Helper
# -----------------------------
def convert_to_mp3(input_path: str) -> str:
    """
    Convert an audio file to mp3 and return the mp3 file path.
    If already MP3, return original. Otherwise convert.
    """
    # If already MP3, return as-is
    if input_path.lower().endswith('.mp3'):
        return input_path
    
    # Convert other formats to MP3
    mp3_path = os.path.splitext(input_path)[0] + ".mp3"
    
    # Try auto-detection first, then fallback to web formats
    try:
        AudioSegment.from_file(input_path).export(mp3_path, format="mp3", bitrate="192k")
    except:
        # Fallback for web audio formats
        AudioSegment.from_file(input_path, format="webm").export(mp3_path, format="mp3", bitrate="192k")
    
    return mp3_path

# -----------------------------
# API Endpoint
# -----------------------------
@app.post("/analyze-audio")
async def analyze_audio(
    file: UploadFile = File(...),
    user_id: str = Form(...),
    user_filename: str = Form(...)
):
    """
    Upload audio -> convert to MP3 immediately -> run Whisper + Prosody -> insert results to Supabase.
    """

    # 1) Save uploaded file to a temp file
    try:
        suffix = os.path.splitext(file.filename)[1] or ".webm"
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            tmp.write(await file.read())
            temp_path = tmp.name
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save uploaded file: {e}")

    # 2) Convert to MP3 immediately
    try:
        mp3_path = await run_blocking(convert_to_mp3, temp_path)
        
        # Validate converted audio file
        if os.path.getsize(mp3_path) == 0:
            raise HTTPException(status_code=500, detail="Converted audio file is empty")
        
        # Add debugging logs
        print(f"Original file size: {os.path.getsize(temp_path)}")
        print(f"MP3 file size: {os.path.getsize(mp3_path)}")
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to convert file to mp3: {e}")

    # Keep track for cleanup / rollback
    clip_id = None

    try:
        # 3) Run Whisper analysis on MP3
        print(f"About to call analyze_audio_file with: {mp3_path}")
        whisper_results = await run_blocking(analyze_audio_file, mp3_path)
        print(f"Whisper results: {whisper_results}")
        if not whisper_results:
            print("ERROR: Whisper analysis returned None")
            raise HTTPException(status_code=500, detail="Whisper analysis returned no result")

        whisper_results = jsonable_encoder(whisper_results)

        # 4) Run Prosody analysis on MP3
        prosody_results = await run_blocking(analyze_prosody, mp3_path)
        if not prosody_results:
            raise HTTPException(status_code=500, detail="Prosody analysis returned no result")

        prosody_results = jsonable_encoder(prosody_results)

        # 5) Calculate overall score
        whisper_score = whisper_results.get("whisper_score", 0)
        prosody_scores = prosody_results.get("scores", {})
        combined_prosody_score = prosody_scores.get("combined_prosody_score", 0)
        overall_score = (whisper_score + combined_prosody_score) / 2
        
        print(f"Calculated overall score: {overall_score} (whisper: {whisper_score}, prosody: {combined_prosody_score})")
        
        # 6) Insert audio_clips row
        clip_payload = {
            "user_id": user_id,
            "user_filename": user_filename,
            "duration_sec": prosody_results.get("duration_sec"),
            "overall_score": overall_score
        }
        clip_resp = supabase.table("audio_clips").insert(clip_payload).execute()

        if not getattr(clip_resp, "data", None):
            raise HTTPException(status_code=500, detail=f"Failed to insert audio_clips: {clip_resp}")

        clip_id = clip_resp.data[0]["id"]

        # 7) Insert whisper_analysis
        whisper_payload = {
            "clip_id": clip_id,
            "user_filename": user_filename,
            "transcript": whisper_results.get("transcript"),
            "pace_wpm": whisper_results.get("pace_wpm"),
            "filler_count": whisper_results.get("filler_count"),
            "filler_words": whisper_results.get("filler_words", []),
            "pause_count": whisper_results.get("pause_count"),
            "long_pauses": whisper_results.get("long_pauses"),
            "whisper_score": whisper_results.get("whisper_score")
        }
        whisper_resp = supabase.table("whisper_analysis").insert(whisper_payload).execute()

        if not getattr(whisper_resp, "data", None):
            supabase.table("audio_clips").delete().eq("id", clip_id).execute()
            raise HTTPException(status_code=500, detail=f"Failed to insert whisper_analysis: {whisper_resp}")

        # 8) Insert prosody_analysis
        prosody_scores = prosody_results.get("scores") or {}
        prosody_payload = {
            "clip_id": clip_id,
            "user_filename": user_filename,
            "pitch_mean_hz": prosody_results.get("pitch_mean_hz"),
            "pitch_variation_hz": prosody_results.get("pitch_variation_hz"),
            "energy_db": prosody_results.get("energy_db"),
            "resonance_variation": prosody_results.get("resonance_variation"),
            "pitch_score": prosody_scores.get("pitch_score"),
            "energy_score": prosody_scores.get("energy_score"),
            "resonance_score": prosody_scores.get("resonance_score"),
            "combined_prosody_score": prosody_scores.get("combined_prosody_score")
        }
        prosody_resp = supabase.table("prosody_analysis").insert(prosody_payload).execute()

        if not getattr(prosody_resp, "data", None):
            supabase.table("whisper_analysis").delete().eq("clip_id", clip_id).execute()
            supabase.table("audio_clips").delete().eq("id", clip_id).execute()
            raise HTTPException(status_code=500, detail=f"Failed to insert prosody_analysis: {prosody_resp}")

        # 9) success — return combined results
        return JSONResponse(content={
            "clip_id": clip_id,
            "whisper": whisper_results,
            "prosody": prosody_results
        })

    except HTTPException:
        raise
    except Exception as e:
        if clip_id:
            try:
                supabase.table("whisper_analysis").delete().eq("clip_id", clip_id).execute()
                supabase.table("prosody_analysis").delete().eq("clip_id", clip_id).execute()
                supabase.table("audio_clips").delete().eq("id", clip_id).execute()
            except Exception:
                pass
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        for path in [temp_path, mp3_path]:
            if path and os.path.exists(path):
                try:
                    os.remove(path)
                except Exception:
                    pass