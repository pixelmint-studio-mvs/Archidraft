// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'financials.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Invoice {

 String get id;@JsonKey(name: 'project_id') String get projectId;@JsonKey(name: 'invoice_number') String get invoiceNumber;@JsonKey(fromJson: _parseDouble) double get amount; String get currency; InvoiceStatus get status;@JsonKey(name: 'due_date') DateTime get dueDate;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of Invoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvoiceCopyWith<Invoice> get copyWith => _$InvoiceCopyWithImpl<Invoice>(this as Invoice, _$identity);

  /// Serializes this Invoice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Invoice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Invoice&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.projectId, _this.projectId) || other.projectId == _this.projectId)&&(identical(other.invoiceNumber, _this.invoiceNumber) || other.invoiceNumber == _this.invoiceNumber)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.dueDate, _this.dueDate) || other.dueDate == _this.dueDate)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Invoice;
  return Object.hash(runtimeType,_this.id,_this.projectId,_this.invoiceNumber,_this.amount,_this.currency,_this.status,_this.dueDate,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as Invoice;
  return 'Invoice(id: ${_this.id}, projectId: ${_this.projectId}, invoiceNumber: ${_this.invoiceNumber}, amount: ${_this.amount}, currency: ${_this.currency}, status: ${_this.status}, dueDate: ${_this.dueDate}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $InvoiceCopyWith<$Res>  {
  factory $InvoiceCopyWith(Invoice value, $Res Function(Invoice) _then) = _$InvoiceCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'project_id') String projectId,@JsonKey(name: 'invoice_number') String invoiceNumber,@JsonKey(fromJson: _parseDouble) double amount, String currency, InvoiceStatus status,@JsonKey(name: 'due_date') DateTime dueDate,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class _$InvoiceCopyWithImpl<$Res>
    implements $InvoiceCopyWith<$Res> {
  _$InvoiceCopyWithImpl(this._self, this._then);

  final Invoice _self;
  final $Res Function(Invoice) _then;

/// Create a copy of Invoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? projectId = null,Object? invoiceNumber = null,Object? amount = null,Object? currency = null,Object? status = null,Object? dueDate = null,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(Invoice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,projectId: null == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String,invoiceNumber: null == invoiceNumber ? _self.invoiceNumber : invoiceNumber // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InvoiceStatus,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Invoice].
extension InvoicePatterns on Invoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Invoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Invoice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Invoice value)  $default,){
final _that = this;
switch (_that) {
case _Invoice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Invoice value)?  $default,){
final _that = this;
switch (_that) {
case _Invoice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'project_id')  String projectId, @JsonKey(name: 'invoice_number')  String invoiceNumber, @JsonKey(fromJson: _parseDouble)  double amount,  String currency,  InvoiceStatus status, @JsonKey(name: 'due_date')  DateTime dueDate, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Invoice() when $default != null:
return $default(_that.id,_that.projectId,_that.invoiceNumber,_that.amount,_that.currency,_that.status,_that.dueDate,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'project_id')  String projectId, @JsonKey(name: 'invoice_number')  String invoiceNumber, @JsonKey(fromJson: _parseDouble)  double amount,  String currency,  InvoiceStatus status, @JsonKey(name: 'due_date')  DateTime dueDate, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Invoice():
return $default(_that.id,_that.projectId,_that.invoiceNumber,_that.amount,_that.currency,_that.status,_that.dueDate,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'project_id')  String projectId, @JsonKey(name: 'invoice_number')  String invoiceNumber, @JsonKey(fromJson: _parseDouble)  double amount,  String currency,  InvoiceStatus status, @JsonKey(name: 'due_date')  DateTime dueDate, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Invoice() when $default != null:
return $default(_that.id,_that.projectId,_that.invoiceNumber,_that.amount,_that.currency,_that.status,_that.dueDate,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Invoice implements Invoice {
  const _Invoice({required this.id, @JsonKey(name: 'project_id') required this.projectId, @JsonKey(name: 'invoice_number') required this.invoiceNumber, @JsonKey(fromJson: _parseDouble) required this.amount, required this.currency, required this.status, @JsonKey(name: 'due_date') required this.dueDate, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt});
  factory _Invoice.fromJson(Map<String, dynamic> json) => _$InvoiceFromJson(json);

@override final  String id;
@override@JsonKey(name: 'project_id') final  String projectId;
@override@JsonKey(name: 'invoice_number') final  String invoiceNumber;
@override@JsonKey(fromJson: _parseDouble) final  double amount;
@override final  String currency;
@override final  InvoiceStatus status;
@override@JsonKey(name: 'due_date') final  DateTime dueDate;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of Invoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvoiceCopyWith<_Invoice> get copyWith => __$InvoiceCopyWithImpl<_Invoice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvoiceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Invoice&&(identical(other.id, id) || other.id == id)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.invoiceNumber, invoiceNumber) || other.invoiceNumber == invoiceNumber)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.status, status) || other.status == status)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,projectId,invoiceNumber,amount,currency,status,dueDate,createdAt,updatedAt);
}

