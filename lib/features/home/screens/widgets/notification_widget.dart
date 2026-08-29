import 'package:flutter/material.dart';
import 'package:libris/common/localization/app_localization.dart';
import 'package:libris/features/home/screens/widgets/dashboard_card.dart';

class NotificationWidget extends StatelessWidget {
  const NotificationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: l10n('Bildirimler', 'Notifications'),
      subtitle: l10n(
        'Önemli durumlar burada görünür',
        'Important updates appear here',
      ),
      icon: Icons.notifications_none_rounded,
      child: DashboardEmptyState(
        icon: Icons.done_all_rounded,
        title: l10n('Her şey yolunda', 'Everything is up to date'),
        description: l10n(
          'Şu anda dikkat gerektiren bir bildirim bulunmuyor.',
          'There are no notifications requiring attention right now.',
        ),
      ),
    );
  }
}
