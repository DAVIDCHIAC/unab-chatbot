import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

/// Chat general con el agente RAG (WF01).
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  int _lastRendered = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChatProvider>().seedWelcome();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scheduleScroll(int total) {
    if (total == _lastRendered) return;
    _lastRendered = total;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 140,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  void _send([String? preset]) {
    final ChatProvider chat = context.read<ChatProvider>();
    if (chat.sending) return;
    final String text = (preset ?? _controller.text).trim();
    if (text.isEmpty) return;
    _controller.clear();
    chat.send(text);
  }

  @override
  Widget build(BuildContext context) {
    final ChatProvider chat = context.watch<ChatProvider>();
    _scheduleScroll(chat.messages.length + (chat.sending ? 1 : 0));

    return Column(
      children: <Widget>[
        if (!AppConfig.isConfigured) const _ConfigBanner(),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: chat.messages.length + (chat.sending ? 1 : 0),
            itemBuilder: (BuildContext context, int index) {
              if (index >= chat.messages.length) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: TypingIndicator(),
                );
              }
              final ChatMessage message = chat.messages[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MessageBubble(message: message),
              );
            },
          ),
        ),
        if (chat.messages.length <= 1 && !chat.sending)
          _SuggestionStrip(onTap: _send),
        _Composer(
          controller: _controller,
          sending: chat.sending,
          onSend: _send,
        ),
      ],
    );
  }
}

class _ConfigBanner extends StatelessWidget {
  const _ConfigBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF7E0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.settings_ethernet, size: 18, color: AppColors.amber),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Falta configurar la URL de n8n. Ejecuta la app con '
              '--dart-define=N8N_BASE_URL=https://tu-instancia.app.n8n.cloud',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.amber,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionStrip extends StatelessWidget {
  const _SuggestionStrip({required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ChatProvider.suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final String suggestion = ChatProvider.suggestions[index];
          return ActionChip(
            label: Text(suggestion),
            onPressed: () => onTap(suggestion),
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.border),
            labelStyle: const TextStyle(fontSize: 12, color: AppColors.ink),
          );
        },
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(controller.text),
                decoration: const InputDecoration(
                  hintText: 'Escribe tu pregunta sobre la UNAB...',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: sending ? null : () => onSend(controller.text),
              icon: const Icon(Icons.send_rounded, size: 20),
              tooltip: 'Enviar',
            ),
          ],
        ),
      ),
    );
  }
}
