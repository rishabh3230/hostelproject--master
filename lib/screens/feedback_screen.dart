import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/hms_service.dart';
import '../widgets/live_list.dart';
import 'posts_screen.dart' show StudentSummary;

class FeedbackScreen extends StatefulWidget {
  final bool admin;
  const FeedbackScreen({super.key, required this.admin});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  late final Stream<QuerySnapshot<Data>> stream =
      (widget.admin
              ? FirebaseFirestore.instance.collection('feedback')
              : FirebaseFirestore.instance
                    .collection('feedback')
                    .where('studentId', isEqualTo: HmsService().uid))
          .orderBy('createdAt', descending: true)
          .snapshots();
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (!widget.admin)
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const FeedbackDialog(),
            ),
            child: const Text('Give feedback'),
          ),
        ),
      Expanded(
        child: LiveList(
          stream: stream,
          itemBuilder: (doc) {
            final d = doc.data();
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${d['category']} • ${d['rating']}/5',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(d['message'] as String? ?? ''),
                    if (widget.admin)
                      StudentSummary(uid: d['studentId'] as String),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

class FeedbackDialog extends StatefulWidget {
  const FeedbackDialog({super.key});
  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final message = TextEditingController();
  double rating = 5;
  String category = 'Cleanliness';
  @override
  void dispose() {
    message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Hostel feedback'),
    content: SizedBox(
      width: 450,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              for (final c in [
                'Cleanliness',
                'Food',
                'Facilities',
                'Staff',
                'General',
              ])
                DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: (v) => setState(() => category = v!),
          ),
          Slider(
            value: rating,
            min: 1,
            max: 5,
            divisions: 4,
            label: '${rating.toInt()}/5',
            onChanged: (v) => setState(() => rating = v),
          ),
          TextField(
            controller: message,
            maxLength: 2000,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Feedback'),
          ),
        ],
      ),
    ),
    actions: [
      AsyncButton(
        label: 'Submit',
        onPressed: () async {
          if (message.text.trim().isEmpty) {
            throw Exception('Enter your feedback.');
          }
          await FirebaseFirestore.instance.collection('feedback').add({
            'studentId': HmsService().uid,
            'category': category,
            'rating': rating.toInt(),
            'message': message.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });
          if (context.mounted) Navigator.pop(context);
        },
      ),
    ],
  );
}
