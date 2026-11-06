-- Admin-Mediated Drawing Approval Workflow Migration
-- Adds per-version approval state, review metadata, audit history table, and deterministic historical backfill

-- 1. Schema Enhancement for drawing_versions
ALTER TABLE drawing_versions ADD COLUMN approval_status TEXT NOT NULL DEFAULT 'PENDING';
ALTER TABLE drawing_versions ADD COLUMN approval_source TEXT NOT NULL DEFAULT 'UNVERIFIED_HISTORICAL';
ALTER TABLE drawing_versions ADD COLUMN reviewed_by TEXT;
ALTER TABLE drawing_versions ADD COLUMN reviewed_at DATETIME;
ALTER TABLE drawing_versions ADD COLUMN review_feedback TEXT;

CREATE INDEX IF NOT EXISTS idx_drawing_versions_approval_status ON drawing_versions(approval_status);
CREATE INDEX IF NOT EXISTS idx_drawing_versions_approval_source ON drawing_versions(approval_source);

-- 2. Dedicated Drawing Version Reviews Audit Table
CREATE TABLE IF NOT EXISTS drawing_version_reviews (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL,
  drawing_version_id TEXT NOT NULL,
  reviewer_id TEXT NOT NULL,
  decision TEXT NOT NULL, -- 'APPROVED' | 'REJECTED'
  feedback TEXT,          -- Review notes with optional redline pin coordinates [PIN:x,y]
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (drawing_version_id) REFERENCES drawing_versions(id) ON DELETE CASCADE,
  FOREIGN KEY (reviewer_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_dvr_version_id ON drawing_version_reviews(drawing_version_id);
CREATE INDEX IF NOT EXISTS idx_dvr_project_id ON drawing_version_reviews(project_id);

-- 3. Deterministic Historical Backfill Strategy (Non-Destructive & Explicit Provenance)
-- Step 3.1: Mark historical correction target versions.
-- When an engineer opened a correction in legacy workflows against a target version, that version was reviewed work.
UPDATE drawing_versions
SET approval_status = 'APPROVED',
    approval_source = 'LEGACY_CORRECTION_TARGET',
    reviewed_at = NULL
WHERE id IN (
  SELECT target_version_id 
  FROM corrections 
  WHERE target_version_id IS NOT NULL
);

-- Step 3.2: In-review projects released under legacy rules (UNDER_ENGINEER_REVIEW / UNDER_CLIENT_REVIEW).
-- Mark ONLY the latest (terminal) version of currently in-review projects as APPROVED with LEGACY_PRE_QC_RELEASE.
-- Leave reviewed_at as NULL because no Studio Admin review took place.
UPDATE drawing_versions
SET approval_status = 'APPROVED',
    approval_source = 'LEGACY_PRE_QC_RELEASE',
    reviewed_at = NULL
WHERE id IN (
  SELECT dv.id
  FROM drawing_versions dv
  INNER JOIN (
    SELECT project_id, MAX(version_number) AS max_v
    FROM drawing_versions
    GROUP BY project_id
  ) latest ON dv.project_id = latest.project_id AND dv.version_number = latest.max_v
  INNER JOIN projects p ON p.id = dv.project_id
  WHERE p.status IN ('UNDER_ENGINEER_REVIEW', 'UNDER_CLIENT_REVIEW')
);

-- Step 3.3: Completed projects: The terminal accepted version was approved by final client acceptance.
-- Terminal version gets approval_source = 'LEGACY_COMPLETED_ACCEPTANCE' and reviewed_at = projects.approved_at.
UPDATE drawing_versions
SET approval_status = 'APPROVED',
    approval_source = 'LEGACY_COMPLETED_ACCEPTANCE',
    reviewed_at = (SELECT approved_at FROM projects WHERE projects.id = drawing_versions.project_id)
WHERE id IN (
  SELECT dv.id
  FROM drawing_versions dv
  INNER JOIN (
    SELECT project_id, MAX(version_number) AS max_v
    FROM drawing_versions
    GROUP BY project_id
  ) latest ON dv.project_id = latest.project_id AND dv.version_number = latest.max_v
  INNER JOIN projects p ON p.id = dv.project_id
  WHERE p.status = 'COMPLETED'
);

-- Note: All intermediate, unreleased, or unverified historical versions remain:
-- approval_status = 'PENDING', approval_source = 'UNVERIFIED_HISTORICAL', reviewed_at = NULL.
