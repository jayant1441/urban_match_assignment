// lib/features/events/data/models/event_model.dart

import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/event.dart';

part 'event_model.g.dart';

@JsonSerializable()
class EventModel {
  final String name;
  final DateTime time;

  EventModel({required this.name, required this.time});

  factory EventModel.fromJson(Map<String, dynamic> json) =>
      _$EventModelFromJson(json);

  Map<String, dynamic> toJson() => _$EventModelToJson(this);

  // Convert back to domain
  Event toEntity() => Event(name: name, time: time);
}
