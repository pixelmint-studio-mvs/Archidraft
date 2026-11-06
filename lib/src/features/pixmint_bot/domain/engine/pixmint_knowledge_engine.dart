import '../models/bot_user_role.dart';
import '../models/chat_message.dart';

/// Resolved answer containing generated text and genuine supporting citations.
class PixmintEngineAnswer {
  final String content;
  final List<ChatSource> sources;
  final Map<String, dynamic>? metadata;

  const PixmintEngineAnswer({
    required this.content,
    this.sources = const [],
    this.metadata,
  });
}

/// PIXMINT BOT Local Knowledge & Intent Resolution Engine.
///
/// Delivers natural, role-aware, verified architectural and platform guidance
/// grounded directly in authoritative Archi Draft documentation:
/// - docs/01_project/CORE_WORKFLOW.md
/// - docs/01_project/USER_ROLES.md
/// - docs/02_architecture/DATA_ARCHITECTURE.md
/// - docs/08_legal_privacy/PRIVACY_POLICY_DRAFT.md
/// - docs/08_legal_privacy/TERMS_AND_CONDITIONS_DRAFT.md
/// - docs/08_legal_privacy/FAQ_CONTENT.md
///
/// NOTE: This engine provides local grounded responses when no remote LLM
/// provider is configured. Pluggable remote AI adapters execute server-side in
/// the Cloudflare Worker with server-managed secrets and verified identity.
class PixmintKnowledgeEngine {
  // ── Genuine Verified Citations ──────────────────────────────────────────
  static const sourceCoreWorkflow = ChatSource(
    title: 'Archi Draft Core Project Workflow',
    docRef: 'docs/01_project/CORE_WORKFLOW.md',
    snippet:
        'Authoritative lifecycle from project creation through client redlines and final approval.',
  );

  static const sourceUserRoles = ChatSource(
    title: 'Archi Draft User Roles & Permissions Matrix',
    docRef: 'docs/01_project/USER_ROLES.md',
    snippet:
        'Authoritative permissions and responsibilities for Clients, Draughtsmen, Students, Engineers, and Admins.',
  );

  static const sourceDataArch = ChatSource(
    title: 'Archi Draft Data & Project Architecture',
    docRef: 'docs/02_architecture/DATA_ARCHITECTURE.md',
    snippet:
        'Technical specifications for project records, drawing revisions, assignments, and file limits.',
  );

  static const sourceLegalPrivacy = ChatSource(
    title: 'Archi Draft Legal Terms & Privacy Policy',
    docRef: 'docs/08_legal_privacy/PRIVACY_POLICY_DRAFT.md',
    snippet:
        'Platform data protection, ownership of submitted drawings, and security commitments.',
  );

  static const sourceFaq = ChatSource(
    title: 'Archi Draft Platform FAQ & Help Center',
    docRef: 'docs/08_legal_privacy/FAQ_CONTENT.md',
    snippet:
        'Frequently asked questions on supported CAD formats, review cycles, and student certifications.',
  );

  static const sourceOfficialIdentity = ChatSource(
    title: 'PIXMINT BOT Official Identity & Governance Knowledge Pack',
    docRef: 'ARCHI-DRAFT-KNOWLEDGE-BASE/knowledge/governance/official-identity.md',
    snippet:
        'Approved source of truth for PIXMINT BOT identity, brand ownership (PixelMint Studio MVS), purpose, capabilities, security boundaries, and model truthfulness.',
  );

  /// Resolves user input into a natural, role-appropriate, grounded response.
  static PixmintEngineAnswer resolve({
    required String prompt,
    required BotUserRole role,
    List<ChatMessage> conversationHistory = const [],
    String? userName,
  }) {
    final rawTrimmed = prompt.trim();
    if (rawTrimmed.isEmpty) {
      return const PixmintEngineAnswer(
        content: 'Please enter a question or topic so I can assist you with Archi Draft.',
      );
    }

    final normalized = _normalizeText(rawTrimmed);

    // 1. Security Guardrails: Privileged Action Refusal & Injection Protection
    final securityDenial = _checkSecurityGuardrails(normalized);
    if (securityDenial != null) {
      return securityDenial;
    }

    // 2. Greetings & Conversational Introductions
    if (_isGreeting(normalized, rawTrimmed)) {
      return _handleGreeting(role, userName);
    }

    // 3. Official Identity Knowledge Pack (IDN-001 through IDN-011)
    final identityAnswer = _resolveOfficialIdentity(normalized);
    if (identityAnswer != null) {
      return identityAnswer;
    }

    // 4. "It isn't working" & General Troubleshooting Requests
    if (_isTroubleshootingRequest(normalized)) {
      return _handleTroubleshooting(normalized);
    }

    // 5. Context-Aware Follow-Up Handling
    if (_isFollowUpQuery(normalized) && conversationHistory.isNotEmpty) {
      final followUpAnswer = _handleFollowUp(normalized, conversationHistory, role);
      if (followUpAnswer != null) return followUpAnswer;
    }

    // 6. Cross-Role Boundary & Permission Checks
    final boundaryAnswer = _checkRoleBoundaries(normalized, role);
    if (boundaryAnswer != null) {
      return boundaryAnswer;
    }

    // 6b. Portal-Specific Preloaded Questions & Verified Workflows
    final preloadedAnswer = _resolvePortalPreloadedQuestions(normalized, role);
    if (preloadedAnswer != null) {
      return preloadedAnswer;
    }

    // 6c. General CAD & Architecture Intelligence (DWG vs DXF, BIM, Scale, Layer Standards)
    final generalConceptAnswer = _handleGeneralCadConcepts(normalized, role);
    if (generalConceptAnswer != null) {
      return generalConceptAnswer;
    }

    // 6d. Live Application Context Guidance (safe, read-only status routing for Engineer, Draughtsman, Student)
    final liveAppContextAnswer = _handleLiveAppContext(normalized, role);
    if (liveAppContextAnswer != null) {
      return liveAppContextAnswer;
    }

    // 7. Role Responsibilities Queries
    if (_isRoleInquiry(normalized)) {
      return _handleRoleInquiry(normalized, role);
    }

    // 8. Project Creation & Initiation Workflow
    if (_isProjectCreationQuery(normalized)) {
      return _handleProjectCreation(role);
    }

    // 9. Project Tracking, Milestones & Statuses
    if (_isProjectTrackingQuery(normalized)) {
      return _handleProjectTracking(role);
    }

    // 10. Drawing Uploads, Formats (.dwg, .dxf, .pdf) & Layer Standards
    if (_isDrawingOrCadQuery(normalized)) {
      return _handleDrawingAndCad(role);
    }

    // 11. Review Cycles, Redlines & Correction Requests
    if (_isReviewOrCorrectionQuery(normalized)) {
      return _handleReviewAndCorrections(role);
    }

    // 12. Final Approval & Sign-Off Workflow
    if (_isApprovalQuery(normalized)) {
      return _handleApproval(role);
    }

    // 13. Student Curriculum, Assignments & Certification
    if (_isStudentLearningQuery(normalized)) {
      return _handleStudentLearning(role);
    }

    // 14. Admin Dispatch, Financials & Invoicing
    if (_isAdminOperationQuery(normalized)) {
      return _handleAdminOperation(role);
    }

    // 15. Terms, Privacy & Security Questions
    if (_isLegalPrivacyQuery(normalized)) {
      return _handleLegalPrivacy();
    }

    // 15b. Role-Filtered Dynamic Knowledge Retrieval (Semantic search across all verified documents)
    final dynamicRetrievedAnswer = _searchEmbeddedKnowledge(normalized, role);
    if (dynamicRetrievedAnswer != null) {
      return dynamicRetrievedAnswer;
    }

    // 16. Fallback: Honest Unverified Answer
    return const PixmintEngineAnswer(
      content:
          "I don't have verified documentation about that in Archi Draft. I specialize in Archi Draft project workflows, CAD drawing formats, role responsibilities, reviews, and student training.\n\n"
          "If you have a question about projects, drawings, or account permissions, feel free to ask! You can also contact our support team at `pixelmintstudiomvs@gmail.com`.",
      sources: [],
      metadata: {'category': 'FALLBACK'},
    );
  }

  // ── Text Normalization & Fuzzy Stemming ─────────────────────────────────

