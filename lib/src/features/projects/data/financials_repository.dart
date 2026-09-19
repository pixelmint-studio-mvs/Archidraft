import '../domain/financials.dart';
import '../../api/data/api_client.dart';

class FinancialsRepository {
  final ApiClient _apiClient;

  FinancialsRepository(this._apiClient);

  Future<ProjectFinancials> getProjectFinancials(String projectId) async {
    final response = await _apiClient.get(
      '/api/projects/$projectId/financials',
    );
    return ProjectFinancials.fromJson(response as Map<String, dynamic>);
  }

  Future<double> setTotalValue(String projectId, double totalValue) async {
    final response = await _apiClient.patch(
      '/api/projects/$projectId/financials/total_value',
      body: {'total_value': totalValue},
    );
    return (response['total_value'] as num).toDouble();
  }

  Future<Invoice> createInvoice({
    required String projectId,
    required double amount,
    required DateTime dueDate,
  }) async {
    final response = await _apiClient.post(
      '/api/projects/$projectId/invoices',
      body: {'amount': amount, 'due_date': dueDate.toIso8601String()},
    );

    return Invoice(
      id: response['id'],
      projectId: projectId,
      invoiceNumber: response['invoice_number'],
      amount: amount,
      currency: 'INR',
      status: InvoiceStatus.issued,
      dueDate: dueDate,
      createdAt: DateTime.now(),
    );
  }

  Future<Payment> recordPayment({
    required String invoiceId,
    required double amount,
    required PaymentMethod paymentMethod,
  }) async {
    final response = await _apiClient.post(
      '/api/invoices/$invoiceId/payments',
      body: {
        'amount': amount,
        'payment_method': _getPaymentMethodString(paymentMethod),
      },
    );

    // Returning a partial payment object since the API only returns { success, payment_id, new_status }.
    // We will typically just invalidate the provider.
    return Payment(
      id: response['payment_id'],
      invoiceId: invoiceId,
      amount: amount,
      paymentMethod: paymentMethod,
      processedAt: DateTime.now(),
      recordedBy: 'admin', // Optimistic UI
    );
  }

  String _getPaymentMethodString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.bankTransfer:
        return 'BANK_TRANSFER';
      case PaymentMethod.creditCard:
        return 'CREDIT_CARD';
      case PaymentMethod.cash:
        return 'CASH';
      case PaymentMethod.cheque:
        return 'CHEQUE';
      case PaymentMethod.manual:
        return 'MANUAL';
    }
  }
}
