import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/room.dart';
import 'students_list_screen.dart';

class VacancyScreen extends StatelessWidget {
  const VacancyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    final List<String> blocks = const [
      '1st Year',
      '2nd Year',
      '3rd Year',
      '4th Year',
    ];

    final List<Color> colors = [
      Colors.green[600]!,
      Colors.orange[700]!,
      Colors.red[700]!,
      Colors.blue[700]!,
    ];

    return Scaffold(
      body: StreamBuilder<List<Room>>(
        stream: firestoreService.roomsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading vacancy details: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final allRooms = snapshot.data ?? [];

          // Compute dynamically
          Map<String, int> blockVacancies = {for (var b in blocks) b: 0};
          Map<String, int> blockTotalRooms = {for (var b in blocks) b: 0};

          for (var room in allRooms) {
            final block = room.hostelBlock;
            if (blockVacancies.containsKey(block)) {
              blockVacancies[block] = blockVacancies[block]! + room.vacantCount;
              blockTotalRooms[block] = blockTotalRooms[block]! + 1;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hostel Vacancy',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                allRooms.isEmpty
                    ? Card(
                        color: Colors.grey[200],
                        child: const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Center(
                            child: Text(
                              'No vacancy records found. Please seed test database from login select screen.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1.2,
                            ),
                        itemCount: blocks.length,
                        itemBuilder: (context, index) {
                          final String blockName = blocks[index];
                          final int vacantCount =
                              blockVacancies[blockName] ?? 0;
                          final int totalCount =
                              blockTotalRooms[blockName] ?? 0;

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      StudentsListScreen(blockName: blockName),
                                ),
                              );
                            },
                            child: Card(
                              color: colors[index],
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      blockName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '$vacantCount / ${totalCount * 3}', // vacancy slots (3 per room)
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Vacant Slots',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}