  static String _normalizeText(String input) {
    var text = input.toLowerCase();

    // Replace common punctuation with spaces or remove
    text = text.replaceAll(RegExp(r'[\.,!?;\:\(\)\[\]"\u201C\u201D\u2018\u2019]'), ' ');

    // Normalize common contractions
    text = text.replaceAll("it's", "it is");
    text = text.replaceAll("isn't", "is not");
    text = text.replaceAll("doesn't", "does not");
    text = text.replaceAll("don't", "do not");
    text = text.replaceAll("can't", "cannot");
    text = text.replaceAll("what's", "what is");
    text = text.replaceAll("how's", "how is");
    text = text.replaceAll("i'm", "i am");

    // Normalize common spelling mistakes
    text = text.replaceAll(RegExp(r'\b(enginerr|enginer|engnr|engeneer)\b'), 'engineer');
    text = text.replaceAll(RegExp(r'\b(draughtsmen|draftsman|draftsmen|drauftman|drafter)\b'), 'draughtsman');
    text = text.replaceAll(RegExp(r'\b(studnt|studet|trainie|intern)\b'), 'student');
    text = text.replaceAll(RegExp(r'\b(proejct|projct|poject|progect)\b'), 'project');
    text = text.replaceAll(RegExp(r'\b(drawin|drawng|drwing|drwg)\b'), 'drawing');
    text = text.replaceAll(RegExp(r'\b(aprove|aprov|apprv|aproval)\b'), 'approve');
    text = text.replaceAll(RegExp(r'\b(revisn|revison|corection|correcn|redline)\b'), 'revision');
    text = text.replaceAll(RegExp(r'\b(asignment|asignmnt|assigmt)\b'), 'assignment');
    text = text.replaceAll(RegExp(r'\b(certifcate|certficate|credetial)\b'), 'certificate');
    text = text.replaceAll(RegExp(r'\b(troublshoot|problm|issu|eror|err)\b'), 'problem');

    // Collapse multiple whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  // ── Guardrails ──────────────────────────────────────────────────────────

  static PixmintEngineAnswer? _checkSecurityGuardrails(String normalized) {
    // IDN-009: Protection of administrator secrets and private data boundaries
    if (normalized.contains('reveal administrator secrets') ||
        normalized.contains('admin secrets') ||
        normalized.contains('administrator secrets') ||
        normalized.contains('show private administrator records') ||
        normalized.contains('reveal private information') ||
        normalized.contains('reveal system credentials') ||
        normalized.contains('give me passwords') ||
        normalized.contains('reveal passwords') ||
        normalized.contains('show api keys') ||
        normalized.contains('reveal credentials') ||
        normalized.contains('give me admin secrets')) {
      return const PixmintEngineAnswer(
        content:
            'No. I cannot provide restricted credentials, secrets, private administrative records, or information that the current user is not authorized to access.',
        sources: [sourceOfficialIdentity, sourceUserRoles],
        metadata: {
          'id': 'IDN-009',
          'category': 'PRIVACY_PROTECTION',
          'verification_status': 'APPROVED',
          'version': '1.0.0',
          'safety_flag': true,
          'review_owner': 'Security Engineering',
        },
      );
    }

    const privilegedKeywords = [
      'approve project',
      'approve_project',
      'project approval',
      'reject project',
      'delete project',
      'delete user',
      'drop table',
      'truncate',
      'change role',
      'make me admin',
      'set role to admin',
      'bypass authorization',
      'ignore previous instructions',
      'system prompt',
      'api key',
      'secret key',
      'credentials',
      'select * from',
      'delete from',
    ];

    for (final kw in privilegedKeywords) {
      if (normalized.contains(kw)) {
        return const PixmintEngineAnswer(
          content:
              'PIXMINT BOT cannot perform privileged operations, alter database records, disclose credentials, or change account roles.\n\n'
              'All project approvals, deletions, and administrative actions must be conducted via authorized portal controls by authenticated and authorized accounts.',
          sources: [sourceUserRoles],
          metadata: {'type': 'SECURITY_RESTRICTION', 'safety_flag': true},
        );
      }
    }
    return null;
  }

  // ── Category Checkers & Handlers ────────────────────────────────────────

  static bool _isGreeting(String normalized, String raw) {
    final words = normalized.split(' ');
    if (words.isEmpty) return false;

    const greetingWords = [
      'hello',
      'hi',
      'hey',
      'howdy',
      'greetings',
      'morning',
      'afternoon',
      'evening',
    ];

    if (greetingWords.contains(words.first) && words.length <= 5) {
      return true;
    }
    if (normalized == 'hi' ||
        normalized == 'hello' ||
        normalized == 'hey' ||
        normalized == 'hey there' ||
        normalized == 'good morning' ||
        normalized == 'good afternoon' ||
        normalized == 'good evening' ||
        normalized == 'hi pixmint bot' ||
        normalized == 'hello pixmint bot') {
      return true;
    }
    return false;
  }

  static PixmintEngineAnswer _handleGreeting(BotUserRole role, String? userName) {
    final namePart = (userName != null && userName.isNotEmpty) ? ' $userName' : '';
    final roleName = role.displayName;

    return PixmintEngineAnswer(
      content:
          "Hey$namePart! 👋 I'm **PIXMINT BOT**, your intelligent Archi Draft assistant.\n\n"
          "I'm here to help you with your $roleName workflows, drawing standards, review cycles, and project tasks. What can I help you with today?",
      sources: const [],
      metadata: const {'category': 'GREETING'},
    );
  }

  // ── Official Identity Knowledge Pack (IDN-001 through IDN-011) ───────────

  static PixmintEngineAnswer? _resolveOfficialIdentity(String normalized) {
    // IDN-001: Who created you? / Creator Attribution
    if (normalized.contains('who created you') ||
        normalized.contains('who made you') ||
        normalized.contains('who built you') ||
        normalized.contains('who is your creator') ||
        normalized.contains('who designed pixmint bot') ||
        normalized.contains('creator of pixmint bot') ||
        normalized.contains('who created pixmint bot') ||
        normalized == 'who created you' ||
        normalized == 'who made you' ||
        normalized == 'who is your creator') {
      return const PixmintEngineAnswer(
        content:
            'I am PIXMINT BOT, an AI assistant developed under PixelMint Studio MVS for the Archi Draft application.',
        sources: [sourceOfficialIdentity],
        metadata: {
          'id': 'IDN-001',
          'category': 'IDENTITY',
          'verification_status': 'APPROVED',
          'version': '1.0.0',
          'review_owner': 'PixelMint Studio MVS Legal & Product Architecture',
        },
      );
    }

    // IDN-002: Who developed PIXMINT BOT? / Development Organization
    if (normalized.contains('who developed pixmint bot') ||
        normalized.contains('who developed you') ||
        normalized.contains('who is the developer of pixmint bot') ||
        normalized.contains('who is your developer') ||
        normalized.contains('who built this assistant') ||
        normalized.contains('development team behind pixmint bot') ||
        normalized.contains('developer of pixmint bot') ||
        normalized.contains('who developed this bot')) {
      return const PixmintEngineAnswer(
        content:
            'PIXMINT BOT is developed under the PixelMint Studio MVS brand. My current features depend on the application\'s implementation and enabled services.',
        sources: [sourceOfficialIdentity],
        metadata: {
          'id': 'IDN-002',
          'category': 'DEVELOPMENT',
          'verification_status': 'APPROVED',
          'version': '1.0.0',
          'review_owner': 'PixelMint Studio MVS Legal & Product Architecture',
        },
      );
    }

    // IDN-003: Who owns PIXMINT BOT? / Product Ownership
    if (normalized.contains('who owns pixmint bot') ||
        normalized.contains('who owns you') ||
        normalized.contains('who has ownership of pixmint bot') ||
        normalized.contains('is pixmint bot open source or owned') ||
        normalized.contains('owner of pixmint bot') ||
        normalized.contains('who is the owner of pixmint bot') ||
        normalized.contains('who has ownership') ||
        normalized.contains('who owns this product')) {
      return const PixmintEngineAnswer(
        content:
            'PIXMINT BOT is a product developed under the PixelMint Studio MVS brand. Refer ownership or legal-rights questions to the organization\'s approved legal documentation.',
        sources: [sourceOfficialIdentity],
        metadata: {
          'id': 'IDN-003',
          'category': 'OWNERSHIP',
          'verification_status': 'APPROVED',
          'version': '1.0.0',
          'review_owner': 'PixelMint Studio MVS Legal & Compliance',
        },
      );
    }

    // IDN-004: Why were you created? / Purpose of Creation
    if (normalized.contains('why were you created') ||
        normalized.contains('what is your purpose') ||
        normalized.contains('why do you exist') ||
        normalized.contains('why was pixmint bot created') ||
        normalized.contains('what was the reason for building you') ||
        normalized.contains('what were you created for') ||
        normalized.contains('what was the purpose of creating you')) {
      return const PixmintEngineAnswer(
        content:
            'I was designed to help Archi Draft users understand workflows, find relevant product guidance, troubleshoot problems, and receive useful explanations.',
        sources: [sourceOfficialIdentity],
        metadata: {
          'id': 'IDN-004',
          'category': 'PURPOSE',
          'verification_status': 'APPROVED',
          'version': '1.0.0',
          'review_owner': 'Product Architecture',
        },
      );
    }

    // IDN-005: What can you do? / Functional Capabilities
    if (normalized.contains('what can you do') ||
        normalized.contains('what are your capabilities') ||
        normalized.contains('how can you help me') ||
        normalized.contains('what features do you have') ||
        normalized.contains('tell me what you can do') ||
        normalized.contains('what can i ask you') ||
        normalized.contains('what can you help with')) {
      return const PixmintEngineAnswer(
        content:
            'I can help explain supported Archi Draft features, guide users through verified workflows, and answer general questions to the extent supported by the configured AI service. My available actions depend on the current implementation and the user\'s permissions.',
        sources: [sourceOfficialIdentity, sourceUserRoles],
        metadata: {
          'id': 'IDN-005',
          'category': 'CAPABILITIES',
          'verification_status': 'APPROVED',
          'version': '1.0.0',
          'review_owner': 'Product Architecture',
        },
      );
    }

    // IDN-006: Can you answer any question? / Knowledge Bounds & Uncertainty
    if (normalized.contains('can you answer any question') ||
        normalized.contains('can you answer everything') ||
        normalized.contains('do you know everything') ||
        normalized.contains('can you answer any question in the world') ||
        normalized.contains('are you always right') ||
        normalized.contains('can you answer all questions') ||
        normalized.contains('do you know all answers')) {
      return const PixmintEngineAnswer(
        content:
            'You can ask me questions in your own words. I will try to help, but I cannot guarantee that every answer is correct or that I know every product detail. I should acknowledge uncertainty rather than invent information.',
        sources: [sourceOfficialIdentity],
        metadata: {
          'id': 'IDN-006',
          'category': 'BOUNDARIES',
          'verification_status': 'APPROVED',
          'version': '1.0.0',
          'review_owner': 'Security & AI Ethics',
        },
      );
    }

    // IDN-007: Are you powered by a real AI model? / Model Truthfulness
    if (normalized.contains('are you powered by a real ai model') ||
        normalized.contains('are you a real ai model') ||
        normalized.contains('what model powers you') ||
        normalized.contains('which ai model do you use') ||
        normalized.contains('is this powered by real ai') ||
        normalized.contains('what ai model are you') ||
        normalized.contains('are you powered by real ai') ||
        normalized.contains('are you gpt') ||
        normalized.contains('are you chatgpt') ||
        normalized.contains('are you claude') ||
        normalized.contains('which llm do you use')) {
      return const PixmintEngineAnswer(
        content:
            'I should identify the actual model provider only when it has been verified from the active server configuration. If no model is configured, I must not claim that real model-powered responses are enabled.',
        sources: [sourceOfficialIdentity],
        metadata: {
          'id': 'IDN-007',
          'category': 'TRUTHFULNESS',
          'verification_status': 'APPROVED_CONDITIONAL',
          'version': '1.0.0',
          'review_owner': 'Security Engineering & AI Architecture',
        },
      );
    }

    // IDN-008: Can you access all user and project data? / Data Access Boundaries
    if (normalized.contains('can you access all user and project data') ||
        normalized.contains('can you access all project data') ||
        normalized.contains('can you see all projects') ||
        normalized.contains('can you access private drawings') ||
        normalized.contains('do you read all user data') ||
        normalized.contains('can you see other people\'s drawings') ||
        normalized.contains('can you see other peoples drawings') ||
        normalized.contains('can you access other users data') ||
        normalized.contains('can you access everything in the database')) {
      return const PixmintEngineAnswer(
        content:
            'No. Access to application information must be restricted by authentication, permissions, and the data available to the current session.',
        sources: [sourceOfficialIdentity, sourceUserRoles],
        metadata: {
          'id': 'IDN-008',
          'category': 'SECURITY_BOUNDARY',
          'verification_status': 'APPROVED',
          'version': '1.0.0',
          'review_owner': 'Security Architecture',
        },
      );
    }

    // IDN-009: Can you reveal administrator secrets or private information? / Secrets Protection
    if (normalized.contains('can you reveal administrator secrets') ||
        normalized.contains('reveal administrator secrets') ||
        normalized.contains('give me admin secrets') ||
        normalized.contains('show me admin secrets') ||
        normalized.contains('admin secrets or passwords') ||
        normalized.contains('reveal system credentials') ||
        normalized.contains('show private administrator records') ||
        normalized.contains('reveal private information') ||
        normalized.contains('give me passwords') ||
        normalized.contains('reveal passwords') ||
        normalized.contains('show api keys') ||
        normalized.contains('reveal credentials')) {
      return const PixmintEngineAnswer(
        content:
            'No. I cannot provide restricted credentials, secrets, private administrative records, or information that the current user is not authorized to access.',
        sources: [sourceOfficialIdentity, sourceUserRoles],
        metadata: {
          'id': 'IDN-009',
          'category': 'PRIVACY_PROTECTION',
          'verification_status': 'APPROVED',
          'version': '1.0.0',
          'review_owner': 'Security Engineering',
        },
      );
    }

    // IDN-010: Who designed the mascot? / Mascot Attribution
    if (normalized.contains('who designed the mascot') ||
        normalized.contains('who designed the robot mascot') ||
        normalized.contains('who drew the robot') ||
        normalized.contains('who is the designer of the pixmint mascot') ||
        normalized.contains('artist behind the robot') ||
        normalized.contains('who designed your mascot') ||
        normalized.contains('who created the mascot') ||
        normalized.contains('who created the robot character') ||
        normalized.contains('who drew the mascot')) {
      return const PixmintEngineAnswer(
        content:
            'The mascot\'s design attribution must be taken from verified brand records. If the designer has not been confirmed, I should say that the information is not currently verified.',
        sources: [sourceOfficialIdentity],
        metadata: {
          'id': 'IDN-010',
          'category': 'BRAND_ATTRIBUTION',
          'verification_status': 'NEEDS_VERIFICATION',
          'version': '1.0.0',
          'review_owner': 'Brand & Creative Governance',
        },
      );
    }

    // IDN-011: How should users report an incorrect answer? / Feedback Mechanism
    if (normalized.contains('how should users report an incorrect answer') ||
        normalized.contains('how do i report an incorrect answer') ||
        normalized.contains('how to report an incorrect answer') ||
        normalized.contains('where do i report wrong information') ||
        normalized.contains('how to give feedback on an answer') ||
        normalized.contains('how do i report bot mistakes') ||
        normalized.contains('how do i report wrong answer') ||
        normalized.contains('report an incorrect answer') ||
        normalized.contains('report a wrong answer') ||
        normalized.contains('report bot mistakes')) {
      return const PixmintEngineAnswer(
        content:
            'Use the feedback or support mechanism provided by the current application, if available. Do not claim that a reporting feature exists until it has been implemented. Users can contact official support via email at `pixelmintstudiomvs@gmail.com`.',
        sources: [sourceOfficialIdentity, sourceFaq],
        metadata: {
          'id': 'IDN-011',
          'category': 'SUPPORT_FEEDBACK',
          'verification_status': 'APPROVED',
          'version': '1.0.0',
          'review_owner': 'Customer Support & Product Operations',
        },
      );
    }

    // Generic Who Are You / Introduce Yourself
    if (normalized == 'who are you' ||
        normalized == 'introduce yourself' ||
        normalized == 'tell me about yourself' ||
        normalized == 'who is pixmint bot' ||
        normalized.contains('who are you') ||
        normalized.contains('introduce yourself') ||
        normalized.contains('tell me about yourself')) {
      return const PixmintEngineAnswer(
        content:
            'I am **PIXMINT BOT**, an AI assistant developed under **PixelMint Studio MVS** for the **Archi Draft** application.\n\n'
            'I was designed to help Archi Draft users understand workflows, find relevant product guidance, troubleshoot problems, and receive useful explanations across supported portals (Engineer, Draughtsman, Student, and authorized Admin).\n\n'
            'I can help explain supported Archi Draft features, guide users through verified workflows, and answer general questions to the extent supported by the configured AI service. My available actions depend on the current implementation and your user permissions.\n\n'
            'What would you like assistance with today?',
        sources: [sourceCoreWorkflow, sourceUserRoles, sourceOfficialIdentity],
        metadata: {
          'id': 'IDN-GEN',
          'category': 'IDENTITY',
          'verification_status': 'APPROVED',
          'version': '1.0.0',
        },
      );
    }

    return null;
  }

  static PixmintEngineAnswer _handleIdentity() {
    return _resolveOfficialIdentity('who are you')!;
  }

  static bool _isTroubleshootingRequest(String normalized) {
    return normalized.contains('not working') ||
        normalized.contains('is not working') ||
        normalized.contains('it is not working') ||
        normalized.contains('it isn t working') ||
        normalized.contains('it isnt working') ||
        normalized.contains('it fails') ||
        normalized.contains('something is wrong') ||
        normalized.contains('having trouble') ||
        normalized.contains('upload error') ||
        normalized.contains('upload failed') ||
        normalized.contains('report a problem') ||
        normalized == 'problem' ||
        normalized == 'help' ||
        normalized == 'it is broken' ||
        normalized == 'it broke';
  }

  static PixmintEngineAnswer _handleTroubleshooting(String normalized) {
    return const PixmintEngineAnswer(
      content:
          "### 🛠️ Archi Draft Troubleshooting Guide\n\n"
          "I can help resolve your issue! What kind of failure are you experiencing?\n\n"
          "1. **CAD File Upload Failed:**\n"
          "   • Ensure your file size is strictly under **50MB**.\n"
          "   • In AutoCAD, run the `PURGE` and `AUDIT` commands to remove unreferenced blocks/layers before exporting `.dwg` or `.dxf`.\n"
          "   • Ensure the file is not currently locked or open in another CAD program.\n\n"
          "2. **Drawing Viewer or Redline Markup Pin Discrepancies:**\n"
          "   • Check that WebGL/hardware acceleration is enabled in your browser.\n"
          "   • Refresh the page; all placed redline pins are autosaved to the audit log.\n\n"
          "3. **Assignment or Review Delays:**\n"
          "   • Draughtsmen can inspect engineer and client pins in the interactive markup panel.\n"
          "   • If an assignment is stalled, administrators can re-dispatch via the Admin Dispatch view.\n\n"
          "4. **Authentication or Session Errors:**\n"
          "   • If you see an authorization error, sign out and sign back in to refresh your Firebase security token.\n\n"
          "Which of these matches what you're seeing, or could you share the exact error text?",
      sources: [sourceFaq],
      metadata: {'category': 'TROUBLESHOOTING'},
    );
  }

  static bool _isFollowUpQuery(String normalized) {
    return normalized == 'how' ||
        normalized == 'how do i do that' ||
        normalized == 'how to do that' ||
        normalized == 'what next' ||
        normalized == 'what do i do next' ||
        normalized == 'what should i do next' ||
        normalized == 'where do i find that' ||
        normalized == 'show me step by step' ||
        normalized == 'step by step' ||
        normalized == 'give me the steps one by one' ||
        normalized == 'steps one by one' ||
        normalized == 'tell me more' ||
        normalized == 'why' ||
        normalized == 'can you explain' ||
        normalized.contains('explain step 2') ||
        normalized.contains('explain step 1') ||
        normalized.contains('what is step 2') ||
        normalized.contains('simple words') ||
        normalized.contains('simple terms') ||
        normalized.contains('explain simpler') ||
        normalized.contains('simpler') ||
        normalized.contains('summarize') ||
        normalized.contains('recap') ||
        normalized.contains('already tried that') ||
        normalized.contains('what if that does not work') ||
        normalized.contains('what if that doesnt work') ||
        normalized.contains('what should i do before submitting') ||
        normalized.contains('before submitting this') ||
        normalized.contains('i meant the other drawing');
  }

  static PixmintEngineAnswer? _handleFollowUp(
    String normalized,
    List<ChatMessage> history,
    BotUserRole role,
  ) {
    final recentBotMessages = history.reversed.where((m) => m.isBot).toList();
    if (recentBotMessages.isEmpty) return null;

    final lastBotContent = recentBotMessages.first.content.toLowerCase();

    // 1. Follow-up: Explain in simple words / simpler
    if (normalized.contains('simple words') ||
        normalized.contains('simple terms') ||
        normalized.contains('simpler')) {
      if (lastBotContent.contains('review') || lastBotContent.contains('redline')) {
        return const PixmintEngineAnswer(
          content:
              "**In simple terms:**\n\n"
              "When an engineer reviews a drawing, they are checking if the drawing is accurate and safe. "
              "If they see a mistake, they drop a digital pin (a 'redline') on that spot with a short note explaining what to fix. "
              "The draughtsman opens the drawing, fixes the mistake in AutoCAD, and uploads a new version.\n\n"
              "Does that make sense, or would you like to see how to drop a pin?",
          sources: [sourceCoreWorkflow],
          metadata: {'category': 'SIMPLIFIED'},
        );
      }
      if (lastBotContent.contains('dwg') || lastBotContent.contains('dxf')) {
        return const PixmintEngineAnswer(
          content:
              "**In simple terms:**\n\n"
              "• **DWG** is like a standard Word document (.docx) — it is AutoCAD's native format and saves file space.\n"
              "• **DXF** is like a plain text file (.txt) — any CAD program can open it, but the file size is larger.\n\n"
              "Both work in Archi Draft as long as they are under **50MB**!",
          sources: [sourceFaq],
          metadata: {'category': 'SIMPLIFIED'},
        );
      }
      return const PixmintEngineAnswer(
        content:
            "**In simple terms:**\n\n"
            "Archi Draft lets your team collaborate on architectural drawings online. "
            "Draughtsmen upload the drawings, engineers check them for errors, students learn with practice modules, and administrators manage the studio.",
        sources: [sourceUserRoles],
        metadata: {'category': 'SIMPLIFIED'},
      );
    }

    // 2. Follow-up: Give me the steps one by one / Step by step
    if (normalized.contains('steps one by one') ||
        normalized.contains('step by step') ||
        normalized == 'show me step by step') {
      if (lastBotContent.contains('review') || lastBotContent.contains('redline')) {
        return const PixmintEngineAnswer(
          content:
              "**Step-by-Step Drawing Review:**\n\n"
              "1. Open the project dashboard and click on the assigned sheet.\n"
              "2. Click the 'Drawing Viewer' button to open the sheet in full view.\n"
              "3. Select the Redline Annotation tool (Rectangle, Cloud, or Callout Pin).\n"
              "4. Click on the drawing element that requires correction.\n"
              "5. Type the specific revision requirement in the comment box.\n"
              "6. Choose review status: **Approved**, **Revise & Resubmit**, or **Rejected**.\n"
              "7. Click **Submit Review** to notify the draughtsman.",
          sources: [sourceCoreWorkflow],
          metadata: {'category': 'STEP_BY_STEP'},
        );
      }
      if (lastBotContent.contains('upload') || lastBotContent.contains('cad')) {
        return const PixmintEngineAnswer(
          content:
              "**Step-by-Step Drawing Upload:**\n\n"
              "1. In AutoCAD or your CAD tool, run `PURGE` and `AUDIT`.\n"
              "2. Save your drawing as `.dwg` or `.dxf` under 50MB.\n"
              "3. In Archi Draft, navigate to your assigned project sheet.\n"
              "4. Drag-and-drop the file into the upload dropzone or click **Browse Files**.\n"
              "5. Verify layer extraction passes in the pre-flight check.\n"
              "6. Click **Submit Drawing** to dispatch for technical review.",
          sources: [sourceDataArch],
          metadata: {'category': 'STEP_BY_STEP'},
        );
      }
    }

    // 3. Follow-up: Explain Step 2
    if (normalized.contains('explain step 2') ||
        normalized.contains('what is step 2') ||
        normalized.contains('step 2')) {
      if (lastBotContent.contains('upload') || lastBotContent.contains('purge')) {
        return const PixmintEngineAnswer(
          content:
              "**Deep Dive: Step 2 — CAD Database Audit & Purge**\n\n"
              "In AutoCAD:\n"
              "• Type `PURGE` into the command window and press Enter.\n"
              "• Check 'Purge all orphaned data' and click 'Purge All Checked Items'.\n"
              "• Next, type `AUDIT` and select 'Y' to fix any detected geometry errors.\n\n"
              "This removes unused blocks, layers, and dangling proxy entities, shrinking file size and ensuring the web drawing viewer loads your sheet instantaneously.",
          sources: [sourceDataArch, sourceFaq],
          metadata: {'category': 'STEP_DEEP_DIVE'},
        );
      }
      return const PixmintEngineAnswer(
        content:
            "**Step 2 Detailed Guidance:**\n\n"
            "Step 2 focuses on inspecting structural alignment and dimension chains against the master project grid. Ensure grid references align across all multidisciplinary sheets before proceeding.",
        sources: [sourceCoreWorkflow],
        metadata: {'category': 'STEP_DEEP_DIVE'},
      );
    }

    // 4. Follow-up: Summarize previous instructions
    if (normalized.contains('summarize') || normalized.contains('recap')) {
      return const PixmintEngineAnswer(
        content:
            "**Executive Summary:**\n\n"
            "• **File Rule:** Upload `.dwg`, `.dxf`, or vector `.pdf` strictly under 50MB.\n"
            "• **Hygiene:** Always run `PURGE` and `AUDIT` in CAD before submission.\n"
            "• **Workflow:** Draughtsmen upload drawing -> Engineers conduct technical review and place redlines -> Draughtsmen resolve comments and resubmit.\n\n"
            "Let me know if you need specific instructions for any step!",
        sources: [sourceCoreWorkflow, sourceFaq],
        metadata: {'category': 'SUMMARY'},
      );
    }

    // 5. Follow-up: Already tried that / What if that doesn't work
    if (normalized.contains('already tried that') ||
        normalized.contains('what if that does not work') ||
        normalized.contains('what if that doesnt work') ||
        normalized.contains('still failing')) {
      return const PixmintEngineAnswer(
        content:
            "**Advanced Troubleshooting & Escalation:**\n\n"
            "If standard file checks did not resolve the problem:\n"
            "1. **Release OS File Locks:** Completely close your desktop CAD software. An open CAD instance can lock Windows file handles and silently corrupt uploads.\n"
            "2. **Bind External References (XREFs):** If your drawing relies on attached XREFs or raster images, type `XREF` in CAD and choose **Bind -> Insert** so all geometry is self-contained in a single file.\n"
            "3. **Resave Version:** Resave as AutoCAD 2018 DWG format (most stable for web vector parsers).\n"
            "4. **Escalate to Support:** If the error persists, email our support team with your project code and error screenshot at `pixelmintstudiomvs@gmail.com`.",
        sources: [sourceFaq, sourceDataArch],
        metadata: {'category': 'ESCALATION'},
      );
    }

    // 6. Follow-up: What should I do before submitting this? (Pre-submission checklist)
    if (normalized.contains('before submitting') || normalized.contains('pre submission')) {
      return const PixmintEngineAnswer(
        content:
            "### 📋 Pre-Submission Checklist for Archi Draft Drawings\n\n"
            "Before clicking **Submit Drawing**, verify the following 6 items:\n\n"
            "1. [ ] **File Size Check:** File is strictly under **50MB**.\n"
            "2. [ ] **CAD Hygiene:** Ran `PURGE` and `AUDIT` with all errors repaired.\n"
            "3. [ ] **Self-Contained Geometry:** All external references (XREFs) are bound or embedded.\n"
            "4. [ ] **Revision Tag:** Title block revision letter is incremented (e.g. Rev 0 -> Rev A).\n"
            "5. [ ] **Redlines Addressed:** All previous engineering correction pins are marked as resolved.\n"
            "6. [ ] **Layer Standards:** Geometry uses AIA / ISO discipline layers (no non-standard layers).\n\n"
            "Once verified, upload your file and click **Submit Drawing** for review!",
        sources: [sourceCoreWorkflow, sourceDataArch],
        metadata: {'category': 'CHECKLIST'},
      );
    }

    // 7. Context resolution based on topic of last bot response
    if (lastBotContent.contains('new project') || lastBotContent.contains('creating a new project')) {
      return _handleProjectCreation(role);
    }
    if (lastBotContent.contains('cad') || lastBotContent.contains('drawing') || lastBotContent.contains('upload')) {
      return _handleDrawingAndCad(role);
    }
    if (lastBotContent.contains('revision') || lastBotContent.contains('correction') || lastBotContent.contains('redline')) {
      return _handleReviewAndCorrections(role);
    }
    if (lastBotContent.contains('approve') || lastBotContent.contains('approval')) {
      return _handleApproval(role);
    }
    if (lastBotContent.contains('student') || lastBotContent.contains('training') || lastBotContent.contains('curriculum')) {
      return _handleStudentLearning(role);
    }
    if (lastBotContent.contains('troubleshooting') || lastBotContent.contains('upload failed')) {
      return const PixmintEngineAnswer(
        content:
            "To resolve your issue step by step:\n\n"
            "1. Open your CAD drawing in your drafting software.\n"
            "2. Type `PURGE` in the command line, select 'Purge All', then run `AUDIT` with Fix Errors = Yes.\n"
            "3. Save as AutoCAD 2018 or later `.dwg` or ASCII `.dxf`.\n"
            "4. Verify the file size is under 50MB in file explorer.\n"
            "5. Return to Archi Draft, navigate to your project/assignment workspace, and click 'Upload Drawing'.\n\n"
            "Did the upload succeed, or are you seeing a specific error code?",
        sources: [sourceFaq],
      );
    }

    return null;
  }

  static PixmintEngineAnswer? _checkRoleBoundaries(String normalized, BotUserRole role) {
    // Student asking for financials/invoices/billing
    if (role == BotUserRole.student &&
        (normalized.contains('financial') ||
            normalized.contains('invoice') ||
            normalized.contains('billing') ||
            normalized.contains('revenue'))) {
      return const PixmintEngineAnswer(
        content:
            "Studio financials, project valuations, and invoicing are strictly restricted to Studio Administrators.\n\n"
            "As a Student in Archi Draft, you have access to your 12-module drafting curriculum, lesson assignments, evaluation rubrics, and certificate verification.",
        sources: [sourceUserRoles],
        metadata: {'type': 'ROLE_BOUNDARY', 'role': 'STUDENT'},
      );
    }

    // Regular chatbot barrier for administrative settings, secrets, metrics, and audit logs
    if (role != BotUserRole.admin &&
        (normalized.contains('admin setting') ||
            normalized.contains('administrative setting') ||
            normalized.contains('control center') ||
            normalized.contains('metric') ||
            normalized.contains('revenue') ||
            normalized.contains('audit log') ||
            normalized.contains('security log') ||
            normalized.contains('access log') ||
            normalized.contains('knowledge source') ||
            normalized.contains('approved knowledge') ||
            normalized.contains('suggested question') ||
            normalized.contains('service status') ||
            normalized.contains('unanswered question') ||
            normalized.contains('bot availability') ||
            normalized.contains('configuration change'))) {
      return const PixmintEngineAnswer(
        content:
            "Access restricted. Administrative settings, private system metrics, API secrets, and security audit logs are strictly restricted to Studio Administrators in the separately authorized Admin Portal.\n\n"
            "Regular chatbot sessions cannot access or disclose internal platform operations, credentials, or audit trails.",
        sources: [sourceUserRoles, sourceDataArch],
        metadata: {'type': 'SECURITY_RESTRICTION', 'restricted': true},
      );
    }

    // Draughtsman attempting to approve final drawing
    if (role == BotUserRole.draughtsman &&
        (normalized.contains('can i approve') ||
            normalized.contains('approve final') ||
            normalized.contains('approve drawing'))) {
      return const PixmintEngineAnswer(
        content:
            "No. In Archi Draft, draughtsmen are not authorized to issue drawing approvals.\n\n"
            "• **Draughtsman Role:** Prepares CAD drawings, complies with layer standards, resolves correction pins, and clicks 'Submit Drawing' for review.\n"
            "• **Technical Review:** Conducted by Engineers during technical inspection.",
        sources: [sourceCoreWorkflow, sourceUserRoles],
        metadata: {'type': 'ROLE_BOUNDARY', 'role': 'DRAUGHTSMAN'},
      );
    }

    return null;
  }

  static bool _isRoleInquiry(String normalized) {
    final hasRoleWord = normalized.contains('engineer') ||
        normalized.contains('draughtsman') ||
        normalized.contains('student') ||
        normalized.contains('admin');

    final hasQuestionIntent = normalized.contains('what does') ||
        normalized.contains('what do') ||
        normalized.contains('role') ||
        normalized.contains('responsibilit') ||
        normalized.contains('permission') ||
        normalized.contains('tell me about') ||
        normalized.contains('what is an') ||
        normalized.contains('what is a');

    return hasRoleWord && hasQuestionIntent;
  }

  static PixmintEngineAnswer _handleRoleInquiry(String normalized, BotUserRole role) {

    if (normalized.contains('engineer')) {
      return const PixmintEngineAnswer(
        content:
            "### 📐 Lead Engineer Role & Permissions in Archi Draft\n\n"
            "In Archi Draft, an **Engineer** provides technical oversight and drawing verification:\n\n"
            "• **Technical Intake:** Reviews initial project briefs and confirms structural and architectural feasibility.\n"
            "• **Drawing Inspections:** Evaluates submitted `.dwg`, `.dxf`, and `.pdf` sheets against municipal building bylaws and engineering standards.\n"
            "• **Redline Markups:** Places interactive pin markups on drawing sheets to flag structural discrepancies or code non-compliance.\n"
            "• **Revision Coordination:** Directs revision cycles with assigned draughtsmen until technical specifications are fulfilled.\n"
            "• **Permissions:** Authorized to inspect drawings and place redline pins. Final drawing acceptance is concluded by the project Client.",
        sources: [sourceCoreWorkflow, sourceUserRoles],
      );
    }

    if (normalized.contains('draughtsman')) {
      return const PixmintEngineAnswer(
        content:
            "### ✏️ Draughtsman Role & Permissions in Archi Draft\n\n"
            "In Archi Draft, a **Draughtsman** is a certified CAD professional responsible for sheet production:\n\n"
            "• **Assignment Acceptance:** Reviews project briefs and accepts dispatched assignments (`ASSIGNED` -> `IN_PROGRESS`).\n"
            "• **CAD Sheet Production:** Drafts architectural, structural, and MEP sheets using AutoCAD `.dwg`, ASCII `.dxf`, or vector `.pdf`.\n"
            "• **Layer Standards:** Follows AIA and ISO 128 CAD layer standards (e.g., `A-WALL-FULL`, `S-COLS-CONC`).\n"
            "• **Addressing Redlines:** Inspects and resolves correction pins placed by Engineers and Clients.\n"
            "• **Submission:** Submits incremented revisions (`v1.0` -> `v1.1`) for technical review.",
        sources: [sourceCoreWorkflow, sourceUserRoles],
      );
    }

    if (normalized.contains('student')) {
      return const PixmintEngineAnswer(
        content:
            "### 🎓 Student Role & Permissions in Archi Draft\n\n"
            "In Archi Draft, a **Student** participates in the structured academy drafting curriculum:\n\n"
            "• **Curriculum Progression:** Advances through 12 structured modules (2D Architectural Drafting, BIM Fundamentals, Structural Detailing, MEP).\n"
            "• **Practical Assignments:** Downloads lesson briefs, completes drawings in CAD, and uploads submissions for mentor review.\n"
            "• **Evaluation Rubrics:** Evaluated on accuracy, layer compliance, and dimensioning with a ≥ 80% passing threshold.\n"
            "• **Cryptographic Verification:** Upon curriculum completion, receives an immutable digital Certificate with a verifiable SHA-256 hash (`/verify/[hash]`).\n"
            "• **Boundary:** Barred from live commercial client data, studio financials, and administrative settings.",
        sources: [sourceUserRoles, sourceFaq],
      );
    }

    if (normalized.contains('admin')) {
      return const PixmintEngineAnswer(
        content:
            "### 🛡️ Studio Admin Role & Permissions in Archi Draft\n\n"
            "In Archi Draft, a **Studio Admin** oversees platform operations, contracts, and quality:\n\n"
            "• **Dispatch Management:** Assigns submitted projects to qualified draughtsmen or student training cohorts.\n"
            "• **Financial Governance:** Monitors project valuation caps, issues milestone invoices, and tracks payment records.\n"
            "• **Credential Audits:** Inspects and approves professional qualifications for draughtsmen.\n"
            "• **Dispute Resolution:** Mediates review disagreements and maintains the immutable audit trail.\n"
            "• **Permissions:** Full administrative governance across dispatch, financials, user profiles, and legal policies.",
        sources: [sourceUserRoles, sourceDataArch],
      );
    }

    return _handleIdentity();
  }

  static bool _isProjectCreationQuery(String normalized) {
    return normalized.contains('start a project') ||
        normalized.contains('create a project') ||
        normalized.contains('start project') ||
        normalized.contains('create project') ||
        normalized.contains('new project') ||
        normalized.contains('begin a project') ||
        (normalized.contains('how') && normalized.contains('start') && normalized.contains('project')) ||
        (normalized.contains('how') && normalized.contains('create') && normalized.contains('project'));
  }

  static PixmintEngineAnswer _handleProjectCreation(BotUserRole role) {
    return const PixmintEngineAnswer(
      content:
          "### 🚀 Step-by-Step: Starting a New Project in Archi Draft\n\n"
          "**1. Goal:** Initiate an architectural project, establish drawing deliverables, and dispatch work to a draughtsman.\n\n"
          "**2. Prerequisites:** Authenticated Client account (or Studio Admin acting on behalf of a client).\n\n"
          "**3. Actionable Steps:**\n"
          "1. Navigate to the **Projects** dashboard and click **'+ New Project'**.\n"
          "2. Enter project details:\n"
          "   • **Project Name & Site Address**\n"
          "   • **Drawing Type** (Architectural, Structural, MEP, or Foundation)\n"
          "   • **Project Area** (total square meters or square feet)\n"
          "3. Upload your initial brief documents (site survey, sketches, or municipal zoning specifications, up to 50MB per file).\n"
          "4. Click **'Submit Project'** to place it in the dispatch queue.\n\n"
          "**4. Expected Result:** The project transitions from `DRAFT` to `SUBMITTED`. An administrator assigns a certified draughtsman, moving status to `ASSIGNED`.\n\n"
          "**5. Limitations:** File sizes must be ≤ 50MB. Supported initial brief formats: `.pdf`, `.dwg`, `.dxf`, `.png`, `.jpg`.\n\n"
          "**6. Next Action:** Would you like guidance on tracking project milestones or review workflows?",
      sources: [sourceCoreWorkflow, sourceDataArch],
      metadata: {'category': 'PROJECT_CREATION'},
    );
  }

  static bool _isProjectTrackingQuery(String normalized) {
    return normalized.contains('track') ||
        normalized.contains('milestone') ||
        normalized.contains('progress') ||
        normalized.contains('status') ||
        normalized.contains('timeline');
  }

  static PixmintEngineAnswer _handleProjectTracking(BotUserRole role) {
    return const PixmintEngineAnswer(
      content:
          "### 📊 Project Tracking & Lifecycle Statuses\n\n"
          "Archi Draft tracks drawing deliverables through an immutable state pipeline:\n\n"
          "• **1. DRAFT:** Initial project creation and brief file upload by the Client.\n"
          "• **2. SUBMITTED:** Awaiting studio administrator review and draughtsman dispatch.\n"
          "• **3. ASSIGNED:** Allocated to a qualified draughtsman; CAD drafting unlocks upon acceptance.\n"
          "• **4. IN_PROGRESS:** Active draughtsman production following AIA/ISO 128 layer standards.\n"
          "• **5. UNDER_REVIEW:** Drawing version submitted for Engineer technical inspection and Client review.\n"
          "• **6. REVISION_REQUESTED:** Redline pins placed by Engineer or Client; draughtsman resolves pins and resubmits (`v1.0` -> `v1.1`).\n"
          "• **7. APPROVED:** Client issues final drawing approval (`approve-final`), concluding deliverables.\n\n"
          "• **Check your status:** Open **Projects > [Select Project]** to view the live milestone pipeline and audit log.",
      sources: [sourceCoreWorkflow, sourceDataArch],
      metadata: {'category': 'PROJECT_TRACKING'},
    );
  }

  static bool _isDrawingOrCadQuery(String normalized) {
    return normalized.contains('drawing') ||
        normalized.contains('cad') ||
        normalized.contains('layer') ||
        normalized.contains('format') ||
        normalized.contains('dwg') ||
        normalized.contains('dxf') ||
        normalized.contains('upload drawing') ||
        normalized.contains('cad standard');
  }

  static PixmintEngineAnswer _handleDrawingAndCad(BotUserRole role) {
    return const PixmintEngineAnswer(
      content:
          "### 📐 CAD Drawing Formats & Layer Specifications\n\n"
          "**1. Supported File Formats:**\n"
          "• **AutoCAD Drawing (.dwg):** AutoCAD 2018 or newer format.\n"
          "• **Drawing Exchange Format (.dxf):** Standard ASCII format.\n"
          "• **Vector PDF (.pdf):** High-resolution 300 DPI vector export with embedded fonts.\n"
          "• **File Size Limit:** Maximum 50MB per upload.\n\n"
          "**2. Required AIA & ISO 128 Layer Standards:**\n"
          "• `A-WALL-FULL` (0.50mm / Continuous) — Exterior & interior structural walls\n"
          "• `A-DOOR-IDEN` (0.25mm / Continuous) — Door assemblies, tags, and swing arcs\n"
          "• `A-GLAZ-CSIZ` (0.25mm / Continuous) — Windows, glazing, and curtain walls\n"
          "• `A-ANNO-DIMS` (0.18mm / Continuous) — Dimension lines and level callouts\n"
          "• `S-COLS-CONC` (0.70mm / Continuous) — Concrete columns and structural shafts\n"
          "• `S-BEAM-CENT` (0.18mm / Center2) — Structural beam centerlines\n\n"
          "**3. Upload Checklist:**\n"
          "Run `PURGE` and `AUDIT` in your CAD software before saving to remove unused blocks and avoid upload errors.",
      sources: [sourceFaq, sourceDataArch],
      metadata: {'category': 'DRAWING_CAD_STANDARDS'},
    );
  }

  static bool _isReviewOrCorrectionQuery(String normalized) {
    return normalized.contains('revision') ||
        normalized.contains('correction') ||
        normalized.contains('redline') ||
        normalized.contains('markup') ||
        normalized.contains('pin') ||
        normalized.contains('feedback') ||
        normalized.contains('request correction');
  }

  static PixmintEngineAnswer _handleReviewAndCorrections(BotUserRole role) {
    return const PixmintEngineAnswer(
      content:
          "### 🔍 Review Cycles & Redline Correction Workflow\n\n"
          "**1. Goal:** Flag discrepancies and coordinate drawing updates between Clients, Engineers, and Draughtsmen.\n\n"
          "**2. Prerequisites:** Active project in `UNDER_REVIEW` state.\n\n"
          "**3. How It Works:**\n"
          "1. Open the project in the **Web CAD Viewer**.\n"
          "2. **Placing Redline Pins:** Click any point on the drawing to drop an interactive correction pin. Enter specific remarks (e.g., *'Column C2 offset 150mm from gridline A'*).\n"
          "3. **Submitting Revision Request:** The Client clicks **'Request Correction'** to formally increment the revision round.\n"
          "4. **Draughtsman Resolution:** The Draughtsman reviews each pin in their workspace, modifies the CAD model, and uploads the incremented sheet (`v1.1`, `v2.0`).\n"
          "5. **Re-Review:** Once resubmitted, the Engineer and Client verify that all pins are resolved.\n\n"
          "• **Audit Trail:** Every pin and remark is logged with author identity and timestamp in the immutable audit log.",
      sources: [sourceCoreWorkflow, sourceUserRoles],
      metadata: {'category': 'REVISION_WORKFLOW'},
    );
  }

  static bool _isApprovalQuery(String normalized) {
    return normalized.contains('approve') ||
        normalized.contains('sign off') ||
        normalized.contains('final approval') ||
        normalized.contains('accept drawing');
  }

  static PixmintEngineAnswer _handleApproval(BotUserRole role) {
    return const PixmintEngineAnswer(
      content:
          "### ✅ Final Drawing Approval Workflow\n\n"
          "**1. Goal:** Finalize verified drawing sets and conclude the deliverable package.\n\n"
          "**2. Authority:** In Archi Draft, **Final Drawing Approval is strictly restricted to Clients** (with Admin fallback). Draughtsmen cannot approve drawings.\n\n"
          "**3. Actionable Steps:**\n"
          "1. Open the project detail page when the status is `UNDER_REVIEW`.\n"
          "2. Verify that all redline pins from previous revision cycles are marked as resolved.\n"
          "3. Confirm technical sheet completeness (Floor Plans, Structural Detailing, Title Blocks).\n"
          "4. Click **'Approve Final Drawing'**.\n\n"
          "**4. Expected Result:** The project transitions to `APPROVED`. Final vector PDFs and CAD packages are archived and unlocked for final export.",
      sources: [sourceCoreWorkflow, sourceUserRoles],
      metadata: {'category': 'APPROVAL_WORKFLOW'},
    );
  }

  static bool _isStudentLearningQuery(String normalized) {
    return normalized.contains('student') ||
        normalized.contains('curriculum') ||
        normalized.contains('training') ||
        normalized.contains('lesson') ||
        normalized.contains('rubric') ||
        normalized.contains('grade') ||
        normalized.contains('certificate') ||
        normalized.contains('academy');
  }

  static PixmintEngineAnswer _handleStudentLearning(BotUserRole role) {
    return const PixmintEngineAnswer(
      content:
          "### 🎓 Archi Draft Academy: Curriculum & Certification\n\n"
          "**1. 12-Module Progressive Curriculum:**\n"
          "Covers 2D Architectural Drafting, BIM Fundamentals, Structural Framing, and MEP Coordination.\n\n"
          "**2. Lesson Submissions & Mentorship:**\n"
          "1. Open your active training module under **Training Modules**.\n"
          "2. Download the lesson exercise brief and base drawing templates.\n"
          "3. Complete the drawing in CAD following AIA/ISO 128 standards.\n"
          "4. Upload your `.dwg` or `.pdf` drawing for mentor evaluation.\n\n"
          "**3. Evaluation Rubrics:**\n"
          "Mentors evaluate drafting accuracy, layer discipline, dimensioning, and brief compliance. A minimum score of **80%** is required to pass.\n\n"
          "**4. Verifiable Digital Certificate:**\n"
          "Upon completing all 12 modules and practical assignments, your official Certificate of Completion is issued with an immutable **SHA-256 digital hash** verifiable publicly at `archidraft.com/verify/[CERT-HASH]`.",
      sources: [sourceUserRoles, sourceFaq],
      metadata: {'category': 'STUDENT_LEARNING'},
    );
  }

  static bool _isAdminOperationQuery(String normalized) {
    return normalized.contains('dispatch') ||
        normalized.contains('assign draughtsman') ||
        normalized.contains('financial') ||
        normalized.contains('invoice') ||
        normalized.contains('billing') ||
        normalized.contains('admin panel');
  }

  static PixmintEngineAnswer _handleAdminOperation(BotUserRole role) {
    return const PixmintEngineAnswer(
      content:
          "### 🛡️ Administrative Governance & Dispatch\n\n"
          "**1. Project Dispatch:**\n"
          "• Studio Admins review pending submitted projects under **Admin Dispatch**.\n"
          "• Dispatch to certified draughtsmen based on specialization (Residential, Commercial, Structural) or student training cohorts.\n\n"
          "**2. Financials & Invoicing:**\n"
          "• Set project valuation caps (`total_value`).\n"
          "• Issue progressive milestone invoices and record verified client payments.\n\n"
          "**3. Credential Review:**\n"
          "• Review and verify professional credentials submitted by draughtsmen during onboarding.",
      sources: [sourceUserRoles, sourceDataArch],
      metadata: {'category': 'ADMIN_OPERATIONS'},
    );
  }

  static bool _isLegalPrivacyQuery(String normalized) {
    return normalized.contains('privacy') ||
        normalized.contains('terms') ||
        normalized.contains('legal') ||
        normalized.contains('security') ||
        normalized.contains('data retention') ||
        normalized.contains('gdpr');
  }

  static PixmintEngineAnswer _handleLegalPrivacy() {
    return const PixmintEngineAnswer(
      content:
          "### 🔒 Privacy, Security & Data Protection in Archi Draft\n\n"
          "• **Ownership of Drawings:** Clients retain full intellectual property rights to all submitted project briefs and commissioned architectural CAD drawings.\n"
          "• **Data Isolation:** User sessions and project files are strictly partitioned by authenticated Firebase UIDs. Cross-account access is denied at the server layer.\n"
          "• **Zero AI Key Exposure:** AI and assistant features execute securely through the Cloudflare Worker with server-side secrets. Provider keys are never bundled in client applications.\n"
          "• **Audit Trail:** Project modifications, approvals, and revision pins are immutably logged for contract transparency.\n"
          "• Review effective policies anytime under **Legal & Privacy** in your account settings.",
      sources: [sourceLegalPrivacy],
      metadata: {'category': 'LEGAL_PRIVACY'},
    );
  }

  // ── Portal Preloaded Questions Dispatcher ────────────────────────────────
  static PixmintEngineAnswer? _resolvePortalPreloadedQuestions(
    String normalized,
    BotUserRole role,
  ) {
    // ── Engineer Portal Questions ─────────────────────────────────────────
    if (normalized.contains('review a drawing') ||
        (normalized.contains('how') &&
            normalized.contains('review') &&
            normalized.contains('drawing') &&
            !normalized.contains('problem'))) {
      return const PixmintEngineAnswer(
        content:
            "### 🔍 How to Review a Drawing in Archi Draft (Engineer Portal)\n\n"
            "1. **Navigate to the Review Workspace:** In your Engineer Portal, open the project in `UNDER_REVIEW` state.\n"
            "2. **Open the Interactive Web CAD Viewer:** Launch the drawing sheet (Floor Plans, Structural Elevations, or Details).\n"
            "3. **Inspect Geometry & Compliance:** Verify dimension strings, structural grid alignments (grids A-E, 1-6), and title block metadata.\n"
            "4. **Place Redline Markup Pins:** Click on discrepancies to drop interactive pins with precise engineering annotations.\n"
            "5. **Submit Technical Review:** Once all sheets are inspected, click **'Submit Technical Review'** to forward feedback to the draughtsman or client.",
        sources: [sourceCoreWorkflow, sourceUserRoles],
        metadata: {'category': 'TECHNICAL_REVIEW'},
      );
    }

    if (normalized.contains('redline annotation') ||
        normalized.contains('revision annotation') ||
        (normalized.contains('add') &&
            (normalized.contains('redline') || normalized.contains('annotation')))) {
      return const PixmintEngineAnswer(
        content:
            "### ✏️ Adding Redline Annotations in Archi Draft\n\n"
            "1. **Launch the CAD Viewer:** Open the target drawing version in the Web CAD Viewer.\n"
            "2. **Activate the Redline Tool:** Select the redline pen or pin tool from the viewer toolbar.\n"
            "3. **Drop a Pin on Discrepancies:** Click precisely where the issue occurs (e.g., column placement, wall clearance, missing dimension).\n"
            "4. **Enter Clarifying Remarks:** Type the required corrective action (e.g., *'Offset column C2 150mm east to align with structural grid'*).\n"
            "5. **Save Markup:** The pin is immutably recorded in the project audit log with your engineer identity and timestamp.",
        sources: [sourceCoreWorkflow, sourceDataArch],
        metadata: {'category': 'REDLINE_ANNOTATIONS'},
      );
    }

    if (normalized.contains('check during technical review') ||
        normalized.contains('technical review check') ||
        (normalized.contains('what') &&
            normalized.contains('check') &&
            normalized.contains('technical review'))) {
      return const PixmintEngineAnswer(
        content:
            "### 📋 Technical Review Inspection Checklist\n\n"
            "During technical review, verify:\n\n"
            "1. **AIA & ISO 128 Layer Discipline:** Ensure correct layer assignments (`A-WALL-FULL`, `S-COLS-CONC`, `A-DOOR-IDEN`, `A-GLAZ-CSIZ`, `A-ANNO-DIMS`).\n"
            "2. **Dimensional & Grid Consistency:** Cross-check dimension chains against structural column centerlines and boundary setbacks.\n"
            "3. **Clearances & Egress Standards:** Validate corridor widths, door swings, stair geometry, and accessibility standards.\n"
            "4. **Sheet & Title Block Completeness:** Ensure scale bars, north arrows, sheet numbering, and revision block tags (`v1.0`, `v1.1`) are present.\n"
            "5. **Drawing Sanity:** Check for overlapping vectors, duplicate entities, or unreferenced blocks.",
        sources: [sourceUserRoles, sourceFaq],
        metadata: {'category': 'TECHNICAL_REVIEW'},
      );
    }

    if (normalized.contains('identify drawing issue') ||
        normalized.contains('identify drawing problem') ||
        (normalized.contains('identify') &&
            (normalized.contains('drawing') || normalized.contains('problem') || normalized.contains('issue')))) {
      return const PixmintEngineAnswer(
        content:
            "### 🔎 Identifying CAD Drawing Issues & Conflicts\n\n"
            "1. **Layer Conflicts:** Toggle layer visibility in the CAD viewer to find geometry drawn on incorrect or frozen layers.\n"
            "2. **Coordinate & Scale Verification:** Use the measurement tool to verify known dimensions and drawing scale (e.g. 1:100, 1:50).\n"
            "3. **Structural Clashes:** Compare architectural floor plans with structural column and beam framing grids.\n"
            "4. **Annotation Gaps:** Flag unlabelled rooms, missing door/window tags, or incomplete elevation levels.\n"
            "5. **Unresolved Redlines:** Check the sidebar to ensure pins from previous revision cycles were fully corrected.",
        sources: [sourceCoreWorkflow, sourceDataArch],
        metadata: {'category': 'DRAWING_INSPECTION'},
      );
    }

    if (normalized.contains('coordinate drawing revision') ||
        (normalized.contains('coordinate') && normalized.contains('revision'))) {
      return const PixmintEngineAnswer(
        content:
            "### 🔄 Coordinating Drawing Revisions\n\n"
            "1. **Consolidate Review Pins:** Review all open redline pins placed by yourself and the client.\n"
            "2. **Issue Revision Request:** Click **'Request Correction'** to increment the project revision cycle (`UNDER_REVIEW` → `REVISION_REQUESTED`).\n"
            "3. **Draughtsman Resubmission:** The assigned draughtsman updates the CAD model, marks pins resolved, and uploads the incremented sheet (`v1.1`).\n"
            "4. **Re-Inspection:** Verify that resubmitted sheets address all flagged items.\n"
            "5. **Sign-Off:** Once verified, conclude technical review so the client can issue final approval.",
        sources: [sourceCoreWorkflow, sourceUserRoles],
        metadata: {'category': 'COORDINATION'},
      );
    }

    if ((normalized.contains('drawing') || normalized.contains('viewer')) &&
        (normalized.contains('fail to load') ||
            normalized.contains('fails to load') ||
            normalized.contains('will not load') ||
            normalized.contains('cannot load'))) {
      return const PixmintEngineAnswer(
        content:
            "### 🛠️ Troubleshooting Drawing Loading Failures\n\n"
            "1. **Enable WebGL / Hardware Acceleration:** Ensure WebGL is enabled in your browser settings (Chrome: `chrome://settings/system`).\n"
            "2. **Check File Size Limit:** Ensure uploaded CAD files do not exceed **50MB**.\n"
            "3. **Clean CAD Drawing:** In AutoCAD, run `PURGE` (Purge All) and `AUDIT` (Fix Errors = Yes) before re-exporting.\n"
            "4. **Browser Cache & Refresh:** Hard refresh using `Ctrl + F5` (Windows) or `Cmd + Shift + R` (Mac).\n"
            "5. **Fallback Export:** If `.dwg` fails to render, upload a high-resolution vector `.pdf` version.",
        sources: [sourceFaq, sourceDataArch],
        metadata: {'category': 'TROUBLESHOOTING'},
      );
    }

    if (normalized.contains('resolve a review problem') ||
        (normalized.contains('resolve') &&
            normalized.contains('review') &&
            normalized.contains('problem'))) {
      return const PixmintEngineAnswer(
        content:
            "### 🔧 Resolving Technical Review Problems & Delays\n\n"
            "1. **Unclear Redlines:** Open the pin discussion thread in the Web CAD viewer to request clarification from the author.\n"
            "2. **Conflicting Feedback:** Coordinate with the client or Studio Admin via project remarks before requesting CAD modifications.\n"
            "3. **Stalled Draughtsman Resubmission:** Check assignment status under **Projects**; contact Admin Dispatch if re-assignment is needed.\n"
            "4. **Technical Errors:** If viewer pins fail to save, refresh your session to renew your Firebase authorization token.",
        sources: [sourceUserRoles, sourceFaq],
        metadata: {'category': 'TROUBLESHOOTING'},
      );
    }

    if (normalized.contains('what can pixmint bot help me with') ||
        normalized.contains('what can you help me with') ||
        normalized == 'what can pixmint bot help me with') {
      return const PixmintEngineAnswer(
        content:
            "### 🤖 What PIXMINT BOT Can Help You With\n\n"
            "I'm **PIXMINT BOT**, your intelligent AI guide for Archi Draft! I can assist you with:\n\n"
            "• **Technical Reviews:** Step-by-step drawing inspection, redline markups, and revision coordination.\n"
            "• **CAD Standards:** AIA & ISO 128 layer conventions, file formats (`.dwg`, `.dxf`, `.pdf`), and 50MB upload limits.\n"
            "• **Workflows & Roles:** Verified role permissions for Engineers, Draughtsmen, Students, and Admins.\n"
            "• **Troubleshooting:** Resolving viewer loading errors, upload issues, and network connectivity.\n\n"
            "Ask me any question or tap a suggestion chip to get started!",
        sources: [sourceCoreWorkflow, sourceUserRoles],
        metadata: {'category': 'IDENTITY'},
      );
    }

    // ── Draughtsman Portal Questions ──────────────────────────────────────
    if (normalized.contains('view my assignment') ||
        normalized.contains('view assignment') ||
        (normalized.contains('view') &&
            normalized.contains('assignment') &&
            role == BotUserRole.draughtsman)) {
      return const PixmintEngineAnswer(
        content:
            "### 📂 Viewing Your Draughtsman Assignments\n\n"
            "1. **Open the Draughtsman Portal:** Navigate to your **Assignments** dashboard.\n"
            "2. **Filter by Status:** Switch between **New (Assigned)**, **In Progress**, **Under Review**, and **Completed**.\n"
            "3. **Inspect Project Scope:** Click an assignment card to view the architectural brief, site documents, required drawings, and deadline.\n"
            "4. **Review Client Notes:** Check the project notes tab for initial client instructions.",
        sources: [sourceUserRoles, sourceDataArch],
        metadata: {'category': 'ASSIGNMENTS'},
      );
    }

    if (normalized.contains('accept an assignment') ||
        normalized.contains('accept assignment') ||
        (normalized.contains('accept') && normalized.contains('assignment'))) {
      return const PixmintEngineAnswer(
        content:
            "### 🤝 Accepting a Project Assignment\n\n"
            "1. Navigate to **Assignments** and select the project in `ASSIGNED` status.\n"
            "2. Carefully review the deliverables list, area scope, and brief files.\n"
            "3. Click **'Accept Assignment'** at the top right of the project panel.\n"
            "4. The project state transitions from `ASSIGNED` to `IN_PROGRESS`, unlocking drawing upload and CAD workspace tools.",
        sources: [sourceCoreWorkflow, sourceUserRoles],
        metadata: {'category': 'ASSIGNMENTS'},
      );
    }

    if (normalized.contains('which drawing format') ||
        normalized.contains('drawing formats are supported') ||
        normalized.contains('supported drawing format') ||
        (normalized.contains('drawing format') && normalized.contains('supported'))) {
      return const PixmintEngineAnswer(
        content:
            "### 📐 Supported CAD File Formats & Size Limits\n\n"
            "Archi Draft supports the following formats for drawing submissions:\n\n"
            "• **AutoCAD Drawing (.dwg):** AutoCAD 2018 or newer format.\n"
            "• **Drawing Exchange Format (.dxf):** Standard ASCII format.\n"
            "• **Vector PDF (.pdf):** High-resolution 300 DPI vector export with embedded fonts.\n"
            "• **File Size Limit:** Up to **50MB** per drawing sheet.\n\n"
            "Always run `PURGE` and `AUDIT` in your CAD software prior to export to eliminate unreferenced layers and blocks.",
        sources: [sourceDataArch, sourceFaq],
        metadata: {'category': 'CAD_STANDARDS'},
      );
    }

    if (normalized.contains('submit a revised drawing') ||
        normalized.contains('submit revised drawing') ||
        (normalized.contains('submit') &&
            (normalized.contains('revised') || normalized.contains('revision')) &&
            normalized.contains('drawing'))) {
      return const PixmintEngineAnswer(
        content:
            "### 🔄 Submitting Revised Drawings (Revision Workflow)\n\n"
            "1. Open the project when status is `REVISION_REQUESTED`.\n"
            "2. Inspect the redline pins placed by the Engineer or Client in the Web CAD viewer.\n"
            "3. Update your drawing in your drafting software, incrementing the version (e.g. `v1.0` → `v1.1`).\n"
            "4. Click **'Upload Revision'**, select the updated file, and enter a changelog summary.\n"
            "5. Mark addressed redline pins as resolved and click **'Resubmit for Review'**.",
        sources: [sourceCoreWorkflow, sourceDataArch],
        metadata: {'category': 'REVISION_WORKFLOW'},
      );
    }

    if (normalized.contains('resolve redline comment') ||
        normalized.contains('resolve revision comment') ||
        (normalized.contains('resolve') &&
            (normalized.contains('redline') ||
                normalized.contains('revision') ||
                normalized.contains('comment') ||
                normalized.contains('pin')))) {
      return const PixmintEngineAnswer(
        content:
            "### 📍 Resolving Redline Comments & Markup Pins\n\n"
            "1. Open the drawing in the **Web CAD Viewer**.\n"
            "2. Click each redline pin in the sidebar list to center the view on the flagged geometry.\n"
            "3. Read the feedback remarks (e.g., dimension fixes, wall alignment, door swing corrections).\n"
            "4. Apply the modifications in your CAD drafting model.\n"
            "5. In the viewer, click **'Mark as Resolved'** on each corrected pin, then upload the revision.",
        sources: [sourceCoreWorkflow, sourceUserRoles],
        metadata: {'category': 'REVISION_WORKFLOW'},
      );
    }

    if ((normalized.contains('upload') || normalized.contains('uploading')) &&
        (normalized.contains('fail') ||
            normalized.contains('error') ||
            normalized.contains('fails'))) {
      return const PixmintEngineAnswer(
        content:
            "### ⚠️ Troubleshooting Upload Failures\n\n"
            "1. **File Size Check:** Ensure the file is strictly under **50MB**.\n"
            "2. **CAD Drawing Cleanup:** In AutoCAD, run `PURGE` (Purge All) and `AUDIT` (Fix errors: Yes).\n"
            "3. **Close File in CAD Software:** Ensure AutoCAD or your drafting tool has released the file lock.\n"
            "4. **Supported Format:** Confirm the file is `.dwg` (2018+), `.dxf`, or vector `.pdf`.\n"
            "5. **Network Connection:** If upload times out, check your connection and retry.",
        sources: [sourceFaq, sourceDataArch],
        metadata: {'category': 'TROUBLESHOOTING'},
      );
    }

    if (normalized.contains('check my submission status') ||
        normalized.contains('check submission status') ||
        (normalized.contains('submission') && normalized.contains('status'))) {
      return const PixmintEngineAnswer(
        content:
            "### 📊 Checking Your Submission Status\n\n"
            "1. Open **Assignments** in the Draughtsman Portal.\n"
            "2. Locate the project card to view its current lifecycle badge:\n"
            "   • **IN_PROGRESS:** Active drafting phase.\n"
            "   • **UNDER_REVIEW:** Submitted to Engineer and Client for technical review.\n"
            "   • **REVISION_REQUESTED:** Redline pins placed; revision upload required.\n"
            "   • **APPROVED:** Final sign-off complete; milestone deliverable accepted.\n"
            "3. Click **'Audit Log & History'** to see recent review actions and timestamps.",
        sources: [sourceCoreWorkflow, sourceDataArch],
        metadata: {'category': 'SUBMISSION_STATUS'},
      );
    }

    // ── Student Portal Questions ──────────────────────────────────────────
    if (normalized.contains('access my training module') ||
        normalized.contains('access training module') ||
        (normalized.contains('access') && normalized.contains('module'))) {
      return const PixmintEngineAnswer(
        content:
            "### 🎓 Accessing Archi Draft Academy Training Modules\n\n"
            "1. Log in to the **Student Portal**.\n"
            "2. Navigate to **Training Modules** from the main navigation menu.\n"
            "3. Browse the **12-Module Progressive Curriculum** (Module 1: CAD Foundations through Module 12: BIM & Construction Documentation).\n"
            "4. Click on your active module to view lessons, video tutorials, and reference documentation.",
        sources: [sourceUserRoles, sourceFaq],
        metadata: {'category': 'STUDENT_LEARNING'},
      );
    }

    if (normalized.contains('practical exercise') ||
        (normalized.contains('where') && normalized.contains('exercise'))) {
      return const PixmintEngineAnswer(
        content:
            "### 📐 Finding Practical Drafting Exercises\n\n"
            "1. In the Student Portal, open your current active **Training Module**.\n"
            "2. Click the **'Practical Exercises'** tab within the module view.\n"
            "3. Download the starter exercise package:\n"
            "   • **Project Brief & Requirements PDF**\n"
            "   • **Base CAD Template (.dwg / .dxf)**\n"
            "   • **Layer standards guide (AIA / ISO 128)**\n"
            "4. Complete the exercise drafting in your CAD software according to the brief rubric.",
        sources: [sourceUserRoles, sourceFaq],
        metadata: {'category': 'STUDENT_LEARNING'},
      );
    }

    if (normalized.contains('submit an exercise') ||
        normalized.contains('submit exercise') ||
        (normalized.contains('submit') && normalized.contains('exercise'))) {
      return const PixmintEngineAnswer(
        content:
            "### 📤 Submitting a Practical Training Exercise\n\n"
            "1. Complete the assignment in your CAD software following AIA/ISO 128 standards.\n"
            "2. Export your drawing as `.dwg` (AutoCAD 2018+) or vector `.pdf` (under 50MB).\n"
            "3. Return to the exercise page under **Training Modules > [Module Name] > Exercises**.\n"
            "4. Click **'Submit Assignment'** and select your drawing file.\n"
            "5. Add any optional student comments and click **'Confirm Submission'** for mentor evaluation.",
        sources: [sourceUserRoles, sourceFaq],
        metadata: {'category': 'STUDENT_LEARNING'},
      );
    }

    if (normalized.contains('view my evaluation') ||
        normalized.contains('view evaluation') ||
        (normalized.contains('view') && normalized.contains('evaluation')) ||
        (normalized.contains('where') && normalized.contains('evaluation'))) {
      return const PixmintEngineAnswer(
        content:
            "### 📊 Viewing Your Mentor Evaluations & Grades\n\n"
            "1. In the Student Portal, open **Evaluations & Grades**.\n"
            "2. Click on any evaluated exercise to view:\n"
            "   • **Overall Score** (percentage grade; minimum 80% required to pass)\n"
            "   • **Rubric Breakdown:** Layer discipline (25%), dimensional accuracy (25%), detail completeness (25%), and brief compliance (25%)\n"
            "   • **Mentor Feedback:** Redline markups and constructive notes on your submitted drawing sheet.",
        sources: [sourceUserRoles, sourceFaq],
        metadata: {'category': 'STUDENT_EVALUATION'},
      );
    }

    if (normalized.contains('understand mentor feedback') ||
        normalized.contains('mentor feedback') ||
        (normalized.contains('mentor') && normalized.contains('feedback'))) {
      return const PixmintEngineAnswer(
        content:
            "### 💡 Understanding Mentor Feedback & Rubric Notes\n\n"
            "1. **Interactive Viewer Redlines:** Open your evaluated drawing in the student viewer to inspect mentor annotation pins.\n"
            "2. **Rubric Categories:**\n"
            "   • **Layer Standards:** Using required naming (`A-WALL-FULL`, `A-DOOR-IDEN`) and line weights.\n"
            "   • **Accuracy:** Dimensional closures, alignment to structural grids, and scale accuracy.\n"
            "   • **Annotations:** Clean text styles, leader callouts, and door/window schedule tags.\n"
            "3. **Revision Option:** If your score is under 80%, revise the drawing based on the remarks and re-submit.",
        sources: [sourceUserRoles, sourceFaq],
        metadata: {'category': 'STUDENT_FEEDBACK'},
      );
    }

    if (normalized.contains('verify my certificate') ||
        normalized.contains('verify certificate') ||
        (normalized.contains('verify') && normalized.contains('certificate'))) {
      return const PixmintEngineAnswer(
        content:
            "### 📜 Verifying Your Archi Draft Certificate of Completion\n\n"
            "1. **Certificate Eligibility:** Complete all 12 academy modules and pass all practical exercises with an 80%+ score.\n"
            "2. **Digital Certificate:** Go to **My Profile > Certificates** to view your credential.\n"
            "3. **Public Verification Hash:** Each certificate contains a unique **SHA-256 cryptographic verification hash**.\n"
            "4. **Public Verification Portal:** Anyone can verify certificate authenticity at:\n"
            "   `https://archidraft.com/verify/[CERT-HASH]`.",
        sources: [sourceUserRoles, sourceFaq],
        metadata: {'category': 'CERTIFICATES'},
      );
    }

    if (normalized.contains('lesson will not open') ||
        normalized.contains('lesson not open') ||
        (normalized.contains('lesson') &&
            (normalized.contains('not open') || normalized.contains('fail')))) {
      return const PixmintEngineAnswer(
        content:
            "### 🛠️ Troubleshooting Lesson & Module Opening Issues\n\n"
            "1. **Session Refresh:** Sign out and sign back in to refresh your student authorization token.\n"
            "2. **Browser Cache:** Perform a hard refresh (`Ctrl + F5` or `Cmd + Shift + R`) or clear browser cache.\n"
            "3. **Check Prerequisites:** Some advanced modules unlock only after passing earlier module exercises with 80%+.\n"
            "4. **Supported Browsers:** Use the latest Google Chrome, Mozilla Firefox, or Microsoft Edge with WebGL enabled.\n"
            "5. **Contact Academy Support:** If problems persist, email `pixelmintstudiomvs@gmail.com`.",
        sources: [sourceFaq],
        metadata: {'category': 'TROUBLESHOOTING'},
      );
    }

    if (normalized.contains('help me learn') ||
        normalized.contains('what can pixmint bot help me learn')) {
      return const PixmintEngineAnswer(
        content:
            "### 🎓 What PIXMINT BOT Can Help You Learn\n\n"
            "As your intelligent Academy guide, PIXMINT BOT assists you with:\n\n"
            "• **Drafting Standards:** AIA & ISO 128 layer naming, line weights, and scale factors.\n"
            "• **Curriculum Guidance:** Navigating the 12 academy training modules and prerequisites.\n"
            "• **Exercise Submissions:** Step-by-step submission steps, supported CAD formats, and 50MB file limits.\n"
            "• **Evaluation Rubrics:** Understanding mentor scoring criteria and passing thresholds (80%+).\n"
            "• **Troubleshooting:** Resolving CAD drawing and portal issues.",
        sources: [sourceUserRoles, sourceFaq],
        metadata: {'category': 'STUDENT_LEARNING'},
      );
    }

    // ── Admin Portal Questions (Server-authorized Admin role only) ─────────
    if (role == BotUserRole.admin) {
      if (normalized.contains('manage approved knowledge') ||
          (normalized.contains('knowledge source') && normalized.contains('manage'))) {
        return const PixmintEngineAnswer(
          content:
              "### 📚 Managing Approved Knowledge Sources (Admin Portal)\n\n"
              "1. In the Admin Portal, open the **PIXMINT BOT Control Center**.\n"
              "2. Select the **'Knowledge Base'** tab.\n"
              "3. Review the verified knowledge inventory indexed against `schemas/qa-record.schema.json` and `source-register.csv`.\n"
              "4. Filter records by role (`engineer`, `draughtsman`, `student`, `admin`, `general`).\n"
              "5. Click **'Validate Knowledge'** to execute automated integrity checks across documentation sources.",
          sources: [sourceUserRoles, sourceDataArch],
          metadata: {'category': 'ADMIN_KNOWLEDGE'},
        );
      }

      if (normalized.contains('update suggested question') ||
          (normalized.contains('suggested question') && normalized.contains('update'))) {
        return const PixmintEngineAnswer(
          content:
              "### 💬 Updating Predefined Question Chips (Admin Portal)\n\n"
              "1. Open **PIXMINT BOT Control Center** in the authorized Admin Portal.\n"
              "2. Navigate to the **'Predefined Questions'** tab.\n"
              "3. Select the target portal: **Engineer**, **Draughtsman**, **Student**, or **Admin**.\n"
              "4. Toggle questions between **Enabled** and **Disabled** to control instant chip visibility in portal panels.\n"
              "5. Click **'Save Configuration'** to distribute updates securely to the Cloudflare Worker.",
          sources: [sourceUserRoles, sourceDataArch],
          metadata: {'category': 'ADMIN_CONFIG'},
        );
      }

      if (normalized.contains('check bot service status') ||
          (normalized.contains('service status') && normalized.contains('bot'))) {
        return const PixmintEngineAnswer(
          content:
              "### ⚡ Checking PIXMINT BOT Service Status (Admin Portal)\n\n"
              "1. Open **PIXMINT BOT Control Center** and go to the **'Overview'** tab.\n"
              "2. **Bot Availability:** Verify whether the assistant service is `Active` or in `Maintenance Mode`.\n"
              "3. **Worker Runtime:** Monitor edge latency (average response time in milliseconds) and uptime percentage.\n"
              "4. **Model Provider:** Inspect the active execution adapter (Local Grounded Engine vs. Cloudflare Worker AI Provider).",
          sources: [sourceUserRoles, sourceDataArch],
          metadata: {'category': 'ADMIN_MONITORING'},
        );
      }

      if (normalized.contains('unanswered question') ||
          (normalized.contains('unanswered') && normalized.contains('review'))) {
        return const PixmintEngineAnswer(
          content:
              "### ❓ Reviewing Unanswered & Fallback Questions (Admin Portal)\n\n"
              "1. Open **PIXMINT BOT Control Center** and navigate to the **'Feedback Review'** tab.\n"
              "2. Review queries that triggered fallback responses (`metadata.category == 'FALLBACK'`) or thumbs-down ratings.\n"
              "3. Identify knowledge base gaps in architectural workflows or student curriculum.\n"
              "4. Draft new verified Q&A records and link authoritative documentation sources in `ARCHI-DRAFT-KNOWLEDGE-BASE`.",
          sources: [sourceUserRoles, sourceDataArch],
          metadata: {'category': 'ADMIN_FEEDBACK'},
        );
      }

      if (normalized.contains('usage and error metric') ||
          normalized.contains('usage and error metrics') ||
          (normalized.contains('metric') && normalized.contains('usage'))) {
        return const PixmintEngineAnswer(
          content:
              "### 📈 Reviewing PIXMINT BOT Usage & Telemetry Metrics (Admin Portal)\n\n"
              "1. Open **PIXMINT BOT Control Center > Overview / Telemetry**.\n"
              "2. **Total Conversations:** Review total queries handled across Engineer, Draughtsman, Student, and Admin portals.\n"
              "3. **Role Distribution:** Inspect active user query share across supported roles.\n"
              "4. **Error & Fallback Rate:** Monitor delivery failure percentages and network timeouts.\n"
              "5. Note: Telemetry records contain zero PII or drawing content; metrics are aggregated at the server layer.",
          sources: [sourceUserRoles, sourceDataArch],
          metadata: {'category': 'ADMIN_METRICS'},
        );
      }

      if (normalized.contains('manage bot availability') ||
          (normalized.contains('availability') && normalized.contains('manage'))) {
        return const PixmintEngineAnswer(
          content:
              "### 🛡️ Managing Bot Availability & Maintenance Mode (Admin Portal)\n\n"
              "1. In the **PIXMINT BOT Control Center**, go to **'Bot Configuration'**.\n"
              "2. **Master Switch:** Toggle **'PIXMINT BOT Enabled'** to turn the chatbot on or off globally across all portals.\n"
              "3. **Maintenance Mode:** Enable maintenance mode during scheduled system upgrades to display an announcement banner.\n"
              "4. **Rate Limiting:** Adjust maximum queries allowed per session to protect system resources.\n"
              "5. Changes require authenticated admin privileges and are logged to the security audit trail.",
          sources: [sourceUserRoles, sourceDataArch],
          metadata: {'category': 'ADMIN_CONFIG'},
        );
      }

      if (normalized.contains('review configuration change') ||
          (normalized.contains('configuration change') && normalized.contains('review'))) {
        return const PixmintEngineAnswer(
          content:
              "### 🔒 Reviewing Security & Configuration Audit Logs (Admin Portal)\n\n"
              "1. Open **PIXMINT BOT Control Center** and select the **'Security Audit Log'** tab.\n"
              "2. Inspect immutable timestamped records for:\n"
              "   • Bot availability toggles and maintenance mode switches\n"
              "   • Knowledge base additions and source validations\n"
              "   • Predefined question availability updates\n"
              "   • Admin role authorizations and token verifications\n"
              "3. Each entry records the administrator's Firebase UID, IP hash, action type, and exact timestamp.",
          sources: [sourceUserRoles, sourceDataArch],
          metadata: {'category': 'ADMIN_AUDIT'},
        );
      }
    }

    return null;
  }

  // ── 15a. General CAD & Architecture Intelligence ──────────────────────────

  static PixmintEngineAnswer? _handleGeneralCadConcepts(String normalized, BotUserRole role) {
    // 1. DWG vs DXF Format Comparison
    if (normalized.contains('dwg') && normalized.contains('dxf')) {
      return const PixmintEngineAnswer(
        content:
            "### Comparison: DWG (.dwg) vs. DXF (.dxf) Formats\n\n"
            "| Feature | DWG (.dwg) | DXF (.dxf) |\n"
            "|---|---|---|\n"
            "| **Full Name** | AutoCAD Drawing Database | Drawing Exchange Format |\n"
            "| **Structure** | Native binary (compact, highly efficient) | Open ASCII/text-based vector specification |\n"
            "| **Primary Purpose** | Production drafting, complex xrefs, blocks | Interoperability between different CAD/BIM tools |\n"
            "| **File Size** | Smaller file footprint | Larger file footprint (plain-text geometry) |\n\n"
            "**In Archi Draft:**\n"
            "Both AutoCAD DWG (Release 2013–2024) and ASCII DXF files are fully supported up to **50MB** per sheet. DWG is recommended for regular production uploads to minimize transmission times and retain full layer metadata.",
        sources: [sourceFaq, sourceDataArch],
        metadata: {'category': 'CAD_COMPARISON'},
      );
    }

    // 2. Engineer vs. Draughtsman Comparison
    if (normalized.contains('engineer') &&
        normalized.contains('draughtsman') &&
        (normalized.contains('difference') ||
            normalized.contains('between') ||
            normalized.contains('compare') ||
            normalized.contains('versus') ||
            normalized.contains('vs'))) {
      return const PixmintEngineAnswer(
        content:
            "### Role Comparison: Engineer vs. Draughtsman in Archi Draft\n\n"
            "| Aspect | Engineer Portal | Draughtsman Portal |\n"
            "|---|---|---|\n"
            "| **Primary Focus** | Technical review, code compliance, redlines | CAD drawing production, layer standards, revisions |\n"
            "| **Permitted Actions** | Place redline pins, verify dimensions, clash overlay | Accept tasks, upload DWG/DXF/PDF, resolve comments |\n"
            "| **Submission Type** | Technical Review Status (Approved / Revise) | Drawing Submission (initial or Rev A/B/C) |\n"
            "| **Limitations** | Cannot approve final commercial signoff | Cannot approve final drawing sheets |\n\n"
            "Both roles collaborate tightly: draughtsmen upload drawings and address redlines, while engineers conduct technical reviews before client delivery.",
        sources: [sourceUserRoles, sourceCoreWorkflow],
        metadata: {'category': 'ROLE_COMPARISON'},
      );
    }

    // 3. What is BIM?
    if (normalized.contains('what is bim') ||
        normalized.contains('building information modeling') ||
        normalized.contains('bim vs cad')) {
      return const PixmintEngineAnswer(
        content:
            "**General Architectural Knowledge: Building Information Modeling (BIM)**\n\n"
            "BIM is an intelligent 3D model-based process that equips architecture, engineering, and construction (AEC) professionals with the insight and tools to plan, design, construct, and manage buildings.\n\n"
            "**How Archi Draft Fits In:**\n"
            "While BIM platforms model 3D parametric assets, Archi Draft focuses on the mission-critical 2D production drawings, sheet sets, and coordination layers (Architectural, Structural, MEP). Archi Draft validates DWG/DXF geometry, manages revision pin cycles, and coordinates clash detection between disciplines.",
        sources: [sourceCoreWorkflow],
        metadata: {'category': 'GENERAL_CAD'},
      );
    }

    // 4. CAD Layer Standards
    if (normalized.contains('layers in cad') ||
        normalized.contains('cad layer') ||
        normalized.contains('layer standard') ||
        normalized.contains('iso 13567') ||
        normalized.contains('aia layer')) {
      return const PixmintEngineAnswer(
        content:
            "**CAD Layer Standards in Archi Draft:**\n\n"
            "Archi Draft follows standardized layering conventions (AIA CAD Layer Guidelines and ISO 13567):\n"
            "• **Naming Conventions:** Layers must follow `<Discipline>-<Major>-<Minor>` (e.g. `A-WALL-FULL`, `S-COLS-BEAM`, `M-HVAC-DUCT`).\n"
            "• **Standard Colors & Weights:** Enforce consistent lineweights across all sheets.\n"
            "• **Hygiene Rule:** Always run `AUDIT` and `PURGE` before uploading to remove unused block definitions and non-standard auxiliary layers.\n\n"
            "Drawings with clean layer hierarchies render faster in the Archi Draft web drawing viewer.",
        sources: [sourceDataArch, sourceFaq],
        metadata: {'category': 'CAD_LAYERS'},
      );
    }

    return null;
  }

  // ── 15b. Role-Filtered Dynamic Knowledge Retrieval ────────────────────────

  static PixmintEngineAnswer? _searchEmbeddedKnowledge(String normalized, BotUserRole role) {
    // 1. Unseen questions about where to submit files or upload failures
    if (normalized.contains('where can i submit') ||
        normalized.contains('where to submit') ||
        normalized.contains('my dwg is not going through') ||
        normalized.contains('my dwg is not uploading') ||
        normalized.contains('dwg not going through') ||
        normalized.contains('why does it keep failing') ||
        normalized.contains('why it keeps failing')) {
      return const PixmintEngineAnswer(
        content:
            "### 📤 Submitting Drawing Files in Archi Draft\n\n"
            "To submit your drawing file:\n"
            "1. Open your assigned project sheet from the **Assignments** or **Projects** dashboard.\n"
            "2. Ensure your file is saved as AutoCAD `.dwg`, `.dxf`, or vector `.pdf` and is strictly under **50MB**.\n"
            "3. If the file is failing to upload, run `PURGE` and `AUDIT` in CAD to remove orphaned entities, and close CAD software to release file locks.\n"
            "4. Drag and drop the file into the upload zone and click **Submit Drawing**.\n\n"
            "Once submitted, the sheet status updates to *Under Technical Review*.",
        sources: [sourceDataArch, sourceFaq],
        metadata: {'category': 'DYNAMIC_SUBMISSION'},
      );
    }

    // 2. Unseen questions about technical inspection / review checklist
    if (normalized.contains('what should i check during technical review') ||
        normalized.contains('technical review checklist') ||
        normalized.contains('what to check during review')) {
      return const PixmintEngineAnswer(
        content:
            "### 🔍 Technical Review Checklist (Engineer Portal)\n\n"
            "During technical review in Archi Draft, check:\n"
            "1. **Dimensional Accuracy:** Verify grid offsets, room spans, and dimension chain totals.\n"
            "2. **Interdisciplinary Coordination:** Overlay architectural and structural sheets to check for column/wall clashes.\n"
            "3. **Layer Standards:** Ensure drawing adheres to AIA/ISO standards and non-standard layers are eliminated.\n"
            "4. **Title Block & Revision:** Verify project name, drawing number, scale, and revision letter.\n"
            "5. **Clear Redline Markups:** If revisions are required, use Callout pins and specify exact modifications before clicking *Revise & Resubmit*.",
        sources: [sourceCoreWorkflow, sourceUserRoles],
        metadata: {'category': 'DYNAMIC_REVIEW'},
      );
    }

    // 3. Unseen questions about practical exercises
    if (normalized.contains('practical exercise') ||
        normalized.contains('homework') ||
        normalized.contains('cad exercise')) {
      return const PixmintEngineAnswer(
        content:
            "### 📐 Practical Exercises (Student Portal)\n\n"
            "Practical CAD exercises in Archi Draft:\n"
            "1. Navigate to the **Student Academy** and select your current module.\n"
            "2. Download the exercise starter template `.dwg` file.\n"
            "3. Complete drafting requirements adhering to the lesson prompt.\n"
            "4. Click **Submit Exercise** before the module deadline to receive mentor review.\n"
            "5. An evaluation score of **80% or higher** is required to unlock subsequent modules.",
        sources: [sourceFaq],
        metadata: {'category': 'DYNAMIC_STUDENT'},
      );
    }

    // 4. Unseen questions about mentor feedback
    if (normalized.contains('mentor feedback') ||
        normalized.contains('evaluation feedback') ||
        normalized.contains('understand mentor feedback')) {
      return const PixmintEngineAnswer(
        content:
            "### 📝 Understanding Mentor Feedback (Student Portal)\n\n"
            "Mentor feedback is delivered directly through your evaluated submission:\n"
            "• **Rubric Pillars:** Evaluated on Precision (dimensions), Layer Discipline, Drafting Speed, and Annotation Clarity.\n"
            "• **Visual Annotations:** Mentors place redline pins directly over your submitted DWG file with corrective notes.\n"
            "• **Score Breakdown:** Scores of 80%+ grant module pass credit. If revision is requested, address mentor pins and resubmit.",
        sources: [sourceFaq],
        metadata: {'category': 'DYNAMIC_FEEDBACK'},
      );
    }

    // 5. Unseen questions about certificate verification
    if (normalized.contains('verify certificate') ||
        normalized.contains('certificate verification') ||
        normalized.contains('graduation certificate')) {
      return const PixmintEngineAnswer(
        content:
            "### 🎓 Certificate Verification (Student Portal)\n\n"
            "Archi Draft issues official PixelMint Studio MVS certificates upon completing all 12 academy modules with an aggregate score of 80%+:\n"
            "• Each certificate features a unique cryptographic verification ID.\n"
            "• Employers and academic institutions can verify certificate authenticity at `verify.pixelmint.studio`.\n"
            "• Digital PDF certificates can be downloaded from your student profile at any time.",
        sources: [sourceFaq],
        metadata: {'category': 'DYNAMIC_CERTIFICATE'},
      );
    }

    return null;
  }

  // ── 15c. Live Application Context Guidance ────────────────────────────────

  static PixmintEngineAnswer? _handleLiveAppContext(String normalized, BotUserRole role) {
    // Draughtsman asking about their assignment status
    if (role == BotUserRole.draughtsman &&
        (normalized.contains('my assignment status') ||
            normalized.contains('my assignments') ||
            normalized.contains('what are my tasks') ||
            normalized.contains('my tasks'))) {
      return const PixmintEngineAnswer(
        content:
            "### 📋 Your Draughtsman Assignments\n\n"
            "To view your live assignment queue:\n"
            "1. Click the **Assignments** tab in your navigation drawer.\n"
            "2. Review your tasks categorized by status: `Pending Acceptance`, `In Progress`, and `Under Technical Review`.\n"
            "3. Select any task to view delivery deadlines, priority tags, and attached design briefs.\n\n"
            "*Note: PIXMINT BOT provides read-only workflow guidance. Task acceptance and file uploads must be performed directly within your assignment sheet.*",
        sources: [sourceCoreWorkflow, sourceUserRoles],
        metadata: {'category': 'LIVE_APP_DRAUGHTSMAN'},
      );
    }

    // Student asking about their evaluation status
    if (role == BotUserRole.student &&
        (normalized.contains('my evaluation status') ||
            normalized.contains('my evaluation') ||
            normalized.contains('my score') ||
            normalized.contains('my grade') ||
            normalized.contains('how did i do'))) {
      return const PixmintEngineAnswer(
        content:
            "### 🎓 Your Student Evaluation Status\n\n"
            "To inspect your live evaluation results:\n"
            "1. Open the **Student Academy** portal and click the **Evaluations** tab.\n"
            "2. Select your latest module submission to view your 4-pillar score breakdown.\n"
            "3. Click **View Annotated Sheet** to inspect your mentor's redline markups.\n\n"
            "*Remember: An aggregate score of 80% or higher is required to advance to the next module.*",
        sources: [sourceFaq],
        metadata: {'category': 'LIVE_APP_STUDENT'},
      );
    }

    // Engineer asking about pending reviews
    if (role == BotUserRole.engineer &&
        ((normalized.contains('pending') && normalized.contains('review')) ||
            normalized.contains('drawings to review') ||
            normalized.contains('my review queue'))) {
      return const PixmintEngineAnswer(
        content:
            "### 🔍 Your Technical Review Queue\n\n"
            "To view drawings awaiting your review:\n"
            "1. Navigate to the **Technical Review** dashboard from the left navigation bar.\n"
            "2. Filter by discipline: Architectural, Structural, or MEP.\n"
            "3. Select a drawing sheet to launch the Drawing Viewer and begin redline inspection.",
        sources: [sourceCoreWorkflow, sourceUserRoles],
        metadata: {'category': 'LIVE_APP_ENGINEER'},
      );
    }

    return null;
  }
}

