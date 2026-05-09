-- Migration: Create sentence_progress, daily_metrics, user_profiles tables
-- (recordings table already exists in 001_create_recordings.sql)

-- Bảng tiến bộ mỗi câu
CREATE TABLE IF NOT EXISTS sentence_progress (
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  sentence_id TEXT NOT NULL,
  correct_streak INT DEFAULT 0,
  best_accuracy FLOAT DEFAULT 0,
  last_practiced TIMESTAMPTZ,
  PRIMARY KEY (user_id, sentence_id)
);

-- Bảng metrics hàng ngày
CREATE TABLE IF NOT EXISTS daily_metrics (
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  date DATE NOT NULL,
  sentences_practiced INT DEFAULT 0,
  sentences_mastered INT DEFAULT 0,
  avg_accuracy FLOAT DEFAULT 0,
  avg_response_time_ms INT DEFAULT 0,
  PRIMARY KEY (user_id, date)
);

-- Bảng kết quả placement và profile
CREATE TABLE IF NOT EXISTS user_profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id),
  placement_completed BOOLEAN DEFAULT FALSE,
  placement_avg_accuracy FLOAT,
  starting_level TEXT CHECK (
    starting_level IN ('easy', 'easy_medium', 'medium_hard')
  ),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_sentence_progress_user
  ON sentence_progress(user_id);

CREATE INDEX IF NOT EXISTS idx_daily_metrics_user_date
  ON daily_metrics(user_id, date DESC);

-- Bật Row Level Security
ALTER TABLE sentence_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- RLS policies: sentence_progress
CREATE POLICY "Users can select own sentence_progress"
  ON sentence_progress FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sentence_progress"
  ON sentence_progress FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own sentence_progress"
  ON sentence_progress FOR UPDATE
  USING (auth.uid() = user_id);

-- RLS policies: daily_metrics
CREATE POLICY "Users can select own daily_metrics"
  ON daily_metrics FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own daily_metrics"
  ON daily_metrics FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own daily_metrics"
  ON daily_metrics FOR UPDATE
  USING (auth.uid() = user_id);

-- RLS policies: user_profiles
CREATE POLICY "Users can select own user_profiles"
  ON user_profiles FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own user_profiles"
  ON user_profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own user_profiles"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = user_id);
