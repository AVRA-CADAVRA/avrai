// Add Friend QR Page
//
// Displays user's QR code for friending
// Other users can scan this QR code to send a friend request

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:avrai/core/services/friend_qr_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Add Friend QR Page
///
/// Displays a QR code containing the user's agentId.
/// Other users can scan this QR code to send a friend request.
class AddFriendQRPage extends StatefulWidget {
  const AddFriendQRPage({super.key});

  @override
  State<AddFriendQRPage> createState() => _AddFriendQRPageState();
}

class _AddFriendQRPageState extends State<AddFriendQRPage> {
  final AgentIdService _agentIdService = di.sl<AgentIdService>();
  String? _agentId;
  String? _qrCodeData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAgentId();
  }

  Future<void> _loadAgentId() async {
    try {
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;
      if (authState is! Authenticated) {
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }

      final userId = authState.user.id;
      final agentId = await _agentIdService.getUserAgentId(userId);
      final qrCodeData = FriendQRService.generateFriendQRCodeData(agentId);

      if (mounted) {
        setState(() {
          _agentId = agentId;
          _qrCodeData = qrCodeData;
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log(
        'Error loading agent ID: $e',
        name: 'AddFriendQRPage',
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading QR code: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Friend'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _qrCodeData == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Unable to generate QR code',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadAgentId,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Let your friend scan this QR code',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'They can scan this code to send you a friend request',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // QR Code Display
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.grey300,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.grey300.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: _qrCodeData!,
                          version: QrVersions.auto,
                          size: 250,
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Agent ID Display (for manual entry fallback)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.grey300,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Or share your Agent ID manually',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SelectableText(
                              _agentId ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                fontFamily: 'monospace',
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                // Copy to clipboard
                                if (_agentId != null) {
                                  Clipboard.setData(ClipboardData(text: _agentId!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Agent ID copied to clipboard'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('Copy Agent ID'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Instructions
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.electricGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.electricGreen.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.help_outline,
                                  size: 18,
                                  color: AppColors.electricGreen,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'How it works',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              '1. Show this QR code to your friend\n'
                              '2. They scan it with their phone\n'
                              '3. They send you a friend request\n'
                              '4. You accept to become friends',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
