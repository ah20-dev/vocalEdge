import os
import numpy as np
import librosa
import parselmouth


# --- Voice Profile Configuration ---
VOICE_PROFILES = {
    "male": {
        "pitch_range": (85, 180),  # Male typical pitch range
        "pitch_variation_target": (15, 35),  # Male typical variation
    },
    "female": {
        "pitch_range": (165, 255),  # Female typical pitch range
        "pitch_variation_target": (25, 45),  # Female typical variation
    }
}


def detect_voice_profile(pitch_mean_hz):
    """
    Auto-detects voice profile based on average pitch.
    Threshold: 160 Hz (between typical male and female ranges)
    
    Returns: "male" or "female"
    """
    if pitch_mean_hz < 160:
        return "male"
    else:
        return "female"


def _score_linear_interpolation(value, min_val, max_val, min_score=50, max_score=100):
    """Linearly maps a value between min_val and max_val to a score between min_score and max_score."""
    if value <= min_val:
        return min_score
    if value >= max_val:
        return max_score

    # Linear interpolation
    normalized_value = (value - min_val) / (max_val - min_val)
    score = normalized_value * (max_score - min_score) + min_score
    return round(float(score), 1)

# --- 2. Target Range Scoring (Best for Pitch and Resonance) ---
# Scores based on proximity to an optimal range, penalizing both extremes.
def _score_target_range(value, optimal_min, optimal_max, max_score=100, penalty_factor=0.5):
    """
    Scores a value based on how close it is to an optimal range.
    Uses a maximum score for values in the range, and penalizes outside it.
    """
    if optimal_min <= value <= optimal_max:
        return max_score
    
    # Calculate distance from the optimal range
    if value < optimal_min:
        distance = optimal_min - value
    else: # value > optimal_max
        distance = value - optimal_max

    # Apply a penalty proportional to the distance. Max penalty ensures a score floor of 50.
    penalty = distance * penalty_factor
    score = max_score - penalty
    
    return round(float(max(50, score)), 1)


def get_audio_duration(audio_path):
    try:
        y, sr = librosa.load(audio_path, sr=None)
        return librosa.get_duration(y=y, sr=sr)
    except Exception as e:
        print(f"Error reading audio file: {e}")
        return None

def load_and_normalize_audio(audio_path, sr=16000):
    """
    Loads audio and applies peak normalization.
    Peak normalization ensures consistent volume across recordings for fair energy scoring.
    """
    y, sr = librosa.load(audio_path, sr=sr)
    
    # Peak normalization (scales audio so peak amplitude = 1.0)
    y_normalized = librosa.util.normalize(y)
    
    return y_normalized, sr

def analyze_prosody(audio_path):
    """
    Analyzes audio prosody: pitch, energy, resonance (MFCCs)
    Auto-detects voice profile and uses adaptive scoring.
    Returns metrics and scored values.
    """
    if not os.path.exists(audio_path):
        print(f"File '{audio_path}' not found.")
        return None

    # Load and normalize audio (peak normalization for consistent energy scoring)
    y, sr = load_and_normalize_audio(audio_path)
    duration_sec = get_audio_duration(audio_path)

    # Pitch (F0)
    snd = parselmouth.Sound(audio_path)
    pitch = snd.to_pitch()
    pitch_values = pitch.selected_array['frequency']
    pitch_values = pitch_values[pitch_values > 0]
    pitch_mean_hz = float(np.mean(pitch_values)) if len(pitch_values) > 0 else 0
    pitch_variation_hz = float(np.std(pitch_values)) if len(pitch_values) > 0 else 0

    # Auto-detect voice profile from pitch
    detected_profile = detect_voice_profile(pitch_mean_hz)
    profile_config = VOICE_PROFILES[detected_profile]

    # Energy (dB) - Calculated from NORMALIZED audio
    energy_mean = float(np.mean(y**2))
    energy_db = 10 * np.log10(energy_mean) if energy_mean > 0 else -float('inf')

    # Resonance (MFCC variation)
    mfccs = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=13)
    resonance_variation = float(np.std(mfccs))

    # --- Adaptive Scoring Logic ---
    
    # 1. Pitch Variation Score (ADAPTIVE based on detected voice profile)
    # Uses profile-specific target range for fair scoring across genders
    pitch_variation_min, pitch_variation_max = profile_config["pitch_variation_target"]
    pitch_score = _score_target_range(
        pitch_variation_hz, 
        pitch_variation_min, 
        pitch_variation_max, 
        penalty_factor=0.8
    )

    # 2. Energy Score (Linear Interpolation: -60 dB to -20 dB for normalized audio)
    # Updated range for peak-normalized audio (louder = better projection)
    energy_score = _score_linear_interpolation(energy_db, -60, -20)

    # 3. Resonance Variation Score (Target Range: 40 - 90)
    # Rewards variation in voice texture (timbre) that is engaging but not chaotic
    resonance_score = _score_target_range(resonance_variation, 40, 90, penalty_factor=0.4)

    # Combined Score (Simple Average)
    combined_prosody_score = round((pitch_score + energy_score + resonance_score) / 3, 1)

    return {
        "duration_sec": duration_sec,
        "pitch_mean_hz": pitch_mean_hz,
        "pitch_variation_hz": pitch_variation_hz,
        "energy_db": energy_db,
        "resonance_variation": resonance_variation,
        "detected_voice_profile": detected_profile,  # Include for logging/debugging
        "scores": {
            "pitch_score": pitch_score,
            "energy_score": energy_score,
            "resonance_score": resonance_score,
            "combined_prosody_score": combined_prosody_score
        }
    }
