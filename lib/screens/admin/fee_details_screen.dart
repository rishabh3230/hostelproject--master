import 'package:flutter/material.dart';

class FeeDetailsScreen extends StatelessWidget {
  const FeeDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fee Details',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Card(
             // Adjusted card color
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.account_balance_wallet,

                    ), // Icon color
                    title: const Text('Total Fee'),
                    subtitle: const Text('₹ 50,000 /-'),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.payment,

                    ), // Icon color
                    title: const Text('Paid Amount'),
                    subtitle: const Text('₹ 45,000 /-'),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.pending_actions,
                      color: Colors.orange,
                    ), // Retain semantic color
                    title: const Text('Pending Amount'),
                    subtitle: const Text('₹ 5,000 /-'),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.calendar_today,
                      color: Colors.red,
                    ), // Retain semantic color
                    title: const Text('Due Date'),
                    subtitle: const Text('15 Dec 2024'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Payment History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (BuildContext context, int index) {
              List<String> dates = <String>[
                '2024-01-15',
                '2024-02-15',
                '2024-03-15',
                '2024-04-15',
                '2024-05-15',
              ];
              List<String> amounts = [
                '10,000',
                '10,000',
                '10,000',
                '10,000',
                '5,000',
              ];
              List<String> methods = [
                'Online',
                'Cash',
                'Online',
                'Cheque',
                'Online',
              ];

              return Card(
                child: ListTile(
                  leading: Icon(Icons.receipt), // Icon color
                  title: Text('₹ ${amounts[index]}'),
                  subtitle: Text('Paid on ${dates[index]}'),
                  trailing: Chip(
                    label: Text(methods[index]),
                   // Adjusted chip color
                    labelStyle: const TextStyle(

                    ), // Adjusted label color
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Proceeding to payment gateway...'),
                  ),
                );
              },
              // Style inherited from theme
              child: const Text(
                'Pay Now',
                style: TextStyle(fontSize: 18), // Color white from theme
              ),
            ),
          ),
        ],
      ),
    );
  }
}