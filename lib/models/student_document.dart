import 'package:flutter/material.dart';

enum DocType { proofOfRegistration, idDocument, other }

extension DocTypeX on DocType {
  String get dbValue {
    switch (this) {
      case DocType.proofOfRegistration:
        return 'proof_of_registration';
      case DocType.idDocument:
        return 'id_document';
      case DocType.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case DocType.proofOfRegistration:
        return 'Proof of registration';
      case DocType.idDocument:
        return 'ID document';
      case DocType.other:
        return 'Other document';
    }
  }

  IconData get icon {
    switch (this) {
      case DocType.proofOfRegistration:
        return Icons.school_outlined;
      case DocType.idDocument:
        return Icons.badge_outlined;
      case DocType.other:
        return Icons.insert_drive_file_outlined;
    }
  }
}

DocType parseDocType(String? s) {
  switch (s) {
    case 'proof_of_registration':
      return DocType.proofOfRegistration;
    case 'id_document':
      return DocType.idDocument;
    default:
      return DocType.other;
  }
}

class StudentDocument {
  const StudentDocument({
    required this.id,
    required this.type,
    required this.fileName,
    required this.filePath,
    required this.uploadedAt,
  });

  final String id;
  final DocType type;
  final String fileName;
  final String filePath;
  final DateTime uploadedAt;

  bool get isPdf => fileName.toLowerCase().endsWith('.pdf');

  factory StudentDocument.fromMap(Map<String, dynamic> m) => StudentDocument(
        id: m['document_id'] as String,
        type: parseDocType(m['doc_type'] as String?),
        fileName: m['file_name'] as String,
        filePath: m['file_path'] as String,
        uploadedAt: DateTime.parse(m['uploaded_at'] as String).toLocal(),
      );
}