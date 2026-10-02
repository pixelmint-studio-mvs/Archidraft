-- Training Module Lessons Table
CREATE TABLE IF NOT EXISTS training_lessons (
  id TEXT PRIMARY KEY,
  module_id TEXT NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  lesson_order INTEGER NOT NULL,
  estimated_duration TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (module_id) REFERENCES training_modules(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_training_lessons_module_id ON training_lessons(module_id);
CREATE INDEX IF NOT EXISTS idx_training_lessons_order ON training_lessons(module_id, lesson_order);

-- Student Lesson Progress Table
CREATE TABLE IF NOT EXISTS student_lesson_progress (
  id TEXT PRIMARY KEY,
  student_id TEXT NOT NULL,
  lesson_id TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'IN_PROGRESS', -- 'IN_PROGRESS', 'COMPLETED'
  completed_at DATETIME,
  FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (lesson_id) REFERENCES training_lessons(id) ON DELETE CASCADE,
  UNIQUE(student_id, lesson_id)
);

CREATE INDEX IF NOT EXISTS idx_student_lesson_progress_student ON student_lesson_progress(student_id);
