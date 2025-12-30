import 'package:flutter/material.dart';

// İşlev kazanmadı
class NotificationWidget extends StatefulWidget {
  @override
  _NotificationWidgetState createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              'Bildirimler',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: 5,

                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text("Bildirim"),
                    subtitle: Text("Bildirim Açıklaması"),
                    trailing: Icon(Icons.notifications),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
