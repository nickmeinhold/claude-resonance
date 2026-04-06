// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'prompt_variant.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PromptVariant {

 String get id; String get systemPrompt; int get generation;/// Single parent for backward compatibility (simple mutations).
 String? get parentId; DateTime get createdAt; String? get researcherHypothesis; String? get researcherRationale;/// The MAP-Elites strategy classification for this variant.
 String? get strategyType;/// Multiple parent IDs for crossover offspring.
 List<String>? get parentIds;/// Which mutation operator produced this variant.
 String? get mutationOperator;
/// Create a copy of PromptVariant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PromptVariantCopyWith<PromptVariant> get copyWith => _$PromptVariantCopyWithImpl<PromptVariant>(this as PromptVariant, _$identity);

  /// Serializes this PromptVariant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PromptVariant&&(identical(other.id, id) || other.id == id)&&(identical(other.systemPrompt, systemPrompt) || other.systemPrompt == systemPrompt)&&(identical(other.generation, generation) || other.generation == generation)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.researcherHypothesis, researcherHypothesis) || other.researcherHypothesis == researcherHypothesis)&&(identical(other.researcherRationale, researcherRationale) || other.researcherRationale == researcherRationale)&&(identical(other.strategyType, strategyType) || other.strategyType == strategyType)&&const DeepCollectionEquality().equals(other.parentIds, parentIds)&&(identical(other.mutationOperator, mutationOperator) || other.mutationOperator == mutationOperator));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,systemPrompt,generation,parentId,createdAt,researcherHypothesis,researcherRationale,strategyType,const DeepCollectionEquality().hash(parentIds),mutationOperator);

@override
String toString() {
  return 'PromptVariant(id: $id, systemPrompt: $systemPrompt, generation: $generation, parentId: $parentId, createdAt: $createdAt, researcherHypothesis: $researcherHypothesis, researcherRationale: $researcherRationale, strategyType: $strategyType, parentIds: $parentIds, mutationOperator: $mutationOperator)';
}


}

