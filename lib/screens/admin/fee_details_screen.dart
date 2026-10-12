import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/fee.dart';
import '../../models/student.dart';

class FeeDetailsScreen extends StatefulWidget {
  const FeeDetailsScreen({super.key});

  @override
  State<FeeDetailsScreen> createState() => _FeeDetailsScreenState();
}

class _FeeDetailsScreenState extends State<FeeDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  bool _isProcessingPayment = false;

  void _payOutstandingFees(List<Fee> fees) async {
    final pendingFees = fees.where((f) => f.status != 'Paid').toList();
    if (pendingFees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All fees are already paid! No outstanding dues.'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Process/Pay they first outstanding fee for simulation
      final targetFee = pendingFees.first;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processing payment gateway simulation...'),
        ),
      );

      await Future<void>.delayed(const Duration(seconds: 1));

      await _firestoreService.updateFeeStatus(
        targetFee.id,
        'Paid',
        paidOn: DateTime.now(),
        paymentMethod: 'Online',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment of ₹${targetFee.amount.toStringAsFixed(0)} registered successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Student?>(
      stream: _authService.currentStudentProfile,
      builder: (context, studentSnapshot) {
        if (studentSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
          );
        }

        final student = studentSnapshot.data;
        if (student == null) {
          return const Center(
            child: Text(
              'No student session active.',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        return StreamBuilder<List<Fee>>(
          stream: _firestoreService.studentFeesStream(student.rollNo),
          builder: (context, feesSnapshot) {
            if (feesSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
              );
            }

            if (feesSnapshot.hasError) {
              return Center(
                child: Text('Error loading fees: ${feesSnapshot.error}'),
              );
            }

            final fees = feesSnapshot.data ?? [];

            // Calculate aggregations
            double totalFee = 0.0;
            double paidAmount = 0.0;
            double pendingAmount = 0.0;
            DateTime? nextDueDate;

            for (var fee in fees) {
              totalFee += fee.amount;
              if (fee.status == 'Paid') {
                paidAmount += fee.amount;
              } else {
                pendingAmount += fee.amount;
                // Get the earliest due date for outstanding fees
                if (nextDueDate == null || fee.dueDate.isBefore(nextDueDate)) {
                  nextDueDate = fee.dueDate;
                }
              }
            }

            // Fallback total if no fee record has been created yet (seed check)
            if (fees.isEmpty) {
              totalFee = 50000.0;
              pendingAmount = 50000.0;
              nextDueDate = DateTime(2025, 12, 15);
            }

            final String dueDateStr = nextDueDate != null
                ? DateFormat('dd MMM yyyy').format(nextDueDate)
                : 'No outstanding dues';

            final paymentHistory = fees
                .where((f) => f.status == 'Paid')
                .toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fee Details',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.account_balance_wallet,
                              color: Color(0xFF1B5E20),
                            ),
                            title: const Text('Total Fee Structure'),
                            subtitle: Text(
                              '₹ ${NumberFormat('#,##,###').format(totalFee)} /-',
                            ),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.payment,
                              color: Colors.green,
                            ),
                            title: const Text('Paid Amount'),
                            subtitle: Text(
                              '₹ ${NumberFormat('#,##,###').format(paidAmount)} /-',
                            ),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.pending_actions,
                              color: Colors.orange,
                            ),
                            title: const Text('Pending Amount'),
                            subtitle: Text(
                              '₹ ${NumberFormat('#,##,###').format(pendingAmount)} /-',
                            ),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.calendar_today,
                              color: Colors.red,
                            ),
                            title: const Text('Next Due Date'),
                            subtitle: Text(dueDateStr),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Payment History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  paymentHistory.isEmpty
                      ? const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'No payment records found.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: paymentHistory.length,
                          itemBuilder: (BuildContext context, int index) {
                            final fee = paymentHistory[index];
                            final String paidDate = fee.paidOn != null
                                ? DateFormat('dd MMM yyyy').format(fee.paidOn!)
                                : 'Unknown';

                            return Card(
                              child: ListTile(
                                leading: const Icon(
                                  Icons.receipt,
                                  color: Color(0xFF1B5E20),
                                ),
                                title: Text(
                                  '₹ ${NumberFormat('#,##,###').format(fee.amount)}',
                                ),
                                subtitle: Text('Paid on $paidDate'),
                                trailing: Chip(
                                  label: Text(fee.paymentMethod),
                                  backgroundColor: Colors.green[100],
                                ),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 20),
                  _isProcessingPayment
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF1B5E20),
                          ),
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: pendingAmount > 0
                                ? () => _payOutstandingFees(fees)
                                : null,
                            child: Text(
                              pendingAmount > 0 ? 'Pay Now' : 'Fully Paid',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
