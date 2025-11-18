import 'package:flutter/material.dart';
import 'students_list_screen.dart';

class VacancyScreen extends StatelessWidget {
  const VacancyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    List<String> blocks = [
      '1st Year',
      '2nd Year',
      '3rd Year',
      '4th Year',
    ];

    List<int> vacancies = [5, 12, 8, 3];
    List<int> totalRooms = [50, 60, 45, 40];

    List<Color> colors = [
      Colors.green[600]!,
      Colors.orange,
      Colors.red,
      Colors.blue,
    ];

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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.2,
            ),
            itemCount: blocks.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentsListScreen(
                        blockName: blocks[index],
                      ),
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
                          blocks[index],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${vacancies[index]} / ${totalRooms[index]}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Vacant',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
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
  }
}
