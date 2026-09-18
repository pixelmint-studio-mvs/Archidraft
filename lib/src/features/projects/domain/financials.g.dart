// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'financials.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Invoice _$InvoiceFromJson(Map<String, dynamic> json) => _Invoice(
  id: json['id'] as String,
  projectId: json['project_id'] as String,
  invoiceNumber: json['invoice_number'] as String,
  amount: _parseDouble(json['amount']),
  currency: json['currency'] as String,
  status: $enumDecode(_$InvoiceStatusEnumMap, json['status']),
  dueDate: DateTime.parse(json['due_date'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$InvoiceToJson(_Invoice instance) => <String, dynamic>{
  'id': instance.id,
  'project_id': instance.projectId,
  'invoice_number': instance.invoiceNumber,
  'amount': instance.amount,
  'currency': instance.currency,
  'status': _$InvoiceStatusEnumMap[instance.status]!,
  'due_date': instance.dueDate.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

const _$InvoiceStatusEnumMap = {
  InvoiceStatus.issued: 'ISSUED',
  InvoiceStatus.partiallyPaid: 'PARTIALLY_PAID',
  InvoiceStatus.paid: 'PAID',
  InvoiceStatus.overdue: 'OVERDUE',
  InvoiceStatus.cancelled: 'CANCELLED',
};

_Payment _$PaymentFromJson(Map<String, dynamic> json) => _Payment(
  id: json['id'] as String,
  invoiceId: json['invoice_id'] as String,
  amount: _parseDouble(json['amount']),
  paymentMethod: $enumDecode(_$PaymentMethodEnumMap, json['payment_method']),
  processedAt: DateTime.parse(json['processed_at'] as String),
  recordedBy: json['recorded_by'] as String,
);

Map<String, dynamic> _$PaymentToJson(_Payment instance) => <String, dynamic>{
  'id': instance.id,
  'invoice_id': instance.invoiceId,
  'amount': instance.amount,
  'payment_method': _$PaymentMethodEnumMap[instance.paymentMethod]!,
  'processed_at': instance.processedAt.toIso8601String(),
  'recorded_by': instance.recordedBy,
};

const _$PaymentMethodEnumMap = {
  PaymentMethod.bankTransfer: 'BANK_TRANSFER',
  PaymentMethod.creditCard: 'CREDIT_CARD',
  PaymentMethod.cash: 'CASH',
  PaymentMethod.cheque: 'CHEQUE',
  PaymentMethod.manual: 'MANUAL',
};

_ProjectFinancials _$ProjectFinancialsFromJson(Map<String, dynamic> json) =>
    _ProjectFinancials(
      totalValue: _parseDoubleNullable(json['total_value']),
      paidAmount: _parseDouble(json['paid_amount']),
      outstandingBalance: _parseDoubleNullable(json['outstanding_balance']),
      invoices:
          (json['invoices'] as List<dynamic>?)
              ?.map((e) => Invoice.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      payments:
          (json['payments'] as List<dynamic>?)
              ?.map((e) => Payment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ProjectFinancialsToJson(_ProjectFinancials instance) =>
    <String, dynamic>{
      'total_value': instance.totalValue,
      'paid_amount': instance.paidAmount,
      'outstanding_balance': instance.outstandingBalance,
      'invoices': instance.invoices,
      'payments': instance.payments,
    };
