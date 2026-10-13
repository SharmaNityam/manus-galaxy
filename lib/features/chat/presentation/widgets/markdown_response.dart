import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as markdown;

import '../../../../core/theme/app_theme.dart';

class MarkdownResponse extends StatelessWidget {
  const MarkdownResponse({required this.data, super.key});

  final String data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final base = MarkdownStyleSheet.fromTheme(Theme.of(context));
    return MarkdownBody(
      data: data,
      selectable: true,
      softLineBreak: true,
      builders: {'pre': _CodeBlockBuilder()},
      styleSheet: base.copyWith(
        p: textTheme.bodyLarge,
        h1: textTheme.headlineMedium,
        h2: textTheme.titleLarge,
        h3: textTheme.titleMedium,
        code: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: Color(0xFF282828),
          backgroundColor: Color(0xFFECECE9),
        ),
        codeblockPadding: const EdgeInsets.all(14),
        codeblockDecoration: BoxDecoration(
          color: const Color(0xFF202124),
          borderRadius: BorderRadius.circular(14),
        ),
        blockquoteDecoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: AppTheme.secondaryText, width: 3),
          ),
        ),
        blockquotePadding: const EdgeInsets.only(left: 14),
        tableBorder: TableBorder.all(color: const Color(0xFFDDDDD8)),
        tableHead: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        tableBody: textTheme.bodyMedium,
        tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
      ),
    );
  }
}

class _CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    markdown.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final children = element.children?.whereType<markdown.Element>();
    final codeElement = children?.isNotEmpty == true ? children!.first : null;
    final languageClass = codeElement?.attributes['class'] ?? '';
    final language = languageClass.startsWith('language-')
        ? languageClass.substring('language-'.length)
        : 'Code';
    final code = element.textContent.trimRight();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF202124),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    language,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy code',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 17),
                  color: Colors.white70,
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: SelectableText(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.5,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
