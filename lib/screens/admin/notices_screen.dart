import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/notice.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  bool _isAdmin = false;
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  void _checkRole() async {
    final user = _authService.currentUser;
    if (user != null) {
      final isAdm = await _authService.isAdmin(user.uid);
      if (mounted) {
        setState(() {
          _isAdmin = isAdm;
          _isLoadingRole = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingRole = false;
        });
      }
    }
  }

  void _showAddNoticeDialog() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    bool isPosting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Post New Announcement'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Notice Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: bodyController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Announcement Details',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter announcement body';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isPosting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                isPosting
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() {
                            isPosting = true;
                          });

                          try {
                            final notice = Notice(
                              id: '',
                              title: titleController.text.trim(),
                              body: bodyController.text.trim(),
                              postedBy: 'Administration',
                              createdAt: DateTime.now(),
                            );

                            await _firestoreService.postNotice(notice);

                            if (!context.mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Notice posted successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error posting notice: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Text('Post'),
                      ),
              ],
            );
          },
        );
      },
    ).then((_) {
      titleController.dispose();
      bodyController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Color> avatarBackgrounds = <Color>[
      Colors.green[700]!,
      Colors.teal[700]!,
      Colors.lime[700]!,
      Colors.brown[700]!,
      Colors.purple[700]!,
      Colors.cyan[700]!,
      Colors.indigo[700]!,
      Colors.blueGrey[700]!,
    ];

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Notices & Announcements',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Notice>>(
              stream: _firestoreService.noticesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading notices: ${snapshot.error}'),
                  );
                }

                final notices = snapshot.data ?? [];
                if (notices.isEmpty) {
                  return const Center(
                    child: Text(
                      'No notices or announcements posted yet.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: notices.length,
                  itemBuilder: (BuildContext context, int index) {
                    final notice = notices[index];
                    final dateStr =
                        DateFormat('dd MMM yyyy').format(notice.createdAt);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              avatarBackgrounds[
                                index % avatarBackgrounds.length
                              ],
                          child: const Icon(
                            Icons.notifications,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          notice.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('By: ${notice.postedBy} • $dateStr'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          showDialog<void>(
                            context: context,
                            builder:
                                (BuildContext context) => AlertDialog(
                                  title: Text(notice.title),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Posted by: ${notice.postedBy} on $dateStr',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          notice.body,
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton:
          (_isLoadingRole || !_isAdmin)
          ? null
          : FloatingActionButton(
              onPressed: _showAddNoticeDialog,
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
    );
  }
}
