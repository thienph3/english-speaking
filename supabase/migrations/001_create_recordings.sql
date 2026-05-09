-- Migration: Create recordings table and Storage bucket
-- Lưu metadata bản ghi âm before/after/practice cho mỗi sentence.

-- Tạo bảng recordings
CREATE TABLE IF NOT EXISTS recordings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  sentence_id TEXT NOT NULL,
  audio_path TEXT NOT NULL,
  accuracy FLOAT,
  recording_type TEXT NOT NULL CHECK (
    recording_type IN ('before', 'after', 'practice')
  ),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Index cho truy vấn theo user + sentence
CREATE INDEX idx_recordings_user_sentence
  ON recordings(user_id, sentence_id);

-- Index cho lọc theo recording_type
CREATE INDEX idx_recordings_type
  ON recordings(user_id, sentence_id, recording_type);

-- Bật Row Level Security
ALTER TABLE recordings ENABLE ROW LEVEL SECURITY;

-- Policy: User chỉ đọc được recordings của chính mình
CREATE POLICY "Users can select own recordings"
  ON recordings FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: User chỉ insert recordings của chính mình
CREATE POLICY "Users can insert own recordings"
  ON recordings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: User chỉ xóa recordings của chính mình
CREATE POLICY "Users can delete own recordings"
  ON recordings FOR DELETE
  USING (auth.uid() = user_id);

-- Tạo Storage bucket "recordings" (public = false)
INSERT INTO storage.buckets (id, name, public)
VALUES ('recordings', 'recordings', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policy: User upload vào folder của mình
CREATE POLICY "Users can upload own recordings"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'recordings'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Storage policy: User đọc file của mình
CREATE POLICY "Users can read own recordings"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'recordings'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Storage policy: User xóa file của mình
CREATE POLICY "Users can delete own recordings"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'recordings'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );
