-- Migration 0021: Teaching Students Curriculum Schema
-- Enhances training_modules, adds chapters, updates lessons, and creates student learning plans.

-- 1. Extend training_modules
ALTER TABLE training_modules ADD COLUMN publication_status TEXT DEFAULT 'PUBLISHED';
ALTER TABLE training_modules ADD COLUMN learning_objectives TEXT;
ALTER TABLE training_modules ADD COLUMN thumbnail_url TEXT;
ALTER TABLE training_modules ADD COLUMN updated_at DATETIME;

-- 2. Training Chapters Table
CREATE TABLE IF NOT EXISTS training_chapters (
  id TEXT PRIMARY KEY,
  module_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  chapter_order INTEGER NOT NULL DEFAULT 1,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (module_id) REFERENCES training_modules(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_training_chapters_module_id ON training_chapters(module_id);
CREATE INDEX IF NOT EXISTS idx_training_chapters_order ON training_chapters(module_id, chapter_order);

-- 3. Extend training_lessons
ALTER TABLE training_lessons ADD COLUMN chapter_id TEXT;
ALTER TABLE training_lessons ADD COLUMN resources_json TEXT;
ALTER TABLE training_lessons ADD COLUMN video_url TEXT;
ALTER TABLE training_lessons ADD COLUMN is_required INTEGER DEFAULT 1;
ALTER TABLE training_lessons ADD COLUMN updated_at DATETIME;

CREATE INDEX IF NOT EXISTS idx_training_lessons_chapter_id ON training_lessons(chapter_id);

-- 4. Student Learning Plans Table
CREATE TABLE IF NOT EXISTS student_learning_plans (
  id TEXT PRIMARY KEY,
  student_id TEXT NOT NULL,
  module_id TEXT NOT NULL,
  assigned_by TEXT NOT NULL,
  assigned_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  target_completion_date DATETIME,
  instructions TEXT,
  selected_chapters TEXT,
  selected_lessons TEXT,
  status TEXT NOT NULL DEFAULT 'ASSIGNED',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (module_id) REFERENCES training_modules(id) ON DELETE CASCADE,
  UNIQUE(student_id, module_id)
);

CREATE INDEX IF NOT EXISTS idx_student_learning_plans_student ON student_learning_plans(student_id);
CREATE INDEX IF NOT EXISTS idx_student_learning_plans_module ON student_learning_plans(module_id);
