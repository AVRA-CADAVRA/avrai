import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:avrai/core/services/storage_service.dart' show SharedPreferencesCompat;
import 'package:avrai/core/services/model_safety_supervisor.dart';

import 'model_pack_manifest.dart';
import 'signed_manifest.dart';
import 'signed_manifest_verifier.dart';

class LocalLlmModelPackStatus {
  final bool isInstalled;
  final String? activePackId;
  final String? activeDir;

  const LocalLlmModelPackStatus({
    required this.isInstalled,
    required this.activePackId,
    required this.activeDir,
  });
}

/// Downloads/verifies/activates a local chat LLM model pack.
///
/// This is the “model pack” primitive used by Option B:
/// - iOS loads CoreML artifacts from an active directory
/// - Android loads GGUF from an active directory
class LocalLlmModelPackManager {
  static const String _logName = 'LocalLlmModelPackManager';

  static const String prefsKeyActiveModelDir = 'local_llm_active_model_dir_v1';
  static const String prefsKeyActiveModelId = 'local_llm_active_model_id_v1';
  static const String prefsKeyLastGoodModelDir =
      'local_llm_last_good_model_dir_v1';
  static const String prefsKeyLastGoodModelId =
      'local_llm_last_good_model_id_v1';
  static const String prefsKeyLastManifestJson =
      'local_llm_last_manifest_json_v1';

  final http.Client _client;
  final SharedPreferencesCompat? _prefsOverride;
  final Directory? _rootDirOverride;

  LocalLlmModelPackManager({
    http.Client? client,
    SharedPreferencesCompat? prefs,
    Directory? rootDir,
  })  : _client = client ?? http.Client(),
        _prefsOverride = prefs,
        _rootDirOverride = rootDir;

  Future<SharedPreferencesCompat> _prefs() async {
    if (_prefsOverride != null) return _prefsOverride!;
    return await SharedPreferencesCompat.getInstance();
  }

  Future<Directory> _rootDir() async {
    if (_rootDirOverride != null) return _rootDirOverride!;
    final dir = await getApplicationSupportDirectory();
    return Directory(p.join(dir.path, 'local_llm_packs'));
  }

  Future<LocalLlmModelPackStatus> getStatus() async {
    final prefs = await _prefs();
    final id = prefs.getString(prefsKeyActiveModelId);
    final dir = prefs.getString(prefsKeyActiveModelDir);
    if (id == null || id.isEmpty || dir == null || dir.isEmpty) {
      return const LocalLlmModelPackStatus(
        isInstalled: false,
        activePackId: null,
        activeDir: null,
      );
    }

    try {
      final exists = await Directory(dir).exists();
      return LocalLlmModelPackStatus(
        isInstalled: exists,
        activePackId: id,
        activeDir: dir,
      );
    } catch (_) {
      return LocalLlmModelPackStatus(
        isInstalled: false,
        activePackId: id,
        activeDir: dir,
      );
    }
  }

  Future<LocalLlmModelPackManifest> fetchManifest(Uri manifestUrl) async {
    if (kIsWeb) {
      throw UnsupportedError('Model packs are not supported on web.');
    }

    final res = await _client.get(manifestUrl);
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch manifest: ${res.statusCode}');
    }

    final manifest =
        LocalLlmModelPackManifest.tryParse(res.body) ??
            (throw Exception('Invalid manifest JSON'));

    if (manifest.modelId.isEmpty || manifest.version.isEmpty) {
      throw Exception('Invalid manifest: missing model_id/version');
    }