@override
String toString() {
    return 'Invoice(id: $id, projectId: $projectId, invoiceNumber: $invoiceNumber, amount: $amount, currency: $currency, status: $status, dueDate: $dueDate, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$InvoiceCopyWith<$Res> implements $InvoiceCopyWith<$Res> {
  factory _$InvoiceCopyWith(_Invoice value, $Res Function(_Invoice) _then) = __$InvoiceCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'project_id') String projectId,@JsonKey(name: 'invoice_number') String invoiceNumber,@JsonKey(fromJson: _parseDouble) double amount, String currency, InvoiceStatus status,@JsonKey(name: 'due_date') DateTime dueDate,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class __$InvoiceCopyWithImpl<$Res>
    implements _$InvoiceCopyWith<$Res> {
  __$InvoiceCopyWithImpl(this._self, this._then);

  final _Invoice _self;
  final $Res Function(_Invoice) _then;

/// Create a copy of Invoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? projectId = null,Object? invoiceNumber = null,Object? amount = null,Object? currency = null,Object? status = null,Object? dueDate = null,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_Invoice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,projectId: null == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String,invoiceNumber: null == invoiceNumber ? _self.invoiceNumber : invoiceNumber // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InvoiceStatus,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$Payment {

 String get id;@JsonKey(name: 'invoice_id') String get invoiceId;@JsonKey(fromJson: _parseDouble) double get amount;@JsonKey(name: 'payment_method') PaymentMethod get paymentMethod;@JsonKey(name: 'processed_at') DateTime get processedAt;@JsonKey(name: 'recorded_by') String get recordedBy;
/// Create a copy of Payment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentCopyWith<Payment> get copyWith => _$PaymentCopyWithImpl<Payment>(this as Payment, _$identity);

  /// Serializes this Payment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Payment;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Payment&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.invoiceId, _this.invoiceId) || other.invoiceId == _this.invoiceId)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.paymentMethod, _this.paymentMethod) || other.paymentMethod == _this.paymentMethod)&&(identical(other.processedAt, _this.processedAt) || other.processedAt == _this.processedAt)&&(identical(other.recordedBy, _this.recordedBy) || other.recordedBy == _this.recordedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Payment;
  return Object.hash(runtimeType,_this.id,_this.invoiceId,_this.amount,_this.paymentMethod,_this.processedAt,_this.recordedBy);
}

@override
String toString() {
  final _this = this as Payment;
  return 'Payment(id: ${_this.id}, invoiceId: ${_this.invoiceId}, amount: ${_this.amount}, paymentMethod: ${_this.paymentMethod}, processedAt: ${_this.processedAt}, recordedBy: ${_this.recordedBy})';
}


}

