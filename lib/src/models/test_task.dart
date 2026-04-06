import 'package:freezed_annotation/freezed_annotation.dart';

part 'test_task.freezed.dart';
part 'test_task.g.dart';

/// A single task in the test battery used to evaluate prompt variants.
@freezed
abstract class TestTask with _$TestTask {
  const factory TestTask({
    required String id,
    required String name,
    required String category,
    required String userMessage,
  }) = _TestTask;

  factory TestTask.fromJson(Map<String, dynamic> json) =>
      _$TestTaskFromJson(json);
}
