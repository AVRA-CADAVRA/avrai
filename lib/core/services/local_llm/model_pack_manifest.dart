import 'dart:convert';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;

class LocalLlmModelPackArtifact {
  /// `android_gguf` | `ios_coreml_zip`
  final String platform;
  final String url;
  final String sha256;
  final int sizeBytes;
  final String fileName;

  /// True if artifact is a zip that must be extracted.
  final bool isZip;

  const LocalLlmModelPackArtifact({
    required this.platform,
    required this.url,
    required this.sha256,
    required this.sizeBytes,
    required this.fileName,
    required this.isZip,
  });

  factory LocalLlmModelPackArtifact.fromJson(Map<String, dynamic> json) {
    return LocalLlmModelPackArtifact(
      platform: (json['platform'] as String?) ?? '',
      url: (json['url'] as String?) ?? '',
      sha256: (json['sha256'] as String?) ?? '',
      sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
      fileName: (json['file_name'] as String?) ?? '',
      isZip: (json['is_zip'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'platform': platform,
        'url': url,
        'sha256': sha256,
        'size_bytes': sizeBytes,
        'file_name': fileName,
        'is_zip': isZip,
      };
}

class LocalLlmModelPackManifest {
  final String modelId;
  final String version;
  final String family;
  final int contextLen;

  /// Minimum device requirements (soft gate; hard gate lives in Dart policy).
  final int minRamMb;
  final int minFreeDiskMb;

  final List<LocalLlmModelPackArtifact> artifacts;

  const LocalLlmModelPackManifest({
    required this.modelId,
    required this.version,
    required this.family,
    required this.contextLen,
    required this.minRamMb,
    required this.minFreeDiskMb,
    required this.artifacts,
  });

  factory LocalLlmModelPackManifest.fromJson(Map<String, dynamic> json) {
    final artifactsRaw = json['artifacts'];
    final artifacts = <LocalLlmModelPackArtifact>[];
    if (artifactsRaw is List) {
      for (final e in artifactsRaw) {
        if (e is Map) {
          artifacts.add(
            LocalLlmModelPackArtifact.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ),
          );
        }
      }
    }

    final requirements = json['min_device'] as Map?;

    return LocalLlmModelPackManifest(
      modelId: (json['model_id'] as String?) ?? '',
      version: (json['version'] as String?) ?? '',
      family: (json['family'] as String?) ?? '',
      contextLen: (json['context_len'] as num?)?.toInt() ?? 0,
      minRamMb: (requirements?['min_ram_mb'] as num?)?.toInt() ?? 0,
      minFreeDiskMb: (requirements?['min_free_disk_mb'] as num?)?.toInt() ?? 0,
      artifacts: artifacts,
    );
  }

  static LocalLlmModelPackManifest? tryParse(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map) {
        return LocalLlmModelPackManifest.fromJson(
          decoded.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'model_id': modelId,
        'version': version,
        'family': family,
        'context_len': contextLen,
        'min_device': <String, dynamic>{
          'min_ram_mb': minRamMb,
          'min_free_disk_mb': minFreeDiskMb,
        },
        'artifacts': artifacts.map((a) => a.toJson()).toList(),
      };

  LocalLlmModelPackArtifact? selectArtifactForCurrentPlatform() {
    return selectArtifactForPlatform(defaultTargetPlatform);
  }

  LocalLlmModelPackArtifact? selectArtifactForPlatform(TargetPlatform platform) {
    final key = switch (platform) {
      TargetPlatform.android => 'android_gguf',
      TargetPlatform.iOS => 'ios_coreml_zip',
      TargetPlatform.macOS => 'macos_coreml_zip', // Primary: CoreML for Apple Silicon
      _ => '',
    };
    if (key.isEmpty) return null;
    // Check for primary artifact first (CoreML for macOS)
    for (final a in artifacts) {
      if (a.platform == key) return a;
    }
    // Fallback to Intel GGUF if CoreML not available (for Intel Macs)
    if (platform == TargetPlatform.macOS) {
      for (final a in artifacts) {
        if (a.platform == 'macos_intel_gguf') return a;
      }
    }
    return null;
  }

  String get packId => '$modelId@$version';
}

