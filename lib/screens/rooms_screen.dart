import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/hms_service.dart';
import '../widgets/live_list.dart';
import 'posts_screen.dart';
import '../models/room_input.dart';

class RoomsScreen extends StatefulWidget {
  final bool admin;
  const RoomsScreen({super.key, required this.admin});
  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  final stream = HmsService().rooms();
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (widget.admin)
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const RoomDialog(),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Create / edit room'),
          ),
        ),
      Expanded(
        child: StreamBuilder<QuerySnapshot<Data>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(friendlyError(snapshot.error!)));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No rooms configured.'));
            }
            final blocks = <String, List<QueryDocumentSnapshot<Data>>>{};
            for (final room in snapshot.data!.docs) {
              blocks
                  .putIfAbsent(room.data()['block'] as String, () => [])
                  .add(room);
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: blocks.entries
                  .map(
                    (block) => Card(
                      child: ExpansionTile(
                        title: Text('Block ${block.key}'),
                        subtitle: Text('${block.value.length} rooms'),
                        initiallyExpanded: true,
                        children: block.value.map((doc) {
                          final r = doc.data(),
                              count = r['occupied'] as int,
                              capacity = r['capacity'] as int;
                          final color = count == 0
                              ? Colors.green
                              : count >= capacity
                              ? Colors.red
                              : Colors.orange;
                          return ExpansionTile(
                            leading: Icon(Icons.meeting_room, color: color),
                            title: Text('Room ${r['number']}'),
                            subtitle: Text(
                              '$count / $capacity occupied • ${capacity - count} vacant',
                            ),
                            childrenPadding: const EdgeInsets.all(16),
                            children: [
                              if (count == 0) const Text('Vacant'),
                              if (widget.admin)
                                for (final uid in List<String>.from(
                                  r['occupantIds'] as List,
                                ))
                                  StudentSummary(uid: uid)
                              else if ((r['occupantIds'] as List).contains(
                                HmsService().uid,
                              ))
                                const Text('You are allotted to this room.')
                              else if (count > 0)
                                const Text(
                                  'Occupant personal details are available to administrators.',
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
    ],
  );
}

class RoomDialog extends StatefulWidget {
  const RoomDialog({super.key});
  @override
  State<RoomDialog> createState() => _RoomDialogState();
}

class _RoomDialogState extends State<RoomDialog> {
  String? error;
  final block = TextEditingController(),
      number = TextEditingController(),
      capacity = TextEditingController(text: '3');
  @override
  void dispose() {
    block.dispose();
    number.dispose();
    capacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Create / edit room'),
    content: SizedBox(
      width: 450,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Use the same block and room number to update capacity.'),
          if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: block,
            decoration: const InputDecoration(labelText: 'Block'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: number,
            decoration: const InputDecoration(labelText: 'Room number'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: capacity,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Capacity (1–20)'),
          ),
        ],
      ),
    ),
    actions: [
      AsyncButton(
        label: 'Save room',
        onPressed: () async {
          final input = RoomInput(block.text, number.text, capacity.text);
          setState(() => error = input.error);
          if (error != null) return;
          try {
            await HmsService().saveRoom(input);
            if (context.mounted) Navigator.pop(context);
          } catch (e) {
            if (mounted) setState(() => error = friendlyError(e));
          }
        },
      ),
    ],
  );
}
