// Reference: Current ChatMessageModel structure
// This shows the existing pattern for data models in this project

import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_message_model.g.dart';

@Collection()
@JsonSerializable()
class ChatMessageModel {
  Id id = Isar.autoIncrement;

  @Index()
  late String sessionId;

  late String content;
  late bool isUser;
  late DateTime timestamp;

  // Audio-related fields
  String? audioPath;
  bool isAudioMessage = false;

  // Persona metadata (added in FT-049)
  String? personaKey;
  String? personaDisplayName;

  ChatMessageModel({
    required this.sessionId,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.audioPath,
    this.isAudioMessage = false,
    this.personaKey,
    this.personaDisplayName,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageModelToJson(this);
}
