import 'package:flutter/material.dart';

class NoticesScreen extends StatelessWidget {
  const NoticesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Notices & Announcements',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: 10,
            itemBuilder: (BuildContext context, int index) {
              List<String> titles = <String>[
                'Hostel Maintenance Schedule',
                'Fee Payment Deadline',
                'Summer Vacation Notice',
                'WiFi Maintenance',
                'Common Room Rules',
                'Mess Timings Update',
                'Security Guidelines',
                'Water Supply Interruption',
                'Festival Celebration',
                'Important Contact Numbers',
              ];

              List<String> dates = <String>[
                '2024-01-15',
                '2024-01-12',
                '2024-01-10',
                '2024-01-08',
                '2024-01-05',
                '2024-01-03',
                '2024-01-01',
                '2023-12-28',
                '2023-12-25',
                '2023-12-20',
              ];

              // Using a consistent dark green for avatar backgrounds,
              // or shades of green for variety but adherence to theme.
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

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                // Card background light green
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                    avatarBackgrounds[index %
                        avatarBackgrounds
                            .length], // Variety in dark green shades
                    child: const Icon(Icons.notifications, color: Colors.white),
                  ),
                  title: Text(titles[index]),
                  subtitle: Text('Posted on: ${dates[index]}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    showDialog<void>(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: Text(titles[index]),
                        content: Text(
                          'This is the detailed content of the notice regarding ${titles[index]}. '
                              'All students are requested to read this notice carefully and comply with the instructions.',
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Close',

                            ), // Button text color
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}