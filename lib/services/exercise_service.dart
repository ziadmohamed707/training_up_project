import 'dart:convert';

import 'package:flutter/services.dart';

import 'api_service.dart';

/// Loads exercise JSON files packaged under `assets/exercises_by_category/`.
class ExerciseService {
  static const String _fallbackIndexPath =
      'assets/exercises_by_category/_index.json';
  static const String _apiOrigin = 'https://trainingg.pythonanywhere.com';
  Future<Set<String>>? _assetKeysCache;
  final ApiService _apiService = ApiService();
  final Map<String, Map<String, dynamic>> _apiItemsByKey = {};

  String? _normalizeApiImagePath(dynamic raw) {
    if (raw is! String) return null;
    final value = raw.trim();
    if (value.isEmpty) return null;

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('assets/')) {
      return value;
    }
    if (value.startsWith('/')) {
      return '$_apiOrigin$value';
    }

    return '$_apiOrigin/$value';
  }

  String _normalizeCategoryFolder(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
  }

  List<String> _nameCandidates(String rawName) {
    final base = rawName.trim();
    if (base.isEmpty) return const [];

    final set = <String>{};
    set.add(base);
    set.add(base.replaceAll(', ', '_'));
    set.add(base.replaceAll(',', ''));
    set.add(base.replaceAll(', ', ' ').replaceAll(',', ''));
    set.add(base.replaceAll(' - ', '_-_'));
    set.add(base.replaceAll(' - ', '_').replaceAll('-', '_'));
    set.add(base.replaceAll(' ', '_'));
    set.add(
      base
          .replaceAll(',', '')
          .replaceAll(' - ', '_')
          .replaceAll('-', '_')
          .replaceAll(' ', '_'),
    );

    return set
        .map((e) => e.replaceAll('__', '_').trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  String? _inferAssetImageForApiExercise(
    Map<String, dynamic> data,
    Set<String> assetKeys,
  ) {
    final name = (data['name'] ?? '').toString();
    if (name.trim().isEmpty) return null;

    final categoryFolder = _normalizeCategoryFolder(
      (data['category'] ?? '').toString(),
    );

    final candidates = _nameCandidates(
      name,
    ).map((e) => e.toLowerCase()).toList();

    List<String> searchPool = assetKeys
        .where(
          (k) =>
              k.startsWith('assets/exercises_by_category/') && _isImagePath(k),
        )
        .toList();

    if (categoryFolder.isNotEmpty) {
      final scoped = searchPool
          .where((k) => k.contains('/$categoryFolder/images/'))
          .toList();
      if (scoped.isNotEmpty) {
        searchPool = scoped;
      }
    }

    for (final candidate in candidates) {
      final withSlashes = '/$candidate/';
      final hit = searchPool.firstWhere(
        (k) => k.toLowerCase().contains(withSlashes),
        orElse: () => '',
      );
      if (hit.isNotEmpty) return hit;
    }

    return null;
  }

  List<String> _normalizeInstructions(dynamic value) {
    if (value is List) {
      return value
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
    }
    return const [];
  }

  String _apiKeyFromId(dynamic id) => 'api:$id';

  Map<String, dynamic> _normalizeApiExercise(Map<String, dynamic> source) {
    final id = source['id'] ?? source['exercise_id'] ?? source['pk'];
    final key = _apiKeyFromId(id ?? source.hashCode);

    final data = <String, dynamic>{
      ...source,
      'id': id,
      'name':
          source['name'] ??
          source['title'] ??
          source['exercise_name'] ??
          'Exercise',
      'category': source['category'] ?? '',
      'force': source['force'] ?? '',
      'level': source['level'] ?? 'beginner',
      'mechanic': source['mechanic'] ?? '',
      'equipment': source['equipment'] ?? '',
      'instructions': _normalizeInstructions(
        source['instructions'] ??
            source['instruction'] ??
            source['steps'] ??
            source['description'],
      ),
    };

    final imagePath = _normalizeApiImagePath(
      source['image'] ?? source['image_url'] ?? source['thumbnail'],
    );

    return {'path': key, 'data': data, 'image': imagePath};
  }

  Future<List<Map<String, dynamic>>> _loadFromApi({int? limit}) async {
    final result = await _apiService.getExercises();
    if (!(result['success'] as bool? ?? false)) return const [];

    final decoded = result['data'];
    if (decoded is! List) return const [];

    final mapped = decoded
        .whereType<Map>()
        .map((item) => _normalizeApiExercise(Map<String, dynamic>.from(item)))
        .toList();

    // If backend doesn't provide image URLs, try to map each exercise
    // to bundled assets by category + name.
    try {
      final assetKeys = await _loadAssetKeys();
      for (final item in mapped) {
        if (item['image'] != null) continue;
        final data = item['data'] as Map<String, dynamic>?;
        if (data == null) continue;
        final inferred = _inferAssetImageForApiExercise(data, assetKeys);
        if (inferred != null) {
          item['image'] = inferred;
        }
      }
    } catch (_) {
      // keep null image when asset inspection fails
    }

    _apiItemsByKey
      ..clear()
      ..addEntries(
        mapped.map((item) => MapEntry(item['path'].toString(), item)),
      );

    if (limit != null && mapped.length > limit) {
      return mapped.take(limit).toList();
    }
    return mapped;
  }

  Future<Set<String>> _loadAssetKeys() {
    _assetKeysCache ??= () async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      return manifest.listAssets().toSet();
    }();
    return _assetKeysCache!;
  }

  bool _isImagePath(String value) {
    final lower = value.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');
  }

  List<String> _extractImageCandidates(dynamic node) {
    final out = <String>[];

    void walk(dynamic n) {
      if (n == null) return;
      if (n is String) {
        if (_isImagePath(n)) out.add(n);
        return;
      }
      if (n is List) {
        for (final e in n) {
          walk(e);
        }
        return;
      }
      if (n is Map) {
        for (final v in n.values) {
          walk(v);
        }
      }
    }

    walk(node);
    return out;
  }

  String? _resolveImagePath(
    String jsonKey,
    List<String> candidates,
    Set<String> assetKeys,
  ) {
    final dir = jsonKey.contains('/')
        ? jsonKey.substring(0, jsonKey.lastIndexOf('/') + 1)
        : '';

    String normalize(String p) =>
        p.replaceAll('\\', '/').replaceFirst('./', '');

    for (final raw in candidates) {
      final candidate = normalize(raw.trim());
      final tryPaths = <String>[];

      if (candidate.startsWith('assets/')) {
        tryPaths.add(candidate);
      } else {
        tryPaths.add('$dir$candidate');
        tryPaths.add('${dir}images/$candidate');
      }

      for (final p in tryPaths) {
        if (assetKeys.contains(p)) return p;
      }
    }

    // final fallback: choose first image under same JSON folder
    final fallback = assetKeys.where((k) {
      if (!k.startsWith(dir)) return false;
      return _isImagePath(k);
    }).toList();

    if (fallback.isNotEmpty) {
      fallback.sort((a, b) {
        final aPref = a.contains('/images/') ? 0 : 1;
        final bPref = b.contains('/images/') ? 0 : 1;
        return aPref - bPref;
      });
      return fallback.first;
    }

    return null;
  }

  /// Returns a list of maps with keys: `path` (asset path) and `data` (decoded JSON).
  Future<List<Map<String, dynamic>>> loadAllExercises({int? limit}) async {
    final apiItems = await _loadFromApi(limit: limit);
    if (apiItems.isNotEmpty) return apiItems;

    final assetKeys = await _loadAssetKeys();
    final jsonKeys = assetKeys
        .where(
          (k) =>
              k.startsWith('assets/exercises_by_category/') &&
              k.endsWith('.json'),
        )
        .toList();

    final List<Map<String, dynamic>> results = [];

    for (final key in jsonKeys) {
      try {
        final raw = await rootBundle.loadString(key);
        final decoded = json.decode(raw);
        final candidates = _extractImageCandidates(decoded);
        final imagePath = _resolveImagePath(key, candidates, assetKeys);

        if (decoded is Map<String, dynamic>) {
          results.add({'path': key, 'data': decoded, 'image': imagePath});
        } else if (decoded is List) {
          results.add({
            'path': key,
            'data': {'list': decoded},
            'image': imagePath,
          });
        } else {
          results.add({
            'path': key,
            'data': {'value': decoded},
            'image': imagePath,
          });
        }
        if (limit != null && results.length >= limit) break;
      } catch (e) {
        // ignore malformed/unsupported JSON files
      }
    }

    return results;
  }

  /// Return raw list of JSON asset keys under `assets/exercises_by_category/`.
  Future<List<String>> listJsonKeys() async {
    final apiItems = await _loadFromApi();
    if (apiItems.isNotEmpty) {
      return apiItems.map((e) => e['path'].toString()).toList();
    }

    final assetKeys = await _loadAssetKeys();
    var jsonKeys = assetKeys
        .where(
          (k) =>
              k.startsWith('assets/exercises_by_category/') &&
              k.endsWith('.json') &&
              k != _fallbackIndexPath,
        )
        .toList();

    // Fallback if manifest-based discovery unexpectedly returns empty.
    if (jsonKeys.isEmpty) {
      try {
        final raw = await rootBundle.loadString(_fallbackIndexPath);
        final decoded = json.decode(raw);
        if (decoded is Map<String, dynamic> && decoded['json_paths'] is List) {
          jsonKeys = (decoded['json_paths'] as List)
              .whereType<String>()
              .where((p) => p.endsWith('.json') && p != _fallbackIndexPath)
              .toList();
        }
      } catch (_) {
        // keep empty on failure
      }
    }

    return jsonKeys;
  }

  /// Load and parse a single exercise JSON asset and resolve an image path if possible.
  Future<Map<String, dynamic>?> loadExerciseByKey(String key) async {
    if (key.startsWith('api:')) {
      final cached = _apiItemsByKey[key];
      if (cached != null) return cached;

      final idPart = key.replaceFirst('api:', '');
      if (idPart.isNotEmpty) {
        final result = await _apiService.getExerciseDetails(idPart);
        if (result['success'] == true && result['data'] is Map) {
          final normalized = _normalizeApiExercise(
            Map<String, dynamic>.from(result['data'] as Map),
          );
          _apiItemsByKey[normalized['path'].toString()] = normalized;
          return normalized;
        }
      }
    }

    try {
      final assetKeys = await _loadAssetKeys();

      final raw = await rootBundle.loadString(key);
      final decoded = json.decode(raw);

      final candidates = _extractImageCandidates(decoded);
      final imagePath = _resolveImagePath(key, candidates, assetKeys);

      if (decoded is Map<String, dynamic>) {
        return {'path': key, 'data': decoded, 'image': imagePath};
      } else if (decoded is List) {
        return {
          'path': key,
          'data': {'list': decoded},
          'image': imagePath,
        };
      } else {
        return {
          'path': key,
          'data': {'value': decoded},
          'image': imagePath,
        };
      }
    } catch (e) {
      return null;
    }
  }
}
