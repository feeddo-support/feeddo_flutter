import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../feeddo_client.dart';
import '../../models/conversation.dart';
import '../../models/message.dart';
import '../../models/task.dart';
import '../../models/ticket.dart';
import '../../theme/feeddo_theme.dart';
import '../widgets/task_details_sheet.dart';
import '../widgets/chat_input_area.dart';
import '../widgets/task_card.dart';
import '../widgets/ticket_card.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/rating_widget.dart';

class FeeddoChatScreen extends StatefulWidget {
  final Conversation? conversation;
  final FeeddoTheme? theme;
  final String? initialMessage;

  const FeeddoChatScreen({
    Key? key,
    this.conversation,
    this.theme,
    this.initialMessage,
  }) : super(key: key);

  @override
  State<FeeddoChatScreen> createState() => _FeeddoChatScreenState();
}

class _FeeddoChatScreenState extends State<FeeddoChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  List<Message> _messages = [];
  String? _error;
  late FeeddoTheme _theme;
  Conversation? _conversation;

  final Map<String, Task> _taskCache = {};
  final Map<String, Future<Task>> _taskFutures = {};
  final Map<String, Ticket> _ticketCache = {};
  final Map<String, Future<Ticket>> _ticketFutures = {};
  StreamSubscription? _wsSubscription;
  bool _isSending = false;
  bool _isTyping = false;
  String? _systemStatus;
  bool _hasSentMessage = false;
  bool _isInitializingConversation = false;

  @override
  void initState() {
    super.initState();
    _theme = widget.theme ?? FeeddoTheme.light();
    _conversation = widget.conversation;

    if (_conversation != null) {
      _loadMessages();
      Feeddo.instance.conversationService
          .setActiveConversationId(_conversation!.id);
    } else {
      _isLoading = false;
      _addWelcomeMessage();
    }

    _setupWebSocket();
    Feeddo.instance.conversationService.addListener(_onConversationUpdated);

    // Send read receipt when conversation is opened
    if (_conversation != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _sendReadReceipt();
      });
    }
  }

  @override
  void dispose() {
    Feeddo.instance.conversationService.setActiveConversationId(null);
    Feeddo.instance.conversationService.removeListener(_onConversationUpdated);
    _wsSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onConversationUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  void _setupWebSocket() {
    // Ensure we are connected to this conversation
    Feeddo.instance.connectWebSocket(conversationId: _conversation?.id);

    final wsService = Feeddo.instance.webSocketService;
    if (wsService != null) {
      _wsSubscription = wsService.messages.listen((data) {
        _handleWebSocketMessage(data);
      });
    }
  }

  void _handleWebSocketMessage(Map<String, dynamic> data) {
    debugPrint('ChatScreen: Received WebSocket message: $data');

    // System welcome message might not have conversationId
    if (data['type'] == 'system') {
      debugPrint('ChatScreen: Connected to ${data['id']}');
      return;
    }

    // If we don't have a conversation yet, check if this message assigns one
    if (_conversation == null && data['conversationId'] != null) {
      final newConversationId = data['conversationId'];
      debugPrint(
          'ChatScreen: Assigned new conversation ID: $newConversationId');

      // Fetch full conversation details
      _fetchConversation(newConversationId);
    }

    // Filter messages for current conversation
    if (_conversation != null && data['conversationId'] != _conversation!.id) {
      debugPrint(
          'ChatScreen: Ignoring message for different conversation (or none): ${data['conversationId']}');
      return;
    }

    if (data['role'] == 'assistant' || data['role'] == 'human') {
      // New message received
      final message = Message.fromJson(data);
      setState(() {
        _messages.insert(0, message);
        _isTyping = false;
        _systemStatus = null;
      });
      _sendReadReceipt();
    } else if (data['type'] == 'typing') {
      setState(() {
        _isTyping = data['status'] == 'on';
      });
    } else if (data['type'] == 'system_status') {
      setState(() {
        _systemStatus = data['content'];
      });
    } else if (data['type'] == 'error' || data['success'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(data['error'] ?? data['message'] ?? 'Unknown error')),
      );
    }
  }

  void _sendReadReceipt() {
    if (_conversation == null) return;
    Feeddo.instance.conversationService.sendReadReceipt(_conversation!.id);
  }

  void _addWelcomeMessage() {
    final conversationId = _conversation?.id ?? 'new';

    // Use custom welcome message if initialMessage is provided, otherwise use default
    String welcomeContent;
    if (widget.initialMessage != null) {
      welcomeContent = widget.initialMessage!;
    } else {
      welcomeContent =
          'How can I help you?\nYou can ask any question about the app, report a bug, or request a new feature.';
    }

    final welcomeMessage = Message(
      id: 'welcome-$conversationId',
      conversationId: conversationId,
      role: 'assistant',
      content: welcomeContent,
      hasAttachments: false,
      attachments: null,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      displayName: Feeddo.instance.chatBotName,
    );

    setState(() {
      _messages.add(welcomeMessage);
    });
  }

  Future<void> _loadMessages() async {
    if (_conversation == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final messages =
          await Feeddo.instance.apiService.getMessages(_conversation!.id);

      setState(() {
        _messages = messages.reversed.toList();
        _isLoading = false;
      });

      // Add welcome message at the end (oldest message position)
      _addWelcomeMessage();
      _sendReadReceipt();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  ({String content, String? taskId, String? ticketId}) _parseMessageContent(
      String content) {
    final regex = RegExp(r'```json\s*(\{[\s\S]*?\})\s*```');
    final match = regex.firstMatch(content);

    if (match != null) {
      try {
        final jsonStr = match.group(1)!;
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;

        String? taskId = json['taskId'];
        String? ticketId = json['ticketId'];

        if (taskId != null || ticketId != null) {
          final newContent = content.replaceFirst(match.group(0)!, '').trim();
          return (content: newContent, taskId: taskId, ticketId: ticketId);
        }
      } catch (e) {
        // Ignore parsing errors
      }
    }
    return (content: content, taskId: null, ticketId: null);
  }

  Widget _buildTaskCardUI(Task task) {
    return TaskCard(
      task: task,
      onTap: () => TaskDetailsSheet.show(
        context,
        task: task,
        onTaskUpdated: (updatedTask) {
          setState(() {
            _taskCache[updatedTask.id] = updatedTask;
          });
        },
      ),
    );
  }

  Widget _buildTaskCard(String taskId) {
    if (_taskCache.containsKey(taskId)) {
      return _buildTaskCardUI(_taskCache[taskId]!);
    }

    if (!_taskFutures.containsKey(taskId)) {
      _taskFutures[taskId] = Feeddo.instance.getTask(taskId).then((task) {
        if (mounted) {
          setState(() {
            _taskCache[taskId] = task;
          });
        }
        return task;
      });
    }

    return FutureBuilder<Task>(
      future: _taskFutures[taskId],
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        return _buildTaskCardUI(snapshot.data!);
      },
    );
  }

  Widget _buildTicketCard(String ticketId) {
    if (_ticketCache.containsKey(ticketId)) {
      return TicketCard(ticket: _ticketCache[ticketId]!);
    }

    if (!_ticketFutures.containsKey(ticketId)) {
      _ticketFutures[ticketId] =
          Feeddo.instance.getTicket(ticketId).then((ticket) {
        if (mounted) {
          setState(() {
            _ticketCache[ticketId] = ticket;
          });
        }
        return ticket;
      });
    }

    return FutureBuilder<Ticket>(
      future: _ticketFutures[ticketId],
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        return TicketCard(ticket: snapshot.data!);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _theme;

    // Get the latest conversation object from the service if available
    Conversation? conversation = _conversation;
    if (conversation != null) {
      conversation = Feeddo.instance.conversationService.conversations
          .firstWhere((c) => c.id == conversation!.id,
              orElse: () => conversation!);
    }

    // Use chatbot name for new conversations, otherwise use the conversation's display name
    final displayTitle = conversation?.displayName ??
        conversation?.title ??
        Feeddo.instance.chatBotName;

    return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (didPop) return;
          Navigator.of(context).pop(_hasSentMessage);
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: Colors.grey.withOpacity(0.1),
                height: 1,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(_hasSentMessage),
            ),
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colors.primary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      displayTitle.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayTitle,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (conversation?.status == 'active')
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Online',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                            color: theme.colors.primary))
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Failed to load messages',
                                  style: TextStyle(color: theme.colors.error),
                                ),
                                TextButton(
                                  onPressed: _loadMessages,
                                  child: Text('Retry',
                                      style: TextStyle(
                                          color: theme.colors.primary)),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            reverse: true,
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length +
                                (_isTyping || _systemStatus != null ? 1 : 0),
                            itemBuilder: (context, index) {
                              final hasIndicator =
                                  _isTyping || _systemStatus != null;

                              if (hasIndicator && index == 0) {
                                return _buildStatusIndicator(theme);
                              }

                              final msgIndex = hasIndicator ? index - 1 : index;
                              final message = _messages[msgIndex];
                              return _buildMessageBubble(message, theme);
                            },
                          ),
              ),
              _buildInputArea(theme),
            ],
          ),
        ));
  }

  Widget _buildMessageBubble(Message message, FeeddoTheme theme) {
    // Parse content for tasks/tickets
    final parsedContent = _parseMessageContent(message.content ?? '');
    final hasTask = parsedContent.taskId != null;
    final hasTicket = parsedContent.ticketId != null;

    return MessageBubble(
      message: message,
      theme: theme,
      taskCard: hasTask ? _buildTaskCard(parsedContent.taskId!) : null,
      ticketCard: hasTicket ? _buildTicketCard(parsedContent.ticketId!) : null,
    );
  }

  Future<void> _pickAndUploadMedia() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    final file = File(image.path);
    final userId = Feeddo.instance.userId;

    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
      }
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final media =
          await Feeddo.instance.conversationService.uploadMedia(file, userId);

      // Send message with attachment
      _sendAttachmentMessage(media);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload media: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _sendAttachmentMessage(Map<String, dynamic> media) {
    final wsService = Feeddo.instance.webSocketService;
    if (wsService == null) return;

    // Optimistically add message
    final tempMessage = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _conversation?.id ?? 'temp',
      role: 'user',
      content: 'Sent an attachment',
      hasAttachments: true,
      attachments: [media],
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    setState(() {
      _messages.insert(0, tempMessage);
      _hasSentMessage = true;
    });

    // Send via WebSocket
    final messageData = {
      'type': 'message',
      'message': 'Sent an attachment',
      'id': tempMessage.id,
      'attachments': [media],
    };

    if (_conversation != null) {
      messageData['conversationId'] = _conversation!.id;
    }

    wsService.send(messageData);
  }

  Widget _buildInputArea(FeeddoTheme theme) {
    if (_conversation?.status == 'resolved') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: theme.colors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This conversation has been resolved.',
              style: TextStyle(
                color: theme.colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text('How would you rate your experience?'),
            const SizedBox(height: 8),
            RatingWidget(
              initialRating: _conversation?.userSatisfaction ?? 0,
              onRatingChanged: _submitRating,
              readOnly: _conversation?.userSatisfaction != null,
            ),
          ],
        ),
      );
    }

    return ChatInputArea(
      controller: _messageController,
      isSending: _isSending || _isInitializingConversation,
      onSend: _sendMessage,
      onAttachment: _pickAndUploadMedia,
    );
  }

  Future<void> _submitRating(int rating) async {
    if (_conversation == null) return;
    try {
      await Feeddo.instance.conversationService
          .rateConversation(_conversation!.id, rating);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit rating: $e')),
        );
      }
    }
  }

  Future<void> _fetchConversation(String conversationId) async {
    // Try to find in service first
    try {
      // Wait a bit for the service to potentially update via websocket
      await Future.delayed(const Duration(milliseconds: 500));

      // Reload conversations to be sure
      if (Feeddo.instance.userId != null) {
        await Feeddo.instance.conversationService
            .loadConversations(Feeddo.instance.userId!);
      }

      final conv = Feeddo.instance.conversationService.conversations
          .firstWhere((c) => c.id == conversationId);

      if (mounted) {
        setState(() {
          _conversation = conv;
          _isInitializingConversation = false;
        });
        Feeddo.instance.conversationService
            .setActiveConversationId(conversationId);
        _loadMessages();
      }
    } catch (e) {
      debugPrint('ChatScreen: Failed to fetch new conversation: $e');
      if (mounted) {
        setState(() {
          _isInitializingConversation = false;
        });
      }
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final wsService = Feeddo.instance.webSocketService;
    if (wsService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not connected to chat server')),
      );
      return;
    }

    setState(() {
      _isSending = true;
      if (_conversation == null) {
        _isInitializingConversation = true;
      }
    });

    // Optimistically add user message
    final tempMessage = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _conversation?.id ?? 'temp',
      role: 'user',
      content: text,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      hasAttachments: false,
    );

    setState(() {
      _messages.insert(0, tempMessage);
      _messageController.clear();
      _hasSentMessage = true;
    });

    // Send via WebSocket
    final messageData = {
      'type': 'message',
      'message': text,
      'id': tempMessage.id,
    };

    if (_conversation != null) {
      messageData['conversationId'] = _conversation!.id;
    }

    wsService.send(messageData);

    setState(() {
      _isSending = false;
    });
  }

  Widget _buildStatusIndicator(FeeddoTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (_systemStatus != null) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _systemStatus!,
              style: TextStyle(
                color: theme.colors.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else if (_isTyping) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colors.border),
              ),
              child: TypingIndicator(
                color: theme.colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
