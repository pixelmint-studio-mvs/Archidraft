import 'bot_user_role.dart';
import 'chat_suggestion.dart';

/// Authoritative predefined question catalog for all supported Archi Draft portals.
///
/// Provides instant, reliable local defaults for:
/// - Engineer Portal (8 verified questions)
/// - Draughtsman Portal (8 verified questions)
/// - Student Portal (8 verified questions)
/// - Admin Portal (7 verified questions — server-authorized only)
/// - Guest / Fallback (3 introductory questions)
class PixmintDefaultSuggestions {
  const PixmintDefaultSuggestions._();

  // ── Engineer Portal Suggestions (8) ──────────────────────────────────────
  static const List<ChatSuggestion> engineer = [
    ChatSuggestion(
      id: 'eng_rev_drawing',
      label: 'How do I review a drawing?',
      prompt: 'How do I review a drawing?',
      role: BotUserRole.engineer,
      iconName: 'rate_review',
    ),
    ChatSuggestion(
      id: 'eng_redline_anno',
      label: 'How do I add redline annotations?',
      prompt: 'How do I add redline annotations?',
      role: BotUserRole.engineer,
      iconName: 'edit_note',
    ),
    ChatSuggestion(
      id: 'eng_tech_review',
      label: 'What should I check during technical review?',
      prompt: 'What should I check during technical review?',
      role: BotUserRole.engineer,
      iconName: 'fact_check',
    ),
    ChatSuggestion(
      id: 'eng_drawing_issues',
      label: 'How do I identify drawing issues?',
      prompt: 'How do I identify drawing issues?',
      role: BotUserRole.engineer,
      iconName: 'search',
    ),
    ChatSuggestion(
      id: 'eng_coord_revisions',
      label: 'How can I coordinate drawing revisions?',
      prompt: 'How can I coordinate drawing revisions?',
      role: BotUserRole.engineer,
      iconName: 'sync_alt',
    ),
    ChatSuggestion(
      id: 'eng_drawing_fail_load',
      label: 'What should I do if a drawing fails to load?',
      prompt: 'What should I do if a drawing fails to load?',
      role: BotUserRole.engineer,
      iconName: 'broken_image',
    ),
    ChatSuggestion(
      id: 'eng_resolve_review_prob',
      label: 'How do I resolve a review problem?',
      prompt: 'How do I resolve a review problem?',
      role: BotUserRole.engineer,
      iconName: 'build',
    ),
    ChatSuggestion(
      id: 'eng_bot_capabilities',
      label: 'What can PIXMINT BOT help me with?',
      prompt: 'What can PIXMINT BOT help me with?',
      role: BotUserRole.engineer,
      iconName: 'help_outline',
    ),
  ];

  // ── Draughtsman Portal Suggestions (8) ────────────────────────────────────
  static const List<ChatSuggestion> draughtsman = [
    ChatSuggestion(
      id: 'dft_view_assignments',
      label: 'How do I view my assignments?',
      prompt: 'How do I view my assignments?',
      role: BotUserRole.draughtsman,
      iconName: 'assignment',
    ),
    ChatSuggestion(
      id: 'dft_accept_assignment',
      label: 'How do I accept an assignment?',
      prompt: 'How do I accept an assignment?',
      role: BotUserRole.draughtsman,
      iconName: 'check_circle',
    ),
    ChatSuggestion(
      id: 'dft_upload_drawing',
      label: 'How do I upload a drawing?',
      prompt: 'How do I upload a drawing?',
      role: BotUserRole.draughtsman,
      iconName: 'upload_file',
    ),
    ChatSuggestion(
      id: 'dft_drawing_formats',
      label: 'Which drawing formats are supported?',
      prompt: 'Which drawing formats are supported?',
      role: BotUserRole.draughtsman,
      iconName: 'layers',
    ),
    ChatSuggestion(
      id: 'dft_submit_revision',
      label: 'How do I submit a revised drawing?',
      prompt: 'How do I submit a revised drawing?',
      role: BotUserRole.draughtsman,
      iconName: 'publish',
    ),
    ChatSuggestion(
      id: 'dft_resolve_redlines',
      label: 'How do I resolve redline comments?',
      prompt: 'How do I resolve redline comments?',
      role: BotUserRole.draughtsman,
      iconName: 'rule',
    ),
    ChatSuggestion(
      id: 'dft_upload_fails',
      label: 'What should I do if an upload fails?',
      prompt: 'What should I do if an upload fails?',
      role: BotUserRole.draughtsman,
      iconName: 'warning',
    ),
    ChatSuggestion(
      id: 'dft_submission_status',
      label: 'How do I check my submission status?',
      prompt: 'How do I check my submission status?',
      role: BotUserRole.draughtsman,
      iconName: 'timeline',
    ),
  ];

