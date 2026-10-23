import 'package:flutter/material.dart';

import '../../core/brand.dart';
import '../../models/appointment.dart';
import '../../models/student_profile.dart';
import '../../widgets/common.dart';
import '../../widgets/home_hero.dart';
import '../../widgets/student_avatar.dart';
import '../appointment/history_screen.dart';
import '../appointment/my_appointment_screen.dart';
import '../appointment/request_appointment_screen.dart';
import '../notifications/notifications_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.profile,
    required this.appointments,
    required this.onOpenTab,
  });

  final StudentProfile profile;
  final List<Appointment> appointments;
  final void Function(int tabIndex) onOpenTab;

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final active = appointments.where((a) => a.isActive).firstOrNull;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Stack(
          children: [
            // Campus photo hero behind the floating card
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 300,
              child: HomeHero(
                title: 'Hi, ${profile.firstName}',
                subtitle: 'Student no. ${profile.studentNumber}',
                leading: StudentAvatar(
                  firstName: profile.firstName,
                  lastName: profile.lastName,
                  avatarPath: profile.avatarPath,
                  radius: 28,
                ),
              ),
            ),
            // Floating white card that overlaps the bottom of the photo
            Padding(
              padding: const EdgeInsets.only(top: 236),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(36),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionTitle('Your appointment'),
                        if (active != null)
                          AppointmentCard(
                              appointment: active, onTap: () => onOpenTab(1))
                        else
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: t.colorScheme.primaryContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.event_available_outlined,
                                        color: CutColors.blue),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Text('No active appointment. Request one and '
                                        'the clinic will assign you a date and time.'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        const SectionTitle('What do you need to do?'),
                        GridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            mainAxisExtent: 116,
                          ),
                          children: [
                            _ActionTile(
                              icon: Icons.edit_calendar_rounded,
                              title: 'Request an appointment',
                              subtitle: active == null
                                  ? 'Book a clinic visit'
                                  : 'You have one active',
                              colors: const [CutColors.blueDark, Color(0xFF0B5CAD)],
                              locked: active != null,
                              onTap: () => active == null
                                  ? _open(context, const RequestAppointmentScreen())
                                  : showInfo(context,
                                      'You already have an active appointment. Cancel it to make a new request.'),
                            ),
                            _ActionTile(
                              icon: Icons.event_rounded,
                              title: 'My Appointment',
                              subtitle: active?.status.label ?? 'None active',
                              colors: const [CutColors.blue, Color(0xFF1565C0)],
                              onTap: () => _open(context, const MyAppointmentScreen()),
                            ),
                            _ActionTile(
                              icon: Icons.history_rounded,
                              title: 'Past appointments',
                              subtitle: 'Your clinic history',
                              colors: const [Color(0xFF0A4F94), Color(0xFF2A7BD1)],
                              onTap: () => _open(context, const HistoryScreen()),
                            ),
                            _ActionTile(
                              icon: Icons.notifications_active_rounded,
                              title: 'Alerts',
                              subtitle: 'Updates & reminders',
                              colors: const [Color(0xFF12559E), Color(0xFF3A8EDB)],
                              onTap: () => _open(context,
                                  const Scaffold(body: NotificationsPage(showBack: true))),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionTitle('How it works'),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: const [
                                _HowStep(
                                    n: 1,
                                    title: 'Request',
                                    text: 'Choose the type of service you need.'),
                                SizedBox(height: 14),
                                _HowStep(
                                    n: 2,
                                    title: 'Clinic confirms',
                                    text: 'Staff review your request and assign a date and time.'),
                                SizedBox(height: 14),
                                _HowStep(
                                    n: 3,
                                    title: 'Get notified',
                                    text: 'You receive an SMS/email, plus a reminder the day before.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Compact gradient button with icon, title, subtitle and a press animation.
class _ActionTile extends StatefulWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
    this.locked = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;
  final bool locked;

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.locked
        ? const [Color(0xFF7D8799), Color(0xFFA3ACBC)]
        : widget.colors;

    return Semantics(
      button: true,
      label: '${widget.title}. ${widget.subtitle}',
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: colors.last.withAlpha(80),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
              ),
              child: InkWell(
                onTap: widget.onTap,
                onHighlightChanged: (v) => setState(() => _pressed = v),
                child: Stack(
                  children: [
                    Positioned(
                      right: -12,
                      bottom: -14,
                      child: Icon(widget.icon,
                          size: 78, color: Colors.white.withAlpha(26)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                height: 34,
                                width: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withAlpha(40),
                                ),
                                child: Icon(widget.icon, color: Colors.white, size: 18),
                              ),
                              const Spacer(),
                              Icon(
                                widget.locked
                                    ? Icons.lock_outline_rounded
                                    : Icons.arrow_forward_rounded,
                                color: Colors.white70,
                                size: 18,
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            widget.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HowStep extends StatelessWidget {
  const _HowStep({required this.n, required this.title, required this.text});

  final int n;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 30,
          width: 30,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: CutColors.gold, shape: BoxShape.circle),
          child: Text('$n',
              style: const TextStyle(color: CutColors.blue, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(text,
                  style: t.textTheme.bodyMedium
                      ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}