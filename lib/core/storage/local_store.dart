import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:lumacart/core/constants/storage_keys.dart';
import 'package:lumacart/core/errors/failure.dart';

class LocalStore {
  LocalStore._(this._appBox, this._catalogBox);

  final Box<dynamic> _appBox;
  final Box<dynamic> _catalogBox;

  static Future<LocalStore> initialize() async {
    await Hive.initFlutter();
    final Box<dynamic> appBox = await Hive.openBox<dynamic>(StorageKeys.appBox);
    final Box<dynamic> catalogBox =
        await Hive.openBox<dynamic>(StorageKeys.catalogBox);
    return LocalStore._(appBox, catalogBox);
  }

  T? readApp<T>(String key) {
    try {
      return _appBox.get(key) as T?;
    } on Object catch (error) {
      throw Failure(
        message: 'Stored app data could not be read.',
        type: FailureType.storage,
        cause: error,
      );
    }
  }

  Future<void> writeApp(String key, Object? value) async {
    try {
      await _appBox.put(key, value);
    } on Object catch (error) {
      throw Failure(
        message: 'App data could not be saved.',
        type: FailureType.storage,
        cause: error,
      );
    }
  }

  T? readCatalog<T>(String key) {
    try {
      return _catalogBox.get(key) as T?;
    } on Object catch (error) {
      throw Failure(
        message: 'Cached catalog data could not be read.',
        type: FailureType.storage,
        cause: error,
      );
    }
  }

  Future<void> writeCatalog(String key, Object? value) async {
    try {
      await _catalogBox.put(key, value);
    } on Object catch (error) {
      throw Failure(
        message: 'Catalog data could not be cached.',
        type: FailureType.storage,
        cause: error,
      );
    }
  }

  Future<void> clearForTesting() async {
    await _appBox.clear();
    await _catalogBox.clear();
  }
}
