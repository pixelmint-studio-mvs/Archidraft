/// PIXMINT BOT 2.0 — Smart AI Companion for ARCHI DRAFT.
///
/// Integrated directly into ARCHI DRAFT by PixelMint Studio MVS.
library;

// Theme
export 'theme/pixmint_bot_theme.dart';

// Domain Models & Repository Interface
export 'domain/models/bot_user_role.dart';
export 'domain/models/chat_message.dart';
export 'domain/models/chat_session.dart';
export 'domain/models/chat_suggestion.dart';
export 'domain/models/pixmint_default_suggestions.dart';
export 'domain/repositories/pixmint_bot_repository.dart';
export 'domain/engine/pixmint_knowledge_engine.dart';

// Data & Implementations
export 'data/repositories/mock_pixmint_bot_repository.dart';
export 'data/repositories/archi_draft_pixmint_bot_repository.dart';

// Riverpod Providers & Controller
export 'providers/pixmint_bot_providers.dart';
export 'providers/pixmint_chat_controller.dart';

// Presentation Widgets & Animation
export 'presentation/animation/mascot_animation_state.dart';
export 'presentation/launcher/pixmint_bot_launcher.dart';
export 'presentation/launcher/pixmint_mascot_painter.dart';
export 'presentation/widgets/pixmint_living_mascot.dart';
export 'presentation/sheet/pixmint_chat_sheet.dart';
export 'presentation/sheet/pixmint_chat_header.dart';
export 'presentation/sheet/pixmint_chat_input.dart';
export 'presentation/widgets/chat_bubble.dart';
export 'presentation/widgets/quick_action_chips.dart';
export 'presentation/widgets/typing_indicator.dart';
export 'presentation/widgets/error_retry_banner.dart';

