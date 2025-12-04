import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:spots/core/services/logger.dart';

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  Map<Permission, PermissionStatus> _statuses = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refreshStatuses();
  }

  Future<void> _refreshStatuses() async {
    // Skip permission checks on web - they're not supported
    if (kIsWeb) {
      setState(() => _statuses = {});
      return;
    }
    
    final permissions = <Permission>[
      Permission.locationWhenInUse,
      Permission.locationAlways,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.nearbyWifiDevices,
    ];
    final statuses = <Permission, PermissionStatus>{};
    for (final p in permissions) {
      try {
        statuses[p] = await p.status;
      } catch (e) {
        // Skip permissions that aren't supported on this platform
        continue;
      }
    }
    setState(() => _statuses = statuses);
  }

  Future<void> _requestAll() async {
    // Skip permission requests on web - they're not supported
    if (kIsWeb) {
      _logger.info('Skipping permission requests on web', tag: 'PermissionsPage');
      return;
    }
    
    setState(() => _loading = true);
    try {
      await [
        Permission.locationWhenInUse,
        Permission.locationAlways,
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.nearbyWifiDevices,
      ].request();
      await _refreshStatuses();
    } catch (e) {
      _logger.error('Error requesting permissions', error: e, tag: 'PermissionsPage');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enable Connectivity & Location', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('To enable ai2ai connectivity, presence, and location-based experiences, please allow these permissions. We ask only what we need and you remain in control.'),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: _statuses.entries.map((e) {
                final name = e.key.toString().split('.').last;
                final status = e.value.toString().split('.').last;
                String rationale;
                switch (e.key) {
                  case Permission.locationWhenInUse:
                    rationale = 'Needed to show nearby spots and personalize discovery.';
                    break;
                  case Permission.locationAlways:
                    rationale = 'Enables background spot detection and presence for ai2ai.';
                    break;
                  case Permission.bluetooth:
                  case Permission.bluetoothScan:
                  case Permission.bluetoothConnect:
                  case Permission.bluetoothAdvertise:
                    rationale = 'Enables secure ai2ai presence and proximity awareness.';
                    break;
                  case Permission.nearbyWifiDevices:
                    rationale = 'Improves device discovery and connectivity quality.';
                    break;
                  default:
                    rationale = '';
                }
                return ListTile(
                  title: Text(name),
                  subtitle: Text('$status • $rationale'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      await e.key.request();
                      await _refreshStatuses();
                    },
                    child: const Text('Allow'),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: openAppSettings,
            child: const Text('Open Settings'),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _requestAll,
              child: Text(_loading ? 'Requesting…' : 'Enable All'),
            ),
          ),
        ],
      ),
    );
  }
}
enum OnboardingStepType {
  homebase,
  favoritePlaces,
  preferences,
  baselineLists,
  friends,
}

class OnboardingStep {
  final OnboardingStepType type;
  final String title;
  final String description;
  final Widget page;

  const OnboardingStep({
    required this.type,
    required this.title,
    required this.description,
    required this.page,
  });
}
