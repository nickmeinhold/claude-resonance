// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TaskResponse {

 String get taskId; String get variantId; String get responseText;/// How long Claude took to respond, in milliseconds.
 int get latencyMs;/// Token counts from verbose output. Null for legacy/mock data.
 int? get inputTokens; int? get outputTokens; int? get cacheCreationInputTokens; int? get cacheReadInputTokens; double? get costUsd;
/// Create a copy of TaskResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskResponseCopyWith<TaskResponse> get copyWith => _$TaskResponseCopyWithImpl<TaskResponse>(this as TaskResponse, _$identity);

  /// Serializes this TaskResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskResponse&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.variantId, variantId) || other.variantId == variantId)&&(identical(other.responseText, responseText) || other.responseText == responseText)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs)&&(identical(other.inputTokens, inputTokens) || other.inputTokens == inputTokens)&&(identical(other.outputTokens, outputTokens) || other.outputTokens == outputTokens)&&(identical(other.cacheCreationInputTokens, cacheCreationInputTokens) || other.cacheCreationInputTokens == cacheCreationInputTokens)&&(identical(other.cacheReadInputTokens, cacheReadInputTokens) || other.cacheReadInputTokens == cacheReadInputTokens)&&(identical(other.costUsd, costUsd) || other.costUsd == costUsd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,taskId,variantId,responseText,latencyMs,inputTokens,outputTokens,cacheCreationInputTokens,cacheReadInputTokens,costUsd);

@override
String toString() {
  return 'TaskResponse(taskId: $taskId, variantId: $variantId, responseText: $responseText, latencyMs: $latencyMs, inputTokens: $inputTokens, outputTokens: $outputTokens, cacheCreationInputTokens: $cacheCreationInputTokens, cacheReadInputTokens: $cacheReadInputTokens, costUsd: $costUsd)';
}


}

