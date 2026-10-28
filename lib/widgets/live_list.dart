import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/hms_service.dart';

class LiveList extends StatelessWidget {
  final Stream<QuerySnapshot<Data>> stream;
  final Widget Function(QueryDocumentSnapshot<Data>) itemBuilder;
  final String empty;
  const LiveList({
    super.key,
    required this.stream,
    required this.itemBuilder,
    this.empty = 'Nothing here yet.',
  });
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Data>>(
    stream: stream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: SelectableText(friendlyError(snapshot.error!)),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.data!.docs.isEmpty) {
        return Center(
          child: Padding(padding: const EdgeInsets.all(24), child: Text(empty)),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: snapshot.data!.docs.length,
        separatorBuilder: (_, index) => const SizedBox(height: 8),
        itemBuilder: (_, index) => itemBuilder(snapshot.data!.docs[index]),
      );
    },
  );
}

Future<void> runAction(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  try {
    await action();
    if (context.mounted && success != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(success)));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }
}

class AsyncButton extends StatefulWidget {
  final Future<void> Function() onPressed;
  final String label;
  const AsyncButton({super.key, required this.onPressed, required this.label});
  @override
  State<AsyncButton> createState() => _AsyncButtonState();
}

class _AsyncButtonState extends State<AsyncButton> {
  bool busy = false;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: busy
        ? null
        : () async {
            setState(() => busy = true);
            await runAction(context, widget.onPressed);
            if (mounted) setState(() => busy = false);
          },
    child: busy
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(widget.label),
  );
}
