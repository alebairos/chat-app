import 'package:isar/isar.dart';
import 'message_type.dart';

part 'chat_message_model.g.dart';

@collection
class ChatMessageModel {
  Id id = Isar.autoIncrement;

  @Index()
  @Index(composite: [CompositeIndex('personaKey')])
  @Index(composite: [CompositeIndex('isUser')])
  DateTime timestamp;

  @Index()
  String text;

  bool isUser;

  @enumerated
  MessageType type;

  List<byte>? mediaData;

  String? mediaPath;

  @Index()
  int? durationInMillis;

  // NEW FIELDS for persona metadata
  @Index()
  String? personaKey; // e.g., 'ariLifeCoach', 'sergeantOracle', 'iThereClone'

  String?
      personaDisplayName; // e.g., 'Ari Life Coach', 'Sergeant Oracle', 'I-There'

  ChatMessageModel({
    required this.text,
    required this.isUser,
    required this.type,
    required this.timestamp,
    this.mediaData,
    this.mediaPath,
    Duration? duration,
    this.personaKey, // NEW
    this.personaDisplayName, // NEW
  }) : durationInMillis = duration?.inMilliseconds;

  // Additional constructor for AI messages with persona
  ChatMessageModel.aiMessage({
    required this.text,
    required this.type,
    required this.timestamp,
    required this.personaKey,
    required this.personaDisplayName,
    this.mediaData,
    this.mediaPath,
    Duration? duration,
  })  : isUser = false,
        durationInMillis = duration?.inMilliseconds;

  @ignore
  Duration? get duration => durationInMillis != null
      ? Duration(milliseconds: durationInMillis!)
      : null;

  @ignore
  set duration(Duration? value) {
    durationInMillis = value?.inMilliseconds;
  }

  ChatMessageModel copyWith({
    Id? id,
    DateTime? timestamp,
    String? text,
    bool? isUser,
    MessageType? type,
    List<byte>? mediaData,
    String? mediaPath,
    Duration? duration,
    String? personaKey, // NEW
    String? personaDisplayName, // NEW
  }) {
    final model = ChatMessageModel(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      mediaData: mediaData ?? this.mediaData,
      mediaPath: mediaPath ?? this.mediaPath,
      duration: duration ?? this.duration,
      personaKey: personaKey ?? this.personaKey, // NEW
      personaDisplayName: personaDisplayName ?? this.personaDisplayName, // NEW
    );
    model.id = id ?? this.id;
    return model;
  }
}
