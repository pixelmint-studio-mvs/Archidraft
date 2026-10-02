# 1. EXISTING LEARNING DATA

Relevant tables:
- `training_modules`: Defines `category` ('Architectural', 'Structural', 'Interior', 'Approval') and `level`.
- `training_lessons`: Contains individual lesson definitions and `lesson_order`.
- `student_progress`: Tracks high-level module status ('Not Started', 'In Progress', 'Completed') and `score`.
- `student_lesson_progress`: Tracks individual lesson completions.

Relevant APIs and Providers:
- `GET /api/training/modules` -> `studentModulesProvider`
- `GET /api/training/modules/:moduleId/lessons` -> `trainingModuleLessonsProvider`

# 2. EXISTING PRACTICAL DATA

Relevant tables:
- `student_assignments`: Links a `student_id` to a `project_id` and tracks assignment status ('PENDING', 'IN_PROGRESS', 'COMPLETED').
- `projects`: Contains `drawing_type` (which aligns with training categories) and `correction_round` counter.
- `drawing_versions`: Tracks iterations of submitted work.
- `corrections`: Tracks specific feedback requests and their resolution status ('OPEN', 'IN_PROGRESS', 'RESOLVED').

Relevant APIs and Providers:
- `GET /api/student/assigned-projects` -> `studentAssignedProjectsProvider`
- `GET /api/projects/:projectId/versions` -> `projectDrawingVersionsProvider`

# 3. EXISTING EVALUATION DATA

The Part 3 implementation introduced the `evaluations` table:
- **`overall_result`**: Strict enum (`APPROVED`, `NEEDS_CORRECTION`).
- **`general_feedback`**: Free-form text.
- **`criteria_json`**: A flexible JSON object. Currently, the `EvaluationDialog` saves `Accuracy` and `Technical Standards` as free-form string inputs (e.g., "4/5, Excellent, Needs work..."). 

Currently, evaluations **do not** enforce a strict numeric scale. They are primarily qualitative.

# 4. EXISTING SKILL/CATEGORY TAXONOMY

**Authoritative Categories (Currently Defined):**
The system currently relies on 4 core domains, heavily used in both `training_modules.category` and `projects.drawing_type`:
1. Architectural
2. Structural
3. Interior
4. Approval

**Possible Future Categories (Based on Evaluation UI):**
- Drawing Accuracy
- Technical Standards
- Presentation / Layout

There is currently no formal, normalized lookup table or taxonomy for "Skills".

# 5. POSSIBLE SKILL METRICS

| Skill/Metric | Data Source | Calculation | Data Available? | Confidence |
|---|---|---|---|---|
| **Learning Progress (by Category)** | `training_lessons`, `student_lesson_progress` | (Completed lessons) / (Total lessons in category) | Yes | High |
| **Practical Experience (by Category)** | `student_assignments`, `projects` | Count of COMPLETED assignments per `drawing_type` | Yes | High |
| **First-Time Approval Rate** | `evaluations` | % of evaluations resulting in `APPROVED` on version 1 | Yes | Medium |
| **Correction Density** | `corrections` | Avg corrections needed per project | Yes | High |
| **Drawing Accuracy** | `evaluations.criteria_json` | Average of the "Accuracy" numeric score | **No** (Currently free-form text) | Low |
| **Technical Standards** | `evaluations.criteria_json` | Average of "Technical Standards" numeric score | **No** (Currently free-form text) | Low |

# 6. LEARNING VS PERFORMANCE

These concepts must be strictly separated in the UI:
- **Learning Progress:** Percentage of video/reading content consumed. Represents effort and theoretical exposure.
- **Practical Performance:** Derived from the quality of deliverables (First-Time Approval, Correction Density, Numeric Evaluation Scores). Represents proficiency.
- **Project Activity:** Count of completed projects or submitted drafts. Represents volume/experience, but not strictly quality.

# 7. SCORING MODEL

**Calculations Supported by Existing Data:**
- Learning Progress % per category.
- Practical Volume (projects completed) per category.
- Quality proxy: Correction rounds per project (lower is better).

**Product Decision Required:**
To calculate actual "Skill Proficiencies" (e.g., Drawing Accuracy = 80%), we must update `EvaluationDialog` to enforce strict numeric inputs (e.g., 1-5 stars or a 0-100 slider) for predefined criteria, rather than free-form text fields.

