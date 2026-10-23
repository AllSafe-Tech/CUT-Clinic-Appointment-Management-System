import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/brand.dart';
import '../../core/errors.dart';
import '../../models/student_document.dart';
import '../../services/clinic_service.dart';
import '../../widgets/common.dart';
import '../../widgets/cut_logo.dart';

/// Upload proof of registration / ID (stored privately, visible only to the
/// student and authorised clinic staff).
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  static const int _maxBytes = 5 * 1024 * 1024;
  static const _allowed = ['pdf', 'jpg', 'jpeg', 'png'];

  late Future<List<StudentDocument>> _future = ClinicService.fetchDocuments();
  bool _busy = false;

  void _reload() => setState(() => _future = ClinicService.fetchDocuments());

  Future<DocType?> _chooseType() {
    return showDialog<DocType>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('What are you uploading?'),
        children: [
          for (final t in DocType.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, t),
              child: Row(
                children: [
                  Icon(t.icon, color: CutColors.blue),
                  const SizedBox(width: 12),
                  Text(t.label),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _upload() async {
    final type = await _chooseType();
    if (type == null) return;

    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowed,
      withData: true,
    );
    if (res == null || res.files.isEmpty || !mounted) return;

    final f = res.files.first;
    final bytes = f.bytes;
    final ext = (f.extension ?? '').toLowerCase();
    if (bytes == null) {
      showError(context, 'Could not read that file. Please try again.');
      return;
    }
    if (!_allowed.contains(ext)) {
      showError(context, 'Only PDF, JPG or PNG files are allowed.');
      return;
    }
    if (bytes.length > _maxBytes) {
      showError(context, 'That file is too large. The maximum size is 5 MB.');
      return;
    }

    setState(() => _busy = true);
    try {
      await ClinicService.uploadDocument(type: type, fileName: f.name, bytes: bytes);
      if (mounted) showInfo(context, '${type.label} uploaded.');
      _reload();
    } catch (e) {
      if (mounted) showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _view(StudentDocument d) async {
    final url = await ClinicService.signedUrl(ClinicService.documentsBucket, d.filePath);
    if (!mounted) return;
    if (url == null) {
      showError(context, 'Could not open the file. Please try again.');
      return;
    }
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) showError(context, 'No app found to open this file.');
  }

  Future<void> _delete(StudentDocument d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text('${d.fileName} will be permanently removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep it')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                minimumSize: const Size(110, 44), backgroundColor: CutColors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ClinicService.deleteDocument(d);
      if (mounted) showInfo(context, 'Document deleted.');
      _reload();
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
      appBar: cutAppBar('My documents'),
      body: FutureBuilder<List<StudentDocument>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorView(message: friendlyError(snap.error!), onRetry: _reload);
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!;
          bool has(DocType type) => docs.any((d) => d.type == type);

          Widget check(DocType type) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      has(type)
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: has(type) ? CutColors.blue : CutColors.border,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(type.label,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Text(has(type) ? 'Uploaded' : 'Not uploaded',
                        style: t.textTheme.bodySmall?.copyWith(
                            color: has(type)
                                ? CutColors.blue
                                : t.colorScheme.outline)),
                  ],
                ),
              );

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('Registration documents'),
                      Text(
                        'Upload your proof of registration so the clinic can confirm '
                        'you are a registered CUT student. Your ID is optional.',
                        style: t.textTheme.bodyMedium
                            ?.copyWith(color: t.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      check(DocType.proofOfRegistration),
                      check(DocType.idDocument),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              LoadingButton(
                label: 'Upload a document',
                icon: Icons.upload_file_rounded,
                busy: _busy,
                onPressed: _upload,
              ),
              const SizedBox(height: 8),
              Text(
                'PDF, JPG or PNG, up to 5 MB. Only you and authorised clinic staff can see your documents.',
                style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              const SectionTitle('Your uploads'),
              if (docs.isEmpty)
                const EmptyState(
                  icon: Icons.folder_open_rounded,
                  title: 'No documents yet',
                  subtitle: 'Uploaded documents will appear here.',
                )
              else
                for (final d in docs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: t.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            d.isPdf
                                ? Icons.picture_as_pdf_outlined
                                : Icons.image_outlined,
                            color: CutColors.blue,
                          ),
                        ),
                        title: Text(d.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${d.type.label}  |  ${DateFormat('d MMM yyyy').format(d.uploadedAt)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'View',
                              icon: const Icon(Icons.open_in_new_rounded,
                                  color: CutColors.blue),
                              onPressed: _busy ? null : () => _view(d),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline, color: CutColors.red),
                              onPressed: _busy ? null : () => _delete(d),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}