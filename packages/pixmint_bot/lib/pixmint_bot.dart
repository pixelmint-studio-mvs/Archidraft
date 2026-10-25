/// PIXMINT BOT - Flutter Client Package
///
/// NOTE: This package provides the client-side presentation components
/// (`PixmintBotLauncher`, `PixmintChatSheet`, theme tokens, and Riverpod configuration providers).
///
/// LIMITATION: The current chat sheet is presentational and does not yet implement
/// the complete bidirectional AI backend communication with the Pixmint Bot service (Port 8788).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BotUserRole {
  engineer,
  draughtsman,
  student,
  admin,
}

class PixmintBotTheme {
  static const Color emerald = Color(0xFF10B981);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color surface = Color(0xFFF8FAFC);
}

class PixmintUseRemoteNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  @override
  set state(bool value) => super.state = value;
  @override
  bool get state => super.state;
}

final pixmintUseRemoteProvider =
    NotifierProvider<PixmintUseRemoteNotifier, bool>(PixmintUseRemoteNotifier.new);

class PixmintApiBaseUrlNotifier extends Notifier<String> {
  @override
  String build() => 'http://127.0.0.1:8788';

  @override
  set state(String value) => super.state = value;
  @override
  String get state => super.state;
}

final pixmintApiBaseUrlProvider =
    NotifierProvider<PixmintApiBaseUrlNotifier, String>(PixmintApiBaseUrlNotifier.new);

class PixmintAuthTokenNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  @override
  set state(String? value) => super.state = value;
  @override
  String? get state => super.state;
}

final pixmintAuthTokenProvider =
    NotifierProvider<PixmintAuthTokenNotifier, String?>(PixmintAuthTokenNotifier.new);

class PixmintBotLauncher extends StatefulWidget {
  final BotUserRole role;
  final bool animate;
  final Future<void> Function()? onCustomTap;

  const PixmintBotLauncher({
    super.key,
    required this.role,
    this.animate = true,
    this.onCustomTap,
  });

  @override
  State<PixmintBotLauncher> createState() => _PixmintBotLauncherState();
}

class _PixmintBotLauncherState extends State<PixmintBotLauncher>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.animate) {
      _animController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onCustomTap ??
            () {
              PixmintChatSheet.show(context, role: widget.role);
            },
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF0D1C32),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: PixmintBotTheme.emerald.withValues(alpha: 0.35),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: PixmintBotTheme.emerald,
              width: 1.5,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.smart_toy_rounded,
              color: PixmintBotTheme.emerald,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class PixmintChatSheet extends StatelessWidget {
  final BotUserRole role;

  const PixmintChatSheet({super.key, required this.role});

  static Future<void> show(BuildContext context, {required BotUserRole role}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PixmintChatSheet(role: role),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: PixmintBotTheme.emerald.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        color: PixmintBotTheme.emerald,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PIXMINT AI Assistant',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Role: ${role.name.toUpperCase()}',
                          style: TextStyle(
                            color: PixmintBotTheme.emerald.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.info_outline, color: PixmintBotTheme.emerald, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Assistant Connected',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'How can I help you today with your drafting specifications, projects, or calculations?',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B),
                    border: Border(top: BorderSide(color: Colors.white10)),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFCBD5E1),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Expanded(
                          child: TextField(
                            cursorColor: Colors.black,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Ask a question...',
                              hintStyle: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13.5,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_upward_rounded, color: PixmintBotTheme.emerald),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
