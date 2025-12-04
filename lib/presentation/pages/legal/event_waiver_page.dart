import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/legal/event_waiver.dart';
import 'package:spots/core/services/legal_document_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';

/// Event Waiver Page
/// 
/// Agent 2: Phase 5, Week 18-19 - Legal Document UI
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
/// 
/// Features:
/// - Event-specific waiver
/// - Acknowledgment checkboxes
/// - Accept button
class EventWaiverPage extends StatefulWidget {
  final ExpertiseEvent event;
  final bool requireAcceptance;

  const EventWaiverPage({
    super.key,
    required this.event,
    this.requireAcceptance = true,
  });

  @override
  State<EventWaiverPage> createState() => _EventWaiverPageState();
}

class _EventWaiverPageState extends State<EventWaiverPage> {
  final LegalDocumentService _legalService = LegalDocumentService(
    eventService: GetIt.instance<ExpertiseEventService>(),
  );

  bool _acknowledgeRisks = false;
  bool _acknowledgeRelease = false;
  bool _acknowledgeAge = false;
  bool _hasAccepted = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAcceptanceStatus();
  }

  Future<void> _checkAcceptanceStatus() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        final accepted = await _legalService.hasAcceptedEventWaiver(
          authState.user.id,
          widget.event.id,
        );
        setState(() {
          _hasAccepted = accepted;
          if (accepted) {
            _acknowledgeRisks = true;
            _acknowledgeRelease = true;
            _acknowledgeAge = true;
          }
        });
      }
    } catch (e) {
      // Ignore errors, assume not accepted
    }
  }

  Future<void> _acceptWaiver() async {
    if (!_acknowledgeRisks || !_acknowledgeRelease || !_acknowledgeAge) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please acknowledge all statements'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('Please sign in to accept the event waiver');
      }

      await _legalService.acceptEventWaiver(
        userId: authState.user.id,
        eventId: widget.event.id,
        ipAddress: null, // In production, get from request
        userAgent: null, // In production, get from request
      );

      setState(() {
        _hasAccepted = true;
        _isSubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Event waiver accepted'),
            backgroundColor: AppColors.electricGreen,
          ),
        );
        if (widget.requireAcceptance) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final requiresFull = EventWaiver.requiresFullWaiver(widget.event);
    final waiverText = requiresFull
        ? EventWaiver.generateWaiver(widget.event)
        : EventWaiver.generateSimplifiedWaiver(widget.event);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Event Waiver',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Event Info Header
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: AppTheme.warningColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.event.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${_formatDateTime(widget.event.startTime)} • ${widget.event.location ?? 'Location TBD'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_hasAccepted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.electricGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 16, color: AppColors.electricGreen),
                            const SizedBox(width: 4),
                            Text(
                              'Accepted',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.electricGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Waiver Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    waiverText,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Acknowledgment Checkboxes
                  if (requiresFull && !_hasAccepted) ...[
                    Divider(color: AppColors.grey300),
                    const SizedBox(height: 16),
                    Text(
                      'Acknowledgment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: Text(
                        'I understand and acknowledge the risks of participation',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      value: _acknowledgeRisks,
                      onChanged: (value) {
                        setState(() {
                          _acknowledgeRisks = value ?? false;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: Text(
                        'I release SPOTS and all parties from liability',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      value: _acknowledgeRelease,
                      onChanged: (value) {
                        setState(() {
                          _acknowledgeRelease = value ?? false;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: Text(
                        'I am of legal age to enter into this agreement (or have guardian consent)',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      value: _acknowledgeAge,
                      onChanged: (value) {
                        setState(() {
                          _acknowledgeAge = value ?? false;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Accept Button
          if (widget.requireAcceptance && !_hasAccepted) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.grey300)),
              ),
              child: Column(
                children: [
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: AppColors.error, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _acceptWaiver,
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
                        : const Text('I Agree'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

