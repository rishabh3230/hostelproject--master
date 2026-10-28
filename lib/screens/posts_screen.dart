import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/hms_service.dart';
import '../widgets/live_list.dart';

class PostsScreen extends StatefulWidget {
  final bool notice, admin;
  const PostsScreen({super.key, required this.notice, required this.admin});
  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final service = HmsService();
  late final stream = widget.notice
      ? service.notices()
      : service.complaints(widget.admin);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (widget.notice == widget.admin)
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => ComposePost(notice: widget.notice),
            ),
            icon: const Icon(Icons.add),
            label: Text(widget.notice ? 'Publish notice' : 'File complaint'),
          ),
        ),
      Expanded(
        child: LiveList(
          stream: stream,
          empty: widget.notice ? 'No notices published.' : 'No complaints yet.',
          itemBuilder: (doc) {
            final d = doc.data();
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d['title'] as String? ?? '',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      d[widget.notice ? 'body' : 'description'] as String? ??
                          '',
                    ),
                    if (d['createdAt'] is Timestamp)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          (d['createdAt'] as Timestamp)
                              .toDate()
                              .toLocal()
                              .toString()
                              .split('.')
                              .first,
                        ),
                      ),
                    if (!widget.notice) ...[
                      Chip(label: Text(d['status'] as String? ?? 'open')),
                      if ((d['remark'] as String? ?? '').isNotEmpty)
                        Text('Admin remark: ${d['remark']}'),
                      if (widget.admin)
                        StudentSummary(uid: d['studentId'] as String),
                      if (widget.admin && d['status'] != 'resolved')
                        TextButton(
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => ResolveDialog(id: doc.id),
                          ),
                          child: const Text('Mark resolved'),
                        ),
                    ],
                    if ((d['attachmentPath'] as String? ?? '').isNotEmpty)
                      TextButton.icon(
                        onPressed: () => runAction(
                          context,
                          () => viewAttachment(
                            context,
                            d['attachmentPath'] as String,
                          ),
                        ),
                        icon: const Icon(Icons.attach_file),
                        label: const Text('View attachment'),
                      ),
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

class StudentSummary extends StatelessWidget {
  final String uid;
  const StudentSummary({super.key, required this.uid});
  @override
  Widget build(BuildContext context) => StreamBuilder<DocumentSnapshot<Data>>(
    stream: HmsService().profile(uid),
    builder: (context, snapshot) {
      if (snapshot.hasError) return Text(friendlyError(snapshot.error!));
      final s = snapshot.data?.data();
      if (s == null) return const Text('Loading student details…');
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          '${s['name']} • ${s['rollNo']}\n${s['branch']} • Year ${s['year']} • ${s['block']} / ${s['roomNumber']}\nContact: ${s['contact']}',
        ),
      );
    },
  );
}

class ComposePost extends StatefulWidget {
  final bool notice;
  const ComposePost({super.key, required this.notice});
  @override
  State<ComposePost> createState() => _ComposePostState();
}

class _ComposePostState extends State<ComposePost> {
  final title = TextEditingController(), body = TextEditingController();
  final form = GlobalKey<FormState>();
  PlatformFile? file;
  bool sending = false;
  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !sending,
    child: AlertDialog(
      title: Text(widget.notice ? 'Publish notice' : 'File complaint'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: title,
                  maxLength: 120,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: body,
                  maxLength: 5000,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: widget.notice ? 'Notice text' : 'Description',
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Required' : null,
                ),
                TextButton.icon(
                  onPressed: sending
                      ? null
                      : () => runAction(context, () async {
                          final picked = await HmsService().pickAttachment();
                          if (mounted) setState(() => file = picked);
                        }),
                  icon: const Icon(Icons.attach_file),
                  label: Text(
                    file?.name ?? 'Attach image, PDF or text (up to 5 MB)',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: sending ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        AsyncButton(
          label: widget.notice ? 'Publish' : 'Submit',
          onPressed: () async {
            if (!form.currentState!.validate()) return;
            setState(() => sending = true);
            try {
              await HmsService().publish(
                notice: widget.notice,
                title: title.text,
                body: body.text,
                file: file,
              );
              if (context.mounted) Navigator.pop(context);
            } finally {
              if (mounted) setState(() => sending = false);
            }
          },
        ),
      ],
    ),
  );
}

class ResolveDialog extends StatefulWidget {
  final String id;
  const ResolveDialog({super.key, required this.id});
  @override
  State<ResolveDialog> createState() => _ResolveDialogState();
}

class _ResolveDialogState extends State<ResolveDialog> {
  final remark = TextEditingController();
  @override
  void dispose() {
    remark.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Resolve complaint'),
    content: TextField(
      controller: remark,
      maxLength: 2000,
      maxLines: 3,
      decoration: const InputDecoration(labelText: 'Resolution remark'),
    ),
    actions: [
      AsyncButton(
        label: 'Mark resolved',
        onPressed: () async {
          if (remark.text.trim().isEmpty) {
            throw Exception('Enter a resolution remark.');
          }
          await HmsService().resolve(widget.id, remark.text);
          if (context.mounted) Navigator.pop(context);
        },
      ),
    ],
  );
}

Future<void> viewAttachment(BuildContext context, String path) async {
  // Authenticated byte download avoids sharing permanent bearer-token download URLs.
  final bytes = await HmsService().attachment(path);
  if (bytes == null || !context.mounted) return;
  final image =
      bytes.length > 3 &&
      ((bytes[0] == 0x89 && bytes[1] == 0x50) ||
          (bytes[0] == 0xff && bytes[1] == 0xd8));
  final pdf = bytes.length > 3 && bytes[0] == 0x25 && bytes[1] == 0x50;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Attachment'),
      content: SizedBox(
        width: 600,
        child: image
            ? InteractiveViewer(child: Image.memory(bytes))
            : Text(
                pdf
                    ? 'PDF document • ${bytes.length} bytes'
                    : String.fromCharCodes(bytes.take(5000)),
              ),
      ),
      actions: [
        AsyncButton(
          label: 'Save file',
          onPressed: () async {
            await FilePicker.platform.saveFile(
              dialogTitle: 'Save attachment',
              fileName: image
                  ? (bytes[0] == 0x89 ? 'attachment.png' : 'attachment.jpg')
                  : pdf
                  ? 'attachment.pdf'
                  : 'attachment.txt',
              bytes: bytes,
            );
          },
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
