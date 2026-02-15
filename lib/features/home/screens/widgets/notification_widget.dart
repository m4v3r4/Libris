import 'package:flutter/material.dart';

class NotificationWidget extends StatelessWidget {
  const NotificationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              'Bildirimler',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                return const ListTile(
                  title: Text('Bildirim'),
                  subtitle: Text('Bildirim aciklamasi'),
                  trailing: Icon(Icons.notifications),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
