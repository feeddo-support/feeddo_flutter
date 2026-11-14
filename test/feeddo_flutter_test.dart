import 'package:flutter_test/flutter_test.dart';
import 'package:feeddo_flutter/src/models/task_comment.dart';
import 'package:feeddo_flutter/src/models/message.dart';
import 'package:feeddo_flutter/src/models/conversation.dart';
import 'package:feeddo_flutter/src/services/api_service.dart';
import 'package:feeddo_flutter/src/services/websocket_service.dart';
import 'package:feeddo_flutter/src/services/conversation_service.dart';

void main() {
  group('Model parsing tests', () {
    test('TaskComment parses has_attachments as int and bool correctly', () {
      final commentFromSql = TaskComment.fromJson({
        'id': 'c1',
        'content': 'Test comment',
        'user_type': 'developer',
        'has_attachments': 1,
        'attachments': [
          {'url': 'https://example.com/test.png', 'contentType': 'image/png'}
        ],
      });

      expect(commentFromSql.hasAttachments, isTrue);
      expect(commentFromSql.attachments, isNotNull);
      expect(commentFromSql.attachments!.length, 1);
      expect(commentFromSql.attachments!.first['url'],
          'https://example.com/test.png');

      final commentZero = TaskComment.fromJson({
        'id': 'c2',
        'content': 'Another comment',
        'has_attachments': 0,
      });

      expect(commentZero.hasAttachments, isFalse);
    });

    test('Message and Conversation parse correctly', () {
      final message = Message.fromJson({
        'id': 'm1',
        'conversationId': 'conv1',
        'role': 'assistant',
        'content': 'Hello',
        'has_attachments': 0,
        'createdAt': 123456789,
      });

      expect(message.id, 'm1');
      expect(message.hasAttachments, isFalse);
      expect(message.isUser, isFalse);

      final conversation = Conversation.fromJson({
        'id': 'conv1',
        'appId': 'app1',
        'status': 'active',
        'autoReply': true,
        'startedAt': 123456789,
        'lastMessageAt': 123456789,
      });

      expect(conversation.id, 'conv1');
      expect(conversation.autoReply, isTrue);
    });

    test('ConversationService unread count updates properly', () {
      final service = ConversationService(
        ApiService(apiUrl: 'https://example.com', apiKey: 'key'),
        WebSocketService(baseUrl: 'https://example.com', apiKey: 'key'),
      );

      expect(service.unreadMessageCount, 0);

      service.incrementUnreadCount('conv1');
      expect(service.unreadMessageCount, 1);

      service.incrementUnreadCount('conv1');
      expect(service.unreadMessageCount, 2);

      service.incrementUnreadCount('conv2');
      expect(service.unreadMessageCount, 3);

      service.setTotalUnreadCount(10);
      expect(service.unreadMessageCount, 10);

      service.markAsRead('conv1');
      expect(service.unreadMessageCount, 1);
    });
  });
}
