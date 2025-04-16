import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'battle/battle_unit.dart';
import 'battle/level_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class GameDataManager {
  static const String _coinsKey = 'coins';
  static const String _winStreakKey = 'winStreak';
  static const String _currentLevelKey = 'currentLevel';
  static const String _playerUnitsKey = 'playerUnits';
  static const String _enemyUnitsKey = 'enemyUnits';
  static const String _enemyConfigKey = 'enemyConfig';
  
  // 棋盤大小常量
  static const int totalRows = 6;
  static const int totalCols = 5;

  // 保存遊戲數據
  static Future<void> saveGameData({
    required int coins,
    required int winStreak,
    required int currentLevel,
    required List<List<BattleUnit?>> playerUnits,
    required List<List<BattleUnit?>> enemyUnits,
    List<EnemyConfig>? enemyConfig,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 保存基本遊戲數據
      await prefs.setInt(_coinsKey, coins);
      await prefs.setInt(_winStreakKey, winStreak);
      await prefs.setInt(_currentLevelKey, currentLevel);
      
      // 保存單位數據
      await _saveUnits(_playerUnitsKey, playerUnits);
      await _saveUnits(_enemyUnitsKey, enemyUnits);
      
      // 保存敵人配置
      if (enemyConfig != null) {
        final configJson = jsonEncode(enemyConfig.map((e) => e.toJson()).toList());
        await prefs.setString(_enemyConfigKey, configJson);
      } else {
        await prefs.remove(_enemyConfigKey);
      }

      // 在 Web 環境下，確保數據已經寫入
      if (kIsWeb) {
        await prefs.reload();
        print('Web 環境：遊戲數據已保存到 localStorage');
      }
    } catch (e) {
      print('保存遊戲數據時出錯: $e');
      if (kIsWeb) {
        print('Web 環境：請確保瀏覽器允許使用 localStorage');
      }
    }
  }

  // 讀取遊戲數據
  static Future<Map<String, dynamic>> loadGameData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 在 Web 環境下，確保數據已經加載
      if (kIsWeb) {
        await prefs.reload();
      }
      
      return {
        'coins': prefs.getInt(_coinsKey) ?? 0,
        'winStreak': prefs.getInt(_winStreakKey) ?? 0,
        'currentLevel': prefs.getInt(_currentLevelKey) ?? 1,
        'playerUnits': await _loadUnits(_playerUnitsKey),
        'enemyUnits': await _loadUnits(_enemyUnitsKey),
        'enemyConfig': await _loadEnemyConfig(prefs),
      };
    } catch (e) {
      print('讀取遊戲數據時出錯: $e');
      if (kIsWeb) {
        print('Web 環境：無法讀取 localStorage 數據');
      }
      return {
        'coins': 0,
        'winStreak': 0,
        'currentLevel': 1,
        'playerUnits': List.generate(totalRows, (row) => List.generate(totalCols, (col) => null)),
        'enemyUnits': List.generate(totalRows, (row) => List.generate(totalCols, (col) => null)),
        'enemyConfig': null,
      };
    }
  }

  // 保存單位數據
  static Future<void> _saveUnits(String key, List<List<BattleUnit?>> units) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unitsJson = jsonEncode(units.map((row) {
        return row.map((unit) => unit?.toJson()).toList();
      }).toList());
      await prefs.setString(key, unitsJson);
      
      if (kIsWeb) {
        await prefs.reload();
      }
    } catch (e) {
      print('保存單位數據時出錯: $e');
    }
  }

  // 讀取單位數據
  static Future<List<List<BattleUnit?>>> _loadUnits(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (kIsWeb) {
        await prefs.reload();
      }
      
      final unitsJson = prefs.getString(key);
      if (unitsJson == null) {
        return List.generate(totalRows, (row) => List.generate(totalCols, (col) => null));
      }

      final List<List<dynamic>> decodedData = jsonDecode(unitsJson);
      return decodedData.map((row) {
        return row.map((unitJson) {
          if (unitJson == null) return null;
          return BattleUnit.fromJson(unitJson as Map<String, dynamic>);
        }).toList();
      }).toList();
    } catch (e) {
      print('讀取單位數據時出錯: $e');
      return List.generate(totalRows, (row) => List.generate(totalCols, (col) => null));
    }
  }

  // 讀取敵人配置
  static Future<List<EnemyConfig>?> _loadEnemyConfig(SharedPreferences prefs) async {
    try {
      if (kIsWeb) {
        await prefs.reload();
      }
      
      final configJson = prefs.getString(_enemyConfigKey);
      if (configJson == null) return null;

      final List<dynamic> decodedData = jsonDecode(configJson);
      return decodedData.map((json) => EnemyConfig.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('讀取敵人配置時出錯: $e');
      return null;
    }
  }

  // 清除所有保存的數據
  static Future<void> clearGameData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      if (kIsWeb) {
        await prefs.reload();
      }
    } catch (e) {
      print('清除遊戲數據時出錯: $e');
    }
  }
} 