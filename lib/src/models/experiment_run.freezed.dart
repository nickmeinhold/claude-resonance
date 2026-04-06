// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'experiment_run.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExperimentRun {

 int get generation; PromptVariant get variant; List<TaskResponse> get responses; List<EvaluationResult> get evaluations; double get overallScore; DateTime get startedAt; DateTime get completedAt;
/// Create a copy of ExperimentRun
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExperimentRunCopyWith<ExperimentRun> get copyWith => _$ExperimentRunCopyWithImpl<ExperimentRun>(this as ExperimentRun, _$identity);

  /// Serializes this ExperimentRun to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExperimentRun&&(identical(other.generation, generation) || other.generation == generation)&&(identical(other.variant, variant) || other.variant == variant)&&const DeepCollectionEquality().equals(other.responses, responses)&&const DeepCollectionEquality().equals(other.evaluations, evaluations)&&(identical(other.overallScore, overallScore) || other.overallScore == overallScore)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,generation,variant,const DeepCollectionEquality().hash(responses),const DeepCollectionEquality().hash(evaluations),overallScore,startedAt,completedAt);

@override
String toString() {
  return 'ExperimentRun(generation: $generation, variant: $variant, responses: $responses, evaluations: $evaluations, overallScore: $overallScore, startedAt: $startedAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class $ExperimentRunCopyWith<$Res>  {
  factory $ExperimentRunCopyWith(ExperimentRun value, $Res Function(ExperimentRun) _then) = _$ExperimentRunCopyWithImpl;
@useResult
$Res call({
 int generation, PromptVariant variant, List<TaskResponse> responses, List<EvaluationResult> evaluations, double overallScore, DateTime startedAt, DateTime completedAt
});


$PromptVariantCopyWith<$Res> get variant;

}
/// @nodoc
class _$ExperimentRunCopyWithImpl<$Res>
    implements $ExperimentRunCopyWith<$Res> {
  _$ExperimentRunCopyWithImpl(this._self, this._then);

  final ExperimentRun _self;
  final $Res Function(ExperimentRun) _then;

/// Create a copy of ExperimentRun
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? generation = null,Object? variant = null,Object? responses = null,Object? evaluations = null,Object? overallScore = null,Object? startedAt = null,Object? completedAt = null,}) {
  return _then(_self.copyWith(
generation: null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as int,variant: null == variant ? _self.variant : variant // ignore: cast_nullable_to_non_nullable
as PromptVariant,responses: null == responses ? _self.responses : responses // ignore: cast_nullable_to_non_nullable
as List<TaskResponse>,evaluations: null == evaluations ? _self.evaluations : evaluations // ignore: cast_nullable_to_non_nullable
as List<EvaluationResult>,overallScore: null == overallScore ? _self.overallScore : overallScore // ignore: cast_nullable_to_non_nullable
as double,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of ExperimentRun
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PromptVariantCopyWith<$Res> get variant {
  
  return $PromptVariantCopyWith<$Res>(_self.variant, (value) {
    return _then(_self.copyWith(variant: value));
  });
}
}


/// Adds pattern-matching-related methods to [ExperimentRun].
extension ExperimentRunPatterns on ExperimentRun {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExperimentRun value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExperimentRun() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExperimentRun value)  $default,){
final _that = this;
switch (_that) {
case _ExperimentRun():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExperimentRun value)?  $default,){
final _that = this;
switch (_that) {
case _ExperimentRun() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int generation,  PromptVariant variant,  List<TaskResponse> responses,  List<EvaluationResult> evaluations,  double overallScore,  DateTime startedAt,  DateTime completedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExperimentRun() when $default != null:
return $default(_that.generation,_that.variant,_that.responses,_that.evaluations,_that.overallScore,_that.startedAt,_that.completedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int generation,  PromptVariant variant,  List<TaskResponse> responses,  List<EvaluationResult> evaluations,  double overallScore,  DateTime startedAt,  DateTime completedAt)  $default,) {final _that = this;
switch (_that) {
case _ExperimentRun():
return $default(_that.generation,_that.variant,_that.responses,_that.evaluations,_that.overallScore,_that.startedAt,_that.completedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int generation,  PromptVariant variant,  List<TaskResponse> responses,  List<EvaluationResult> evaluations,  double overallScore,  DateTime startedAt,  DateTime completedAt)?  $default,) {final _that = this;
switch (_that) {
case _ExperimentRun() when $default != null:
return $default(_that.generation,_that.variant,_that.responses,_that.evaluations,_that.overallScore,_that.startedAt,_that.completedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExperimentRun implements ExperimentRun {
  const _ExperimentRun({required this.generation, required this.variant, required final  List<TaskResponse> responses, required final  List<EvaluationResult> evaluations, required this.overallScore, required this.startedAt, required this.completedAt}): _responses = responses,_evaluations = evaluations;
  factory _ExperimentRun.fromJson(Map<String, dynamic> json) => _$ExperimentRunFromJson(json);

@override final  int generation;
@override final  PromptVariant variant;
 final  List<TaskResponse> _responses;
@override List<TaskResponse> get responses {
  if (_responses is EqualUnmodifiableListView) return _responses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_responses);
}

 final  List<EvaluationResult> _evaluations;
@override List<EvaluationResult> get evaluations {
  if (_evaluations is EqualUnmodifiableListView) return _evaluations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_evaluations);
}

@override final  double overallScore;
@override final  DateTime startedAt;
@override final  DateTime completedAt;

/// Create a copy of ExperimentRun
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExperimentRunCopyWith<_ExperimentRun> get copyWith => __$ExperimentRunCopyWithImpl<_ExperimentRun>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExperimentRunToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExperimentRun&&(identical(other.generation, generation) || other.generation == generation)&&(identical(other.variant, variant) || other.variant == variant)&&const DeepCollectionEquality().equals(other._responses, _responses)&&const DeepCollectionEquality().equals(other._evaluations, _evaluations)&&(identical(other.overallScore, overallScore) || other.overallScore == overallScore)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,generation,variant,const DeepCollectionEquality().hash(_responses),const DeepCollectionEquality().hash(_evaluations),overallScore,startedAt,completedAt);

@override
String toString() {
  return 'ExperimentRun(generation: $generation, variant: $variant, responses: $responses, evaluations: $evaluations, overallScore: $overallScore, startedAt: $startedAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class _$ExperimentRunCopyWith<$Res> implements $ExperimentRunCopyWith<$Res> {
  factory _$ExperimentRunCopyWith(_ExperimentRun value, $Res Function(_ExperimentRun) _then) = __$ExperimentRunCopyWithImpl;
@override @useResult
$Res call({
 int generation, PromptVariant variant, List<TaskResponse> responses, List<EvaluationResult> evaluations, double overallScore, DateTime startedAt, DateTime completedAt
});


@override $PromptVariantCopyWith<$Res> get variant;

}
/// @nodoc
class __$ExperimentRunCopyWithImpl<$Res>
    implements _$ExperimentRunCopyWith<$Res> {
  __$ExperimentRunCopyWithImpl(this._self, this._then);

  final _ExperimentRun _self;
  final $Res Function(_ExperimentRun) _then;

/// Create a copy of ExperimentRun
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? generation = null,Object? variant = null,Object? responses = null,Object? evaluations = null,Object? overallScore = null,Object? startedAt = null,Object? completedAt = null,}) {
  return _then(_ExperimentRun(
generation: null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as int,variant: null == variant ? _self.variant : variant // ignore: cast_nullable_to_non_nullable
as PromptVariant,responses: null == responses ? _self._responses : responses // ignore: cast_nullable_to_non_nullable
as List<TaskResponse>,evaluations: null == evaluations ? _self._evaluations : evaluations // ignore: cast_nullable_to_non_nullable
as List<EvaluationResult>,overallScore: null == overallScore ? _self.overallScore : overallScore // ignore: cast_nullable_to_non_nullable
as double,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of ExperimentRun
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PromptVariantCopyWith<$Res> get variant {
  
  return $PromptVariantCopyWith<$Res>(_self.variant, (value) {
    return _then(_self.copyWith(variant: value));
  });
}
}

// dart format on
