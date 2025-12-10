import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

const _documentsChannelName = 'com.rgs.app/documents_path';

FlutterAuthClientOptions createPlatformAuthOptions({
  required String persistSessionKey,
}) {
  final localStorage =
      FileLocalStorage(persistSessionKey: persistSessionKey);
  final pkceStorage = FileGotrueAsyncStorage();

  return FlutterAuthClientOptions(
    authFlowType: AuthFlowType.pkce,
    localStorage: localStorage,
    pkceAsyncStorage: pkceStorage,
  );
}

class FileLocalStorage extends LocalStorage {
  FileLocalStorage({required this.persistSessionKey});

  final String persistSessionKey;
  final _FileStore _store = _FileStore('supabase_session.json');

  @override
  Future<void> initialize() => _store.ensureInitialized();

  @override
  Future<bool> hasAccessToken() async {
    await _store.ensureInitialized();
    return _store.containsKey(persistSessionKey);
  }

  @override
  Future<String?> accessToken() async {
    await _store.ensureInitialized();
    return _store.read(persistSessionKey);
  }

  @override
  Future<void> removePersistedSession() async {
    await _store.ensureInitialized();
    await _store.write(persistSessionKey, null);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await _store.ensureInitialized();
    await _store.write(persistSessionKey, persistSessionString);
  }
}

class FileGotrueAsyncStorage extends GotrueAsyncStorage {
  FileGotrueAsyncStorage({String fileName = 'supabase_pkce.json'})
      : _store = _FileStore(fileName);

  final _FileStore _store;

  @override
  Future<String?> getItem({required String key}) async {
    await _store.ensureInitialized();
    return _store.read(key);
  }

  @override
  Future<void> removeItem({required String key}) async {
    await _store.ensureInitialized();
    await _store.write(key, null);
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    await _store.ensureInitialized();
    await _store.write(key, value);
  }
}

class _FileStore {
  _FileStore(this.fileName);

  final String fileName;
  final MethodChannel _documentsChannel =
      const MethodChannel(_documentsChannelName);
  File? _file;
  Map<String, dynamic> _cache = {};
  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    if (kIsWeb) {
      throw UnsupportedError('File storage is not available on web.');
    }

    final directory = await _resolveStorageDirectory();
    final file = File(p.join(directory.path, fileName));
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode({}));
    }

    try {
      final contents = await file.readAsString();
      if (contents.isNotEmpty) {
        _cache = jsonDecode(contents) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('⚠️ Failed to read $_documentsChannelName storage: $e');
      _cache = {};
    }

    _file = file;
    _initialized = true;
  }

  Future<Directory> _resolveStorageDirectory() async {
    // Try shared method channel (implemented on iOS & Android)
    final channelPath = await _tryGetDocumentsPathViaChannel();
    if (channelPath != null) {
      final directory = Directory(channelPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    }

    final fallback =
        Directory(p.join(Directory.systemTemp.path, 'rgs_app_storage'));
    if (!await fallback.exists()) {
      await fallback.create(recursive: true);
    }
    return fallback;
  }

  Future<String?> _tryGetDocumentsPathViaChannel() async {
    try {
      final result =
          await _documentsChannel.invokeMethod<String>('getDocumentsPath');
      if (result != null && result.isNotEmpty) {
        return result;
      }
    } on PlatformException catch (e) {
      debugPrint('⚠️ MethodChannel documents path failed: ${e.message}');
    } catch (e) {
      debugPrint('⚠️ MethodChannel documents path error: $e');
    }
    return null;
  }

  Future<void> write(String key, String? value) async {
    if (_file == null) return;
    if (value == null) {
      _cache.remove(key);
    } else {
      _cache[key] = value;
    }
    await _file!.writeAsString(jsonEncode(_cache));
  }

  Future<String?> read(String key) async {
    return _cache[key] as String?;
  }

  bool containsKey(String key) {
    return _cache.containsKey(key);
  }
}