# 8. DATABASE REQUIREMENT

**Is a new table required? NO.**
The Skill Matrix can be fully derived (Option A) by aggregating existing data from `student_lesson_progress`, `student_assignments`, and `evaluations`. 

If performance becomes a concern due to complex aggregations, a materialized view or periodic snapshot table (`student_skills_summary`) could be introduced later, but it is not necessary for the MVP.

# 9. API REQUIREMENT

**Is a new endpoint required? YES.**
The calculations should happen server-side to prevent sending the entire history of a student's lessons, assignments, and evaluations to the Flutter client. 

**Proposed Endpoint:** `GET /api/student/metrics`
```json
{
  "learning_progress": {
    "Architectural": 85,
    "Structural": 40
  },
  "practical_experience": {
    "completed_projects": { "Architectural": 3, "Approval": 1 },
    "avg_corrections_per_project": 1.5,
    "first_time_approval_rate": 0.4
  },
  "evaluated_skills": {
    "Accuracy": 80, 
    "Technical Standards": 75 
  }
}
```

# 10. UI / INFORMATION ARCHITECTURE

**Recommendation:** Place the Skill Matrix on the **Student Studio** tab. 
**Why:** The Studio tab currently acts as the student's main dashboard and landing page. Providing a high-level summary of their growth here contextualizes their ongoing tasks (which are also listed in the Studio). Alternatively, it could exist under the Profile/Settings screen, but it is too valuable to hide. It does not warrant its own top-level navigation item yet.

# 11. STUDENT EXPERIENCE

The student will see a dual-dashboard widget:
1. **"Knowledge Acquisition"**: Progress bars for categories (Architectural, Structural, etc.) based purely on lesson completion.
2. **"Practical Proficiency"**: Displaying completed projects and average evaluation scores.

**Insufficient Data State:**
If no evaluations have been completed, the "Practical Proficiency" section should display:
*"Complete your first practical assignment and receive an evaluation to unlock performance metrics."* It must not default to 0% or 100%.

# 12. SECURITY

- **Authentication:** Endpoint must extract `studentId` directly from the validated Firebase JWT token inside the Cloudflare Worker. Do not accept `studentId` as a URL parameter or request body payload.
- **Data Isolation:** When aggregating `evaluations`, the SQL query must properly join: `evaluations` -> `projects` -> `student_assignments` ensuring `student_assignments.student_id = ?` (the authenticated user). Evaluations table alone does not store `student_id`, so the join is critical to prevent cross-student data leakage.

# 13. RISKS

- **Fake/Unsupported Scores:** Attempting to parse text inputs like "4/5" or "Excellent" from `criteria_json` into numbers will fail or produce inaccurate data.
- **Mixing Learning Progress with Proficiency:** Confusing 100% video completion with 100% practical skill.
- **Cross-student data leakage:** Forgetting to join `student_assignments` when querying `evaluations`.
- **Changing criteria over time:** If we change the name of the JSON keys in evaluations later, historical data might not match new aggregations.

# 14. RECOMMENDED PART 4 DESIGN

1. **Backend Refine:** Modify `GET /api/projects/evaluate` (Admin side) to accept numeric ratings for specific criteria alongside text.
2. **Backend API:** Create `GET /api/student/metrics` in the Cloudflare Worker to perform the authorized SQL aggregations.
3. **Frontend Domain:** Create `StudentMetrics` domain model and Repository methods.
4. **Frontend UI (Admin):** Update `EvaluationDialog` to use sliders/dropdowns (1-5 scale) for "Accuracy" and "Technical Standards".
5. **Frontend UI (Student):** Add a `SkillMatrixDashboard` widget to `StudentStudioScreen` that displays the fetched metrics, clearly separating "Learning" from "Practical" and handling empty states gracefully.

# 15. FILES THAT WOULD EVENTUALLY CHANGE

- `worker/src/index.ts`
- `lib/src/features/projects/presentation/widgets/evaluation_dialog.dart`
- `lib/src/features/training/domain/student_metrics.dart` (New File)
- `lib/src/features/training/data/training_repository.dart`
- `lib/src/features/training/providers/training_providers.dart`
- `lib/src/features/training/presentation/student_studio_screen.dart`
