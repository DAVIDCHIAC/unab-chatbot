import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/chat_message.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Burbuja de mensaje del chat con soporte de Markdown para el asistente.
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.isUser;
    final bool isError = message.isError;

    final Color background = isError
        ? const Color(0xFFFDECEC)
        : isUser
            ? AppColors.red
            : Colors.white;

    final Color foreground = isError
        ? AppColors.darkRed
        : isUser
            ? Colors.white
            : AppColors.ink;

    final BorderRadius radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isUser ? 18 : 6),
      bottomRight: Radius.circular(isUser ? 6 : 18),
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.84,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: background,
            borderRadius: radius,
            border: isUser
                ? null
                : Border.all(
                    color: isError ? AppColors.red.withValues(alpha: 0.25) : AppColors.border,
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (isError)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(Icons.error_outline, size: 18, color: AppColors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SelectableText(
                        message.content,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: AppColors.darkRed,
                        ),
                      ),
                    ),
                  ],
                )
              else if (isUser)
                SelectableText(
                  message.content,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    color: Colors.white,
                  ),
                )
              else
                MarkdownBody(
                  data: message.content,
                  selectable: true,
                  onTapLink: (String text, String? href, String title) {
                    if (href == null || href.isEmpty) return;
                    final Uri? uri = Uri.tryParse(href);
                    if (uri != null) {
                      launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                      .copyWith(
                    p: TextStyle(fontSize: 14.5, height: 1.5, color: foreground),
                    h1: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                    h2: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                    h3: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                    listBullet: TextStyle(
                      fontSize: 14.5,
                      height: 1.5,
                      color: foreground,
                    ),
                    a: const TextStyle(
                      color: AppColors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    code: TextStyle(
                      fontSize: 13,
                      backgroundColor: AppColors.background,
                      color: foreground,
                    ),
                    blockSpacing: 8,
                  ),
                ),
              if (!isUser && !isError && (message.latencyMs ?? 0) > 0) ...<Widget>[
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.bolt, size: 13, color: AppColors.muted),
                    const SizedBox(width: 3),
                    Text(
                      Formatters.latency(message.latencyMs),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
