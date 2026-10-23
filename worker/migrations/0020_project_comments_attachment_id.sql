-- Migration 0020: Expose attachment_file_id in project_comments view
DROP VIEW IF EXISTS project_comments;
CREATE VIEW project_comments AS
SELECT
  m.id,
  m.project_id,
  m.sender_id AS author_id,
  m.sender_name AS author_name,
  m.sender_role AS author_role,
  m.message AS content,
  m.attachment_file_id,
  f.original_name AS attachment_name,
  CAST(f.size AS TEXT) AS attachment_size,
  f.content_type AS attachment_type,
  m.created_at
FROM project_messages m
LEFT JOIN files f ON m.attachment_file_id = f.id;
