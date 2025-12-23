library feeddo_flutter;

// Core client - Main public API
export 'src/feeddo_client.dart' show Feeddo;

// Models - For type safety in responses
export 'src/models/end_user.dart' show UpsertEndUserResponse;
export 'src/models/task.dart';
export 'src/models/ticket.dart';
export 'src/models/conversation.dart';
export 'src/models/message.dart';
export 'src/models/task_comment.dart';

// Exception - For error handling
export 'src/services/api_service.dart' show FeeddoApiException;

// Theme - For UI customization
export 'src/theme/feeddo_theme.dart' show FeeddoTheme, FeeddoColors;
