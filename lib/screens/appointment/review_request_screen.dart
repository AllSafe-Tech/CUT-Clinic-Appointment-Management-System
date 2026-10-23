import 'package:flutter/material.dart';

import '../../core/brand.dart';
import '../../core/errors.dart';
import '../../models/service_type.dart';
import '../../services/clinic_service.dart';
import '../../widgets/common.dart';
import '../../widgets/cut_logo.dart';
import 'submitted_screen.dart';

/// Step 2 of 2: review and confirm, then save to Supabase (IR2).
class ReviewRequestScreen extends StatefulWidget {
  const ReviewRequestScreen({
    super.key,
    required this.service,
    required this.details,
    this.preferred,
  });

  final ServiceType service;
  final String details;
  final String? preferred;

  @override
  State<ReviewRequestScreen> createState() => _ReviewRequestScreenState();
}

class _ReviewRequestScreenState extends State<ReviewRequestScreen> {
  bool _busy = false;

  Future<void> _submit() async {
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    try {
      await ClinicService.requestAppointment(
        serviceId: widget.service.id,
        notes: composeDetails(widget.details, preferred: widget.preferred),
      );
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SubmittedScreen()),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (mounted) showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: cutAppBar('Review request'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text('Step 2 of 2',
                      style: t.textTheme.labelLarge
                          ?.copyWith(color: CutColors.blue, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: LinearProgressIndicator(
                      value: 1,
                      minHeight: 6,
                      borderRadius: BorderRadius.all(Radius.circular(3)),
                      color: CutColors.gold,
                      backgroundColor: CutColors.border,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Check your request',
                  style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      InfoRow(
                          icon: widget.service.icon,
                          label: 'Type of service',
                          value: widget.service.name),
                      if (widget.details.isNotEmpty)
                        InfoRow(
                            icon: Icons.notes_rounded,
                            label: 'Details',
                            value: widget.details),
                      if (widget.preferred != null)
                        InfoRow(
                            icon: Icons.favorite_border_rounded,
                            label: 'Your preference',
                            value: widget.preferred!),
                      const Divider(height: 24),
                      const InfoRow(
                          icon: Icons.schedule_rounded,
                          label: 'Final date & time',
                          value: 'Will be assigned by clinic staff'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              LoadingButton(label: 'Submit request', busy: _busy, onPressed: _submit),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                child: const Text('Edit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}