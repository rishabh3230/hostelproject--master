import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/hms_service.dart';
import '../widgets/live_list.dart';
import 'payments_screen.dart';
import '../models/student_record.dart';

String rupees(num paise) => '₹${(paise / 100).toStringAsFixed(2)}';
int? parsePaise(String value) {
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value.trim())) return null;
  return (double.parse(value.trim()) * 100).round();
}

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});
  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final service = HmsService();
  late final stream = service.students();
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const AllotmentScreen()),
          ),
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Allot room / create student'),
        ),
      ),
      Expanded(
        child: LiveList(
          stream: stream,
          empty: 'Create rooms first, then allot students.',
          itemBuilder: (doc) => StudentCard(uid: doc.id, data: doc.data()),
        ),
      ),
    ],
  );
}

class StudentCard extends StatelessWidget {
  final String uid;
  final Data data;
  const StudentCard({super.key, required this.uid, required this.data});
  @override
  Widget build(BuildContext context) {
    final record = StudentRecord(uid, data);
    return Card(
      child: ExpansionTile(
        title: Text('${record.text('name')} • ${record.text('rollNo')}'),
        subtitle: Text(
          '${record.text('block')} / ${record.text('roomNumber')} • ${record.text('feeStatus')}',
        ),
        childrenPadding: const EdgeInsets.all(16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            "${record.text('branch')} • B.Tech year ${record.text('year')}\nFather: ${record.text('fatherName')}\nStudent contact: ${record.text('contact')} • Father: ${record.text('fatherContact')}\nCaste: ${record.text('caste')}\nAddress: ${record.text('address')}\nFee: ${record.amount('feeTotal') == null ? 'Not recorded' : rupees(record.amount('feeTotal')!)} • Received: ${record.paid == null ? 'Not recorded' : rupees(record.paid!)}",
          ),
          if (!record.canManage)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'This older student record needs account and fee migration before room changes or payments. Existing details are preserved.',
              ),
            ),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: !record.canManage
                    ? null
                    : () => showDialog<void>(
                        context: context,
                        builder: (_) => MoveDialog(uid: uid),
                      ),
                child: const Text('Change / vacate room'),
              ),
              TextButton(
                onPressed: !record.canManage
                    ? null
                    : () => showDialog<void>(
                        context: context,
                        builder: (_) => FeeDialog(uid: uid, data: record.data),
                      ),
                child: const Text('Edit fees'),
              ),
              TextButton(
                onPressed: !record.canManage
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => Scaffold(
                            appBar: AppBar(
                              title: Text('${record.text('name')} • payments'),
                            ),
                            body: PaymentsScreen(uid: uid, admin: true),
                          ),
                        ),
                      ),
                child: const Text('Payment history'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AllotmentScreen extends StatefulWidget {
  const AllotmentScreen({super.key});
  @override
  State<AllotmentScreen> createState() => _AllotmentScreenState();
}

class _AllotmentScreenState extends State<AllotmentScreen> {
  final form = GlobalKey<FormState>();
  final fields = {
    for (final key in [
      'rollNo',
      'name',
      'fatherName',
      'contact',
      'fatherContact',
      'branch',
      'caste',
      'address',
      'feeTotal',
      'manualPaid',
    ])
      key: TextEditingController(),
  };
  final roomStream = HmsService().rooms();
  String? roomId;
  String status = 'unpaid';
  int year = 1;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    fields['manualPaid']!.text = '0';
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? validate(String key, String? input) {
    final value = (input ?? '').trim();
    if (value.isEmpty) return 'Required';
    if (key == 'rollNo' &&
        !RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_-]{1,39}$').hasMatch(value)) {
      return 'Use 2–40 letters, digits, _ or -';
    }
    if (['contact', 'fatherContact'].contains(key) &&
        !RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
      return 'Enter a 10-digit Indian mobile number';
    }
    if (['feeTotal', 'manualPaid'].contains(key) && parsePaise(value) == null) {
      return 'Enter a rupee amount with up to 2 decimals';
    }
    if (value.length > (key == 'address' ? 1000 : 200)) {
      return 'Value is too long';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: Scaffold(
      appBar: AppBar(title: const Text('Student allotment')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'The student account is created securely without signing you out. The initial password is the student contact number.',
                  ),
                  const SizedBox(height: 20),
                  for (final entry in {
                    'rollNo': 'Roll number',
                    'name': 'Student name',
                    'fatherName': "Father’s name",
                    'contact': 'Student contact',
                    'fatherContact': "Father’s contact",
                    'branch': 'Branch',
                    'caste': 'Caste',
                    'address': 'Address',
                    'feeTotal': 'Total hostel fee (₹)',
                    'manualPaid': 'Already paid offline (₹)',
                  }.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        controller: fields[entry.key],
                        enabled: !saving,
                        decoration: InputDecoration(labelText: entry.value),
                        maxLines: entry.key == 'address' ? 3 : 1,
                        keyboardType:
                            [
                              'contact',
                              'fatherContact',
                              'feeTotal',
                              'manualPaid',
                            ].contains(entry.key)
                            ? const TextInputType.numberWithOptions(
                                decimal: true,
                              )
                            : TextInputType.text,
                        validator: (v) => validate(entry.key, v),
                      ),
                    ),
                  DropdownButtonFormField<int>(
                    initialValue: year,
                    decoration: const InputDecoration(labelText: 'B.Tech year'),
                    items: [
                      for (int i = 1; i <= 4; i++)
                        DropdownMenuItem(value: i, child: Text('Year $i')),
                    ],
                    onChanged: saving ? null : (v) => setState(() => year = v!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Fee status'),
                    items: [
                      for (final s in ['unpaid', 'partial', 'paid'])
                        DropdownMenuItem(value: s, child: Text(s)),
                    ],
                    onChanged: saving
                        ? null
                        : (v) => setState(() {
                            status = v!;
                            if (v == 'paid') {
                              fields['manualPaid']!.text =
                                  fields['feeTotal']!.text;
                            }
                            if (v == 'unpaid') fields['manualPaid']!.text = '0';
                          }),
                  ),
                  const SizedBox(height: 16),
                  RoomSelector(
                    stream: roomStream,
                    value: roomId,
                    onChanged: saving
                        ? null
                        : (v) => setState(() => roomId = v),
                  ),
                  const SizedBox(height: 24),
                  AsyncButton(
                    label: 'Create student and allot room',
                    onPressed: () async {
                      if (!form.currentState!.validate()) return;
                      if (roomId == null) throw Exception('Select a room.');
                      final total = parsePaise(fields['feeTotal']!.text)!,
                          paid = parsePaise(fields['manualPaid']!.text)!;
                      if (total < 100 || paid > total) {
                        throw Exception('Check fee amounts.');
                      }
                      final actual = paid >= total
                          ? 'paid'
                          : paid > 0
                          ? 'partial'
                          : 'unpaid';
                      if (status != actual) {
                        throw Exception(
                          'Fee status must match the amount already paid.',
                        );
                      }
                      setState(() => saving = true);
                      try {
                        await HmsService().call('allotStudent', {
                          for (final e in fields.entries)
                            e.key: e.value.text.trim(),
                          'year': year,
                          'roomId': roomId,
                          'feeTotal': total,
                          'manualPaid': paid,
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Student created and room allotted.',
                              ),
                            ),
                          );
                          Navigator.pop(context);
                        }
                      } finally {
                        if (mounted) setState(() => saving = false);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'If a connection failure interrupts creation, submit the same roll again to finish provisioning. The first saved details are retained.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class RoomSelector extends StatelessWidget {
  final Stream<QuerySnapshot<Data>> stream;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final bool allowVacate;
  const RoomSelector({
    super.key,
    required this.stream,
    required this.value,
    required this.onChanged,
    this.allowVacate = false,
  });
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Data>>(
    stream: stream,
    builder: (context, snapshot) {
      if (snapshot.hasError) return Text(friendlyError(snapshot.error!));
      if (!snapshot.hasData) return const LinearProgressIndicator();
      return DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Block / room'),
        items: [
          if (allowVacate)
            const DropdownMenuItem(value: '', child: Text('Vacate room')),
          ...snapshot.data!.docs.map((doc) {
            final r = doc.data();
            return DropdownMenuItem(
              value: doc.id,
              child: Text(
                '${r['block']} / ${r['number']} (${r['occupied']}/${r['capacity']})',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
        ],
        onChanged: onChanged,
      );
    },
  );
}

class MoveDialog extends StatefulWidget {
  final String uid;
  const MoveDialog({super.key, required this.uid});
  @override
  State<MoveDialog> createState() => _MoveDialogState();
}

class _MoveDialogState extends State<MoveDialog> {
  final stream = HmsService().rooms();
  String? room;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Change room'),
    content: SizedBox(
      width: 450,
      child: RoomSelector(
        stream: stream,
        value: room,
        allowVacate: true,
        onChanged: (v) => setState(() => room = v),
      ),
    ),
    actions: [
      AsyncButton(
        label: 'Save',
        onPressed: () async {
          if (room == null) throw Exception('Choose a room or select Vacate.');
          await HmsService().call('moveStudent', {
            'uid': widget.uid,
            'roomId': room,
          });
          if (context.mounted) Navigator.pop(context);
        },
      ),
    ],
  );
}

class FeeDialog extends StatefulWidget {
  final String uid;
  final Data data;
  const FeeDialog({super.key, required this.uid, required this.data});
  @override
  State<FeeDialog> createState() => _FeeDialogState();
}

class _FeeDialogState extends State<FeeDialog> {
  late final total = TextEditingController(
    text: ((widget.data['feeTotal'] as num) / 100).toStringAsFixed(2),
  );
  late final manual = TextEditingController(
    text: ((widget.data['manualPaid'] as num) / 100).toStringAsFixed(2),
  );
  @override
  void dispose() {
    total.dispose();
    manual.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Edit fee status'),
    scrollable: true,
    content: SizedBox(
      width: 450,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Online payments: ${rupees(widget.data['onlinePaid'] as num)}. Status is calculated from all recorded payments.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: total,
            decoration: const InputDecoration(labelText: 'Total fee (₹)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: manual,
            decoration: const InputDecoration(
              labelText: 'Total paid offline (₹)',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
    ),
    actions: [
      AsyncButton(
        label: 'Update fees',
        onPressed: () async {
          final feeTotal = parsePaise(total.text),
              manualPaid = parsePaise(manual.text);
          if (feeTotal == null || manualPaid == null) {
            throw Exception('Enter valid rupee amounts.');
          }
          await HmsService().call('updateFee', {
            'uid': widget.uid,
            'feeTotal': feeTotal,
            'manualPaid': manualPaid,
          });
          if (context.mounted) Navigator.pop(context);
        },
      ),
    ],
  );
}
