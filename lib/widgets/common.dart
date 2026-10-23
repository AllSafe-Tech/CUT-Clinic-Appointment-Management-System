import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/brand.dart';
import '../models/appointment.dart';

void showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: CutColors.red,
      behavior: SnackBarBehavior.floating,
    ));
}

void showInfo(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ));
}

String formatDateTime(DateTime d) => DateFormat('d MMM yyyy, HH:mm').format(d);

/// Blue CUT header used at the top of every main screen.
class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    required this.title,
    this.eyebrow = 'CENTRAL UNIVERSITY OF TECHNOLOGY',
    this.subtitle,
    this.leading,
    this.showMark = false,
  });

  final String title;
  final String eyebrow;
  final String? subtitle;
  final Widget? leading;
  final bool showMark;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: t.labelSmall?.copyWith(
            color: CutColors.gold,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: t.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: t.bodyMedium?.copyWith(color: Colors.white70)),
        ],
        const SizedBox(height: 14),
        Container(
          height: 4,
          width: 44,
          decoration: BoxDecoration(
            color: CutColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [CutColors.blueDark, CutColors.blue],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showMark) ...[
                  Container(
                    height: 60,
                    width: 60,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_hospital_rounded,
                        size: 32, color: CutColors.blue),
                  ),
                  const SizedBox(height: 18),
                ],
                if (leading != null)
                  Row(children: [
                    leading!,
                    const SizedBox(width: 16),
                    Expanded(child: text),
                  ])
                else
                  text,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700, color: CutColors.blue),
      ),
    );
  }
}

class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                Text(label),
              ],
            ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: CutColors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(minimumSize: const Size(140, 44)),
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: t.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: CutColors.blue),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: t.textTheme.bodyMedium
                      ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final c = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 16, color: c),
          const SizedBox(width: 6),
          Text(status.label,
              style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: t.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: CutColors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: t.textTheme.labelMedium
                        ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(value,
                    style: t.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({super.key, required this.appointment, this.onTap});

  final Appointment appointment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final a = appointment;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: a.status.color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusChip(status: a.status),
                          const Spacer(),
                          if (onTap != null)
                            const Icon(Icons.chevron_right_rounded,
                                color: CutColors.blue),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 18, color: CutColors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              a.scheduledAt == null
                                  ? 'Date & time to be assigned'
                                  : '${a.dateText} at ${a.timeText}',
                              style: t.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      if ((a.notes ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(a.notes!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: t.textTheme.bodyMedium
                                ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                      ],
                      const SizedBox(height: 8),
                      Text('Requested ${formatDateTime(a.createdAt)}',
                          style: t.textTheme.bodySmall
                              ?.copyWith(color: t.colorScheme.outline)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _StepState { done, current, todo, failed }

class _Step {
  const _Step(this.label, this.state);
  final String label;
  final _StepState state;
}

/// Simple vertical progress tracker for an appointment.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.status});

  final AppointmentStatus status;

  List<_Step> _steps() {
    switch (status) {
      case AppointmentStatus.pending:
        return const [
          _Step('Request sent', _StepState.done),
          _Step('Clinic reviewing your request', _StepState.current),
          _Step('Date & time confirmed', _StepState.todo),
        ];
      case AppointmentStatus.approved:
        return const [
          _Step('Request sent', _StepState.done),
          _Step('Reviewed by clinic', _StepState.done),
          _Step('Date & time confirmed', _StepState.current),
          _Step('Visit the clinic', _StepState.todo),
        ];
      case AppointmentStatus.completed:
        return const [
          _Step('Request sent', _StepState.done),
          _Step('Reviewed by clinic', _StepState.done),
          _Step('Date & time confirmed', _StepState.done),
          _Step('Visit completed', _StepState.done),
        ];
      case AppointmentStatus.rejected:
        return const [
          _Step('Request sent', _StepState.done),
          _Step('Reviewed by clinic', _StepState.done),
          _Step('Not approved', _StepState.failed),
        ];
      case AppointmentStatus.cancelled:
        return const [
          _Step('Request sent', _StepState.done),
          _Step('Cancelled', _StepState.failed),
        ];
      case AppointmentStatus.unknown:
        return const [_Step('Request sent', _StepState.done)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps();
    final t = Theme.of(context);
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  _icon(steps[i].state),
                  if (i < steps.length - 1)
                    Container(
                      width: 2,
                      height: 22,
                      color: steps[i].state == _StepState.done
                          ? CutColors.blue
                          : CutColors.border,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  steps[i].label,
                  style: t.textTheme.bodyMedium?.copyWith(
                    fontWeight: steps[i].state == _StepState.current
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: steps[i].state == _StepState.todo
                        ? t.colorScheme.outline
                        : null,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _icon(_StepState s) {
    switch (s) {
      case _StepState.done:
        return const Icon(Icons.check_circle_rounded, size: 22, color: CutColors.blue);
      case _StepState.current:
        return const Icon(Icons.radio_button_checked_rounded,
            size: 22, color: CutColors.gold);
      case _StepState.failed:
        return const Icon(Icons.cancel_rounded, size: 22, color: CutColors.red);
      case _StepState.todo:
        return const Icon(Icons.radio_button_unchecked_rounded,
            size: 22, color: CutColors.border);
    }
  }
}
