import 'package:freezed_annotation/freezed_annotation.dart';

part 'financials.freezed.dart';
part 'financials.g.dart';

enum InvoiceStatus {
  @JsonValue('ISSUED')
  issued,
  @JsonValue('PARTIALLY_PAID')
  partiallyPaid,
  @JsonValue('PAID')
  paid,
  @JsonValue('OVERDUE')
  overdue,
  @JsonValue('CANCELLED') // Just in case, though removed from rules
  cancelled,
}

enum PaymentMethod {
  @JsonValue('BANK_TRANSFER')
  bankTransfer,
  @JsonValue('CREDIT_CARD')
  creditCard,
  @JsonValue('CASH')
  cash,
  @JsonValue('CHEQUE')
  cheque,
  @JsonValue('MANUAL')
  manual,
}

double? _parseDoubleNullable(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

double _parseDouble(dynamic value) {
  return _parseDoubleNullable(value) ?? 0.0;
}

@freezed
abstract class Invoice with _$Invoice {
  const factory Invoice({
    required String id,
    @JsonKey(name: 'project_id') required String projectId,
    @JsonKey(name: 'invoice_number') required String invoiceNumber,
    @JsonKey(fromJson: _parseDouble) required double amount,
    required String currency,
    required InvoiceStatus status,
    @JsonKey(name: 'due_date') required DateTime dueDate,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Invoice;

  factory Invoice.fromJson(Map<String, dynamic> json) =>
      _$InvoiceFromJson(json);
}

@freezed
abstract class Payment with _$Payment {
  const factory Payment({
    required String id,
    @JsonKey(name: 'invoice_id') required String invoiceId,
    @JsonKey(fromJson: _parseDouble) required double amount,
    @JsonKey(name: 'payment_method') required PaymentMethod paymentMethod,
    @JsonKey(name: 'processed_at') required DateTime processedAt,
    @JsonKey(name: 'recorded_by') required String recordedBy,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);
}

@freezed
abstract class ProjectFinancials with _$ProjectFinancials {
  const factory ProjectFinancials({
    @JsonKey(name: 'total_value', fromJson: _parseDoubleNullable)
    double? totalValue,
    @JsonKey(name: 'paid_amount', fromJson: _parseDouble)
    required double paidAmount,
    @JsonKey(name: 'outstanding_balance', fromJson: _parseDoubleNullable)
    double? outstandingBalance,
    @Default([]) List<Invoice> invoices,
    @Default([]) List<Payment> payments,
  }) = _ProjectFinancials;

  factory ProjectFinancials.fromJson(Map<String, dynamic> json) =>
      _$ProjectFinancialsFromJson(json);
}

// EOF
