// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'evaluation_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EvaluationResult {

 String get taskId; String get variantId; List<DimensionScore> get scores; double get aggregateScore; String? get notes;
/// Create a copy of EvaluationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EvaluationResultCopyWith<EvaluationResult> get copyWith => _$EvaluationResultCopyWithImpl<EvaluationResult>(this as EvaluationResult, _$identity);

  /// Serializes this EvaluationResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EvaluationResult&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.variantId, variantId) || other.variantId == variantId)&&const DeepCollectionEquality().equals(other.scores, scores)&&(identical(other.aggregateScore, aggregateScore) || other.aggregateScore == aggregateScore)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,taskId,variantId,const DeepCollectionEquality().hash(scores),aggregateScore,notes);

@override
String toString() {
  return 'EvaluationResult(taskId: $taskId, variantId: $variantId, scores: $scores, aggregateScore: $aggregateScore, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $EvaluationResultCopyWith<$Res>  {
  factory $EvaluationResultCopyWith(EvaluationResult value, $Res Function(EvaluationResult) _then) = _$EvaluationResultCopyWithImpl;
@useResult
$Res call({
 String taskId, String variantId, List<DimensionScore> scores, double aggregateScore, String? notes
});




}
/// @nodoc
class _$EvaluationResultCopyWithImpl<$Res>
    implements $EvaluationResultCopyWith<$Res> {
  _$EvaluationResultCopyWithImpl(this._self, this._then);

  final EvaluationResult _self;
  final $Res Function(EvaluationResult) _then;

/// Create a copy of EvaluationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? taskId = null,Object? variantId = null,Object? scores = null,Object? aggregateScore = null,Object? notes = freezed,}) {
  return _then(_self.copyWith(
taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,variantId: null == variantId ? _self.variantId : variantId // ignore: cast_nullable_to_non_nullable
as String,scores: null == scores ? _self.scores : scores // ignore: cast_nullable_to_non_nullable
as List<DimensionScore>,aggregateScore: null == aggregateScore ? _self.aggregateScore : aggregateScore // ignore: cast_nullable_to_non_nullable
as double,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [EvaluationResult].
extension EvaluationResultPatterns on EvaluationResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EvaluationResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EvaluationResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EvaluationResult value)  $default,){
final _that = this;
switch (_that) {
case _EvaluationResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EvaluationResult value)?  $default,){
final _that = this;
switch (_that) {
case _EvaluationResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String taskId,  String variantId,  List<DimensionScore> scores,  double aggregateScore,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EvaluationResult() when $default != null:
return $default(_that.taskId,_that.variantId,_that.scores,_that.aggregateScore,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String taskId,  String variantId,  List<DimensionScore> scores,  double aggregateScore,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _EvaluationResult():
return $default(_that.taskId,_that.variantId,_that.scores,_that.aggregateScore,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String taskId,  String variantId,  List<DimensionScore> scores,  double aggregateScore,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _EvaluationResult() when $default != null:
return $default(_that.taskId,_that.variantId,_that.scores,_that.aggregateScore,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EvaluationResult implements EvaluationResult {
  const _EvaluationResult({required this.taskId, required this.variantId, required final  List<DimensionScore> scores, required this.aggregateScore, this.notes}): _scores = scores;
  factory _EvaluationResult.fromJson(Map<String, dynamic> json) => _$EvaluationResultFromJson(json);

@override final  String taskId;
@override final  String variantId;
 final  List<DimensionScore> _scores;
@override List<DimensionScore> get scores {
  if (_scores is EqualUnmodifiableListView) return _scores;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_scores);
}

@override final  double aggregateScore;
@override final  String? notes;

/// Create a copy of EvaluationResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EvaluationResultCopyWith<_EvaluationResult> get copyWith => __$EvaluationResultCopyWithImpl<_EvaluationResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EvaluationResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EvaluationResult&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.variantId, variantId) || other.variantId == variantId)&&const DeepCollectionEquality().equals(other._scores, _scores)&&(identical(other.aggregateScore, aggregateScore) || other.aggregateScore == aggregateScore)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,taskId,variantId,const DeepCollectionEquality().hash(_scores),aggregateScore,notes);

@override
String toString() {
  return 'EvaluationResult(taskId: $taskId, variantId: $variantId, scores: $scores, aggregateScore: $aggregateScore, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$EvaluationResultCopyWith<$Res> implements $EvaluationResultCopyWith<$Res> {
  factory _$EvaluationResultCopyWith(_EvaluationResult value, $Res Function(_EvaluationResult) _then) = __$EvaluationResultCopyWithImpl;
@override @useResult
$Res call({
 String taskId, String variantId, List<DimensionScore> scores, double aggregateScore, String? notes
});




}
/// @nodoc
class __$EvaluationResultCopyWithImpl<$Res>
    implements _$EvaluationResultCopyWith<$Res> {
  __$EvaluationResultCopyWithImpl(this._self, this._then);

  final _EvaluationResult _self;
  final $Res Function(_EvaluationResult) _then;

/// Create a copy of EvaluationResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? taskId = null,Object? variantId = null,Object? scores = null,Object? aggregateScore = null,Object? notes = freezed,}) {
  return _then(_EvaluationResult(
taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,variantId: null == variantId ? _self.variantId : variantId // ignore: cast_nullable_to_non_nullable
as String,scores: null == scores ? _self._scores : scores // ignore: cast_nullable_to_non_nullable
as List<DimensionScore>,aggregateScore: null == aggregateScore ? _self.aggregateScore : aggregateScore // ignore: cast_nullable_to_non_nullable
as double,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