/// @nodoc
abstract mixin class $PromptVariantCopyWith<$Res>  {
  factory $PromptVariantCopyWith(PromptVariant value, $Res Function(PromptVariant) _then) = _$PromptVariantCopyWithImpl;
@useResult
$Res call({
 String id, String systemPrompt, int generation, String? parentId, DateTime createdAt, String? researcherHypothesis, String? researcherRationale, String? strategyType, List<String>? parentIds, String? mutationOperator
});




}
/// @nodoc
class _$PromptVariantCopyWithImpl<$Res>
    implements $PromptVariantCopyWith<$Res> {
  _$PromptVariantCopyWithImpl(this._self, this._then);

  final PromptVariant _self;
  final $Res Function(PromptVariant) _then;

/// Create a copy of PromptVariant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? systemPrompt = null,Object? generation = null,Object? parentId = freezed,Object? createdAt = null,Object? researcherHypothesis = freezed,Object? researcherRationale = freezed,Object? strategyType = freezed,Object? parentIds = freezed,Object? mutationOperator = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,systemPrompt: null == systemPrompt ? _self.systemPrompt : systemPrompt // ignore: cast_nullable_to_non_nullable
as String,generation: null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as int,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,researcherHypothesis: freezed == researcherHypothesis ? _self.researcherHypothesis : researcherHypothesis // ignore: cast_nullable_to_non_nullable
as String?,researcherRationale: freezed == researcherRationale ? _self.researcherRationale : researcherRationale // ignore: cast_nullable_to_non_nullable
as String?,strategyType: freezed == strategyType ? _self.strategyType : strategyType // ignore: cast_nullable_to_non_nullable
as String?,parentIds: freezed == parentIds ? _self.parentIds : parentIds // ignore: cast_nullable_to_non_nullable
as List<String>?,mutationOperator: freezed == mutationOperator ? _self.mutationOperator : mutationOperator // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PromptVariant].
extension PromptVariantPatterns on PromptVariant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PromptVariant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PromptVariant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PromptVariant value)  $default,){
final _that = this;
switch (_that) {
case _PromptVariant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PromptVariant value)?  $default,){
final _that = this;
switch (_that) {
case _PromptVariant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String systemPrompt,  int generation,  String? parentId,  DateTime createdAt,  String? researcherHypothesis,  String? researcherRationale,  String? strategyType,  List<String>? parentIds,  String? mutationOperator)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PromptVariant() when $default != null:
return $default(_that.id,_that.systemPrompt,_that.generation,_that.parentId,_that.createdAt,_that.researcherHypothesis,_that.researcherRationale,_that.strategyType,_that.parentIds,_that.mutationOperator);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String systemPrompt,  int generation,  String? parentId,  DateTime createdAt,  String? researcherHypothesis,  String? researcherRationale,  String? strategyType,  List<String>? parentIds,  String? mutationOperator)  $default,) {final _that = this;
switch (_that) {
case _PromptVariant():
return $default(_that.id,_that.systemPrompt,_that.generation,_that.parentId,_that.createdAt,_that.researcherHypothesis,_that.researcherRationale,_that.strategyType,_that.parentIds,_that.mutationOperator);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String systemPrompt,  int generation,  String? parentId,  DateTime createdAt,  String? researcherHypothesis,  String? researcherRationale,  String? strategyType,  List<String>? parentIds,  String? mutationOperator)?  $default,) {final _that = this;
switch (_that) {
case _PromptVariant() when $default != null:
return $default(_that.id,_that.systemPrompt,_that.generation,_that.parentId,_that.createdAt,_that.researcherHypothesis,_that.researcherRationale,_that.strategyType,_that.parentIds,_that.mutationOperator);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PromptVariant implements PromptVariant {
  const _PromptVariant({required this.id, required this.systemPrompt, required this.generation, this.parentId, required this.createdAt, this.researcherHypothesis, this.researcherRationale, this.strategyType, final  List<String>? parentIds, this.mutationOperator}): _parentIds = parentIds;
  factory _PromptVariant.fromJson(Map<String, dynamic> json) => _$PromptVariantFromJson(json);

@override final  String id;
@override final  String systemPrompt;
@override final  int generation;
/// Single parent for backward compatibility (simple mutations).
@override final  String? parentId;
@override final  DateTime createdAt;
@override final  String? researcherHypothesis;
@override final  String? researcherRationale;
/// The MAP-Elites strategy classification for this variant.
@override final  String? strategyType;
/// Multiple parent IDs for crossover offspring.
 final  List<String>? _parentIds;
/// Multiple parent IDs for crossover offspring.
@override List<String>? get parentIds {
  final value = _parentIds;
  if (value == null) return null;
  if (_parentIds is EqualUnmodifiableListView) return _parentIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Which mutation operator produced this variant.
@override final  String? mutationOperator;

/// Create a copy of PromptVariant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PromptVariantCopyWith<_PromptVariant> get copyWith => __$PromptVariantCopyWithImpl<_PromptVariant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PromptVariantToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PromptVariant&&(identical(other.id, id) || other.id == id)&&(identical(other.systemPrompt, systemPrompt) || other.systemPrompt == systemPrompt)&&(identical(other.generation, generation) || other.generation == generation)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.researcherHypothesis, researcherHypothesis) || other.researcherHypothesis == researcherHypothesis)&&(identical(other.researcherRationale, researcherRationale) || other.researcherRationale == researcherRationale)&&(identical(other.strategyType, strategyType) || other.strategyType == strategyType)&&const DeepCollectionEquality().equals(other._parentIds, _parentIds)&&(identical(other.mutationOperator, mutationOperator) || other.mutationOperator == mutationOperator));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,systemPrompt,generation,parentId,createdAt,researcherHypothesis,researcherRationale,strategyType,const DeepCollectionEquality().hash(_parentIds),mutationOperator);

@override
String toString() {
  return 'PromptVariant(id: $id, systemPrompt: $systemPrompt, generation: $generation, parentId: $parentId, createdAt: $createdAt, researcherHypothesis: $researcherHypothesis, researcherRationale: $researcherRationale, strategyType: $strategyType, parentIds: $parentIds, mutationOperator: $mutationOperator)';
}


}

/// @nodoc
abstract mixin class _$PromptVariantCopyWith<$Res> implements $PromptVariantCopyWith<$Res> {
  factory _$PromptVariantCopyWith(_PromptVariant value, $Res Function(_PromptVariant) _then) = __$PromptVariantCopyWithImpl;
@override @useResult
$Res call({
 String id, String systemPrompt, int generation, String? parentId, DateTime createdAt, String? researcherHypothesis, String? researcherRationale, String? strategyType, List<String>? parentIds, String? mutationOperator
});




}
/// @nodoc
class __$PromptVariantCopyWithImpl<$Res>
    implements _$PromptVariantCopyWith<$Res> {
  __$PromptVariantCopyWithImpl(this._self, this._then);

  final _PromptVariant _self;
  final $Res Function(_PromptVariant) _then;

/// Create a copy of PromptVariant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? systemPrompt = null,Object? generation = null,Object? parentId = freezed,Object? createdAt = null,Object? researcherHypothesis = freezed,Object? researcherRationale = freezed,Object? strategyType = freezed,Object? parentIds = freezed,Object? mutationOperator = freezed,}) {
  return _then(_PromptVariant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,systemPrompt: null == systemPrompt ? _self.systemPrompt : systemPrompt // ignore: cast_nullable_to_non_nullable
as String,generation: null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as int,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,researcherHypothesis: freezed == researcherHypothesis ? _self.researcherHypothesis : researcherHypothesis // ignore: cast_nullable_to_non_nullable
as String?,researcherRationale: freezed == researcherRationale ? _self.researcherRationale : researcherRationale // ignore: cast_nullable_to_non_nullable
as String?,strategyType: freezed == strategyType ? _self.strategyType : strategyType // ignore: cast_nullable_to_non_nullable
as String?,parentIds: freezed == parentIds ? _self._parentIds : parentIds // ignore: cast_nullable_to_non_nullable
as List<String>?,mutationOperator: freezed == mutationOperator ? _self.mutationOperator : mutationOperator // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