    return manifest;
  }

  /// Secure production path: fetch a signed manifest envelope from Supabase,
  /// verify signature locally, then activate the pack.
  ///
  /// This avoids user-provided manifest URLs in release builds.
  Future<void> downloadAndActivateTrusted({
    String tier = 'llama8b',
    void Function(int receivedBytes, int totalBytes)? onProgress,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Model packs are not supported on web.');
    }

    final envelope = await _fetchSignedManifestFromSupabase(tier: tier);
    final verifier = LocalLlmSignedManifestVerifier();
    final payloadBytes = await verifier.verifyAndExtractPayloadBytes(envelope);
    final payloadJson = utf8.decode(payloadBytes);
    final manifest =
        LocalLlmModelPackManifest.tryParse(payloadJson) ??
            (throw Exception('Invalid signed manifest payload'));

    await _downloadAndActivateManifest(
      manifest: manifest,
      onProgress: onProgress,
    );
  }

  Future<void> downloadAndActivate({
    required Uri manifestUrl,
    void Function(int receivedBytes, int totalBytes)? onProgress,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Model packs are not supported on web.');
    }

    final manifest = await fetchManifest(manifestUrl);
    await _downloadAndActivateManifest(
      manifest: manifest,
      onProgress: onProgress,
    );
  }

  Future<void> _downloadAndActivateManifest({
    required LocalLlmModelPackManifest manifest,
    void Function(int receivedBytes, int totalBytes)? onProgress,
  }) async {
    final prefs = await _prefs();
    final root = await _rootDir();
    if (!await root.exists()) {
      await root.create(recursive: true);
    }

    // Idempotency: if the requested pack is already active and present on disk,
    // avoid re-downloading multi-GB artifacts.
    final current = await getStatus();
    if (current.isInstalled && current.activePackId == manifest.packId) {
      developer.log(
        'Model pack already active (${manifest.packId}); skipping download',
        name: _logName,
      );
      return;
    }

    final artifact = manifest.selectArtifactForCurrentPlatform();
    if (artifact == null) {
      throw Exception('No artifact available for this platform');
    }

    final targetDir = Directory(p.join(root.path, manifest.modelId, manifest.version));
    final tmpDir = Directory(p.join(
      root.path,
      '.tmp_${manifest.modelId}_${manifest.version}_${DateTime.now().millisecondsSinceEpoch}',
    ));

    try {
      if (await tmpDir.exists()) {
        await tmpDir.delete(recursive: true);
      }
      await tmpDir.create(recursive: true);

      // 1) Download artifact.
      final artifactFile = File(p.join(tmpDir.path, artifact.fileName));
      await _downloadToFile(
        Uri.parse(artifact.url),
        artifactFile,
        expectedSizeBytes: artifact.sizeBytes,
        onProgress: onProgress,
      );

      // 2) Verify SHA-256.
      final ok = await _verifySha256(
        file: artifactFile,
        expectedHex: artifact.sha256,
      );
      if (!ok) {
        throw Exception('SHA-256 verification failed for ${artifact.fileName}');
      }

      // 3) Prepare target dir and extract/move.
      if (await targetDir.exists()) {
        // If already present, assume it’s fine and just activate.
        developer.log('Target dir already exists; re-activating', name: _logName);
      } else {
        await targetDir.create(recursive: true);
        if (artifact.isZip) {
          await _extractZipSafely(zipFile: artifactFile, destDir: targetDir);
        } else {
          final destFile = File(p.join(targetDir.path, artifact.fileName));
          await artifactFile.copy(destFile.path);
        }
      }

      // 4) Atomically mark last-good → active.
      final previousActiveDir = prefs.getString(prefsKeyActiveModelDir);
      final previousActiveId = prefs.getString(prefsKeyActiveModelId);

      if (previousActiveDir != null &&
          previousActiveDir.isNotEmpty &&
          previousActiveId != null &&
          previousActiveId.isNotEmpty) {
        await prefs.setString(prefsKeyLastGoodModelDir, previousActiveDir);
        await prefs.setString(prefsKeyLastGoodModelId, previousActiveId);
      }

      await prefs.setString(prefsKeyActiveModelDir, targetDir.path);
      await prefs.setString(prefsKeyActiveModelId, manifest.packId);
      await prefs.setString(prefsKeyLastManifestJson, jsonEncode(manifest.toJson()));

      // Start happiness-gated rollout for local chat model pack.
      try {
        if (previousActiveId != null && previousActiveId.isNotEmpty) {
          await ModelSafetySupervisor(prefs: prefs).startRolloutCandidate(
            modelType: 'chat_local_llm',
            fromVersion: previousActiveId,
            toVersion: manifest.packId,
          );
        }
      } catch (_) {
        // Ignore.
      }

      developer.log(
        'Activated local LLM model pack: ${manifest.packId} at ${targetDir.path}',
        name: _logName,
      );
    } catch (e, st) {
      developer.log(
        'Download/activate failed',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      rethrow;
    } finally {
      // Always clean tmp.
      try {
        if (await tmpDir.exists()) {
          await tmpDir.delete(recursive: true);
        }
      } catch (_) {
        // Ignore.
      }
    }
  }

  Future<LocalLlmSignedManifestEnvelope> _fetchSignedManifestFromSupabase({
    required String tier,
  }) async {
    // Uses Supabase Edge Functions. This does not require auth; the payload is
    // signed and verified client-side.
    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      _ => '',
    };
    final client = Supabase.instance.client;
    final res = await client.functions.invoke(
      'local-llm-manifest',
      body: <String, dynamic>{
        'tier': tier,
        if (platform.isNotEmpty) 'platform': platform,
      },
    );
    final data = res.data;
    if (data is! Map) {
      throw Exception('Invalid manifest response');
    }
    return LocalLlmSignedManifestEnvelope.fromJson(
      data.map((k, v) => MapEntry(k.toString(), v)),
    );
  }

  Future<void> rollbackToLastGoodIfPresent() async {
    final prefs = await _prefs();
    final lastDir = prefs.getString(prefsKeyLastGoodModelDir);
    final lastId = prefs.getString(prefsKeyLastGoodModelId);
    if (lastDir == null || lastDir.isEmpty || lastId == null || lastId.isEmpty) {
      return;
    }

    await prefs.setString(prefsKeyActiveModelDir, lastDir);
    await prefs.setString(prefsKeyActiveModelId, lastId);
  }

  Future<void> _downloadToFile(
    Uri url,
    File out, {
    required int expectedSizeBytes,
    void Function(int receivedBytes, int totalBytes)? onProgress,
  }) async {
    final req = http.Request('GET', url);
    final res = await _client.send(req);
    if (res.statusCode != 200) {
      throw Exception('Failed to download artifact: ${res.statusCode}');
    }
    final sink = out.openWrite();
    try {
      final total = expectedSizeBytes > 0
          ? expectedSizeBytes
          : ((res.contentLength != null && res.contentLength! > 0)
              ? res.contentLength!
              : 0);
      int received = 0;
      int lastReported = 0;
      const minReportDelta = 512 * 1024; // 512KB

      if (onProgress != null) {
        onProgress(0, total);
      }

      await for (final chunk in res.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (onProgress != null &&
            (received == total ||
                total == 0 ||
                (received - lastReported) >= minReportDelta)) {
          onProgress(received, total);
          lastReported = received;
        }
      }
    } finally {
      await sink.flush();
      await sink.close();
    }
  }

  Future<bool> _verifySha256({
    required File file,
    required String expectedHex,
  }) async {
    final digest = (await sha256.bind(file.openRead()).first).toString();
    return digest.toLowerCase() == expectedHex.toLowerCase();
  }

  Future<void> _extractZipSafely({
    required File zipFile,
    required Directory destDir,
  }) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final entry in archive) {
      final name = entry.name;
      if (name.isEmpty) continue;

      // Prevent Zip Slip.
      final outPath = p.normalize(p.join(destDir.path, name));
      final destNorm = p.normalize(destDir.path);
      if (!p.isWithin(destNorm, outPath) && outPath != destNorm) {
        throw Exception('Zip entry attempts path traversal: $name');
      }

      if (entry.isFile) {
        final outFile = File(outPath);
        await outFile.parent.create(recursive: true);
        final data = entry.content as List<int>;
        await outFile.writeAsBytes(data, flush: true);
      } else {
        await Directory(outPath).create(recursive: true);
      }
    }
  }
}

