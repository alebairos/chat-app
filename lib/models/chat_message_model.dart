import 'package:isar/isar.dart';
import 'message_type.dart';

part 'chat_message_model.g.dart';

@collection
class ChatMessageModel {
  Id id = Isar.autoIncrement;

  @Index()
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

  ChatMessageModel({
    required this.text,
    required this.isUser,
    required this.type,
    required this.timestamp,
    this.mediaData,
    this.mediaPath,
    Duration? duration,
  }) : durationInMillis = duration?.inMilliseconds;

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
  }) {
    final model = ChatMessageModel(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      mediaData: mediaData ?? this.mediaData,
      mediaPath: mediaPath ?? this.mediaPath,
      duration: duration ?? this.duration,
    );
    model.id = id ?? this.id;
    return model;
  }
}
