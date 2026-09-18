import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/providers/auth_providers.dart';
import '../domain/financials.dart';
import '../providers/financials_providers.dart';

class FinancialsScreen extends ConsumerWidget {
  final String projectId;

  const FinancialsScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).value;
    final isAdmin = userProfile?.role == 'STUDIO_ADMIN';
    final financialsAsync = ref.watch(projectFinancialsProvider(projectId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Financials'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Set Total Value',
              onPressed: () => _showSetTotalValueDialog(context, ref),
            ),
        ],
      ),
      body: financialsAsync.when(
        data: (financials) => _buildContent(context, ref, financials, isAdmin),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: isAdmin && financialsAsync.hasValue
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateInvoiceDialog(context, ref, financialsAsync.value!),
              icon: const Icon(Icons.add),
              label: const Text('Create Invoice'),
            )
          : null,
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, ProjectFinancials financials, bool isAdmin) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildOverviewCards(context, financials),
        const SizedBox(height: 24),
        Text('Invoices', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...financials.invoices.map((inv) => _buildInvoiceCard(context, ref, inv, isAdmin)),
        const SizedBox(height: 24),
        Text('Payments', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...financials.payments.map((pay) => _buildPaymentCard(context, pay)),
      ],
    );
  }

  Widget _buildOverviewCards(BuildContext context, ProjectFinancials financials) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total Value',
            value: financials.totalValue != null ? currencyFormat.format(financials.totalValue) : 'Not Set',
            color: Colors.blue.shade100,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            title: 'Paid',
            value: currencyFormat.format(financials.paidAmount),
            color: Colors.green.shade100,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            title: 'Balance',
            value: financials.outstandingBalance != null ? currencyFormat.format(financials.outstandingBalance) : '-',
            color: Colors.orange.shade100,
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceCard(BuildContext context, WidgetRef ref, Invoice invoice, bool isAdmin) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final dateFormat = DateFormat.yMMMd();

    Color statusColor;
    switch (invoice.status) {
      case InvoiceStatus.issued:
        statusColor = Colors.blue;
        break;
      case InvoiceStatus.partiallyPaid:
        statusColor = Colors.orange;
        break;
      case InvoiceStatus.paid:
        statusColor = Colors.green;
        break;
      case InvoiceStatus.overdue:
        statusColor = Colors.red;
        break;
      case InvoiceStatus.cancelled:
        statusColor = Colors.grey;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(invoice.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                Chip(
                  label: Text(invoice.status.name.toUpperCase()),
                  backgroundColor: statusColor.withOpacity(0.2),
                  labelStyle: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Amount: ${currencyFormat.format(invoice.amount)}', style: Theme.of(context).textTheme.titleMedium),
            Text('Due Date: ${dateFormat.format(invoice.dueDate)}'),
            if (isAdmin && (invoice.status == InvoiceStatus.issued || invoice.status == InvoiceStatus.partiallyPaid || invoice.status == InvoiceStatus.overdue)) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _showRecordPaymentDialog(context, ref, invoice),
                  icon: const Icon(Icons.payment, size: 18),
                  label: const Text('Record Payment'),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, Payment payment) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final dateFormat = DateFormat.yMMMd();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.check, color: Colors.white),
        ),
        title: Text(currencyFormat.format(payment.amount)),
        subtitle: Text('${payment.paymentMethod.name.toUpperCase()} on ${dateFormat.format(payment.processedAt)}'),
        trailing: Text(payment.recordedBy), // In reality, fetch user name. We just show UID or 'admin'.
      ),
    );
  }

  Future<void> _showSetTotalValueDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Total Value'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Total Value (INR)',
            prefixText: '₹ ',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          FilledButton(
            onPressed: () async {
              final val = double.tryParse(controller.text);
              if (val != null && val >= 0) {
                try {
                  await ref.read(financialsRepositoryProvider).setTotalValue(projectId, val);
                  ref.invalidate(projectFinancialsProvider(projectId));
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateInvoiceDialog(BuildContext context, WidgetRef ref, ProjectFinancials financials) async {
    final amountController = TextEditingController();
    DateTime? selectedDate = DateTime.now().add(const Duration(days: 7));

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Create Invoice'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (financials.totalValue == null)
                  const Text('Warning: Project Total Value is not set.', style: TextStyle(color: Colors.red)),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (INR)',
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Due Date: ${DateFormat.yMMMd().format(selectedDate!)}'),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate!,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => selectedDate = date);
                        }
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
              FilledButton(
                onPressed: () async {
                  final val = double.tryParse(amountController.text);
                  if (val != null && val > 0) {
                    try {
                      await ref.read(financialsRepositoryProvider).createInvoice(
                            projectId: projectId,
                            amount: val,
                            dueDate: selectedDate!,
                          );
                      ref.invalidate(projectFinancialsProvider(projectId));
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  }
                },
                child: const Text('CREATE'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showRecordPaymentDialog(BuildContext context, WidgetRef ref, Invoice invoice) async {
    final amountController = TextEditingController();
    PaymentMethod selectedMethod = PaymentMethod.bankTransfer;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Record Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Invoice: ${invoice.invoiceNumber}'),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (INR)',
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PaymentMethod>(
                  value: selectedMethod,
                  decoration: const InputDecoration(labelText: 'Payment Method'),
                  items: PaymentMethod.values.map((m) => DropdownMenuItem(value: m, child: Text(m.name.toUpperCase()))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedMethod = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
              FilledButton(
                onPressed: () async {
                  final val = double.tryParse(amountController.text);
                  if (val != null && val > 0) {
                    try {
                      await ref.read(financialsRepositoryProvider).recordPayment(
                            invoiceId: invoice.id,
                            amount: val,
                            paymentMethod: selectedMethod,
                          );
                      ref.invalidate(projectFinancialsProvider(projectId));
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  }
                },
                child: const Text('RECORD'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black87)),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}
