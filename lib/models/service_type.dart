import 'package:flutter/material.dart';

/// A type of clinic service a student can book (from the "services" table).
class ServiceType {
  const ServiceType({
    required this.id,
    required this.name,
    this.description,
    this.iconKey,
    this.requiresDetails = false,
  });

  final String id;
  final String name;
  final String? description;
  final String? iconKey;

  /// When true the student must describe their reason (e.g. "Other").
  final bool requiresDetails;

  IconData get icon {
    switch (iconKey) {
      case 'consultation':
        return Icons.medical_services_outlined;
      case 'illness':
        return Icons.thermostat_outlined;
      case 'injury':
        return Icons.healing_outlined;
      case 'chronic':
        return Icons.medication_outlined;
      case 'screening':
        return Icons.monitor_heart_outlined;
      case 'vaccine':
        return Icons.vaccines_outlined;
      case 'sexual':
        return Icons.favorite_border_rounded;
      case 'mental':
        return Icons.psychology_alt_outlined;
      case 'certificate':
        return Icons.description_outlined;
      case 'other':
        return Icons.more_horiz_rounded;
      default:
        return Icons.local_hospital_outlined;
    }
  }

  factory ServiceType.fromMap(Map<String, dynamic> m) => ServiceType(
        id: m['service_id'] as String,
        name: m['name'] as String,
        description: m['description'] as String?,
        iconKey: m['icon'] as String?,
        requiresDetails: (m['requires_details'] as bool?) ?? false,
      );
}

/// Details + optional preference, saved in appointments.notes.
/// The preference is a hint only - clinic staff assign the final date/time.
String composeDetails(String details, {String? preferred}) {
  final parts = <String>[];
  if (details.trim().isNotEmpty) parts.add(details.trim());
  if (preferred != null && preferred.isNotEmpty) {
    parts.add('Preferred: $preferred');
  }
  return parts.join(' | ');
}