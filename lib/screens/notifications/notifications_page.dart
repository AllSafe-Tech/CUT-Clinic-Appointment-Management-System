import 'package:flutter/material.dart';

import '../../core/brand.dart';
import '../../core/errors.dart';
import '../../models/app_notification.dart';
import '../../services/clinic_service.dart';
import '../../widgets/common.dart';
import '../../widgets/cut_header.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, this.showBack = false});

  /// Show a back arrow in the header (when opened from the Home buttons).
  final bool showBack;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Stream<List<AppNotification>> _stream = ClinicService.watchNotifications();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return StreamBuilder<List<AppNotification>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError && !snap.hasData) {
          return SafeArea(
            child: ErrorView(
              message: friendlyError(snap.error!),
              onRetry: () =>
                  setState(() => _stream = ClinicService.watchNotifications()),
            ),
          );
        }
        if (!snap.hasData) {
          return const SafeArea(child: Center(child: CircularProgressIndicator()));
        }
        final items = snap.data!;
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            CutHeader(
              title: 'Alerts',
              onBack: widget.showBack ? () => Navigator.of(context).maybePop() : null,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: EmptyState(
                        icon: Icons.notifications_none_rounded,
                        title: 'Nothing yet',
                        subtitle: 'Updates about your appointment will appear here.',
                      ),
                    )
                  : Column(
                      children: [
                        for (final n in items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: n.isReminder
                                          ? t.colorScheme.secondaryContainer
                                          : t.colorScheme.primaryContainer,
                                      child: Icon(
                                        n.isReminder
                                            ? Icons.alarm_rounded
                                            : Icons.notifications_active_outlined,
                                        color: CutColors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(n.message,
                                              style: t.textTheme.bodyMedium?.copyWith(
                                                  fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 4),
                                          Text(formatDateTime(n.createdAt),
                                              style: t.textTheme.bodySmall?.copyWith(
                                                  color: t.colorScheme.outline)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}