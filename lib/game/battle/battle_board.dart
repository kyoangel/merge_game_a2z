import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'battle_unit.dart';
import 'bullet.dart';
import 'dart:async';
import 'dart:math';
import '../../screens/running_screen.dart';
import '../game_manager.dart';
import 'level_config.dart';

class BattleBoard extends StatefulWidget {
  final int coins;
  final int winStreak;
  final int currentLevel;

  const BattleBoard({
    super.key,
    required this.coins,
    required this.winStreak,
    required this.currentLevel,
  });

  @override
  State<BattleBoard> createState() => _BattleBoardState();
}

class _BattleBoardState extends State<BattleBoard> {
  static const int totalRows = 6; // 总行数：6行
  static const int cols = 5;
  static const int playerStartRow = 3; // 玩家区域从第3行开始

  // 使用单个棋盘来表示整个战场
  List<List<BattleUnit?>> battleBoard = [];

  BattleUnit? selectedUnit;
  List<Bullet> bullets = [];
  bool _buttonsVisible = true;
  bool _isBattleStarted = false;

  // 添加计时器变量
  DateTime? _lastPlayerBulletTime;
  DateTime? _lastEnemyBulletTime;
  static const bulletCooldown = Duration(seconds: 1); // 子弹冷却时间

  late int coins;
  late int winStreak;
  late int currentLevel;
  static const int unitCost = 100; // 新增角色所需金币
  static const int victoryReward = 200; // 胜利奖励
  static const int unitKillReward = 50; // 击杀敌人奖励

  bool _gameOver = false;
  String? _battleResult;

  // 關卡系統
  int _playerMaxUnitLevel = 1; // 追蹤玩家最高單位等級

  // 保存玩家和敵方單位狀態
  List<List<BattleUnit?>>? _savedPlayerUnits;
  List<List<BattleUnit?>>? _savedEnemyUnits;

  int _maxEnemyLevel = 1; // 追蹤敵方最高等級
  int _maxEnemyCount = 3; // 追蹤敵方最大數量

  // 添加定時器引用
  Timer? _autoAttackTimer;

  // 動態生成關卡配置
  LevelConfig _generateLevelConfig() {
    final random = Random();

    // 計算敵人數量
    final baseEnemyCount = 3;
    final winStreakBonus = (winStreak ~/ 2);
    final enemyCount = max(baseEnemyCount + winStreakBonus, 3); // 確保至少有3個敵人
    print(
        '計算敵人數量: base=$baseEnemyCount, bonus=$winStreakBonus, total=$enemyCount');

    // 計算敵人等級
    final baseEnemyLevel = max(1, currentLevel ~/ 2);
    final winStreakLevelBonus = (winStreak ~/ 3);
    final maxEnemyLevel =
        min(baseEnemyLevel + winStreakLevelBonus, 26); // 限制最高等級為Z
    print(
        '計算敵人等級: base=$baseEnemyLevel, bonus=$winStreakLevelBonus, max=$maxEnemyLevel');

    // 生成敵人位置
    final availablePositions = <Position>[];
    for (var row = 0; row < playerStartRow; row++) {
      for (var col = 0; col < cols; col++) {
        availablePositions.add(Position(row, col));
      }
    }
    availablePositions.shuffle(random);

    final enemies = <EnemyConfig>[];
    print('可用位置數量: ${availablePositions.length}');

    // 生成敵人
    for (var i = 0; i < min(enemyCount, availablePositions.length); i++) {
      final position = availablePositions[i];
      final enemyLevel = random.nextInt(maxEnemyLevel) + 1;
      final enemyName = String.fromCharCode('A'.codeUnitAt(0) + enemyLevel - 1);

      print(
          '生成敵人 $i: level=$enemyLevel, name=$enemyName, position=(${position.row}, ${position.col})');

      enemies.add(EnemyConfig(
        row: position.row,
        col: position.col,
        unitName: enemyName,
        statBonus: 1.0 + (winStreak * 0.1), // 根據連勝增加屬性加成
      ));
    }

    // 計算獎勵
    final baseReward = 200;
    final winStreakRewardBonus = winStreak * 50;
    final reward = baseReward + winStreakRewardBonus;

    print('關卡配置完成: 敵人數量=${enemies.length}, 獎勵=$reward');

    return LevelConfig(
      level: currentLevel,
      enemies: enemies,
      reward: reward,
    );
  }