/// @nodoc
abstract mixin class $PaymentCopyWith<$Res>  {
  factory $PaymentCopyWith(Payment value, $Res Function(Payment) _then) = _$PaymentCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'invoice_id') String invoiceId,@JsonKey(fromJson: _parseDouble) double amount,@JsonKey(name: 'payment_method') PaymentMethod paymentMethod,@JsonKey(name: 'processed_at') DateTime processedAt,@JsonKey(name: 'recorded_by') String recordedBy
});




}
/// @nodoc
class _$PaymentCopyWithImpl<$Res>
    implements $PaymentCopyWith<$Res> {
  _$PaymentCopyWithImpl(this._self, this._then);

  final Payment _self;
  final $Res Function(Payment) _then;

/// Create a copy of Payment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? invoiceId = null,Object? amount = null,Object? paymentMethod = null,Object? processedAt = null,Object? recordedBy = null,}) {
  return _then(Payment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,invoiceId: null == invoiceId ? _self.invoiceId : invoiceId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as PaymentMethod,processedAt: null == processedAt ? _self.processedAt : processedAt // ignore: cast_nullable_to_non_nullable
as DateTime,recordedBy: null == recordedBy ? _self.recordedBy : recordedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Payment].
extension PaymentPatterns on Payment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Payment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Payment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Payment value)  $default,){
final _that = this;
switch (_that) {
case _Payment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Payment value)?  $default,){
final _that = this;
switch (_that) {
case _Payment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'invoice_id')  String invoiceId, @JsonKey(fromJson: _parseDouble)  double amount, @JsonKey(name: 'payment_method')  PaymentMethod paymentMethod, @JsonKey(name: 'processed_at')  DateTime processedAt, @JsonKey(name: 'recorded_by')  String recordedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Payment() when $default != null:
return $default(_that.id,_that.invoiceId,_that.amount,_that.paymentMethod,_that.processedAt,_that.recordedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'invoice_id')  String invoiceId, @JsonKey(fromJson: _parseDouble)  double amount, @JsonKey(name: 'payment_method')  PaymentMethod paymentMethod, @JsonKey(name: 'processed_at')  DateTime processedAt, @JsonKey(name: 'recorded_by')  String recordedBy)  $default,) {final _that = this;
switch (_that) {
case _Payment():
return $default(_that.id,_that.invoiceId,_that.amount,_that.paymentMethod,_that.processedAt,_that.recordedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'invoice_id')  String invoiceId, @JsonKey(fromJson: _parseDouble)  double amount, @JsonKey(name: 'payment_method')  PaymentMethod paymentMethod, @JsonKey(name: 'processed_at')  DateTime processedAt, @JsonKey(name: 'recorded_by')  String recordedBy)?  $default,) {final _that = this;
switch (_that) {
case _Payment() when $default != null:
return $default(_that.id,_that.invoiceId,_that.amount,_that.paymentMethod,_that.processedAt,_that.recordedBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Payment implements Payment {
  const _Payment({required this.id, @JsonKey(name: 'invoice_id') required this.invoiceId, @JsonKey(fromJson: _parseDouble) required this.amount, @JsonKey(name: 'payment_method') required this.paymentMethod, @JsonKey(name: 'processed_at') required this.processedAt, @JsonKey(name: 'recorded_by') required this.recordedBy});
  factory _Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);

@override final  String id;
@override@JsonKey(name: 'invoice_id') final  String invoiceId;
@override@JsonKey(fromJson: _parseDouble) final  double amount;
@override@JsonKey(name: 'payment_method') final  PaymentMethod paymentMethod;
@override@JsonKey(name: 'processed_at') final  DateTime processedAt;
@override@JsonKey(name: 'recorded_by') final  String recordedBy;

/// Create a copy of Payment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentCopyWith<_Payment> get copyWith => __$PaymentCopyWithImpl<_Payment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Payment&&(identical(other.id, id) || other.id == id)&&(identical(other.invoiceId, invoiceId) || other.invoiceId == invoiceId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.processedAt, processedAt) || other.processedAt == processedAt)&&(identical(other.recordedBy, recordedBy) || other.recordedBy == recordedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,invoiceId,amount,paymentMethod,processedAt,recordedBy);
}

@override
String toString() {
    return 'Payment(id: $id, invoiceId: $invoiceId, amount: $amount, paymentMethod: $paymentMethod, processedAt: $processedAt, recordedBy: $recordedBy)';
}


}

/// @nodoc
abstract mixin class _$PaymentCopyWith<$Res> implements $PaymentCopyWith<$Res> {
  factory _$PaymentCopyWith(_Payment value, $Res Function(_Payment) _then) = __$PaymentCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'invoice_id') String invoiceId,@JsonKey(fromJson: _parseDouble) double amount,@JsonKey(name: 'payment_method') PaymentMethod paymentMethod,@JsonKey(name: 'processed_at') DateTime processedAt,@JsonKey(name: 'recorded_by') String recordedBy
});




}
/// @nodoc
class __$PaymentCopyWithImpl<$Res>
    implements _$PaymentCopyWith<$Res> {
  __$PaymentCopyWithImpl(this._self, this._then);

  final _Payment _self;
  final $Res Function(_Payment) _then;

/// Create a copy of Payment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? invoiceId = null,Object? amount = null,Object? paymentMethod = null,Object? processedAt = null,Object? recordedBy = null,}) {
  return _then(_Payment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,invoiceId: null == invoiceId ? _self.invoiceId : invoiceId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as PaymentMethod,processedAt: null == processedAt ? _self.processedAt : processedAt // ignore: cast_nullable_to_non_nullable
as DateTime,recordedBy: null == recordedBy ? _self.recordedBy : recordedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ProjectFinancials {

@JsonKey(name: 'total_value', fromJson: _parseDoubleNullable) double? get totalValue;@JsonKey(name: 'paid_amount', fromJson: _parseDouble) double get paidAmount;@JsonKey(name: 'outstanding_balance', fromJson: _parseDoubleNullable) double? get outstandingBalance; List<Invoice> get invoices; List<Payment> get payments;
/// Create a copy of ProjectFinancials
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectFinancialsCopyWith<ProjectFinancials> get copyWith => _$ProjectFinancialsCopyWithImpl<ProjectFinancials>(this as ProjectFinancials, _$identity);

  /// Serializes this ProjectFinancials to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ProjectFinancials;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectFinancials&&(identical(other.totalValue, _this.totalValue) || other.totalValue == _this.totalValue)&&(identical(other.paidAmount, _this.paidAmount) || other.paidAmount == _this.paidAmount)&&(identical(other.outstandingBalance, _this.outstandingBalance) || other.outstandingBalance == _this.outstandingBalance)&&const DeepCollectionEquality().equals(other.invoices, _this.invoices)&&const DeepCollectionEquality().equals(other.payments, _this.payments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ProjectFinancials;
  return Object.hash(runtimeType,_this.totalValue,_this.paidAmount,_this.outstandingBalance,const DeepCollectionEquality().hash(_this.invoices),const DeepCollectionEquality().hash(_this.payments));
}

@override
String toString() {
  final _this = this as ProjectFinancials;
  return 'ProjectFinancials(totalValue: ${_this.totalValue}, paidAmount: ${_this.paidAmount}, outstandingBalance: ${_this.outstandingBalance}, invoices: ${_this.invoices}, payments: ${_this.payments})';
}


}

/// @nodoc
abstract mixin class $ProjectFinancialsCopyWith<$Res>  {
  factory $ProjectFinancialsCopyWith(ProjectFinancials value, $Res Function(ProjectFinancials) _then) = _$ProjectFinancialsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'total_value', fromJson: _parseDoubleNullable) double? totalValue,@JsonKey(name: 'paid_amount', fromJson: _parseDouble) double paidAmount,@JsonKey(name: 'outstanding_balance', fromJson: _parseDoubleNullable) double? outstandingBalance, List<Invoice> invoices, List<Payment> payments
});




}
/// @nodoc
class _$ProjectFinancialsCopyWithImpl<$Res>
    implements $ProjectFinancialsCopyWith<$Res> {
  _$ProjectFinancialsCopyWithImpl(this._self, this._then);

  final ProjectFinancials _self;
  final $Res Function(ProjectFinancials) _then;

/// Create a copy of ProjectFinancials
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalValue = freezed,Object? paidAmount = null,Object? outstandingBalance = freezed,Object? invoices = null,Object? payments = null,}) {
  return _then(ProjectFinancials(
totalValue: freezed == totalValue ? _self.totalValue : totalValue // ignore: cast_nullable_to_non_nullable
as double?,paidAmount: null == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as double,outstandingBalance: freezed == outstandingBalance ? _self.outstandingBalance : outstandingBalance // ignore: cast_nullable_to_non_nullable
as double?,invoices: null == invoices ? _self.invoices : invoices // ignore: cast_nullable_to_non_nullable
as List<Invoice>,payments: null == payments ? _self.payments : payments // ignore: cast_nullable_to_non_nullable
as List<Payment>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectFinancials].
extension ProjectFinancialsPatterns on ProjectFinancials {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectFinancials value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectFinancials() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectFinancials value)  $default,){
final _that = this;
switch (_that) {
case _ProjectFinancials():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectFinancials value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectFinancials() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'total_value', fromJson: _parseDoubleNullable)  double? totalValue, @JsonKey(name: 'paid_amount', fromJson: _parseDouble)  double paidAmount, @JsonKey(name: 'outstanding_balance', fromJson: _parseDoubleNullable)  double? outstandingBalance,  List<Invoice> invoices,  List<Payment> payments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectFinancials() when $default != null:
return $default(_that.totalValue,_that.paidAmount,_that.outstandingBalance,_that.invoices,_that.payments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'total_value', fromJson: _parseDoubleNullable)  double? totalValue, @JsonKey(name: 'paid_amount', fromJson: _parseDouble)  double paidAmount, @JsonKey(name: 'outstanding_balance', fromJson: _parseDoubleNullable)  double? outstandingBalance,  List<Invoice> invoices,  List<Payment> payments)  $default,) {final _that = this;
switch (_that) {
case _ProjectFinancials():
return $default(_that.totalValue,_that.paidAmount,_that.outstandingBalance,_that.invoices,_that.payments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'total_value', fromJson: _parseDoubleNullable)  double? totalValue, @JsonKey(name: 'paid_amount', fromJson: _parseDouble)  double paidAmount, @JsonKey(name: 'outstanding_balance', fromJson: _parseDoubleNullable)  double? outstandingBalance,  List<Invoice> invoices,  List<Payment> payments)?  $default,) {final _that = this;
switch (_that) {
case _ProjectFinancials() when $default != null:
return $default(_that.totalValue,_that.paidAmount,_that.outstandingBalance,_that.invoices,_that.payments);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectFinancials implements ProjectFinancials {
  const _ProjectFinancials({@JsonKey(name: 'total_value', fromJson: _parseDoubleNullable) this.totalValue, @JsonKey(name: 'paid_amount', fromJson: _parseDouble) required this.paidAmount, @JsonKey(name: 'outstanding_balance', fromJson: _parseDoubleNullable) this.outstandingBalance,  List<Invoice> invoices = const [],  List<Payment> payments = const []}): _invoices = invoices,_payments = payments;
  factory _ProjectFinancials.fromJson(Map<String, dynamic> json) => _$ProjectFinancialsFromJson(json);

@override@JsonKey(name: 'total_value', fromJson: _parseDoubleNullable) final  double? totalValue;
@override@JsonKey(name: 'paid_amount', fromJson: _parseDouble) final  double paidAmount;
@override@JsonKey(name: 'outstanding_balance', fromJson: _parseDoubleNullable) final  double? outstandingBalance;
 final  List<Invoice> _invoices;
@override@JsonKey() List<Invoice> get invoices {
  if (_invoices is EqualUnmodifiableListView) return _invoices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_invoices);
}

 final  List<Payment> _payments;
@override@JsonKey() List<Payment> get payments {
  if (_payments is EqualUnmodifiableListView) return _payments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_payments);
}


/// Create a copy of ProjectFinancials
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectFinancialsCopyWith<_ProjectFinancials> get copyWith => __$ProjectFinancialsCopyWithImpl<_ProjectFinancials>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectFinancialsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectFinancials&&(identical(other.totalValue, totalValue) || other.totalValue == totalValue)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.outstandingBalance, outstandingBalance) || other.outstandingBalance == outstandingBalance)&&const DeepCollectionEquality().equals(other.invoices, _invoices)&&const DeepCollectionEquality().equals(other.payments, _payments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,totalValue,paidAmount,outstandingBalance,const DeepCollectionEquality().hash(_invoices),const DeepCollectionEquality().hash(_payments));
}

