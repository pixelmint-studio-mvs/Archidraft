import 'package:flutter/material.dart';

import '../../theme/pixmint_bot_theme.dart';

/// Text input bar for composing messages to PIXMINT BOT.
///
/// Faithfully reproduces the official chat mockup:
/// - Dark rounded capsule container
/// - "Ask a question..." placeholder
/// - Vibrant mint-emerald send button with dark arrow
class PixmintChatInput extends StatefulWidget {
  final ValueChanged<String> onSend;
  final bool isThinking;
  final int maxLength;
  final bool enabled;

  const PixmintChatInput({
    super.key,
    required this.onSend,
    this.isThinking = false,
    this.maxLength = 1000,
    this.enabled = true,
  });

  @override
  State<PixmintChatInput> createState() => _PixmintChatInputState();
}

class _PixmintChatInputState extends State<PixmintChatInput> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant PixmintChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isThinking && !widget.isThinking) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.enabled) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  void _onTextChanged() {
    setState(() {
      _charCount = _textController.text.length;
    });
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty || widget.isThinking || !widget.enabled) return;

    widget.onSend(text);
    _textController.clear();
    _charCount = 0;
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEffectiveEnabled = widget.enabled && !widget.isThinking;
    final canSend = _charCount > 0 && isEffectiveEnabled;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PixmintBotTheme.spacingMd,
        vertical: PixmintBotTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: PixmintBotTheme.surfaceCard,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Input Capsule with explicit contrasting colors
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (widget.enabled) {
                        _focusNode.requestFocus();
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: PixmintBotTheme.composerBackground, // #081824 Dark navy capsule
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _focusNode.hasFocus
                              ? PixmintBotTheme.composerBorderFocused // #00D6A0 Emerald glow
                              : Colors.white.withValues(alpha: 0.12),
                          width: 1.2,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          textSelectionTheme: const TextSelectionThemeData(
                            cursorColor: PixmintBotTheme.composerCursor, // #00D6A0
                            selectionColor: PixmintBotTheme.composerSelection, // #3300D6A0
                            selectionHandleColor: PixmintBotTheme.composerCursor, // #00D6A0
                          ),
                        ),
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          enabled: widget.enabled,
                          maxLines: 4,
                          minLines: 1,
                          maxLength: widget.maxLength,
                          textInputAction: TextInputAction.send,
                          cursorColor: PixmintBotTheme.composerCursor, // #00D6A0
                          cursorWidth: 2.0,
                          cursorRadius: const Radius.circular(2.0),
                          keyboardType: TextInputType.multiline,
                          buildCounter: (
                            _, {
                            required currentLength,
                            required isFocused,
                            maxLength,
                          }) =>
                              null,
                          style: const TextStyle(
                            color: PixmintBotTheme.composerText, // #F8FAFC Crisp white text
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.1,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: PixmintBotTheme.composerBackground, // #081824 Explicit dark fill prevents global white leakage
                            hintText: 'Ask a question...',
                            hintStyle: TextStyle(
                              color: PixmintBotTheme.composerHint, // #64748B Muted grey
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: PixmintBotTheme.spacingSm),

                // Vibrant Mint Send Button (Rounded Rectangle from Mockup)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: canSend
                        ? const LinearGradient(
                            colors: [
                              Color(0xFF00F2A9),
                              Color(0xFF10B981),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: canSend ? null : const Color(0xFF162D3D),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: canSend
                        ? [
                            BoxShadow(
                              color: PixmintBotTheme.emeraldGlow.withValues(
                                alpha: 0.45,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: IconButton(
                    icon: widget.isThinking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Icon(
                            Icons.send_rounded,
                            color: canSend
                                ? const Color(0xFF07141E)
                                : const Color(0xFF64748B),
                            size: 20,
                          ),
                    onPressed: canSend ? _submit : null,
                  ),
                ),
              ],
            ),
            if (_charCount > widget.maxLength * 0.8)
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$_charCount / ${widget.maxLength}',
                    style: TextStyle(
                      color: _charCount >= widget.maxLength
                          ? PixmintBotTheme.error
                          : PixmintBotTheme.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
