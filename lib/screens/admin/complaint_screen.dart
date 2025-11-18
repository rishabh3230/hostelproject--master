import 'package:flutter/material.dart';

class ComplaintScreen extends StatelessWidget {
  const ComplaintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'File a Complaint',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Complaint Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: 'maintenance',
                        child: Text('Maintenance'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'cleaning',
                        child: Text('Cleaning'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'electricity',
                        child: Text('Electricity'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'water',
                        child: Text('Water Supply'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'security',
                        child: Text('Security'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'other',
                        child: Text('Other'),
                      ),
                    ],
                    onChanged: (String? value) {},
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Complaint submitted successfully!'),
                        ),
                      );
                    },
                    // Style inherited from theme
                    child: const Text('Submit Complaint'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Recent Complaints',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (BuildContext context, int index) {
              List<String> statuses = [
                'Pending',
                'In Progress',
                'Resolved',
                'Pending',
                'Resolved',
              ];
              // Adjusted status colors: blue changed to dark green
              List<Color> statusColors = <Color>[
                Colors.orange,
                 Colors.blue,        // In Progress
  Colors.green,       // Resolved
  Colors.orange,      // Pending
  Colors.green,  
            

              ];

              return Card(
                child: ListTile(
                  leading: Icon(
                    Icons.report_problem,

                  ), // Icon color
                  title: Text('Complaint ${index + 1}'),
                  subtitle: Text('Submitted on 2024-0${index + 1}-10'),
                  trailing: Chip(
                    label: Text(
                      statuses[index],
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: statusColors[index],
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