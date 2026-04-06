// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'test_task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TestTask {

 String get id; String get name; String get category; String get userMessage;
/// Create a copy of TestTask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TestTaskCopyWith<TestTask> get copyWith => _$TestTaskCopyWithImpl<TestTask>(this as TestTask, _$identity);

  /// Serializes this TestTask to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TestTask&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.userMessage, userMessage) || other.userMessage == userMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,category,userMessage);

@override
String toString() {
  return 'TestTask(id: $id, name: $name, category: $category, userMessage: $userMessage)';
}


}

/// @nodoc
abstract mixin class $TestTaskCopyWith<$Res>  {
  factory $TestTaskCopyWith(TestTask value, $Res Function(TestTask) _then) = _$TestTaskCopyWithImpl;
@useResult
$Res call({
 String id, String name, String category, String userMessage
});




}
/// @nodoc
class _$TestTaskCopyWithImpl<$Res>
    implements $TestTaskCopyWith<$Res> {
  _$TestTaskCopyWithImpl(this._self, this._then);

  final TestTask _self;
  final $Res Function(TestTask) _then;

/// Create a copy of TestTask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? category = null,Object? userMessage = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,userMessage: null == userMessage ? _self.userMessage : userMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TestTask].
extension TestTaskPatterns on TestTask {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TestTask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TestTask() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TestTask value)  $default,){
final _that = this;
switch (_that) {
case _TestTask():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TestTask value)?  $default,){
final _that = this;
switch (_that) {
case _TestTask() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String category,  String userMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TestTask() when $default != null:
return $default(_that.id,_that.name,_that.category,_that.userMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String category,  String userMessage)  $default,) {final _that = this;
switch (_that) {
case _TestTask():
return $default(_that.id,_that.name,_that.category,_that.userMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String category,  String userMessage)?  $default,) {final _that = this;
switch (_that) {
case _TestTask() when $default != null:
return $default(_that.id,_that.name,_that.category,_that.userMessage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TestTask implements TestTask {
  const _TestTask({required this.id, required this.name, required this.category, required this.userMessage});
  factory _TestTask.fromJson(Map<String, dynamic> json) => _$TestTaskFromJson(json);

@override final  String id;
@override final  String name;
@override final  String category;
@override final  String userMessage;

/// Create a copy of TestTask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TestTaskCopyWith<_TestTask> get copyWith => __$TestTaskCopyWithImpl<_TestTask>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TestTaskToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TestTask&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.userMessage, userMessage) || other.userMessage == userMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,category,userMessage);

@override
String toString() {
  return 'TestTask(id: $id, name: $name, category: $category, userMessage: $userMessage)';
}


}

/// @nodoc
abstract mixin class _$TestTaskCopyWith<$Res> implements $TestTaskCopyWith<$Res> {
  factory _$TestTaskCopyWith(_TestTask value, $Res Function(_TestTask) _then) = __$TestTaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String category, String userMessage
});




}
/// @nodoc
class __$TestTaskCopyWithImpl<$Res>
    implements _$TestTaskCopyWith<$Res> {
  __$TestTaskCopyWithImpl(this._self, this._then);

  final _TestTask _self;
  final $Res Function(_TestTask) _then;

/// Create a copy of TestTask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? category = null,Object? userMessage = null,}) {
  return _then(_TestTask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,userMessage: null == userMessage ? _self.userMessage : userMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
