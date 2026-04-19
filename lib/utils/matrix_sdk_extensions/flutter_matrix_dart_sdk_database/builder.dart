import 'dart:ffi';
import 'dart:io';
import 'dart:math' show max;

import 'package:flutter/foundation.dart';

import 'package:matrix/matrix.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';
import 'package:universal_html/html.dart' as html;

import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/utils/client_manager.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'cipher.dart';

import 'sqlcipher_stub.dart'
    if (dart.library.io) 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

/// Loads the SQLCipher dynamic library. On Windows, sqlcipher_flutter_libs
/// ships [sqlite3.dll] (not libsqlcipher.dll), so we use that for compatibility.
void _sqlCipherFfiInit() {
  open.overrideForAll(_loadSQLCipherDynamicLibrary);
}

DynamicLibrary _loadSQLCipherDynamicLibrary() {
  if (Platform.isAndroid) {
    try {
      return DynamicLibrary.open('libsqlcipher.so');
    } catch (_) {
      final appIdAsBytes = File('/proc/self/cmdline').readAsBytesSync();
      final endOfAppId = max(appIdAsBytes.indexOf(0), 0);
      final appId = String.fromCharCodes(appIdAsBytes.sublist(0, endOfAppId));
      return DynamicLibrary.open('/data/data/$appId/lib/libsqlcipher.so');
    }
  }
  if (Platform.isLinux) {
    try {
      return DynamicLibrary.open('libsqlcipher_flutter_libs_plugin.so');
    } catch (_) {
      return DynamicLibrary.open('libsqlcipher.so');
    }
  }
  if (Platform.isIOS) {
    return DynamicLibrary.process();
  }
  if (Platform.isMacOS) {
    return DynamicLibrary.open(
      'sqlcipher_flutter_libs.framework/Versions/Current/'
      'sqlcipher_flutter_libs',
    );
  }
  if (Platform.isWindows) {
    // sqlcipher_flutter_libs ships SQLCipher as sqlite3.dll on Windows
    return DynamicLibrary.open('sqlite3.dll');
  }

  throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
}

Future<DatabaseApi> flutterMatrixSdkDatabaseBuilder(String clientName) async {
  MatrixSdkDatabase? database;
  try {
    database = await _constructDatabase(clientName);
    await database.open();
    return database;
  } catch (e, s) {
    Logs().wtf('Unable to construct database!', e, s);

    try {
      // Send error notification:
      final l10n = await lookupL10n(PlatformDispatcher.instance.locale);
      ClientManager.sendInitNotification(l10n.initAppError, e.toString());
    } catch (e, s) {
      Logs().e('Unable to send error notification', e, s);
    }

    // Try to delete database so that it can created again on next init:
    database?.delete().catchError(
      (e, s) => Logs().wtf(
        'Unable to delete database, after failed construction',
        e,
        s,
      ),
    );

    // Delete database file:
    if (!kIsWeb) {
      final dbFile = File(await _getDatabasePath(clientName));
      if (await dbFile.exists()) await dbFile.delete();
    }

    rethrow;
  }
}

Future<MatrixSdkDatabase> _constructDatabase(String clientName) async {
  if (kIsWeb) {
    html.window.navigator.storage?.persist();
    return await MatrixSdkDatabase.init(clientName);
  }

  final cipher = await getDatabaseCipher();

  Directory? fileStorageLocation;
  try {
    fileStorageLocation = await getTemporaryDirectory();
  } on MissingPlatformDirectoryException catch (_) {
    Logs().w(
      'No temporary directory for file cache available on this platform.',
    );
  }

  final path = await _getDatabasePath(clientName);

  // fix dlopen for old Android
  await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
  // import the SQLite / SQLCipher shared objects / dynamic libraries
  // Use custom ffiInit so Windows loads sqlite3.dll (sqlcipher_flutter_libs)
  final factory = createDatabaseFactoryFfi(
    ffiInit: _sqlCipherFfiInit,
  );

  // required for [getDatabasesPath]
  databaseFactory = factory;

  // migrate from potential previous SQLite database path to current one
  await _migrateLegacyLocation(path, clientName);

  // in case we got a cipher, we use the encryption helper
  // to manage SQLite encryption
  final helper = cipher == null
      ? null
      : SQfLiteEncryptionHelper(factory: factory, path: path, cipher: cipher);

  // check whether the DB is already encrypted and otherwise do so
  await helper?.ensureDatabaseFileEncrypted();

  final database = await factory.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 1,
      // most important : apply encryption when opening the DB
      onConfigure: helper?.applyPragmaKey,
    ),
  );

  return await MatrixSdkDatabase.init(
    clientName,
    database: database,
    maxFileSize: 1000 * 1000 * 10,
    fileStorageLocation: fileStorageLocation?.uri,
    deleteFilesAfterDuration: const Duration(days: 30),
  );
}

Future<String> _getDatabasePath(String clientName) async {
  final databaseDirectory = PlatformInfos.isIOS || PlatformInfos.isMacOS
      ? await getLibraryDirectory()
      : await getApplicationSupportDirectory();

  return join(databaseDirectory.path, '$clientName.sqlite');
}

Future<void> _migrateLegacyLocation(
  String sqlFilePath,
  String clientName,
) async {
  final oldPath = PlatformInfos.isDesktop
      ? (await getApplicationSupportDirectory()).path
      : await getDatabasesPath();

  final oldFilePath = join(oldPath, clientName);
  if (oldFilePath == sqlFilePath) return;

  final maybeOldFile = File(oldFilePath);
  if (await maybeOldFile.exists()) {
    Logs().i(
      'Migrate legacy location for database from "$oldFilePath" to "$sqlFilePath"',
    );
    await maybeOldFile.copy(sqlFilePath);
    await maybeOldFile.delete();
  }
}
