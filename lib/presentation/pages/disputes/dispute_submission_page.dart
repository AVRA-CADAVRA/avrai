import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:avrai/core/models/expertise_event.dart';
import 'package:avrai/core/models/dispute_type.dart';
import 'package:avrai/core/services/dispute_resolution_service.dart';
import 'package:avrai/core/services/disputes/dispute_evidence_storage_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/common/page_transitions.dart';
import 'package:avrai/presentation/pages/disputes/dispute_status_page.dart';

/// Dispute Submission Page
/// 
/// Agent 2: Phase 5, Week 16-17 - Dispute UI
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
/// 
/// Features:
/// - Dispute type selection
/// - Description field
/// - Evidence upload (photos, screenshots)
/// - Timeline display
/// - Submit button
class DisputeSubmissionPage extends StatefulWidget {
  final ExpertiseEvent event;
  final String? reportedUserId; // User being reported (optional)

  const DisputeSubmissionPage({
    super.key,
    required this.event,
    this.reportedUserId,
  });

  @override
  State<DisputeSubmissionPage> createState() => _DisputeSubmissionPageState();
}

class _DisputeSubmissionPageState extends State<DisputeSubmissionPage> {
  final DisputeResolutionService _disputeService =
      GetIt.instance<DisputeResolutionService>();
  final DisputeEvidenceStorageService _evidenceStorage =
      GetIt.instance<DisputeEvidenceStorageService>();
  final ImagePicker _imagePicker = ImagePicker();

  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DisputeType? _selectedType;
  final List<_EvidenceDraft> _evidenceDrafts = [];
  bool _isSubmitting = false;
  bool _isUploadingEvidence = false;
  String? _error;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      if (result == null) return;

      for (final f in result.files) {
        Uint8List? bytes = f.bytes;
        if (bytes == null) {
          continue;
        }

        final ext = f.extension;
        setState(() {
          _evidenceDrafts.add(_EvidenceDraft(
            bytes: bytes,
            contentType: _guessContentType(ext),
            fileExtension: ext,
          ));
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final ext = image.name.contains('.') ? image.name.split('.').last : null;

      setState(() {
        _evidenceDrafts.add(_EvidenceDraft(
          bytes: bytes,
          contentType: _guessContentType(ext),
          fileExtension: ext,
        ));
      });
    } catch (e) {
      // Some platforms (or permission states) may not support camera capture.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Camera unavailable: $e'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
    }
  }

  Future<void> _submitDispute() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a dispute type'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _isUploadingEvidence = false;
      _error = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('Please sign in to submit a dispute');
      }

      // Determine reported user (host if not specified)
      final reportedId = widget.reportedUserId ?? widget.event.host.id;

      final dispute = await _disputeService.submitDispute(
        eventId: widget.event.id,
        reporterId: authState.user.id,
        reportedId: reportedId,
        type: _selectedType!,
        description: _descriptionController.text.trim(),
        evidenceUrls: const [],
      );

      if (_evidenceDrafts.isNotEmpty) {
        setState(() {
          _isUploadingEvidence = true;
        });

        final uploaded = <String>[];
        for (final d in _evidenceDrafts) {
          final ref = await _evidenceStorage.uploadEvidenceImage(
            userId: authState.user.id,
            disputeId: dispute.id,
            eventId: widget.event.id,
            bytes: d.bytes,
            contentType: d.contentType,
            fileExtension: d.fileExtension,
          );
          uploaded.add(ref);
        }

        await _disputeService.attachEvidence(
          disputeId: dispute.id,
          evidenceUrls: uploaded,
        );
      }

      if (mounted) {
        // Navigate to dispute status page
        Navigator.pushReplacement(
          context,
          PageTransitions.slideFromRight(
            DisputeStatusPage(disputeId: dispute.id),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSubmitting = false;
        _isUploadingEvidence = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Submit Dispute',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Info
                _buildEventInfo(),
                const SizedBox(height: 24),

                // Dispute Type Selection
                _buildTypeSelection(),
                const SizedBox(height: 24),

                // Description
                _buildDescriptionField(),
                const SizedBox(height: 24),

                // Evidence Upload
                _buildEvidenceSection(),
                const SizedBox(height: 24),

                // Error Display
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Submit Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitDispute,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : Text(_isUploadingEvidence ? 'Uploading evidence…' : 'Submit Dispute'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Event Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.event.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatDateTime(widget.event.startTime)} • ${widget.event.location ?? 'Location TBD'}',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dispute Type *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        RadioGroup<DisputeType>(
          groupValue: _selectedType,
          onChanged: (val) {
            setState(() {
              _selectedType = val;
            });
          },
          child: Column(
            children: DisputeType.values.map((type) {
              return RadioListTile<DisputeType>(
                title: Text(
                  type.displayName,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  _getTypeDescription(type),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                value: type,
                activeColor: AppTheme.primaryColor,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Please describe the issue in detail...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryColor),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
          style: const TextStyle(color: AppColors.textPrimary),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please provide a description';
            }
            if (value.trim().length < 20) {
              return 'Description must be at least 20 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEvidenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Evidence (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Upload photos or screenshots to support your dispute',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: const Text('Choose Photo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
          ],
        ),
        if (_evidenceDrafts.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _evidenceDrafts.asMap().entries.map((entry) {
              return Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.grey300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(entry.value.bytes, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _evidenceDrafts.removeAt(entry.key);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  String _guessContentType(String? ext) {
    final e = (ext ?? '').toLowerCase();
    return switch (e) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => 'image/jpeg',
    };
  }

  String _getTypeDescription(DisputeType type) {
    switch (type) {
      case DisputeType.cancellation:
        return 'Issues with event or ticket cancellation';
      case DisputeType.payment:
        return 'Payment, refund, or billing issues';
      case DisputeType.event:
        return 'Event quality, description, or experience issues';
      case DisputeType.partnership:
        return 'Issues with event partnerships';
      case DisputeType.safety:
        return 'Safety concerns or violations';
      case DisputeType.other:
        return 'Other issues not listed above';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} at ${_formatTime(dateTime)}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }
}

class _EvidenceDraft {
  final Uint8List bytes;
  final String contentType;
  final String? fileExtension;

  const _EvidenceDraft({
    required this.bytes,
    required this.contentType,
    required this.fileExtension,
  });
}

