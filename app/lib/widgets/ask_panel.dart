import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../theme/app_theme.dart';
import 'message_bubble.dart';
import 'surface_card.dart';
import 'typing_indicator.dart';

/// Panel de preguntas para los asistentes de calendario y académico.
class AskPanel extends StatefulWidget {
  const AskPanel({
    super.key,
    required this.title,
    required this.hint,
    required this.messages,
    required this.sending,
    required this.onSend,
    this.icon = Icons.auto_awesome,
    this.suggestions = const <String>[],
  });

  final String title;
  final String hint;
  final List<ChatMessage> messages;
  final bool sending;
  final ValueChanged<String> onSend;
  final IconData icon;
  final List<String> suggestions;

  @override
  State<AskPanel> createState() => _AskPanelState();
}

class _AskPanelState extends State<AskPanel> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit([String? preset]) {
    final String text = (preset ?? _controller.text).trim();
    if (text.isEmpty || widget.sending) return;
    _controller.clear();
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, size: 18, color: AppColors.red),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          if (widget.messages.isEmpty && widget.suggestions.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.suggestions
                  .map(
                    (String suggestion) => ActionChip(
                      label: Text(suggestion),
                      onPressed: widget.sending ? null : () => _submit(suggestion),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.border),
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        color: AppColors.ink,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (widget.messages.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            ...widget.messages.map(
              (ChatMessage message) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MessageBubble(message: message),
              ),
            ),
          ],
          if (widget.sending) ...<Widget>[
            const SizedBox(height: 10),
            const TypingIndicator(label: 'Consultando la base de datos'),
          ],
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: widget.sending ? null : () => _submit(),
                icon: const Icon(Icons.send_rounded, size: 20),
                tooltip: 'Enviar',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
