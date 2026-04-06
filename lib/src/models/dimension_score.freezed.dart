// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dimension_score.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DimensionScore {

 String get dimension; int get score; String get justification;
/// Create a copy of DimensionScore
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DimensionScoreCopyWith<DimensionScore> get copyWith => _$DimensionScoreCopyWithImpl<DimensionScore>(this as DimensionScore, _$identity);

  /// Serializes this DimensionScore to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DimensionScore&&(identical(other.dimension, dimension) || other.dimension == dimension)&&(identical(other.score, score) || other.score == score)&&(identical(other.justification, justification) || other.justification == justification));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dimension,score,justification);

@override
String toString() {
  return 'DimensionScore(dimension: $dimension, score: $score, justification: $justification)';
}


}

/// @nodoc
abstract mixin class $DimensionScoreCopyWith<$Res>  {
  factory $DimensionScoreCopyWith(DimensionScore value, $Res Function(DimensionScore) _then) = _$DimensionScoreCopyWithImpl;
@useResult
$Res call({
 String dimension, int score, String justification
});




}
/// @nodoc
class _$DimensionScoreCopyWithImpl<$Res>
    implements $DimensionScoreCopyWith<$Res> {
  _$DimensionScoreCopyWithImpl(this._self, this._then);

  final DimensionScore _self;
  final $Res Function(DimensionScore) _then;

/// Create a copy of DimensionScore
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dimension = null,Object? score = null,Object? justification = null,}) {
  return _then(_self.copyWith(
dimension: null == dimension ? _self.dimension : dimension // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,justification: null == justification ? _self.justification : justification // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DimensionScore].
extension DimensionScorePatterns on DimensionScore {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DimensionScore value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DimensionScore() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DimensionScore value)  $default,){
final _that = this;
switch (_that) {
case _DimensionScore():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DimensionScore value)?  $default,){
final _that = this;
switch (_that) {
case _DimensionScore() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String dimension,  int score,  String justification)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DimensionScore() when $default != null:
return $default(_that.dimension,_that.score,_that.justification);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String dimension,  int score,  String justification)  $default,) {final _that = this;
switch (_that) {
case _DimensionScore():
return $default(_that.dimension,_that.score,_that.justification);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String dimension,  int score,  String justification)?  $default,) {final _that = this;
switch (_that) {
case _DimensionScore() when $default != null:
return $default(_that.dimension,_that.score,_that.justification);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DimensionScore implements DimensionScore {
  const _DimensionScore({required this.dimension, required this.score, required this.justification});
  factory _DimensionScore.fromJson(Map<String, dynamic> json) => _$DimensionScoreFromJson(json);

@override final  String dimension;
@override final  int score;
@override final  String justification;

/// Create a copy of DimensionScore
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DimensionScoreCopyWith<_DimensionScore> get copyWith => __$DimensionScoreCopyWithImpl<_DimensionScore>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DimensionScoreToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DimensionScore&&(identical(other.dimension, dimension) || other.dimension == dimension)&&(identical(other.score, score) || other.score == score)&&(identical(other.justification, justification) || other.justification == justification));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dimension,score,justification);

@override
String toString() {
  return 'DimensionScore(dimension: $dimension, score: $score, justification: $justification)';
}


}

/// @nodoc
abstract mixin class _$DimensionScoreCopyWith<$Res> implements $DimensionScoreCopyWith<$Res> {
  factory _$DimensionScoreCopyWith(_DimensionScore value, $Res Function(_DimensionScore) _then) = __$DimensionScoreCopyWithImpl;
@override @useResult
$Res call({
 String dimension, int score, String justification
});




}
/// @nodoc
class __$DimensionScoreCopyWithImpl<$Res>
    implements _$DimensionScoreCopyWith<$Res> {
  __$DimensionScoreCopyWithImpl(this._self, this._then);

  final _DimensionScore _self;
  final $Res Function(_DimensionScore) _then;

/// Create a copy of DimensionScore
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dimension = null,Object? score = null,Object? justification = null,}) {
  return _then(_DimensionScore(
dimension: null == dimension ? _self.dimension : dimension // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,justification: null == justification ? _self.justification : justification // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