@override
String toString() {
    return 'ProjectFinancials(totalValue: $totalValue, paidAmount: $paidAmount, outstandingBalance: $outstandingBalance, invoices: $invoices, payments: $payments)';
}


}

/// @nodoc
abstract mixin class _$ProjectFinancialsCopyWith<$Res> implements $ProjectFinancialsCopyWith<$Res> {
  factory _$ProjectFinancialsCopyWith(_ProjectFinancials value, $Res Function(_ProjectFinancials) _then) = __$ProjectFinancialsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'total_value', fromJson: _parseDoubleNullable) double? totalValue,@JsonKey(name: 'paid_amount', fromJson: _parseDouble) double paidAmount,@JsonKey(name: 'outstanding_balance', fromJson: _parseDoubleNullable) double? outstandingBalance, List<Invoice> invoices, List<Payment> payments
});




}
/// @nodoc
class __$ProjectFinancialsCopyWithImpl<$Res>
    implements _$ProjectFinancialsCopyWith<$Res> {
  __$ProjectFinancialsCopyWithImpl(this._self, this._then);

  final _ProjectFinancials _self;
  final $Res Function(_ProjectFinancials) _then;

/// Create a copy of ProjectFinancials
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalValue = freezed,Object? paidAmount = null,Object? outstandingBalance = freezed,Object? invoices = null,Object? payments = null,}) {
  return _then(_ProjectFinancials(
totalValue: freezed == totalValue ? _self.totalValue : totalValue // ignore: cast_nullable_to_non_nullable
as double?,paidAmount: null == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as double,outstandingBalance: freezed == outstandingBalance ? _self.outstandingBalance : outstandingBalance // ignore: cast_nullable_to_non_nullable
as double?,invoices: null == invoices ? _self._invoices : invoices // ignore: cast_nullable_to_non_nullable
as List<Invoice>,payments: null == payments ? _self._payments : payments // ignore: cast_nullable_to_non_nullable
as List<Payment>,
  ));
}


}

// dart format on
