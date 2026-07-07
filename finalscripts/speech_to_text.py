import os
import ffmpeg
import re
from fuzzywuzzy import fuzz
from openai import OpenAI
from dotenv import load_dotenv

# Load environment variables from .env file (for local development) 
load_dotenv()

# Initialize OpenAI client. 
# It now correctly reads the value of the environment variable named "OPENAI_API_KEY".
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

FILLER_WORDS = ["um", "uh", "like", "you know", "er", "ah", "oh"]
FUZZY_THRESHOLD = 80

def get_audio_duration(audio_path):
    try:
        probe = ffmpeg.probe(audio_path)
        # Note: 'streams' is a list, and duration is usually in the first stream (audio)
        duration = float(probe['streams'][0]['duration']) 
        return duration
    except ffmpeg.Error as e:
        print(f"ffmpeg-python error: {e.stderr.decode('utf8')}")
        return None

def analyze_audio_file(audio_path):
    """
    Analyzes an audio file using OpenAI Whisper API.
    Returns transcript, pace, filler words, pauses, and score.
    """
    try:
        print(f"Starting analysis of: {audio_path}")
        duration_sec = get_audio_duration(audio_path)
        print(f"Duration: {duration_sec}")
        if duration_sec is None:
            print("ERROR: Could not get audio duration")
            return None

        print("Calling Whisper API...")
        # Transcribe with OpenAI Whisper API
        with open(audio_path, "rb") as audio_file:
            response = client.audio.transcriptions.create(
                model="whisper-1",
                file=audio_file,
                response_format="verbose_json"  # includes segments for pause analysis
            )
        print(f"Whisper response received: {len(response.text)} characters")

        transcript = response.text.strip()
        # Find all words, case-insensitive
        words = re.findall(r'\b\w+\b', transcript) 

        # Fuzzy filler word detection
        filler_found = []
        for word in words:
            for filler in FILLER_WORDS:
                score = fuzz.ratio(word.lower(), filler)
                if score >= FUZZY_THRESHOLD:
                    filler_found.append(word)
                    break

        filler_count = len(filler_found)

        # Words per minute
        word_count = len(words)
        wpm = round(word_count / (duration_sec / 60), 2) if duration_sec > 0 else 0

        # Pauses (using segment timestamps)
        pauses = 0
        long_pauses = 0
        if hasattr(response, 'segments') and response.segments:
            prev_end = 0
            for seg in response.segments:
                start = seg.start
                # A pause is a gap > 0.5 seconds
                if start - prev_end > 0.5:
                    pauses += 1
                # A long pause is a gap > 1.5 seconds
                if start - prev_end > 1.5:
                    long_pauses += 1
                prev_end = seg.end

        """
        # Simple scoring
        score = 100
        # Penalize for pace outside the target range
        if wpm < 90 or wpm > 160:
            score -= 10
        # Penalize for filler words and long pauses
        score -= filler_count * 2
        score -= long_pauses * 3
        score = max(score, 0) # Ensure score is not negative"""

        # --- New Rate-Based Scoring Logic ---
        score = 100
        penalties = 0.0
        
        # Calculate Rates (avoid division by zero if duration_sec is 0, though checked above)
        if duration_sec > 0:
            duration_minutes = duration_sec / 60
            
            # 1. Pace Penalty (WPM) - Graduated Penalty
            # Ideal range: 110 WPM to 140 WPM
            ideal_min_wpm = 110
            ideal_max_wpm = 140
            
            if wpm < ideal_min_wpm:
                distance = ideal_min_wpm - wpm
                # 0.5 points off per WPM outside the low boundary
                penalties += distance * 0.5
            elif wpm > ideal_max_wpm:
                distance = wpm - ideal_max_wpm
                # 1.0 point off per WPM outside the high boundary (faster is penalized more heavily)
                penalties += distance * 1.0

            # 2. Filler Word Penalty - Rate-Based (FWPM)
            # Threshold: 1.0 Filler Word Per Minute (FWPM)
            fwpm = filler_count / duration_minutes
            if fwpm > 1.0:
                # 10 points off per FWPM over the threshold
                penalties += (fwpm - 1.0) * 10
            
            # 3. Long Pause Penalty - Rate-Based (LPPM)
            # Threshold: 0.5 Long Pauses Per Minute (LPPM)
            lppm = long_pauses / duration_minutes
            if lppm > 0.5:
                # 20 points off per LPPM over the threshold (Long pauses are severe)
                penalties += (lppm - 0.5) * 20

        # Apply penalties
        score -= round(penalties, 0)
        score = max(int(score), 0) # Ensure score is an integer and not negative

        print(f"Analysis complete - WPM: {wpm}, Filler words: {filler_count}, Score: {score}")
        return {
            "transcript": transcript,
            "pace_wpm": wpm,
            "filler_count": filler_count,
            "filler_words": filler_found,
            "pause_count": pauses,
            "long_pauses": long_pauses,
            "whisper_score": score
        }

    except Exception as e:
        print(f"Whisper API analysis error: {e}")
        print(f"Error type: {type(e)}")
        return None


if __name__ == "__main__":
    # Example usage for local testing
    # Note: You need a file named 'example.mp3' in the same directory for this to run
    test_file = "example.mp3"
    if os.path.exists(test_file):
        print(f"Analyzing {test_file}...")
        result = analyze_audio_file(test_file)
        if result:
             print(result)
        else:
             print("Analysis failed.")
    else:
        print(f"Audio file '{test_file}' not found. Cannot run local test.")