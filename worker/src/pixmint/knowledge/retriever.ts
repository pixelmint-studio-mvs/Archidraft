/**
 * PIXMINT BOT 2.0 — Grounded Knowledge Retrieval Engine
 *
 * Implements:
 * 1. Role-aware security filtering BEFORE score computation (zero cross-role leakage)
 * 2. Administrative source deactivation enforcement
 * 3. Multi-signal relevance scoring (phrase, token, keyword, term frequency)
 * 4. Deduplicated ChatSource construction for verified citations
 */

import type { BotUserRole, ChatSource, KnowledgeChunk, RetrievalResult } from '../types';
import { EMBEDDED_KNOWLEDGE_CHUNKS } from './embedded_knowledge';

const SOURCE_ID_MAP: Record<string, string[]> = {
  'SRC-001': ['docs/01_project/CORE_WORKFLOW.md', 'CORE_WORKFLOW.md'],
  'SRC-002': ['docs/01_project/USER_ROLES.md', 'USER_ROLES.md'],
  'SRC-003': ['docs/02_architecture/DATA_ARCHITECTURE.md', 'DATA_ARCHITECTURE.md'],
  'SRC-004': ['docs/03_legal/PRIVACY_POLICY_DRAFT.md', 'PRIVACY_POLICY_DRAFT.md'],
  'SRC-005': ['docs/04_support/FAQ_CONTENT.md', 'FAQ_CONTENT.md'],
  'SRC-006': ['RBAC_SECURITY_REMEDIATION_REPORT.md'],
  'SRC-007': ['docs/02_architecture/PIXMINT_BOT_BACKEND_CONTRACT.md', 'PIXMINT_BOT_BACKEND_CONTRACT.md'],
  'SRC-008': ['knowledge/governance/official-identity.md', 'governance/official-identity.md', 'official-identity.md'],
};

function normalizeDeactivatedSources(sources?: string[] | Set<string>): Set<string> | null {
  if (!sources) return null;
  const rawList = sources instanceof Set ? Array.from(sources) : Array.isArray(sources) ? sources : [];
  if (rawList.length === 0) return null;

  const normalized = new Set<string>();
  for (const item of rawList) {
    if (!item || typeof item !== 'string') continue;
    const trimmed = item.trim();
    normalized.add(trimmed);
    normalized.add(trimmed.toLowerCase());

    const mapped = SOURCE_ID_MAP[trimmed] || SOURCE_ID_MAP[trimmed.toUpperCase()];
    if (mapped) {
      for (const m of mapped) {
        normalized.add(m);
        normalized.add(m.toLowerCase());
      }
    }

    const filename = trimmed.split('/').pop();
    if (filename) {
      normalized.add(filename);
      normalized.add(filename.toLowerCase());
    }
  }

  return normalized;
}

/**
 * Searches and retrieves authorized knowledge chunks relevant to the user query.
 * Role-aware security filtering happens BEFORE score computation.
 */
export function retrieveKnowledge(
  query: string,
  role: BotUserRole,
  maxChunks: number = 3,
  deactivatedSources?: string[] | Set<string>,
  extraChunks: KnowledgeChunk[] = []
): RetrievalResult {
  const normalizedQuery = query.toLowerCase().trim();
  const queryTokens = normalizedQuery
    .replace(/[^\w\s]/g, ' ')
    .split(/\s+/)
    .filter((t) => t.length > 2);

  const deactivatedSet = normalizeDeactivatedSources(deactivatedSources);
  const allAvailableChunks = [...EMBEDDED_KNOWLEDGE_CHUNKS, ...extraChunks];

  // 1. Role-based isolation filter & deactivation filter
  const accessibleChunks = allAvailableChunks.filter((chunk) => {
    if (!chunk.allowedRoles.includes(role)) return false;
    if (deactivatedSet) {
      const chunkPathLower = chunk.path.toLowerCase();
      const chunkDocIdLower = chunk.docId.toLowerCase();
      const chunkIdLower = chunk.id.toLowerCase();
      const chunkFilename = chunk.path.split('/').pop()?.toLowerCase() || '';

      if (
        deactivatedSet.has(chunk.id) ||
        deactivatedSet.has(chunk.docId) ||
        deactivatedSet.has(chunk.path) ||
        deactivatedSet.has(chunkIdLower) ||
        deactivatedSet.has(chunkDocIdLower) ||
        deactivatedSet.has(chunkPathLower) ||
        deactivatedSet.has(chunkFilename)
      ) {
        return false;
      }

      for (const item of deactivatedSet) {
        if (
          chunkPathLower.endsWith(item) ||
          chunkDocIdLower.endsWith(item) ||
          (item.length > 5 && chunkPathLower.includes(item))
        ) {
          return false;
        }
      }
    }
    return true;
  });

  if (queryTokens.length === 0 || accessibleChunks.length === 0) {
    return { chunks: [], sources: [], relevanceScores: [] };
  }

  // 2. Score chunks using multi-signal relevance
  const scoredChunks: Array<{ chunk: KnowledgeChunk; score: number }> = [];

  for (const chunk of accessibleChunks) {
    let score = 0;
    const titleLower = chunk.title.toLowerCase();
    const sectionLower = chunk.sectionTitle.toLowerCase();
    const contentLower = chunk.content.toLowerCase();

    // Exact phrase match in content or title
    if (contentLower.includes(normalizedQuery)) score += 8.0;
    if (titleLower.includes(normalizedQuery)) score += 10.0;
    if (sectionLower.includes(normalizedQuery)) score += 7.0;

    // Token matches
    for (const token of queryTokens) {
      if (titleLower.includes(token)) score += 3.5;
      if (sectionLower.includes(token)) score += 2.5;
      if (chunk.keywords.some((k) => k.toLowerCase().includes(token))) score += 3.0;

      // Count term occurrences in content (capped at 5)
      let occurrences = 0;
      let pos = 0;
      while ((pos = contentLower.indexOf(token, pos)) !== -1) {
        occurrences++;
        pos += token.length;
        if (occurrences >= 5) break;
      }
      score += occurrences * 0.8;
    }

    if (score > 1.5) {
      scoredChunks.push({ chunk, score });
    }
  }

  // 3. Sort by relevance descending
  scoredChunks.sort((a, b) => b.score - a.score);

  const topChunks = scoredChunks.slice(0, maxChunks);
  const selectedChunks = topChunks.map((tc) => tc.chunk);
  const relevanceScores = topChunks.map((tc) => tc.score);

  // 4. Construct deduplicated ChatSources
  const seenPaths = new Set<string>();
  const sources: ChatSource[] = [];

  for (const chunk of selectedChunks) {
    if (!seenPaths.has(chunk.path)) {
      seenPaths.add(chunk.path);
      sources.push({
        title: chunk.title,
        path: chunk.path,
        section: chunk.sectionTitle,
        category: chunk.category,
      });
    }
  }

  return {
    chunks: selectedChunks,
    sources,
    relevanceScores,
  };
}

