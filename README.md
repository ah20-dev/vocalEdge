# Vocal Edge - AI Vocal Coaching Mobile App

An AI-powered vocal coaching mobile application built with Flutter that helps users improve their speaking skills through personalized feedback and guided lessons.

## Features

- AI-powered speech analysis with real-time feedback
- Structured learning paths (Beginner, Intermediate, Professional)
- Personalized dashboard with progress and confidence scores
- Streak tracking
- Cross-platform mobile (iOS and Android)
- Supabase authentication with social login
- Native audio recording for voice analysis

## Tech Stack

- **Frontend**: Flutter 3.16+ (iOS and Android)
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth
- **Routing**: Go Router
- **Local Storage**: Shared Preferences
- **Audio**: Record, AudioPlayers, JustAudio
- **Backend**: FastAPI on Cloud Run (see `finalscripts/`)

## Project Structure

```
lib/
├── core/
│   ├── config/          # App configuration
│   ├── routing/         # Navigation setup
│   ├── services/        # Core services
│   └── theme/           # App theming
├── features/
│   ├── auth/            # Authentication
│   ├── dashboard/       # Main dashboard
│   ├── practice/        # Practice modes
│   ├── progress/        # Progress tracking
│   ├── settings/        # Settings and profile
│   └── welcome/         # Onboarding
└── main.dart            # App entry point
```

## Getting Started

### Prerequisites

- Flutter SDK 3.16.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio (for Android development)
- Xcode (for iOS development, macOS only)
- Supabase account
- OpenAI API key (for backend analysis)

### Installation

1. Clone the repository and install dependencies:

   ```bash
   git clone <repository-url>
   cd vocal-edge
   flutter pub get
   ```

2. Copy the environment template and fill in your values locally:

   ```bash
   cp .env.example .env
   ```

   Required variables:

   | Variable | Description |
   | --- | --- |
   | `OPENAI_API_KEY` | OpenAI API key for speech analysis |
   | `SUPABASE_URL` | Supabase project URL |
   | `SUPABASE_KEY` | Supabase service role key (backend only) |
   | `SUPABASE_ANON_KEY` | Supabase anon key (mobile app) |
   | `GOOGLE_CLIENT_ID` | Google OAuth web client ID |
   | `GOOGLE_IOS_CLIENT_ID` | Google OAuth iOS client ID |
   | `GOOGLE_REVERSED_CLIENT_ID` | Google OAuth reversed client ID |
   | `BACKEND_URL` | Cloud Run or local backend base URL |

3. Update app config files with your values:

   - `lib/core/config/supabase_config.dart` — `YOUR_SUPABASE_URL`, `YOUR_SUPABASE_ANON_KEY`, `YOUR_GOOGLE_CLIENT_ID`
   - `lib/core/config/app_config.dart` — `YOUR_BACKEND_URL`
   - `ios/Runner/GoogleService-Info.plist` — Google iOS client IDs
   - `ios/Runner/Info.plist` — `GIDClientID` and URL scheme

4. Run the app:

   ```bash
   flutter run
   ```

### Backend Setup

The analysis API lives in `finalscripts/`. It reads secrets from environment variables:

- `OPENAI_API_KEY`
- `SUPABASE_URL`
- `SUPABASE_KEY`

Deploy using `cloudbuild.yaml` after replacing placeholder values (`PROJECT_ID`, `REGION`, `SERVICE_NAME`, etc.) with your own infrastructure details. Store secret values in your cloud provider's secret manager — never commit them to the repository.

### Supabase Database Schema

Create the following tables in your Supabase project:

```sql
-- Users table (extends Supabase auth.users)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE,
  email TEXT,
  full_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (id)
);

-- Practice sessions
CREATE TABLE practice_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  session_type TEXT NOT NULL,
  duration_seconds INTEGER,
  confidence_score DECIMAL(5,2),
  feedback_data JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User progress
CREATE TABLE user_progress (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  total_sessions INTEGER DEFAULT 0,
  total_minutes INTEGER DEFAULT 0,
  confidence_score DECIMAL(5,2) DEFAULT 0,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Lessons
CREATE TABLE lessons (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  level TEXT NOT NULL,
  duration_minutes INTEGER,
  category TEXT,
  content JSONB,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User lesson progress
CREATE TABLE user_lessons (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
  is_completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMP WITH TIME ZONE,
  score DECIMAL(5,2),
  UNIQUE(user_id, lesson_id)
);
```

### Development Commands

- Debug: `flutter run`
- Tests: `flutter test`
- Analyze: `flutter analyze`
- Android release: `flutter build appbundle --release`
- iOS release: `flutter build ios --release`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push and open a pull request

## License

This project is licensed under the MIT License.

## Roadmap

- Real-time AI speech analysis
- Advanced progress analytics
- Social features and leaderboards
- Offline mode support
- Push notifications for daily practice
- Apple Sign In
