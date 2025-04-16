import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'battle/battle_unit.dart';
import 'battle/level_config.dart';
import 'game_data_manager.dart';

class GameManager extends ChangeNotifier {
  int _coins = 0;
  int _winStreak = 0;
  int _currentLevel = 1;
  bool isRunning = false;
  bool isBattling = false;
  
  // 保存玩家單位狀態
  List<List<BattleUnit?>>? _savedPlayerUnits;
  List<List<BattleUnit?>>? _savedEnemyUnits;
  List<EnemyConfig>? _currentEnemyConfig;

  GameManager() {
    _loadSavedData();
  }

  // Getters
  int get coins => _coins;
  int get winStreak => _winStreak;
  int get currentLevel => _currentLevel;
  List<List<BattleUnit?>>? get savedPlayerUnits => _savedPlayerUnits;
  List<List<BattleUnit?>>? get savedEnemyUnits => _savedEnemyUnits;
  List<EnemyConfig>? get currentEnemyConfig => _currentEnemyConfig;
  set currentEnemyConfig(List<EnemyConfig>? config) {
    _currentEnemyConfig = config;
    _saveGameData();
    notifyListeners();
  }

  Future<void> _loadSavedData() async {
    final savedData = await GameDataManager.loadGameData();
    _coins = savedData['coins'];
    _winStreak = savedData['winStreak'];
    _currentLevel = savedData['currentLevel'];
    _savedPlayerUnits = savedData['playerUnits'];
    _savedEnemyUnits = savedData['enemyUnits'];
    _currentEnemyConfig = savedData['enemyConfig'];
    notifyListeners();
  }

  void addCoins(int amount) {
    _coins += amount;
    _saveGameData();
    notifyListeners();
  }

  void updateWinStreak(int streak) {
    _winStreak = streak;
    _saveGameData();
    notifyListeners();
  }

  void updateLevel(int level) {
    _currentLevel = level;
    _saveGameData();
    notifyListeners();
  }

  // 保存戰鬥狀態
  void saveBattleState({
    required List<List<BattleUnit?>> playerUnits,
    required List<List<BattleUnit?>> enemyUnits,
    List<EnemyConfig>? enemyConfig,
  }) {
    _savedPlayerUnits = playerUnits;
    _savedEnemyUnits = enemyUnits;
    _currentEnemyConfig = enemyConfig;
    _saveGameData();
    notifyListeners();
  }

  // 清除保存的戰鬥狀態
  void clearBattleState() {
    _savedPlayerUnits = null;
    _savedEnemyUnits = null;
    _currentEnemyConfig = null;
    _saveGameData();
    notifyListeners();
  }

  Future<void> _saveGameData() async {
    await GameDataManager.saveGameData(
      coins: _coins,
      winStreak: _winStreak,
      currentLevel: _currentLevel,
      playerUnits: _savedPlayerUnits ?? List.generate(6, (row) => List.generate(5, (col) => null)),
      enemyUnits: _savedEnemyUnits ?? List.generate(6, (row) => List.generate(5, (col) => null)),
      enemyConfig: _currentEnemyConfig,
    );
  }

  void startRunning() {
    isRunning = true;
    isBattling = false;
    notifyListeners();
  }

  void startBattle() {
    isRunning = false;
    isBattling = true;
    notifyListeners();
  }

  void endGame() {
    isRunning = false;
    isBattling = false;
    notifyListeners();
  }
} 