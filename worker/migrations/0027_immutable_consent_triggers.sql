-- ============================================================================
-- ARCHI DRAFT — DATABASE MIGRATION 0027: IMMUTABLE AUDIT TRIGGERS
-- TARGET: Cloudflare D1 Database (archi-draft-db)
-- JURISDICTION: India (DPDP Act 2023, CERT-In Direction No. 20(3)/2022)
-- PURPOSE: Strictly enforce append-only immutability on statutory audit ledgers
-- ============================================================================

-- Enforce append-only on legal_consent_events (No UPDATE permitted)
CREATE TRIGGER IF NOT EXISTS prevent_legal_consent_events_update
BEFORE UPDATE ON legal_consent_events
BEGIN
  SELECT RAISE(FAIL, 'UPDATE on legal_consent_events is strictly prohibited (immutable ledger)');
END;

-- Enforce append-only on legal_consent_events (No DELETE permitted)
CREATE TRIGGER IF NOT EXISTS prevent_legal_consent_events_delete
BEFORE DELETE ON legal_consent_events
BEGIN
  SELECT RAISE(FAIL, 'DELETE on legal_consent_events is strictly prohibited (immutable ledger)');
END;
