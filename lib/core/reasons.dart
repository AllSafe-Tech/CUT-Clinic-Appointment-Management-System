import 'package:flutter/material.dart';

class VisitReason {
  const VisitReason(this.label, this.icon, {this.requiresDetails = false});

  final String label;
  final IconData icon;
  final bool requiresDetails;
}

const List<VisitReason> visitReasons = [
  VisitReason('General consultation', Icons.medical_services_outlined),
  VisitReason('Illness (flu, cold, fever)', Icons.thermostat_outlined),
  VisitReason('Injury or first aid', Icons.healing_outlined),
  VisitReason('Medication or chronic condition follow-up', Icons.medication_outlined),
  VisitReason('Health screening / check-up', Icons.monitor_heart_outlined),
  VisitReason('Vaccination', Icons.vaccines_outlined),
  VisitReason('Sexual & reproductive health', Icons.favorite_border_rounded),
  VisitReason('Mental health & wellness', Icons.psychology_alt_outlined),
  VisitReason('Medical certificate (sick note)', Icons.description_outlined),
  VisitReason('Other', Icons.more_horiz_rounded, requiresDetails: true),
];

/// Saved in appointments.notes. The preference is a hint only - clinic staff
/// assign the final date/time.
String composeNotes(String reason, String details, {String? preferred}) {
  final d = details.trim();
  final base = d.isEmpty ? reason : '$reason: $d';
  if (preferred == null || preferred.isEmpty) return base;
  return '$base | Preferred: $preferred';
}