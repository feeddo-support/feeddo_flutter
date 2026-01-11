import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../models/end_user.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/task.dart';
import '../models/ticket.dart';
import '../models/task_comment.dart';
import '../models/home_data.dart';
import '../models/feeddo_notification.dart';

/// Exception thrown when API requests fail
class FeeddoApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  FeeddoApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() =>
      'FeeddoApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}${details != null ? ' - $details' : ''}';
}

/// Service for making API calls to Feeddo backend
class ApiService {
  final String apiUrl;
  final String apiKey;
  final http.Client _client;

  ApiService({
    required this.apiUrl,
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Upsert (create or update) an end user
  ///
  /// This is a public endpoint that doesn't require authentication.
  /// Returns the user ID (created or existing).
  Future<UpsertEndUserResponse> upsertEndUser(EndUser user) async {
    final url = Uri.parse('$apiUrl/end-users/upsert');

    // Add appId to the request body
    final body = {
      ...user.toJson(),
    };

    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return UpsertEndUserResponse.fromJson(json);
      } else {
        final errorBody = _parseErrorBody(response.body);
        throw FeeddoApiException(
          errorBody['error'] ?? 'Failed to upsert end user',
          statusCode: response.statusCode,
          details: errorBody['details'],
        );
      }
    } catch (e) {
      if (e is FeeddoApiException) rethrow;
      throw FeeddoApiException(
        'Network error: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get home data for a user
  Future<HomeData> getHomeData(String userId) async {
    final url = Uri.parse('$apiUrl/end-users/home?userId=$userId');
    print(url.toString());
    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return HomeData.fromJson(json);
      } else {
        final errorBody = _parseErrorBody(response.body);
        throw FeeddoApiException(
          errorBody['error'] ?? 'Failed to get home data',
          statusCode: response.statusCode,
          details: errorBody['details'],
        );
      }
    } catch (e) {
      if (e is FeeddoApiException) rethrow;
      throw FeeddoApiException(
        'Network error: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get notifications for a user
  Future<List<FeeddoNotification>> getNotifications(String userId,
      {int limit = 50, int offset = 0}) async {
    final url = Uri.parse(
        '$apiUrl/end-users/notifications?userId=$userId&limit=$limit&offset=$offset');

    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final responseObj = GetNotificationsResponse.fromJson(json);
        return responseObj.notifications;
      } else {
        debugPrint(
            'Feeddo: Failed to get notifications. Status: ${response.statusCode}, Body: ${response.body}');
        final errorBody = _parseErrorBody(response.body);
        throw FeeddoApiException(
          errorBody['error'] ?? 'Failed to get notifications',
          statusCode: response.statusCode,
          details: errorBody['details'],
        );
      }
    } catch (e) {
      if (e is FeeddoApiException) rethrow;
      throw FeeddoApiException(
        'Network error: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get conversations for a user
  Future<List<Conversation>> getConversations(String userId) async {
    final url = Uri.parse('$apiUrl/conversations?userId=$userId');

    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final responseObj = GetConversationsResponse.fromJson(json);
        return responseObj.conversations;
      } else {
        final errorBody = _parseErrorBody(response.body);
        throw FeeddoApiException(
          errorBody['error'] ?? 'Failed to get conversations',
          statusCode: response.statusCode,
          details: errorBody['details'],
        );
      }
    } catch (e) {
      if (e is FeeddoApiException) rethrow;
      throw FeeddoApiException(
        'Network error: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get a single conversation by ID
  Future<Conversation> getConversation(String conversationId) async {
    final url = Uri.parse('$apiUrl/conversations/$conversationId');

    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true && json['conversation'] != null) {
          return Conversation.fromJson(json['conversation']);
        } else {
          throw FeeddoApiException(
              'Conversation not found or invalid response');
        }
      } else {
        final errorBody = _parseErrorBody(response.body);
        throw FeeddoApiException(
          errorBody['error'] ?? 'Failed to get conversation',
          statusCode: response.statusCode,
          details: errorBody['details'],
        );
      }
    } catch (e) {
      if (e is FeeddoApiException) rethrow;
      throw FeeddoApiException(
        'Network error: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Create a new conversation
  Future<Conversation> createConversation(String userId,
      {String agentName = 'support_agent'}) async {
    final url = Uri.parse('$apiUrl/conversations');

    final body = {
      'userId': userId,
      'agentName': agentName,
    };

    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final conversationId = json['conversationId'];
        // Fetch the full conversation object
        return await getConversation(conversationId);
      } else {
        final errorBody = _parseErrorBody(response.body);
        throw FeeddoApiException(
          errorBody['error'] ?? 'Failed to create conversation',
          statusCode: response.statusCode,
          details: errorBody['details'],
        );
      }
    } catch (e) {
      if (e is FeeddoApiException) rethrow;
      throw FeeddoApiException(
        'Network error: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get messages for a conversation
  Future<List<Message>> getMessages(String conversationId) async {
    final url = Uri.parse('$apiUrl/conversations/$conversationId/messages');

    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
      );

      print(response.body);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final messagesList = json['messages'] as List;
        return messagesList.map((m) => Message.fromJson(m)).toList();
      } else {
        final errorBody = _parseErrorBody(response.body);
        throw FeeddoApiException(
          errorBody['error'] ?? 'Failed to get messages',
          statusCode: response.statusCode,
          details: errorBody['details'],
        );
      }
    } catch (e) {
      if (e is FeeddoApiException) rethrow;
      throw FeeddoApiException(
        'Network error: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get a task by ID
  Future<Task> getTask(String taskId, {String? userId}) async {
    final uri = Uri.parse('$apiUrl/tasks/$taskId').replace(queryParameters: {
      if (userId != null) 'userId': userId,
    });

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
      );

      print(response.body);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true && json['task'] != null) {
          return Task.fromJson(json['task']);
        } else {
          throw FeeddoApiException('Task not found or invalid response');
        }
      } else {
        final errorBody = _parseErrorBody(response.body);
        throw FeeddoApiException(
          errorBody['error'] ?? 'Failed to get task',
          statusCode: response.statusCode,
          details: errorBody['details'],
        );
      }
    } catch (e) {
      if (e is FeeddoApiException) rethrow;
      throw FeeddoApiException(
        'Network error: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get a ticket by ID
  Future<Ticket> getTicket(String ticketId, {String? userId}) async {
    final uri =
        Uri.parse('$apiUrl/tickets/$ticketId').replace(queryParameters: {
      if (userId != null) 'userId': userId,
    });

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true && json['ticket'] != null) {
          return Ticket.fromJson(json['ticket']);
        } else {
          throw FeeddoApiException('Ticket not found or invalid response');
        }
      } else {
        final errorBody = _parseErrorBody(response.body);
        throw FeeddoApiException(
          errorBody['error'] ?? 'Failed to get ticket',
          statusCode: response.statusCode,
          details: errorBody['details'],
        );
      }
    } catch (e) {
      if (e is FeeddoApiException) rethrow;
      throw FeeddoApiException(
        'Network error: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get tickets for a user
  Future<List<Ticket>> getTickets(String userId) async {
    final url = Uri.parse('$apiUrl/tickets?userId=$userId');

    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true && json['tickets'] != null) {
          return (json['tickets'] as List)
              .map((e) => Ticket.fromJson(e))
              .toList();
        } else {
          return [];
        }
      } else {
        final errorBody = _parseErrorBody(response.body);
        throw FeeddoApiException(
          errorBody['error'] ?? 'Failed to get tickets',
          statusCode: response.statusCode,
          details: errorBody['details'],
        );
      }
    } catch (e) {
      if (e is FeeddoApiException) rethrow;
      throw FeeddoApiException(
        'Network error: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get tasks
  Future<List<Task>> getTasks({
    String? userId,
    String? type,
    String? priority,
    String? sortBy,
    String? sortOrder,
    int? page,
    int? limit,
    bool? createdByMe,
  }) async {
    final queryParams = <String, String>{};
    if (userId != null) queryParams['userId'] = userId;
    if (type != null) queryParams['type'] = type;
    if (priority != null) queryParams['priority'] = priority;
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (sortOrder != null) queryParams['sortOrder'] = sortOrder;
    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    if (createdByMe != null)
      queryParams['createdByMe'] = createdByMe.toString();

    final uri =
        Uri.parse('$apiUrl/tasks').replace(queryParameters: queryParams);

    print(uri.toString());

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true && json['tasks'] != null) {
          return (json['tasks'] as List).map((e) => Task.fromJson(e)).toList();
        } else {
          return [];
        }
      } else {
        final errorBody = _parseErrorBody(response.body);
        throw FeeddoApiException(
          errorBody['error'] ?? 'Failed to get tasks',
          statusCode: response.statusCode,
          details: errorBody['details'],
        );
      }
    } catch (e) {
      if (e is FeeddoApiException) rethrow;
      throw FeeddoApiException(
        'Network error: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Add a comment to a task
  Future<TaskComment> addTaskComment(String taskId, String content,
      {String? userId, List<Map<String, dynamic>>? attachments}) async {
    final uri =
        Uri.parse('$apiUrl/tasks/$taskId/comments').replace(queryParameters: {
      if (userId != null) 'userId': userId,
    });

    final body = {
      'content': content,
      if (attachments != null && attachments.isNotEmpty)
        'attachments': attachments,
    };

    try {
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode(body),
      );

      print(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true && json['comment'] != null) {
          return TaskComment.fromJson(json['comment']);
        } else {
          throw FeeddoApiException('Failed to add comment');
        }
      } else {
        final errorBody = _parseErrorBody(response.body);
        throw FeeddoApiException(
          errorBody['error'] ?? 'Failed to add comment',
          statusCode: response.statusCode,
          details: errorBody['details'],
        );
      }
    } catch (e) {
      if (e is FeeddoApiException) rethrow;
      throw FeeddoApiException(
        'Network error: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Vote on a task
  Future<Map<String, dynamic>> voteTask(String taskId, String voteType,
      {String? userId}) async {
    final uri =
        Uri.parse('$apiUrl/tasks/$taskId/vote').replace(queryParameters: {
      if (userId != null) 'userId': userId,
    });

    final body = {
      'voteType': voteType,
    };

    try {
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          return json;
        } else {
          throw FeeddoApiException('Failed to vote on task');
        }
      } else {
        final errorBody = _parseErrorBody(response.body);
        throw FeeddoApiException(
          errorBody['error'] ?? 'Failed to vote on task',
          statusCode: response.statusCode,
          details: errorBody['details'],
        );
      }
    } catch (e) {
      if (e is FeeddoApiException) rethrow;
      throw FeeddoApiException(
        'Network error: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Rate conversation satisfaction
  Future<void> rateConversation(String conversationId, int rating) async {
    final url = Uri.parse('$apiUrl/conversations/$conversationId/satisfaction');

    try {
      final response = await _client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode({'rating': rating}),
      );

      if (response.statusCode == 200) {
        return;
      } else {
        final errorBody = _parseErrorBody(response.body);
        throw FeeddoApiException(
          errorBody['error'] ?? 'Failed to rate conversation',
          statusCode: response.statusCode,
          details: errorBody['details'],
        );
      }
    } catch (e) {
      if (e is FeeddoApiException) rethrow;
      throw FeeddoApiException(
        'Network error: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Parse error response body
  /// Upload media file
  Future<Map<String, dynamic>> uploadMedia(XFile file, String userId) async {
    final url = Uri.parse('$apiUrl/media/upload?userId=$userId');

    final request = http.MultipartRequest('POST', url);
    request.headers['x-api-key'] = apiKey;

    final mimeType = file.mimeType ?? lookupMimeType(file.name);
    MediaType? contentType;
    if (mimeType != null) {
      final split = mimeType.split('/');
      contentType = MediaType(split[0], split[1]);
    }

    final bytes = await file.readAsBytes();
    final multipartFile = http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: file.name,
      contentType: contentType,
    );
    request.files.add(multipartFile);

    try {
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true && json['media'] != null) {
          return json['media'] as Map<String, dynamic>;
        }
        throw FeeddoApiException(
            'Upload failed: ${json['error'] ?? 'Unknown error'}');
      } else {
        final errorBody = _parseErrorBody(response.body);
        throw FeeddoApiException(
          errorBody['error'] ?? 'Failed to upload media',
          statusCode: response.statusCode,
          details: errorBody['details'],
        );
      }
    } catch (e) {
      if (e is FeeddoApiException) rethrow;
      throw FeeddoApiException(
        'Network error: ${e.toString()}',
        details: e,
      );
    }
  }

  Map<String, dynamic> _parseErrorBody(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {'error': body};
    }
  }

  /// Close the HTTP client
  void dispose() {
    _client.close();
  }
}
