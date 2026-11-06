-- ============================================================================
-- Migration 0025: PIXMINT BOT 2.0 Database Schema
-- ============================================================================
-- Provides persistent chat sessions, role-isolated messages, knowledge document
-- index, knowledge chunk storage, suggested questions catalog, centralized bot
-- configuration, administrative audit trail, unanswered question triage, and
-- user feedback collection for the PIXMINT BOT AI Assistant platform.
--
-- Compatibility: Cloudflare D1 (SQLite)
-- Safe: All statements use CREATE TABLE IF NOT EXISTS / CREATE INDEX IF NOT EXISTS
-- Additive: Does NOT modify, drop, or truncate any existing ARCHI DRAFT tables.
-- ============================================================================

-- ────────────────────────────────────────────────────────────────────────────
-- 1. CHAT SESSIONS
-- Stores one record per conversation initiated by an authenticated user.
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS chat_sessions (
    id          TEXT    PRIMARY KEY,
    user_id     TEXT    NOT NULL,
    user_role   TEXT    NOT NULL CHECK(user_role IN ('engineer', 'draughtsman', 'student', 'admin', 'guest')),
    title       TEXT    NOT NULL DEFAULT 'New Conversation',
    is_archived INTEGER NOT NULL DEFAULT 0,
    created_at  INTEGER NOT NULL,
    updated_at  INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_chat_sessions_user      ON chat_sessions(user_id, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_role      ON chat_sessions(user_role);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_archived  ON chat_sessions(is_archived, updated_at DESC);

-- ────────────────────────────────────────────────────────────────────────────
-- 2. CHAT MESSAGES
-- Stores every user query, bot response, and system message within a session.
-- Foreign key enforces session existence; ON DELETE CASCADE removes orphans.
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS chat_messages (
    id           TEXT    PRIMARY KEY,
    session_id   TEXT    NOT NULL,
    user_id      TEXT    NOT NULL,
    sender       TEXT    NOT NULL CHECK(sender IN ('user', 'bot', 'system')),
    content      TEXT    NOT NULL,
    sources_json TEXT,           -- JSON array of ChatSource objects
    model_name   TEXT,
    latency_ms   INTEGER,
    created_at   INTEGER NOT NULL,
    FOREIGN KEY(session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_session   ON chat_messages(session_id, created_at ASC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_user      ON chat_messages(user_id, created_at DESC);

-- ────────────────────────────────────────────────────────────────────────────
-- 3. KNOWLEDGE DOCUMENTS
-- Registry of approved knowledge source documents used for AI grounding.
-- The `status` column (from standalone migration 0018) is included directly.
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS knowledge_documents (
    id                TEXT    PRIMARY KEY,
    path              TEXT    NOT NULL UNIQUE,
    title             TEXT    NOT NULL,
    category          TEXT    NOT NULL,
    version           TEXT    NOT NULL DEFAULT '1.0.0',
    allowed_roles_json TEXT   NOT NULL,  -- JSON array of allowed BotUserRole values
    content           TEXT    NOT NULL,
    status            TEXT    NOT NULL DEFAULT 'approved',
    updated_at        INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_knowledge_documents_status   ON knowledge_documents(status);
CREATE INDEX IF NOT EXISTS idx_knowledge_documents_category ON knowledge_documents(category);

-- ────────────────────────────────────────────────────────────────────────────
-- 4. KNOWLEDGE CHUNKS
-- Subdivided sections of knowledge documents for granular retrieval.
-- Foreign key to parent document; ON DELETE CASCADE removes orphan chunks.
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS knowledge_chunks (
    id                TEXT    PRIMARY KEY,
    doc_id            TEXT    NOT NULL,
    section_title     TEXT    NOT NULL,
    content           TEXT    NOT NULL,
    allowed_roles_json TEXT   NOT NULL,  -- JSON array of allowed BotUserRole values
    keywords          TEXT,              -- Comma-separated or JSON keyword list
    updated_at        INTEGER NOT NULL,
    FOREIGN KEY(doc_id) REFERENCES knowledge_documents(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_doc ON knowledge_chunks(doc_id);

-- ────────────────────────────────────────────────────────────────────────────
-- 5. SUGGESTED QUESTIONS
-- Role-specific prompt suggestions displayed in the chat launcher UI.
-- Managed by administrators through the Admin Control Center.
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS suggested_questions (
    id          TEXT    PRIMARY KEY,
    role        TEXT    NOT NULL CHECK(role IN ('engineer', 'draughtsman', 'student', 'admin', 'guest')),
    label       TEXT    NOT NULL,
    prompt      TEXT    NOT NULL,
    icon        TEXT    NOT NULL DEFAULT 'help_outline',
    sort_order  INTEGER NOT NULL DEFAULT 0,
    is_active   INTEGER NOT NULL DEFAULT 1,
    updated_at  INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_suggested_questions_role ON suggested_questions(role, sort_order ASC);

-- ────────────────────────────────────────────────────────────────────────────
-- 6. BOT CONFIGURATION
-- Key-value store for centralized bot settings (global enable, maintenance
-- mode, portal toggles, rate limits, etc.). Uses UPSERT pattern.
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bot_config (
    key         TEXT    PRIMARY KEY,
    value_json  TEXT    NOT NULL,
    updated_at  INTEGER NOT NULL,
    updated_by  TEXT    NOT NULL
);

-- ────────────────────────────────────────────────────────────────────────────
-- 7. PIXMINT AUDIT LOGS
-- Immutable administrative action records for bot configuration changes,
-- knowledge governance, and operational events. Named `pixmint_audit_logs`
-- to avoid collision with any future ARCHI DRAFT platform audit tables.
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS pixmint_audit_logs (
    id              TEXT    PRIMARY KEY,
    admin_user_id   TEXT    NOT NULL,
    action          TEXT    NOT NULL,
    target          TEXT,
    metadata_json   TEXT,
    created_at      INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_pixmint_audit_logs_created ON pixmint_audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_pixmint_audit_logs_action  ON pixmint_audit_logs(action, created_at DESC);

-- ────────────────────────────────────────────────────────────────────────────
-- 8. UNANSWERED QUESTIONS
-- Records queries where the knowledge retrieval engine found no relevant
-- grounded chunks, enabling administrators to identify knowledge gaps.
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS unanswered_questions (
    id              TEXT    PRIMARY KEY,
    user_id         TEXT    NOT NULL,
    user_role       TEXT    NOT NULL,
    query           TEXT    NOT NULL,
    intent_category TEXT,
    failure_reason  TEXT    NOT NULL,
    created_at      INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_unanswered_questions_created ON unanswered_questions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_unanswered_questions_role    ON unanswered_questions(user_role, created_at DESC);

-- ────────────────────────────────────────────────────────────────────────────
-- 9. USER FEEDBACK
-- Stores thumbs-up (+1) / thumbs-down (-1) ratings and optional text
-- comments on individual bot responses. Foreign key to the rated message.
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_feedback (
    id            TEXT    PRIMARY KEY,
    message_id    TEXT    NOT NULL,
    user_id       TEXT    NOT NULL,
    rating        INTEGER NOT NULL CHECK(rating IN (-1, 1)),
    feedback_text TEXT,
    created_at    INTEGER NOT NULL,
    FOREIGN KEY(message_id) REFERENCES chat_messages(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_user_feedback_message ON user_feedback(message_id);
CREATE INDEX IF NOT EXISTS idx_user_feedback_user    ON user_feedback(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_feedback_rating  ON user_feedback(rating, created_at DESC);

-- ============================================================================
-- END OF MIGRATION 0025
-- ============================================================================

