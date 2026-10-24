import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Renders authoritative legal Markdown documents (Terms & Conditions, Privacy Policy)
/// using the application's standard design system typography (Inter) with bold body styling.
class LegalMarkdownViewer extends StatelessWidget {
  final String markdown;
  final bool isBold;

  const LegalMarkdownViewer({
    super.key,
    required this.markdown,
    this.isBold = true,
  });

  @override
  Widget build(BuildContext context) {
    final fontWeight = isBold ? FontWeight.w700 : FontWeight.w400;
    final bodyStyle = AppTypography.bodySm.copyWith(
      fontWeight: fontWeight,
      color: AppColors.onSurface,
      height: 1.5,
    );

    final blocks = _parseBlocks(markdown);
    final widgets = <Widget>[];

    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      switch (block.type) {
        case _BlockType.h1:
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                block.content,
                style: AppTypography.headlineSmMobile.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          );
          break;
        case _BlockType.h2:
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                block.content,
                style: AppTypography.bodyMd.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          );
          break;
        case _BlockType.h3:
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Text(
                block.content,
                style: AppTypography.bodySm.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          );
          break;
        case _BlockType.divider:
          widgets.add(
            const Divider(color: AppColors.outlineVariant, height: 24, thickness: 1),
          );
          break;
        case _BlockType.blockquote:
          widgets.add(
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
                border: const Border(
                  left: BorderSide(color: AppColors.secondary, width: 3.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildBlockquoteContent(block.lines, bodyStyle),
              ),
            ),
          );
          break;
        case _BlockType.bullet:
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: bodyStyle),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: bodyStyle,
                        children: _parseInlineSpans(block.content, bodyStyle),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          break;
        case _BlockType.paragraph:
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text.rich(
                TextSpan(
                  style: bodyStyle,
                  children: _parseInlineSpans(block.lines.join('\n'), bodyStyle),
                ),
              ),
            ),
          );
          break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  List<Widget> _buildBlockquoteContent(List<String> lines, TextStyle bodyStyle) {
    final widgets = <Widget>[];
    final paraLines = <String>[];

    for (final line in lines) {
      if (line.startsWith('### ')) {
        if (paraLines.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text.rich(
                TextSpan(
                  style: bodyStyle,
                  children: _parseInlineSpans(paraLines.join('\n'), bodyStyle),
                ),
              ),
            ),
          );
          paraLines.clear();
        }
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              line.substring(4).trim(),
              style: AppTypography.bodySm.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ),
        );
      } else {
        paraLines.add(line);
      }
    }

    if (paraLines.isNotEmpty) {
      widgets.add(
        Text.rich(
          TextSpan(
            style: bodyStyle,
            children: _parseInlineSpans(paraLines.join('\n'), bodyStyle),
          ),
        ),
      );
    }

    return widgets;
  }

  List<_Block> _parseBlocks(String text) {
    final lines = text.split('\n');
    final blocks = <_Block>[];
    int i = 0;
    final n = lines.length;

    while (i < n) {
      final rawLine = lines[i];
      final line = rawLine.trim();

      if (line.isEmpty) {
        i++;
        continue;
      }

      if (line == '---') {
        blocks.add(_Block(type: _BlockType.divider, content: '---'));
        i++;
        continue;
      }

      if (line.startsWith('# ')) {
        blocks.add(_Block(type: _BlockType.h1, content: line.substring(2).trim()));
        i++;
        continue;
      }

      if (line.startsWith('## ')) {
        blocks.add(_Block(type: _BlockType.h2, content: line.substring(3).trim()));
        i++;
        continue;
      }

      if (line.startsWith('### ')) {
        blocks.add(_Block(type: _BlockType.h3, content: line.substring(4).trim()));
        i++;
        continue;
      }

      if (line.startsWith('>')) {
        final quoteLines = <String>[];
        while (i < n && lines[i].trim().isNotEmpty) {
          final cur = lines[i].trim();
          if (cur == '---' || (cur.startsWith('#') && !cur.startsWith('###'))) {
            break;
          }
          if (cur.startsWith('>')) {
            quoteLines.add(cur.substring(1).trim());
          } else {
            quoteLines.add(cur);
          }
          i++;
        }
        blocks.add(_Block(type: _BlockType.blockquote, lines: quoteLines));
        continue;
      }

      if (line.startsWith('- ')) {
        blocks.add(_Block(type: _BlockType.bullet, content: line.substring(2).trim()));
        i++;
        continue;
      }

      // Paragraph
      final paraLines = <String>[rawLine.trimRight()];
      i++;
      while (i < n && lines[i].trim().isNotEmpty) {
        final nxt = lines[i].trim();
        if (nxt == '---' || nxt.startsWith('#') || nxt.startsWith('>') || nxt.startsWith('- ')) {
          break;
        }
        paraLines.add(lines[i].trimRight());
        i++;
      }
      blocks.add(_Block(type: _BlockType.paragraph, lines: paraLines));
    }

    return blocks;
  }

  static final RegExp _inlineTokenRegex = RegExp(
    r'(\*\*(?:[^*]|\*(?!\*))+\*\*)|(`[^`]+`)|(\[[^\]]+\]\([^)]+\))',
  );

  List<InlineSpan> _parseInlineSpans(String text, TextStyle baseStyle) {
    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in _inlineTokenRegex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: baseStyle,
          ),
        );
      }

      final matchedText = match.group(0)!;
      if (matchedText.startsWith('**') && matchedText.endsWith('**')) {
        final inner = matchedText.substring(2, matchedText.length - 2);
        spans.add(
          TextSpan(
            text: inner,
            style: baseStyle.copyWith(fontWeight: FontWeight.w900),
          ),
        );
      } else if (matchedText.startsWith('`') && matchedText.endsWith('`')) {
        final inner = matchedText.substring(1, matchedText.length - 1);
        spans.add(
          TextSpan(
            text: inner,
            style: AppTypography.labelMono.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
          ),
        );
      } else if (matchedText.startsWith('[') && matchedText.contains('](')) {
        final closeBracket = matchedText.indexOf('](');
        final label = matchedText.substring(1, closeBracket);
        spans.add(
          TextSpan(
            text: label,
            style: baseStyle.copyWith(
              color: AppColors.secondary,
              decoration: TextDecoration.underline,
            ),
          ),
        );
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: baseStyle,
        ),
      );
    }

    return spans;
  }
}

enum _BlockType { h1, h2, h3, divider, blockquote, bullet, paragraph }

class _Block {
  final _BlockType type;
  final String content;
  final List<String> lines;

  _Block({
    required this.type,
    this.content = '',
    List<String>? lines,
  }) : lines = lines ?? const [];
}