  // 測試模式
  bool isTestMode = false;

  @override
  void initState() {
    super.initState();
    coins = widget.coins;
    winStreak = widget.winStreak;
    currentLevel = widget.currentLevel;
    _initializeBoard();
    _startAutoAttack();
  }

  @override
  void dispose() {
    // 清理定時器
    _autoAttackTimer?.cancel();
    super.dispose();
  }

  void _initializeBoard() {
    final gameManager = context.read<GameManager>();

    // 初始化空的棋盤
    battleBoard = List.generate(totalRows, (row) {
      return List.generate(cols, (col) => null);
    });

    // 檢查是否有有效的保存狀態
    bool hasValidSavedState = false;
    if (gameManager.savedPlayerUnits != null) {
      // 檢查是否有任何玩家單位
      for (var row = playerStartRow; row < totalRows; row++) {
        for (var col = 0; col < cols; col++) {
          if (gameManager.savedPlayerUnits![row][col] != null) {
            hasValidSavedState = true;
            break;
          }
        }
        if (hasValidSavedState) break;
      }
    }

    if (hasValidSavedState) {
      print('恢復保存的玩家單位');

      // 恢復玩家單位
      for (var row = playerStartRow; row < totalRows; row++) {
        for (var col = 0; col < cols; col++) {
          final unit = gameManager.savedPlayerUnits![row][col];
          if (unit != null) {
            // 創建新的單位並補滿血量
            final newUnit = BattleUnit(
              type: UnitType.player,
              position: Position(row, col),
              unitName: unit.unitName,
              level: unit.level,
            );
            battleBoard[row][col] = newUnit;
          }
        }
      }
    }

    // 檢查是否有保存的敵人配置
    if (gameManager.currentEnemyConfig != null) {
      print('使用保存的敵人配置');

      // 使用保存的敵人配置
      for (var enemy in gameManager.currentEnemyConfig!) {
        print(
            '生成敵人: row=${enemy.row}, col=${enemy.col}, name=${enemy.unitName}');
        final unit = BattleUnit(
          type: UnitType.enemy,
          position: Position(enemy.row, enemy.col),
          unitName: enemy.unitName,
        );
        // 應用屬性加成
        unit.health = (unit.health * enemy.statBonus).round();
        unit.attackPower = (unit.attackPower * enemy.statBonus).round();
        battleBoard[enemy.row][enemy.col] = unit;
      }
    } else {
      print('生成新的敵人配置');

      // 生成新的敵人配置
      final currentConfig = _generateLevelConfig();
      print(
          '關卡配置: Level=${currentConfig.level}, 敵人數量=${currentConfig.enemies.length}');

      // 保存新生成的敵人配置
      gameManager.saveBattleState(
        playerUnits: gameManager.savedPlayerUnits ??
            List.generate(
                totalRows, (row) => List.generate(cols, (col) => null)),
        enemyUnits: gameManager.savedEnemyUnits ??
            List.generate(
                totalRows, (row) => List.generate(cols, (col) => null)),
        enemyConfig: currentConfig.enemies,
      );

      // 生成敵人
      for (var enemy in currentConfig.enemies) {
        if (enemy.row >= playerStartRow) continue;

        print(
            '生成敵人: row=${enemy.row}, col=${enemy.col}, name=${enemy.unitName}');
        final unit = BattleUnit(
          type: UnitType.enemy,
          position: Position(enemy.row, enemy.col),
          unitName: enemy.unitName,
        );
        // 應用屬性加成
        unit.health = (unit.health * enemy.statBonus).round();
        unit.attackPower = (unit.attackPower * enemy.statBonus).round();
        battleBoard[enemy.row][enemy.col] = unit;
      }
    }

    // 打印當前棋盤狀態
    _printBoardState();
  }

