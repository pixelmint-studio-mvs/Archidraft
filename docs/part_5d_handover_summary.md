# Part 5D — Student Achievements / Milestones Implementation Handover

## 1. Student / Admin Workflow & Architecture
Students in Archi Draft are **Admin-handled only**. They do not answer to Engineers, Draughtsmen, or Clients. The learning and evaluation cycle strictly follows:
`Student -> Gets Lessons -> Completes Lessons -> Gets Assignments -> Completes Assignment -> Submits -> ADMIN Reviews -> ADMIN Tips/Feedback/Corrections -> Student Revises -> ADMIN Grades/Approves -> Student Progresses`.

Student Achievements are internal motivation and progression milestones derived from existing authoritative relational state in SQLite/D1. Unlike formal Credentials (Parts 5A–5C), Achievements have **no certificate PDFs**, **no Cloudflare R2 artifacts**, and **no public verification tokens**.

Achievements use a **purely derived architecture**:
- **No new D1 tables** (no `student_achievements`).
- **No new D1 migrations**.
- **No persistent achievement-award rows**.
- Deterministic evaluation from existing indexed tables (`student_lesson_progress`, `student_progress`, `projects`, `student_assignments`, `evaluations`, `student_credentials`).

---

## 2. Achievement Definitions & Eligibility Rules

| ID | Title | Category | Eligibility Rule | Authoritative Data Source | Unlock Timestamp |
|---|---|---|---|---|---|
| `first_lesson_completed` | **First Blueprint Step** | `LEARNING` | Completed at least 1 training lesson. | `student_lesson_progress WHERE status = 'COMPLETED'` | Earliest `completed_at` |
| `first_module_completed` | **Foundational Master** | `LEARNING` | Completed at least 1 full training module. | `student_progress WHERE status = 'Completed'` OR `student_credentials (MODULE_COMPLETION)` | Earliest `updated_at` / `issued_at` |
| `first_practical_project_completed` | **Studio Ready** | `PRACTICAL` | Completed at least 1 practical project assignment in student workflow. | `projects p JOIN student_assignments sa` (`is_training_project = 1 AND p.status = 'COMPLETED'`) | Earliest `p.approved_at` / `p.created_at` |
| `first_approved_drawing` | **First Approved Drawing** | `PRACTICAL` | Received at least 1 approved evaluation on submitted drawing work from ADMIN. | `evaluations e JOIN projects p JOIN student_assignments sa` (`e.overall_result = 'APPROVED'`) | Earliest `e.created_at` |
| `first_credential_earned` | **Certified Draughtsman** | `ACHIEVEMENT` | Earned at least 1 official credential. | `student_credentials WHERE student_id = ?` | Earliest `issued_at` |

---

## 3. API Contract
Endpoint added to Cloudflare Worker:
- **`GET /api/student/achievements`**
- **Authentication**: Firebase JWT Bearer token required (`verifyFirebaseToken`).
- **Authorization**: `user.role === 'STUDENT'` enforced.
- **Identity**: Derived strictly from verified token `uid` (client-supplied identity rejected).
- **Execution**: Batched D1 query (`db.batch([ ... ])`) executing all 5 parameterized aggregation queries in a single database roundtrip (< 10ms).
- **Response Format**:
```json
{
  "achievements": [
    {
      "id": "first_lesson_completed",
      "title": "First Blueprint Step",
      "description": "Completed your first training lesson",
      "category": "LEARNING",
      "icon": "school_outlined",
      "isUnlocked": true,
      "unlockedAt": "2026-10-06T15:30:00.000Z",
      "currentProgress": 1,
      "targetProgress": 1
    }
  ]
}
```

---

## 4. Flutter Implementation
- **Domain Model**: `StudentAchievement` in `lib/src/features/profile/domain/student_achievement.dart`.
- **Data Repository**: `AchievementsRepository` in `lib/src/features/profile/data/achievements_repository.dart`.
- **Riverpod Providers**: `achievementsRepositoryProvider` and `studentAchievementsProvider` in `lib/src/features/profile/providers/achievements_providers.dart`.
- **UI Widget**: `StudentAchievementsCard` in `lib/src/features/profile/presentation/widgets/student_achievements_card.dart`.
  - Follows Stitch tokens (`AppColors`, `AppTypography`, `AppSpacing`).
  - Displays progress badges, category tags, unlock count header (`X / Y`), and authoritative unlocked dates.
  - Implements defensive responsive layout that avoids rigid horizontal constraints and wraps cleanly on narrow Android viewports.
- **Screen Integration**: Added `StudentAchievementsCard` to `ProfileScreen` in `lib/src/features/profile/presentation/profile_screen.dart` alongside `StudentCredentialsCard`.

---

## 5. Security & Isolation
- The client cannot request or award an achievement; status is computed dynamically on the server.
- All SQL queries explicitly bind `uid` from the verified Firebase token.
- No cross-student data leakage or privilege escalation paths.

---

## 6. Changed Files
- `worker/src/achievements.ts` *(New)*
- `worker/src/index.ts` *(Modified — added GET route)*
- `lib/src/features/profile/domain/student_achievement.dart` *(New)*
- `lib/src/features/profile/data/achievements_repository.dart` *(New)*
- `lib/src/features/profile/providers/achievements_providers.dart` *(New)*
- `lib/src/features/profile/presentation/widgets/student_achievements_card.dart` *(New)*
- `lib/src/features/profile/presentation/profile_screen.dart` *(Modified — added widget)*
- `test/features/profile/domain/student_achievement_test.dart` *(New)*
- `test/features/profile/presentation/widgets/student_achievements_card_test.dart` *(New)*
- `docs/part_5d_handover_summary.md` *(New)*

---

## 7. Known Limitations
- Achievements are currently static milestones derived from the 5 initial core events. Additional milestones (e.g., category-specific masteries) can be defined in `worker/src/achievements.ts` without requiring schema migrations.
