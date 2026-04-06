// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TestTask _$TestTaskFromJson(Map<String, dynamic> json) => _TestTask(
  id: json['id'] as String,
  name: json['name'] as String,
  category: json['category'] as String,
  userMessage: json['userMessage'] as String,
);

Map<String, dynamic> _$TestTaskToJson(_TestTask instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'category': instance.category,
  'userMessage': instance.userMessage,
};