  // 新增：打印棋盤狀態的輔助方法
  void _printBoardState() {
    print('當前棋盤狀態:');
    for (var row = 0; row < totalRows; row++) {
      String rowStr = '';
      for (var col = 0; col < cols; col++) {
        final unit = battleBoard[row][col];
        if (unit == null) {
          rowStr += '- ';
        } else {
          rowStr += '${unit.type == UnitType.player ? "P" : "E"} ';
        }
      }
      print('$row: $rowStr');
    }
  }

  void _startAutoAttack() {
    // 取消現有的定時器（如果有的話）
    _autoAttackTimer?.cancel();

    // 創建新的定時器
    _autoAttackTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      if (_isBattleStarted && mounted) {
        // 添加 mounted 檢查
        setState(() {
          _generateBullets();
          _moveBullets();
        });
      }
    });
  }

  void _generateBullets() {
    final now = DateTime.now();

    // 玩家子弹生成
    if (_lastPlayerBulletTime == null ||
        now.difference(_lastPlayerBulletTime!) >= bulletCooldown) {
      // 遍历玩家单位
      for (var row = playerStartRow; row < totalRows; row++) {
        for (var col = 0; col < cols; col++) {
          final unit = battleBoard[row][col];
          if (unit != null && unit.isAlive && unit.type == UnitType.player) {
            Position? targetPos = _findNearestEnemy(unit.position);
            if (targetPos != null) {
              bullets.add(Bullet(
                shooter: unit,
                position: unit.position,
                damage: unit.attackPower,
                targetPosition: targetPos,
              ));
              print(
                  '玩家子弹生成: 从(${unit.position.row}, ${unit.position.col}) 射向 (${targetPos.row}, ${targetPos.col})');
            }
          }
        }
      }
      _lastPlayerBulletTime = now;
    }

    // 敌人子弹生成
    if (_lastEnemyBulletTime == null ||
        now.difference(_lastEnemyBulletTime!) >= bulletCooldown) {
      // 遍历敌方单位
      for (var row = 0; row < playerStartRow; row++) {
        for (var col = 0; col < cols; col++) {
          final unit = battleBoard[row][col];
          if (unit != null && unit.isAlive && unit.type == UnitType.enemy) {
            Position? targetPos = _findNearestPlayer(unit.position);
            if (targetPos != null) {
              bullets.add(Bullet(
                shooter: unit,
                position: unit.position,
                damage: unit.attackPower,
                targetPosition: targetPos,
              ));
              print(
                  '敌人子弹生成: 从(${unit.position.row}, ${unit.position.col}) 射向 (${targetPos.row}, ${targetPos.col})');
            }
          }
        }
      }
      _lastEnemyBulletTime = now;
    }
  }

  void _moveBullets() {
    bullets.removeWhere((bullet) {
      // 移动子弹
      bullet.moveTowards(bullet.targetPosition);

      // 检查是否到达目标
      if (bullet.hasReachedTarget()) {
        _applyDamage(bullet);
        return true; // 移除子弹
      }
      return false;
    });
  }

  Position? _findNearestEnemy(Position from) {
    Position? nearest;
    double minDistance = double.infinity;

    // 只在敌方区域（前3行）寻找目标
    for (var row = 0; row < playerStartRow; row++) {
      for (var col = 0; col < cols; col++) {
        final unit = battleBoard[row][col];
        if (unit != null && unit.isAlive && unit.type == UnitType.enemy) {
          double distance = _calculateDistance(from, unit.position);
          if (distance < minDistance) {
            minDistance = distance;
            nearest = unit.position;
          }
        }
      }
    }
    return nearest;
  }

  double _calculateDistance(Position a, Position b) {
    return ((a.row - b.row) * (a.row - b.row) +
            (a.col - b.col) * (a.col - b.col))
        .toDouble();
  }

  Position? _findNearestPlayer(Position from) {
    Position? nearest;
    double minDistance = double.infinity;

    // 在玩家区域（后3行）寻找目标
    for (var row = playerStartRow; row < totalRows; row++) {
      for (var col = 0; col < cols; col++) {
        final unit = battleBoard[row][col];
        if (unit != null && unit.isAlive && unit.type == UnitType.player) {
          double distance = _calculateDistance(from, unit.position);
          if (distance < minDistance) {
            minDistance = distance;
            nearest = unit.position;
          }
        }
      }
    }
    return nearest;
  }

  void _applyDamage(Bullet bullet) {
    print(
        '子弹碰撞: shooter=${bullet.shooter.type}, position=(${bullet.position.row}, ${bullet.position.col}), damage=${bullet.damage}');

    // 找到目标单位
    BattleUnit? targetUnit;
    if (bullet.shooter.type == UnitType.player) {
      targetUnit = battleBoard[bullet.position.row][bullet.position.col];
    } else {
      targetUnit = battleBoard[bullet.position.row][bullet.position.col];
    }

    // 扣除HP
    if (targetUnit != null) {
      targetUnit.takeDamage(bullet.damage);
      if (!targetUnit.isAlive) {
        // 击杀奖励
        if (bullet.shooter.type == UnitType.player) {
          setState(() {
            coins += unitKillReward;
          });
        }

        // 移除死亡单位
        battleBoard[bullet.position.row][bullet.position.col] = null;

        // 检查战斗结果
        _checkBattleResult();
      }
    }
  }

  // 更新玩家最高單位等級
  void _updatePlayerMaxUnitLevel() {
    int maxLevel = 1;
    for (var row = playerStartRow; row < totalRows; row++) {
      for (var col = 0; col < cols; col++) {
        final unit = battleBoard[row][col];
        if (unit != null && unit.type == UnitType.player) {
          final level = unit.unitName.codeUnitAt(0) - 'A'.codeUnitAt(0) + 1;
          maxLevel = max(maxLevel, level);
        }
      }
    }
    _playerMaxUnitLevel = maxLevel;
  }

  // 保存玩家和敵方單位狀態
  void _saveBattleState() {
    // 保存玩家單位
    _savedPlayerUnits = List.generate(totalRows, (row) {
      return List.generate(cols, (col) {
        final unit = battleBoard[row][col];
        if (unit != null && unit.type == UnitType.player) {
          return BattleUnit(
            type: UnitType.player,
            position: Position(row, col),
            unitName: unit.unitName,
            level: unit.level,
          );
        }
        return null;
      });
    });

    // 保存敵方單位
    _savedEnemyUnits = List.generate(totalRows, (row) {
      return List.generate(cols, (col) {
        final unit = battleBoard[row][col];
        if (unit != null && unit.type == UnitType.enemy) {
          return BattleUnit(
            type: UnitType.enemy,
            position: Position(row, col),
            unitName: unit.unitName,
            level: unit.level,
          );
        }
        return null;
      });
    });
  }

  void _restoreBattleState() {
    if (_savedPlayerUnits == null || _savedEnemyUnits == null) return;

    // 清空棋盤
    battleBoard = List.generate(totalRows, (row) {
      return List.generate(cols, (col) => null);
    });

    // 恢復玩家單位
    for (var row = 0; row < totalRows; row++) {
      for (var col = 0; col < cols; col++) {
        final unit = _savedPlayerUnits![row][col];
        if (unit != null) {
          battleBoard[row][col] = unit;
        }
      }
    }

    // 恢復敵方單位
    for (var row = 0; row < totalRows; row++) {
      for (var col = 0; col < cols; col++) {
        final unit = _savedEnemyUnits![row][col];
        if (unit != null) {
          battleBoard[row][col] = unit;
        }
      }
    }
  }

  // 測試功能按鈕
  Widget _buildTestPanel() {
    if (!isTestMode) return const SizedBox.shrink();

    return Positioned(
      top: 20,
      left: 20,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('測試模式 - 關卡 $currentLevel',
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _previousLevel,
                  child: const Text('上一關'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _nextLevel,
                  child: const Text('下一關'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _toggleTestMode,
              child: const Text('關閉測試模式'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleTestMode() {
    setState(() {
      isTestMode = !isTestMode;
    });
  }

  void _previousLevel() {
    if (currentLevel > 1) {
      setState(() {
        currentLevel--;
        _initializeBoard();
      });
    }
  }

  void _nextLevel() {
    setState(() {
      _gameOver = false;
      _battleResult = null;
      _buttonsVisible = true;
      bullets.clear(); // 清除所有子彈

      // 清空棋盤
      battleBoard = List.generate(totalRows, (row) {
        return List.generate(cols, (col) => null);
      });

      // 恢復玩家單位
      if (_savedPlayerUnits != null) {
        for (var row = 0; row < totalRows; row++) {
          for (var col = 0; col < cols; col++) {
            final unit = _savedPlayerUnits![row][col];
            if (unit != null) {
              battleBoard[row][col] = unit;
            }
          }
        }
      }

      // 生成新的敵人
      final currentConfig = _generateLevelConfig();
      for (var enemy in currentConfig.enemies) {
        final unit = BattleUnit(
          type: UnitType.enemy,
          position: Position(enemy.row, enemy.col),
          unitName: enemy.unitName,
        );
        // 應用屬性加成
        unit.health = (unit.health * enemy.statBonus).round();
        unit.attackPower = (unit.attackPower * enemy.statBonus).round();
        battleBoard[enemy.row][enemy.col] = unit;
      }

      currentLevel++;
    });
  }

  void _handleRetryButtonClick() {
    setState(() {
      _gameOver = false;
      _battleResult = null;
      _buttonsVisible = true;
      _restoreBattleState();
      bullets.clear(); // 清除所有子彈
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 显示金幣、連勝數和敵人信息
                Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.monetization_on, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '金幣: $coins',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.star, color: Colors.yellow),
                      const SizedBox(width: 4),
                      Text(
                        '連勝: $winStreak',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        '關卡: $currentLevel',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildBoard(
                          constraints: constraints,
                          borderColor: Colors.grey,
                        ),
                      ),

                      // 显示战斗结果
                      if (_gameOver && _battleResult != null)
                        _buildBattleResultDialog(),
                    ],
                  ),
                ),

                // 按钮布局
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Visibility(
                        visible: _buttonsVisible,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: ElevatedButton(
                          onPressed: _addPlayerUnit,
                          child: const Text('新增玩家角色'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Visibility(
                        visible: _buttonsVisible,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: ElevatedButton(
                          onPressed: _startBattle,
                          child: const Text('開戰'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        _buildTestPanel(),
      ],
    );
  }

  Widget _buildBoard({
    required BoxConstraints constraints,
    required Color borderColor,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / cols;
        final cellHeight = constraints.maxHeight / totalRows;

        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: borderColor, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: AspectRatio(
                aspectRatio: cols / totalRows,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 2.0,
                    mainAxisSpacing: 2.0,
                  ),
                  itemCount: totalRows * cols,
                  itemBuilder: (context, index) {
                    final row = index ~/ cols;
                    final col = index % cols;
                    final unit = battleBoard[row][col];
                    final isEnemyArea = row < playerStartRow;
                    return _buildCell(row, col);
                  },
                ),
              ),
            ),
            ...bullets.map((bullet) {
              final bulletLeft = bullet.x * cellWidth;
              final bulletTop = bullet.y * cellHeight;

              return Positioned(
                left: bulletLeft,
                top: bulletTop,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bullet.shooter.type == UnitType.player
                        ? Colors.blue
                        : Colors.red,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildCell(int row, int col) {
    final unit = battleBoard[row][col];
    final isSelected = selectedUnit != null &&
        selectedUnit!.position.row == row &&
        selectedUnit!.position.col == col;

    return DragTarget<BattleUnit>(
      onAcceptWithDetails: (details) {
        final receivedUnit = details.data;
        final targetUnit = battleBoard[row][col];

        print(
            'DragTarget onAccept: Received unit level: ${receivedUnit.level}, Target unit level: ${targetUnit?.level}');

        if (targetUnit != null && targetUnit.type == UnitType.player) {
          // 目標位置有單位
          if (targetUnit.level == receivedUnit.level &&
              !identical(targetUnit, receivedUnit)) {
            // 修改合成條件，只判斷 level，並防止與自身合成
            // ✅ 合成條件：等級相同且不是同一個單位
            print('Merge condition met. Merging...');
            // 合成發生在目標單位上
            targetUnit.merge(receivedUnit);
            // 移除被拖曳的單位
            battleBoard[receivedUnit.position.row][receivedUnit.position.col] =
                null;
            print(
                'Merge successful via DragTarget. New unit level: ${targetUnit.level}');
          } else {
            // ❌ 等級不同或嘗試與自身合成，交換位置
            print('Merge condition not met or same unit. Swapping positions.');
            final receivedUnitOldPosition = receivedUnit.position;
            final targetUnitOldPosition = targetUnit.position;

            // 更新 board
            battleBoard[row][col] = receivedUnit;
            battleBoard[receivedUnitOldPosition.row]
                [receivedUnitOldPosition.col] = targetUnit;

            // 更新單位的位置屬性
            receivedUnit.updatePosition(Position(row, col));
            targetUnit.updatePosition(receivedUnitOldPosition);
            print('Swap successful.');
          }
        } else {
          // 目標位置沒有單位，直接移動
          print('Target cell is empty. Moving unit.');
          final receivedUnitOldPosition = receivedUnit.position;

          // 更新 board
          battleBoard[row][col] = receivedUnit;
          battleBoard[receivedUnitOldPosition.row]
              [receivedUnitOldPosition.col] = null;

          // 更新單位的位置屬性
          receivedUnit.updatePosition(Position(row, col));
          print('Move successful.');
        }

        // 更新 UI
        setState(() {
          selectedUnit = null; // 拖曳完成後取消選取
        });
      },
      builder: (context, candidateData, rejectedData) {
        final cellContent = Container(
          margin: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            color: _getCellColor(unit, row < playerStartRow),
          ),
          child: unit != null
              ? GestureDetector(
                  onTap: () {
                    if (row < playerStartRow) {
                      _handleCellTap(row, col);
                    }
                  },
                  child: Center(
                    // 用 Center + Column 取代 FittedBox 會比較穩定
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          unit.type == UnitType.player ? unit.unitName : 'E',
                          style: const TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 28),
                        ),
                        Text(
                          '${unit.health}',
                          style: const TextStyle(fontSize: 24),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        );

        return unit != null
            ? Draggable<BattleUnit>(
                data: unit,
                feedback: Material(
                  child: Container(
                    width: 50,
                    height: 50,
                    color: Colors.blue.withOpacity(0.5),
                    child: Center(
                      child: Text(
                        unit.type == UnitType.player ? unit.unitName : 'E',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                childWhenDragging: Container(), // 空白格
                child: cellContent,
              )
            : cellContent;
      },
    );
  }

  void _addPlayerUnit() {
    if (coins < unitCost) {
      // 显示金币不足提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('金币不足！需要 $unitCost 金币')),
      );
      return;
    }

    setState(() {
      // 在玩家区域（后3行）寻找空位
      for (int row = playerStartRow; row < totalRows; row++) {
        for (int col = 0; col < cols; col++) {
          if (battleBoard[row][col] == null) {
            battleBoard[row][col] = BattleUnit(
              type: UnitType.player,
              position: Position(row, col),
            );
            coins -= unitCost; // 扣除金币
            return;
          }
        }
      }
    });
  }

  void _startBattle() {
    setState(() {
      _saveBattleState(); // 開始戰鬥前保存戰鬥狀態
      _isBattleStarted = true;
      _buttonsVisible = false;
      _generateBullets();
    });
  }

  void _handleCellTap(int row, int col) {
    final unit = battleBoard[row][col];

    if (selectedUnit == null && unit != null && unit.type == UnitType.player) {
      // 第一次點擊玩家角色，選取
      setState(() {
        selectedUnit = unit;
      });
    } else if (selectedUnit != null) {
      // 如果已經選取了一個單位
      if (unit == null) {
        // 點擊空單元格：移動選取的玩家角色到新的位置
        final oldPosition = selectedUnit!.position;
        battleBoard[oldPosition.row][oldPosition.col] = null;
        battleBoard[row][col] = selectedUnit;
        selectedUnit!.updatePosition(Position(row, col)); // 使用傳入的 row, col
        setState(() {
          selectedUnit = null;
        });
      } else if (unit.type == UnitType.player) {
        // 點擊另一個玩家角色
        if (selectedUnit!.level == unit.level &&
            !identical(selectedUnit, unit)) {
          // 修改合成條件，並防止與自身合成
          // 合成
          print(
              'Attempting to merge units at (${selectedUnit!.position.row}, ${selectedUnit!.position.col}) and (${row}, ${col})');
          // 合成發生在目標單位上
          unit.merge(selectedUnit!);
          // 移除被合併的單位
          battleBoard[selectedUnit!.position.row][selectedUnit!.position.col] =
              null;
          print('Merge successful. New unit level: ${unit.level}');
          // 更新 UI
          setState(() {
            selectedUnit = null;
            // 不需要手動更新 targetUnit 在 grid 中的位置，因為 merge 操作修改了 unit 物件本身，grid 引用的是同一個物件
          });
        } else {
          // 等級不同或點擊的是同一個單位，重新選取
          setState(() {
            selectedUnit = unit;
          });
        }
      } else {
        // 點擊敵人或其他類型的單位，取消選取
        setState(() {
          selectedUnit = null;
        });
      }
    }
  }

  Color _getCellColor(BattleUnit? unit, bool isEnemy) {
    if (unit == null) {
      return isEnemy ? Colors.red[50]! : Colors.blue[50]!;
    }
    return unit.type == UnitType.player ? Colors.blue[100]! : Colors.red[100]!;
  }

  void _checkBattleResult() {
    bool hasEnemy = false;
    bool hasPlayer = false;

    for (var row = 0; row < totalRows; row++) {
      for (var col = 0; col < cols; col++) {
        final unit = battleBoard[row][col];
        if (unit != null && unit.isAlive) {
          if (unit.type == UnitType.enemy) {
            hasEnemy = true;
          } else {
            hasPlayer = true;
          }
        }
      }
    }

    if (!hasEnemy) {
      setState(() {
        _gameOver = true;
        _battleResult = "勝利！";
        coins += victoryReward;
        _isBattleStarted = false;
        _updatePlayerMaxUnitLevel();
        winStreak++;
        bullets.clear();
        currentLevel++;

        // 立即更新 GameManager 中的金幣和連勝數
        final gameManager = context.read<GameManager>();
        gameManager.addCoins(victoryReward);
        gameManager.updateWinStreak(winStreak);
        gameManager.updateLevel(currentLevel);

        // 清除當前的敵人配置，這樣下一關會生成新的敵人
        gameManager.currentEnemyConfig = null;
      });
    } else if (!hasPlayer) {
      setState(() {
        _gameOver = true;
        _battleResult = "失敗！";
        _isBattleStarted = false;
        _restoreBattleState();
        winStreak = 0;
        bullets.clear();

        // 失敗時也要更新 GameManager 中的連勝數
        final gameManager = context.read<GameManager>();
        gameManager.updateWinStreak(0);
      });
    }
  }

  // 修改戰鬥結束按鈕處理
  Widget _buildBattleResultDialog() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _battleResult!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final gameManager = context.read<GameManager>();

                if (_battleResult == "勝利！") {
                  // 保存當前玩家單位狀態（只保存玩家區域的單位）
                  List<List<BattleUnit?>> playerUnits = List.generate(
                    totalRows,
                    (row) => List.generate(cols, (col) => null),
                  );

                  for (var row = playerStartRow; row < totalRows; row++) {
                    for (var col = 0; col < cols; col++) {
                      final unit = battleBoard[row][col];
                      if (unit != null && unit.type == UnitType.player) {
                        // 創建新的單位並恢復滿血
                        playerUnits[row][col] = BattleUnit(
                          type: UnitType.player,
                          position: Position(row, col),
                          unitName: unit.unitName,
                          level: unit.level,
                        );
                      }
                    }
                  }

                  // 保存玩家單位狀態
                  gameManager.saveBattleState(
                    playerUnits: playerUnits,
                    enemyUnits: List.generate(
                      totalRows,
                      (row) => List.generate(cols, (col) => null),
                    ),
                  );
                }

                // 返回跑酷遊戲
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const RunningScreen(),
                  ),
                );
              },
              child: Text(_battleResult == "勝利！" ? '挑戰下一關' : '重新挑戰'),
            ),
          ],
        ),
      ),
    );
  }
}
