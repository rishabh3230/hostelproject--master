import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/checkout.dart';
import '../models/student_record.dart';
import '../services/hms_service.dart';
import '../widgets/live_list.dart';
import 'students_screen.dart' show rupees;

class PaymentsScreen extends StatefulWidget {
  final String uid;
  final bool admin;
  const PaymentsScreen({super.key, required this.uid, this.admin = false});
  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final service = HmsService();
  late final profile = service.profile(widget.uid),
      payments = service.payments(widget.uid);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      StreamBuilder<DocumentSnapshot<Data>>(
        stream: profile,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(friendlyError(snapshot.error!)),
            );
          }
          if (!snapshot.hasData) return const LinearProgressIndicator();
          final s = snapshot.data!.data();
          if (s == null) return const Text('Student profile not found.');
          final record = StudentRecord(widget.uid, s);
          if (!record.hasFees) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Fee amounts are not recorded in this older profile. Please contact the administrator to migrate the fee records.',
              ),
            );
          }
          final paid = record.paid!, balance = (s['feeTotal'] as num) - paid;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${s['name']} • ${s['rollNo']}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${s['branch']} • Year ${s['year']}\nRoom: ${s['block']} / ${s['roomNumber']}',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Fee status: ${s['feeStatus']}\nTotal: ${rupees(s['feeTotal'] as num)}\nPaid: ${rupees(paid)}\nBalance: ${rupees(balance > 0 ? balance : 0)}',
                    ),
                    if (balance < 0)
                      Text(
                        'Credit balance: ${rupees(-balance)}. Contact the administrator for reconciliation.',
                      ),
                    if (!widget.admin && balance >= 100)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: AsyncButton(
                          label: 'Pay ${rupees(balance)}',
                          onPressed: () async {
                            final order = await service.call(
                              'createPaymentOrder',
                              {},
                            );
                            await openCheckout({
                              'key': order['key'],
                              'order_id': order['orderId'],
                              'amount': order['amount'],
                              'currency': order['currency'],
                              'name': 'IERT Hostel',
                              'description': 'Hostel fee',
                              'prefill': {
                                'name': s['name'],
                                'contact': s['contact'],
                              },
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Checkout completed. Waiting for verified payment confirmation; history updates automatically.',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      const Padding(
        padding: EdgeInsets.all(8),
        child: Text('Verified online payment history'),
      ),
      Expanded(
        child: LiveList(
          stream: payments,
          empty: 'No verified online payments yet.',
          itemBuilder: (doc) {
            final p = doc.data(),
                date = (p['paidAt'] as Timestamp?)?.toDate().toLocal();
            return Card(
              child: ListTile(
                leading: const Icon(Icons.receipt_long),
                title: Text(
                  p['amount'] is num
                      ? rupees(p['amount'] as num)
                      : 'Amount not recorded',
                ),
                subtitle: SelectableText(
                  'Payment: ${doc.id}\nReceipt: ${p['receipt']}\nOrder: ${p['orderId']}\n${date == null ? 'Confirming date' : DateFormat.yMMMd().add_jm().format(date)} • ${p['status']}',
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}
