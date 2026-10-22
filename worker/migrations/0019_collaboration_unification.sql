-- Migration 0019: Collaboration Bridge View (project_comments -> project_messages)
CREATE VIEW IF NOT EXISTS project_comments AS
SELECT
  m.id,
  m.project_id,
  m.sender_id AS author_id,
  m.sender_name AS author_name,
  m.sender_role AS author_role,
  m.message AS content,
  f.original_name AS attachment_name,
  CAST(f.size AS TEXT) AS attachment_size,
  f.content_type AS attachment_type,
  m.created_at
FROM project_messages m
LEFT JOIN files f ON m.attachment_file_id = f.id;
