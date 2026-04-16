import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../features/chatbot/presentation/bloc/chatbot_bloc.dart';
import '../../features/chatbot/presentation/bloc/chatbot_event.dart';
import '../../features/chatbot/presentation/bloc/chatbot_state.dart';

class AIChatbotScreen extends StatefulWidget {
  const AIChatbotScreen({super.key});

  @override
  State<AIChatbotScreen> createState() => _AIChatbotScreenState();
}

class _AIChatbotScreenState extends State<AIChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load chat history when screen opens
    Future.microtask(() {
      context.read<ChatbotBloc>().add(const LoadChatHistory());
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      context.read<ChatbotBloc>().add(SendMessage(message));
      _messageController.clear();
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    final isTinyScreen = screenWidth < 360;

    final headerIconWrapperPadding = isTinyScreen ? 6.0 : 8.0;
    final headerIconSize = isTinyScreen ? 20.0 : 24.0;
    final headerSpacing = isTinyScreen ? 8.0 : 12.0;
    final titleFontSize = isTinyScreen ? 16.0 : 18.0;
    final subtitleFontSize = isTinyScreen ? 11.0 : 12.0;

    final messageListPadding = isTinyScreen ? 12.0 : 16.0;
    final messageFontSize = isTinyScreen ? 14.0 : 15.0;
    final messageRadius = isTinyScreen ? 16.0 : 20.0;
    final messagePaddingHorizontal = isTinyScreen ? 12.0 : 16.0;
    final messagePaddingVertical = isTinyScreen ? 10.0 : 12.0;
    final messageMaxWidth = screenWidth * (isTinyScreen ? 0.82 : 0.75);

    final inputContainerPadding = isTinyScreen ? 12.0 : 16.0;
    final inputPaddingHorizontal = isTinyScreen ? 14.0 : 20.0;
    final inputPaddingVertical = isTinyScreen ? 10.0 : 12.0;
    final sendSpacing = isTinyScreen ? 6.0 : 8.0;
    final sendIconSize = isTinyScreen ? 20.0 : 24.0;

    final welcomePadding = isTinyScreen ? 20.0 : 32.0;
    final welcomeIconPadding = isTinyScreen ? 18.0 : 24.0;
    final welcomeIconSize = isTinyScreen ? 52.0 : 64.0;
    final welcomeTitleSize = isTinyScreen ? 20.0 : 24.0;
    final welcomeBodySize = isTinyScreen ? 14.0 : 16.0;
    final chipSpacing = isTinyScreen ? 6.0 : 8.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(headerIconWrapperPadding),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: headerIconSize,
              ),
            ),
            SizedBox(width: headerSpacing),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.aiAssistant,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.alwaysHereToHelp,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: subtitleFontSize,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text(AppLocalizations.of(context)!.clearChat),
                  content: Text(AppLocalizations.of(context)!.clearChatConfirmation),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<ChatbotBloc>().add(const ClearChat());
                        Navigator.pop(dialogContext);
                      },
                      child: Text(
                        AppLocalizations.of(context)!.clear,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: BlocConsumer<ChatbotBloc, ChatbotState>(
              listener: (context, state) {
                if (state is ChatbotLoaded || state is ChatbotLoading) {
                  _scrollToBottom();
                }
                if (state is ChatbotError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is ChatbotInitial) {
                  return _buildWelcomeScreen(
                    padding: welcomePadding,
                    iconPadding: welcomeIconPadding,
                    iconSize: welcomeIconSize,
                    titleSize: welcomeTitleSize,
                    bodySize: welcomeBodySize,
                    chipSpacing: chipSpacing,
                  );
                }

                final messages = state is ChatbotLoaded
                    ? state.messages
                    : state is ChatbotLoading
                        ? state.messages
                        : state is ChatbotError
                            ? state.messages
                            : [];

                if (messages.isEmpty) {
                  return _buildWelcomeScreen(
                    padding: welcomePadding,
                    iconPadding: welcomeIconPadding,
                    iconSize: welcomeIconSize,
                    titleSize: welcomeTitleSize,
                    bodySize: welcomeBodySize,
                    chipSpacing: chipSpacing,
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(messageListPadding),
                  itemCount: messages.length + (state is ChatbotLoading && messages.last.isUser ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return _buildTypingIndicator(
                        marginBottom: messageListPadding,
                        horizontalPadding: messagePaddingHorizontal,
                        verticalPadding: messagePaddingVertical,
                        radius: messageRadius,
                        dotSize: isTinyScreen ? 7.0 : 8.0,
                      );
                    }
                    final message = messages[index];
                    return _buildMessageBubble(
                      message,
                      maxWidth: messageMaxWidth,
                      radius: messageRadius,
                      horizontalPadding: messagePaddingHorizontal,
                      verticalPadding: messagePaddingVertical,
                      fontSize: messageFontSize,
                      marginBottom: messageListPadding,
                    );
                  },
                );
              },
            ),
          ),

          // Input Field
          Container(
            padding: EdgeInsets.all(inputContainerPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.typeYourQuestion,
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: inputPaddingHorizontal,
                            vertical: inputPaddingVertical,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  SizedBox(width: sendSpacing),
                  BlocBuilder<ChatbotBloc, ChatbotState>(
                    builder: (context, state) {
                      final isLoading = state is ChatbotLoading;
                      return  Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(Icons.send, color: Colors.white, size: sendIconSize),
                          onPressed: isLoading ? null : _sendMessage,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen({
    required double padding,
    required double iconPadding,
    required double iconSize,
    required double titleSize,
    required double bodySize,
    required double chipSpacing,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(iconPadding),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy,
                size: iconSize,
                color: Colors.white,
              ),
            ),
            SizedBox(height: padding * 0.75),
            Text(
              AppLocalizations.of(context)!.welcomeToAI,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGreen,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: chipSpacing + 4),
            Text(
              AppLocalizations.of(context)!.aiDescription,
              style: TextStyle(
                fontSize: bodySize,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: padding),
            Wrap(
              spacing: chipSpacing,
              runSpacing: chipSpacing,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip(AppLocalizations.of(context)!.cropAdvice, chipFontSize: bodySize - 1),
                _buildSuggestionChip(AppLocalizations.of(context)!.pestControl, chipFontSize: bodySize - 1),
                _buildSuggestionChip(AppLocalizations.of(context)!.soilHealth, chipFontSize: bodySize - 1),
                _buildSuggestionChip(AppLocalizations.of(context)!.weatherTips, chipFontSize: bodySize - 1),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String label, {required double chipFontSize}) {
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(fontSize: chipFontSize),
      ),
      onPressed: () {
        _messageController.text = label;
        _sendMessage();
      },
      backgroundColor: Colors.white,
      side: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.3)),
      labelStyle: TextStyle(color: AppTheme.primaryGreen, fontSize: chipFontSize),
    );
  }

  Widget _buildMessageBubble(
    message, {
    required double maxWidth,
    required double radius,
    required double horizontalPadding,
    required double verticalPadding,
    required double fontSize,
    required double marginBottom,
  }) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: marginBottom),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: message.isUser ? AppTheme.primaryGreen : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(radius),
            topRight: Radius.circular(radius),
            bottomLeft: Radius.circular(message.isUser ? radius : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : radius),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.message,
          style: TextStyle(
            color: message.isUser ? Colors.white : Colors.black87,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator({
    required double marginBottom,
    required double horizontalPadding,
    required double verticalPadding,
    required double radius,
    required double dotSize,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: marginBottom),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(radius),
            topRight: Radius.circular(radius),
            bottomLeft: const Radius.circular(4),
            bottomRight: Radius.circular(radius),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(size: dotSize),
            const SizedBox(width: 4),
            _buildDot(delay: 200, size: dotSize),
            const SizedBox(width: 4),
            _buildDot(delay: 400, size: dotSize),
          ],
        ),
      ),
    );
  }

  Widget _buildDot({int delay = 0, required double size}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