  // ── Student Portal Suggestions (8) ────────────────────────────────────────
  static const List<ChatSuggestion> student = [
    ChatSuggestion(
      id: 'stu_access_modules',
      label: 'How do I access my training modules?',
      prompt: 'How do I access my training modules?',
      role: BotUserRole.student,
      iconName: 'school',
    ),
    ChatSuggestion(
      id: 'stu_practical_exercises',
      label: 'Where can I find my practical exercises?',
      prompt: 'Where can I find my practical exercises?',
      role: BotUserRole.student,
      iconName: 'menu_book',
    ),
    ChatSuggestion(
      id: 'stu_submit_exercise',
      label: 'How do I submit an exercise?',
      prompt: 'How do I submit an exercise?',
      role: BotUserRole.student,
      iconName: 'send',
    ),
    ChatSuggestion(
      id: 'stu_view_evaluation',
      label: 'Where can I view my evaluation?',
      prompt: 'Where can I view my evaluation?',
      role: BotUserRole.student,
      iconName: 'grading',
    ),
    ChatSuggestion(
      id: 'stu_mentor_feedback',
      label: 'How do I understand mentor feedback?',
      prompt: 'How do I understand mentor feedback?',
      role: BotUserRole.student,
      iconName: 'comment',
    ),
    ChatSuggestion(
      id: 'stu_verify_cert',
      label: 'How can I verify my certificate?',
      prompt: 'How can I verify my certificate?',
      role: BotUserRole.student,
      iconName: 'verified',
    ),
    ChatSuggestion(
      id: 'stu_lesson_not_open',
      label: 'What should I do if a lesson will not open?',
      prompt: 'What should I do if a lesson will not open?',
      role: BotUserRole.student,
      iconName: 'report_problem',
    ),
    ChatSuggestion(
      id: 'stu_bot_learn',
      label: 'What can PIXMINT BOT help me learn?',
      prompt: 'What can PIXMINT BOT help me learn?',
      role: BotUserRole.student,
      iconName: 'auto_stories',
    ),
  ];

  // ── Admin Portal Suggestions (7 — authorized session only) ────────────────
  static const List<ChatSuggestion> admin = [
    ChatSuggestion(
      id: 'adm_knowledge_sources',
      label: 'How do I manage approved knowledge sources?',
      prompt: 'How do I manage approved knowledge sources?',
      role: BotUserRole.admin,
      iconName: 'source',
    ),
    ChatSuggestion(
      id: 'adm_update_questions',
      label: 'How do I update suggested questions?',
      prompt: 'How do I update suggested questions?',
      role: BotUserRole.admin,
      iconName: 'quiz',
    ),
    ChatSuggestion(
      id: 'adm_service_status',
      label: 'How do I check bot service status?',
      prompt: 'How do I check bot service status?',
      role: BotUserRole.admin,
      iconName: 'monitor_heart',
    ),
    ChatSuggestion(
      id: 'adm_unanswered_qs',
      label: 'How do I review unanswered questions?',
      prompt: 'How do I review unanswered questions?',
      role: BotUserRole.admin,
      iconName: 'mark_chat_unread',
    ),
    ChatSuggestion(
      id: 'adm_usage_metrics',
      label: 'How can I review usage and error metrics?',
      prompt: 'How can I review usage and error metrics?',
      role: BotUserRole.admin,
      iconName: 'query_stats',
    ),
    ChatSuggestion(
      id: 'adm_bot_availability',
      label: 'How do I manage bot availability?',
      prompt: 'How do I manage bot availability?',
      role: BotUserRole.admin,
      iconName: 'toggle_on',
    ),
    ChatSuggestion(
      id: 'adm_config_changes',
      label: 'How can I review configuration changes?',
      prompt: 'How can I review configuration changes?',
      role: BotUserRole.admin,
      iconName: 'history',
    ),
  ];

  // ── Guest / Fallback Suggestions (3) ──────────────────────────────────────
  static const List<ChatSuggestion> guest = [
    ChatSuggestion(
      id: 'gst_how_works',
      label: 'How does Archi Draft work?',
      prompt: 'How does the Archi Draft architectural workflow work?',
      role: BotUserRole.guest,
      iconName: 'explore',
    ),
    ChatSuggestion(
      id: 'gst_start_project',
      label: 'How do I start a new project?',
      prompt: 'How do I start a new project in Archi Draft?',
      role: BotUserRole.guest,
      iconName: 'add_circle',
    ),
    ChatSuggestion(
      id: 'gst_bot_help',
      label: 'What can PIXMINT BOT help me with?',
      prompt: 'What can PIXMINT BOT help me with?',
      role: BotUserRole.guest,
      iconName: 'help_outline',
    ),
  ];

  /// Returns the authoritative question suggestions for the specified role.
  ///
  /// For non-admin roles, admin suggestions are never returned.
  static List<ChatSuggestion> getForRole(BotUserRole role) {
    switch (role) {
      case BotUserRole.engineer:
        return engineer;
      case BotUserRole.draughtsman:
        return draughtsman;
      case BotUserRole.student:
        return student;
      case BotUserRole.admin:
        return admin;
      case BotUserRole.guest:
        return guest;
    }
  }
}
