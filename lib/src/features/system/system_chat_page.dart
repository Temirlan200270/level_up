import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
import '../../models/message_model.dart';
import '../../models/hunter_model.dart';
import '../../services/ai_service.dart';
import '../../services/providers.dart';

class SystemChatPage extends ConsumerStatefulWidget {
  const SystemChatPage({super.key});

  @override
  ConsumerState<SystemChatPage> createState() => _SystemChatPageState();
}

class _SystemChatPageState extends ConsumerState<SystemChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _hasApiKey = false;

  @override
  void initState() {
    super.initState();
    _checkApiKey();
    _sendWelcomeMessage();
  }

  Future<void> _checkApiKey() async {
    final hasKey = await AIService.hasApiKey();
    setState(() {
      _hasApiKey = hasKey;
    });
  }

  Future<void> _sendWelcomeMessage() async {
    final t = useTranslations(ref);
    final hunter = ref.read(hunterProvider);
    if (hunter != null) {
      final welcomeMessage = MessageModel(
        content: t(
          'system_welcome',
          params: {'name': hunter.name, 'level': hunter.level.toString()},
        ),
        isFromSystem: true,
      );
      setState(() {
        _messages.add(welcomeMessage);
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Добавляем сообщение пользователя
    final userMessage = MessageModel(content: text, isFromSystem: false);
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final hunter = ref.read(hunterProvider);
      final cfg = ref.read(activeSystemProvider);
      final rules = ref.read(activeSystemRulesProvider);

      // Генерируем ответ от Системы
      final response = await AIService.generateSystemMessage(
        context: text,
        hunterName: hunter?.name,
        hunterLevel: hunter?.level,
        philosophyVoiceName: cfg.aiVoiceName,
        philosophyToneHint: rules.aiSystemPromptHint(
          hunter ?? Hunter(name: ''),
        ),
        philosophyTerms: {
          'level': cfg.dictionary.levelName,
          'experience': cfg.dictionary.experienceName,
          'currency': cfg.dictionary.currencyName,
          'energy': cfg.dictionary.energyName,
          'skills': cfg.dictionary.skillsName,
        },
      );

      final systemMessage = MessageModel(content: response, isFromSystem: true);

      setState(() {
        _messages.add(systemMessage);
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      final t = useTranslations(ref);
      setState(() {
        _messages.add(
          MessageModel(
            content: '${t('error')}: $e\n\n${t('no_api_key_message')}',
            isFromSystem: true,
          ),
        );
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = useTranslations(ref);
    if (!_hasApiKey) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.key_off,
                    size: 80,
                    color: SoloLevelingColors.neonBlue,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    t('no_api_key'),
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t('no_api_key_message'),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(t('go_to_settings')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            AppBar(
              title: Row(
                children: [
                  Icon(Icons.smart_toy, color: SoloLevelingColors.neonBlue),
                  const SizedBox(width: 8),
                  Text(t('system')),
                ],
              ),
              centerTitle: false,
            ),

            // Список сообщений
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Text(
                        t('start_dialog_with_system'),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: SoloLevelingColors.textTertiary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _messages.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length) {
                          // Индикатор загрузки
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: SoloLevelingColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: SoloLevelingColors.neonBlue,
                                      width: 1,
                                    ),
                                  ),
                                  child: const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final message = _messages[index];
                        return _buildMessageBubble(message);
                      },
                    ),
            ),

            // Поле ввода
            Container(
              decoration: BoxDecoration(
                color: SoloLevelingColors.surface,
                border: Border(
                  top: BorderSide(
                    color: SoloLevelingColors.neonBlue.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(
                        color: SoloLevelingColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: t('write_to_system'),
                        hintStyle: TextStyle(
                          color: SoloLevelingColors.textTertiary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: SoloLevelingColors.neonBlue,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: SoloLevelingColors.neonBlue.withValues(
                              alpha: 0.5,
                            ),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: SoloLevelingColors.neonBlue,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: Icon(
                      Icons.send,
                      color: _isLoading
                          ? SoloLevelingColors.textTertiary
                          : SoloLevelingColors.neonBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message) {
    final isSystem = message.isFromSystem;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: isSystem
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSystem) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    SoloLevelingColors.neonBlue,
                    SoloLevelingColors.background,
                  ],
                ),
                border: Border.all(
                  color: SoloLevelingColors.neonBlue,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: SoloLevelingColors.textPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isSystem
                    ? SoloLevelingColors.surface
                    : SoloLevelingColors.neonBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSystem
                      ? SoloLevelingColors.neonBlue
                      : SoloLevelingColors.neonBlue.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: SoloLevelingColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: SoloLevelingColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isSystem) ...[
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SoloLevelingColors.neonBlue.withValues(alpha: 0.2),
                border: Border.all(
                  color: SoloLevelingColors.neonBlue,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.person,
                color: SoloLevelingColors.neonBlue,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