/// @nodoc
abstract mixin class $TaskResponseCopyWith<$Res>  {
  factory $TaskResponseCopyWith(TaskResponse value, $Res Function(TaskResponse) _then) = _$TaskResponseCopyWithImpl;
@useResult
$Res call({
 String taskId, String variantId, String responseText, int latencyMs, int? inputTokens, int? outputTokens, int? cacheCreationInputTokens, int? cacheReadInputTokens, double? costUsd
});




}
/// @nodoc
class _$TaskResponseCopyWithImpl<$Res>
    implements $TaskResponseCopyWith<$Res> {
  _$TaskResponseCopyWithImpl(this._self, this._then);

  final TaskResponse _self;
  final $Res Function(TaskResponse) _then;

/// Create a copy of TaskResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? taskId = null,Object? variantId = null,Object? responseText = null,Object? latencyMs = null,Object? inputTokens = freezed,Object? outputTokens = freezed,Object? cacheCreationInputTokens = freezed,Object? cacheReadInputTokens = freezed,Object? costUsd = freezed,}) {
  return _then(_self.copyWith(
taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,variantId: null == variantId ? _self.variantId : variantId // ignore: cast_nullable_to_non_nullable
as String,responseText: null == responseText ? _self.responseText : responseText // ignore: cast_nullable_to_non_nullable
as String,latencyMs: null == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as int,inputTokens: freezed == inputTokens ? _self.inputTokens : inputTokens // ignore: cast_nullable_to_non_nullable
as int?,outputTokens: freezed == outputTokens ? _self.outputTokens : outputTokens // ignore: cast_nullable_to_non_nullable
as int?,cacheCreationInputTokens: freezed == cacheCreationInputTokens ? _self.cacheCreationInputTokens : cacheCreationInputTokens // ignore: cast_nullable_to_non_nullable
as int?,cacheReadInputTokens: freezed == cacheReadInputTokens ? _self.cacheReadInputTokens : cacheReadInputTokens // ignore: cast_nullable_to_non_nullable
as int?,costUsd: freezed == costUsd ? _self.costUsd : costUsd // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskResponse].
extension TaskResponsePatterns on TaskResponse {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskResponse() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskResponse value)  $default,){
final _that = this;
switch (_that) {
case _TaskResponse():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskResponse value)?  $default,){
final _that = this;
switch (_that) {
case _TaskResponse() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String taskId,  String variantId,  String responseText,  int latencyMs,  int? inputTokens,  int? outputTokens,  int? cacheCreationInputTokens,  int? cacheReadInputTokens,  double? costUsd)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskResponse() when $default != null:
return $default(_that.taskId,_that.variantId,_that.responseText,_that.latencyMs,_that.inputTokens,_that.outputTokens,_that.cacheCreationInputTokens,_that.cacheReadInputTokens,_that.costUsd);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String taskId,  String variantId,  String responseText,  int latencyMs,  int? inputTokens,  int? outputTokens,  int? cacheCreationInputTokens,  int? cacheReadInputTokens,  double? costUsd)  $default,) {final _that = this;
switch (_that) {
case _TaskResponse():
return $default(_that.taskId,_that.variantId,_that.responseText,_that.latencyMs,_that.inputTokens,_that.outputTokens,_that.cacheCreationInputTokens,_that.cacheReadInputTokens,_that.costUsd);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String taskId,  String variantId,  String responseText,  int latencyMs,  int? inputTokens,  int? outputTokens,  int? cacheCreationInputTokens,  int? cacheReadInputTokens,  double? costUsd)?  $default,) {final _that = this;
switch (_that) {
case _TaskResponse() when $default != null:
return $default(_that.taskId,_that.variantId,_that.responseText,_that.latencyMs,_that.inputTokens,_that.outputTokens,_that.cacheCreationInputTokens,_that.cacheReadInputTokens,_that.costUsd);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TaskResponse implements TaskResponse {
  const _TaskResponse({required this.taskId, required this.variantId, required this.responseText, required this.latencyMs, this.inputTokens, this.outputTokens, this.cacheCreationInputTokens, this.cacheReadInputTokens, this.costUsd});
  factory _TaskResponse.fromJson(Map<String, dynamic> json) => _$TaskResponseFromJson(json);

@override final  String taskId;
@override final  String variantId;
@override final  String responseText;
/// How long Claude took to respond, in milliseconds.
@override final  int latencyMs;
/// Token counts from verbose output. Null for legacy/mock data.
@override final  int? inputTokens;
@override final  int? outputTokens;
@override final  int? cacheCreationInputTokens;
@override final  int? cacheReadInputTokens;
@override final  double? costUsd;

/// Create a copy of TaskResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskResponseCopyWith<_TaskResponse> get copyWith => __$TaskResponseCopyWithImpl<_TaskResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskResponse&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.variantId, variantId) || other.variantId == variantId)&&(identical(other.responseText, responseText) || other.responseText == responseText)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs)&&(identical(other.inputTokens, inputTokens) || other.inputTokens == inputTokens)&&(identical(other.outputTokens, outputTokens) || other.outputTokens == outputTokens)&&(identical(other.cacheCreationInputTokens, cacheCreationInputTokens) || other.cacheCreationInputTokens == cacheCreationInputTokens)&&(identical(other.cacheReadInputTokens, cacheReadInputTokens) || other.cacheReadInputTokens == cacheReadInputTokens)&&(identical(other.costUsd, costUsd) || other.costUsd == costUsd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,taskId,variantId,responseText,latencyMs,inputTokens,outputTokens,cacheCreationInputTokens,cacheReadInputTokens,costUsd);

@override
String toString() {
  return 'TaskResponse(taskId: $taskId, variantId: $variantId, responseText: $responseText, latencyMs: $latencyMs, inputTokens: $inputTokens, outputTokens: $outputTokens, cacheCreationInputTokens: $cacheCreationInputTokens, cacheReadInputTokens: $cacheReadInputTokens, costUsd: $costUsd)';
}


}

/// @nodoc
abstract mixin class _$TaskResponseCopyWith<$Res> implements $TaskResponseCopyWith<$Res> {
  factory _$TaskResponseCopyWith(_TaskResponse value, $Res Function(_TaskResponse) _then) = __$TaskResponseCopyWithImpl;
@override @useResult
$Res call({
 String taskId, String variantId, String responseText, int latencyMs, int? inputTokens, int? outputTokens, int? cacheCreationInputTokens, int? cacheReadInputTokens, double? costUsd
});




}
/// @nodoc
class __$TaskResponseCopyWithImpl<$Res>
    implements _$TaskResponseCopyWith<$Res> {
  __$TaskResponseCopyWithImpl(this._self, this._then);

  final _TaskResponse _self;
  final $Res Function(_TaskResponse) _then;

/// Create a copy of TaskResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? taskId = null,Object? variantId = null,Object? responseText = null,Object? latencyMs = null,Object? inputTokens = freezed,Object? outputTokens = freezed,Object? cacheCreationInputTokens = freezed,Object? cacheReadInputTokens = freezed,Object? costUsd = freezed,}) {
  return _then(_TaskResponse(
taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,variantId: null == variantId ? _self.variantId : variantId // ignore: cast_nullable_to_non_nullable
as String,responseText: null == responseText ? _self.responseText : responseText // ignore: cast_nullable_to_non_nullable
as String,latencyMs: null == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as int,inputTokens: freezed == inputTokens ? _self.inputTokens : inputTokens // ignore: cast_nullable_to_non_nullable
as int?,outputTokens: freezed == outputTokens ? _self.outputTokens : outputTokens // ignore: cast_nullable_to_non_nullable
as int?,cacheCreationInputTokens: freezed == cacheCreationInputTokens ? _self.cacheCreationInputTokens : cacheCreationInputTokens // ignore: cast_nullable_to_non_nullable
as int?,cacheReadInputTokens: freezed == cacheReadInputTokens ? _self.cacheReadInputTokens : cacheReadInputTokens // ignore: cast_nullable_to_non_nullable
as int?,costUsd: freezed == costUsd ? _self.costUsd : costUsd // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
