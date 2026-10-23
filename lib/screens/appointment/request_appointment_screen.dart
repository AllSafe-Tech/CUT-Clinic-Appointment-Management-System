import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/brand.dart';
import '../../core/errors.dart';
import '../../models/service_type.dart';
import '../../services/clinic_service.dart';
import '../../widgets/common.dart';
import '../../widgets/cut_logo.dart';
import 'review_request_screen.dart';

/// Step 1 of 2. Choose the type of service + optional details and preference.
/// The student does NOT choose the final date/time; staff assign it (FR12).
class RequestAppointmentScreen extends StatefulWidget {
  const RequestAppointmentScreen({super.key});

  @override
  State<RequestAppointmentScreen> createState() => _RequestAppointmentScreenState();
}

class _RequestAppointmentScreenState extends State<RequestAppointmentScreen> {
  final _form = GlobalKey<FormState>();
  final _details = TextEditingController();
  late Future<List<ServiceType>> _services = ClinicService.fetchServices();
  ServiceType? _service;
  DateTime? _prefDate;
  String _slot = 'No preference';

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _services = ClinicService.fetchServices());

  String? get _preferred {
    final parts = <String>[];
    if (_prefDate != null) parts.add(DateFormat('EEE d MMM yyyy').format(_prefDate!));
    if (_slot != 'No preference') parts.add(_slot);
    return parts.isEmpty ? null : parts.join(', ');
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _prefDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      helpText: 'Preferred date (clinic confirms final date)',
    );
    if (d != null) setState(() => _prefDate = d);
  }

  void _next() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewRequestScreen(
          service: _service!,
          details: _details.text.trim(),
          preferred: _preferred,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Scaffold(
      appBar: cutAppBar('Request appointment'),
      body: SafeArea(
        child: FutureBuilder<List<ServiceType>>(
          future: _services,
          builder: (context, snap) {
            if (snap.hasError) {
              return ErrorView(message: friendlyError(snap.error!), onRetry: _reload);
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final services = snap.data!;
            if (services.isEmpty) {
              return const EmptyState(
                icon: Icons.medical_services_outlined,
                title: 'No services available',
                subtitle: 'The clinic has not set up its services yet. Please try again later.',
              );
            }
            final needsDetails = _service?.requiresDetails ?? false;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text('Step 1 of 2',
                            style: t.textTheme.labelLarge?.copyWith(
                                color: CutColors.blue, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: LinearProgressIndicator(
                            value: 0.5,
                            minHeight: 6,
                            borderRadius: BorderRadius.all(Radius.circular(3)),
                            color: CutColors.gold,
                            backgroundColor: CutColors.border,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Which service do you need?',
                        style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ServiceType>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Type of service',
                        prefixIcon: Icon(Icons.medical_information_outlined),
                      ),
                      hint: const Text('Select a service'),
                      items: [
                        for (final s in services)
                          DropdownMenuItem<ServiceType>(
                            value: s,
                            child: Row(
                              children: [
                                Icon(s.icon, size: 20, color: CutColors.blue),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Text(s.name, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (s) => setState(() => _service = s),
                      validator: (v) => v == null ? 'Please choose a type of service' : null,
                    ),
                    if ((_service?.description ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                        child: Text(_service!.description!,
                            style: t.textTheme.bodySmall
                                ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _details,
                      maxLines: 3,
                      maxLength: 200,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: needsDetails
                            ? 'Please describe your reason'
                            : 'Additional details (optional)',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (needsDetails && s.length < 5) {
                          return 'Please describe your reason (at least 5 characters)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Text('Your preference (optional)',
                        style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                        'This is a preference only. The clinic confirms your final date and time.',
                        style: t.textTheme.bodySmall
                            ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Preferred date',
                          prefixIcon: const Icon(Icons.calendar_today_outlined),
                          suffixIcon: _prefDate == null
                              ? null
                              : IconButton(
                                  tooltip: 'Clear date',
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () => setState(() => _prefDate = null),
                                ),
                        ),
                        child: Text(
                          _prefDate == null
                              ? 'No preference'
                              : DateFormat('EEEE, d MMMM yyyy').format(_prefDate!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 'No preference', label: Text('Any time')),
                        ButtonSegment(value: 'Morning', label: Text('Morning')),
                        ButtonSegment(value: 'Afternoon', label: Text('Afternoon')),
                      ],
                      selected: {_slot},
                      onSelectionChanged: (s) => setState(() => _slot = s.first),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: t.colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.shield_outlined,
                                size: 18, color: CutColors.blue),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Keep details brief. Please do not include detailed '
                                'medical history - discuss that with the nurse at your visit.',
                                style: t.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(onPressed: _next, child: const Text('Continue')),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}