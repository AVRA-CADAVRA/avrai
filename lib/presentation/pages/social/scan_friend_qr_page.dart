// Scan Friend QR Page
//
// Camera view for scanning friend QR codes
// Parses scanned QR code and allows sending friend request

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:avrai/core/services/friend_qr_service.dart';
import 'package:avrai/core/services/social_media_discovery_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Scan Friend QR Page
///
/// Displays camera view for scanning friend QR codes.
/// Parses scanned QR code and allows sending friend request.
class ScanFriendQRPage extends StatefulWidget {
  const ScanFriendQRPage({super.key});

  @override
  State<ScanFriendQRPage> createState() => _ScanFriendQRPageState();
}

class _ScanFriendQRPageState extends State<ScanFriendQRPage> {
  final MobileScannerController _scannerController = MobileScannerController();
  final SocialMediaDiscoveryService _discoveryService =
      di.sl<SocialMediaDiscoveryService>();
  final AgentIdService _agentIdService = di.sl<AgentIdService>();

  bool _isProcessing = false;
  FriendQRData? _scannedData;
  bool _hasScanned = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing || _hasScanned) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    if (barcode.rawValue == null) return;

    final qrData = barcode.rawValue!;
    developer.log(
      'Scanned QR code: ${qrData.length > 50 ? qrData.substring(0, 50) : qrData}...',
      name: 'ScanFriendQRPage',
    );

    // Parse QR code data
    final friendData = FriendQRService.parseFriendQRCodeData(qrData);
    if (friendData == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid QR code. Please scan a friend QR code.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Check if QR code is expired
    if (friendData.isExpired) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR code has expired. Please ask your friend to generate a new one.'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Stop scanning and show preview
    setState(() {
      _isProcessing = true;
      _scannedData = friendData;
      _hasScanned = true;
    });

    _scannerController.stop();
  }

  Future<void> _sendFriendRequest() async {
    if (_scannedData == null) return;

    try {
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;
      if (authState is! Authenticated) {
        throw Exception('User not authenticated');
      }

      final userId = authState.user.id;
      final agentId = await _agentIdService.getUserAgentId(userId);

      // Check if trying to add self
      if (agentId == _scannedData!.agentId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You cannot add yourself as a friend.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      final success = await _discoveryService.sendFriendConnectionRequest(
        agentId: agentId,
        friendAgentId: _scannedData!.agentId,
        userId: userId,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Friend request sent!'),
              backgroundColor: AppColors.success,
            ),
          );
          // Navigate back after short delay
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send friend request. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      developer.log(
        'Error sending friend request: $e',
        name: 'ScanFriendQRPage',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _resetScan() {
    setState(() {
      _scannedData = null;
      _hasScanned = false;
      _isProcessing = false;
    });
    _scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Friend QR Code'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          if (_hasScanned)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetScan,
              tooltip: 'Scan again',
            ),
        ],
      ),
      body: _hasScanned && _scannedData != null
          ? _buildFriendPreview()
          : _buildScannerView(),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        // Camera view
        MobileScanner(
          controller: _scannerController,
          onDetect: _onDetect,
        ),
        // Overlay with instructions
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: const Text(
              'Position the QR code within the frame',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        // Scanning frame overlay
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.electricGreen,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // Bottom instructions
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Scan your friend\'s QR code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Make sure the QR code is clearly visible',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFriendPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 64,
            color: AppColors.success,
          ),
          const SizedBox(height: 16),
          const Text(
            'QR Code Scanned!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agent ID: ${_scannedData!.agentId.length > 20 ? _scannedData!.agentId.substring(0, 20) : _scannedData!.agentId}...',
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.grey300,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Send Friend Request?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This will send a friend request to this user.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _sendFriendRequest,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.person_add),
              label: Text(_isProcessing ? 'Sending...' : 'Send Friend Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _resetScan,
            child: const Text('Scan Another QR Code'),
          ),
        ],
      ),
    );
  }
}
