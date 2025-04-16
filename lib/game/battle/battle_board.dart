import 'package:flutter/material.dart';
import 'battle_unit.dart';
import 'bullet.dart';
import 'dart:async';
import 'dart:math';

class BattleBoard extends StatefulWidget {
  const BattleBoard({super.key});

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
  
  int coins = 0; // 金币数量
  static const int unitCost = 100; // 新增角色所需金币
  static const int victoryReward = 200; // 胜利奖励
  static const int unitKillReward = 50; // 击杀敌人奖励
  
  bool _gameOver = false;
  String? _battleResult;
  
  // 關卡系統
  int currentLevel = 1;
  int _playerMaxUnitLevel = 1; // 追蹤玩家最高單位等級
  
  // 保存玩家和敵方單位狀態
  List<List<BattleUnit?>>? _savedPlayerUnits;
  List<List<BattleUnit?>>? _savedEnemyUnits;

  int _winStreak = 0; // 追蹤連勝數
  static const int maxWinStreak = 10; // 最大連勝數
  int _maxEnemyLevel = 1; // 追蹤敵方最高等級
  int _maxEnemyCount = 3; // 追蹤敵方最大數量
  
  // 動態生成關卡配置
  LevelConfig _generateLevelConfig() {
    final random = Random();
    
    // 計算敵人數量
    final baseEnemyCount = 3;
    final winStreakBonus = (_winStreak ~/ 2);
    final newEnemyCount = min(baseEnemyCount + winStreakBonus, 10);
    _maxEnemyCount = max(_maxEnemyCount, newEnemyCount); // 確保敵人數量不會減少
    
    // 計算敵人等級
    final playerMaxLevel = _playerMaxUnitLevel;
    final winStreakLevelBonus = (_winStreak ~/ 3);
    final newEnemyLevel = playerMaxLevel + winStreakLevelBonus;
    _maxEnemyLevel = max(_maxEnemyLevel, newEnemyLevel); // 確保敵人等級不會降低
    
    final enemyLevelVariation = 2;
    
    // 計算敵人屬性加成
    final winStreakStatBonus = 1.0 + (_winStreak * 0.1);
    
    final enemies = <EnemyConfig>[];
    
    // 生成敵人位置
    final availablePositions = <Position>[];
    for (var row = 0; row < playerStartRow; row++) {
      for (var col = 0; col < cols; col++) {
        availablePositions.add(Position(row, col));
      }
    }
    availablePositions.shuffle(random);
    
    // 生成敵人
    for (var i = 0; i < _maxEnemyCount; i++) {
      if (availablePositions.isEmpty) break;
      
      final position = availablePositions.removeLast();
      final levelVariation = random.nextInt(enemyLevelVariation * 2 + 1) - enemyLevelVariation;
      final enemyLevel = max(1, _maxEnemyLevel + levelVariation);
      final enemyName = String.fromCharCode('A'.codeUnitAt(0) + enemyLevel - 1);
      
      enemies.add(EnemyConfig(
        row: position.row,
        col: position.col,
        unitName: enemyName,
        statBonus: winStreakStatBonus,
      ));
    }
    
    // 計算獎勵
    final baseReward = 200;
    final winStreakRewardBonus = _winStreak * 50;
    final reward = baseReward + winStreakRewardBonus;
    
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
    _initializeBoard();
    _startAutoAttack();
  }
  
  void _initializeBoard() {
    battleBoard = List.generate(totalRows, (row) {
      return List.generate(cols, (col) => null);
    });
    
    // 根據動態生成的關卡配置初始化敵人
    final currentConfig = _generateLevelConfig();
    for (var enemy in currentConfig.enemies) {
      battleBoard[enemy.row][enemy.col] = BattleUnit(
        type: UnitType.enemy,
        position: Position(enemy.row, enemy.col),
        unitName: enemy.unitName,
      );
    }

    coins = 1000;
  }

  void _startAutoAttack() {
    Timer.periodic(Duration(milliseconds: 16), (timer) { // 每帧更新
      if (_isBattleStarted) {
        setState(() {
          _generateBullets(); // 定期生成子弹
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
              print('玩家子弹生成: 从(${unit.position.row}, ${unit.position.col}) 射向 (${targetPos.row}, ${targetPos.col})');
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
              print('敌人子弹生成: 从(${unit.position.row}, ${unit.position.col}) 射向 (${targetPos.row}, ${targetPos.col})');
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
    return ((a.row - b.row) * (a.row - b.row) + (a.col - b.col) * (a.col - b.col)).toDouble();
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
    print('子弹碰撞: shooter=${bullet.shooter.type}, position=(${bullet.position.row}, ${bullet.position.col}), damage=${bullet.damage}');
    
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
                        '連勝: $_winStreak',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        '敵人: ${_maxEnemyCount}x${String.fromCharCode('A'.codeUnitAt(0) + _maxEnemyLevel - 1)}',
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
                        Center(
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
                                if (_battleResult == "胜利！")
                                  ElevatedButton(
                                    onPressed: _nextLevel,
                                    child: const Text('挑戰下一關'),
                                  )
                                else
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _gameOver = false;
                                        _battleResult = null;
                                        _buttonsVisible = true;
                                        _restoreBattleState();
                                      });
                                    },
                                    child: const Text('重新挑戰'),
                                  ),
                              ],
                            ),
                          ),
                        ),
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
                    return _buildCell(unit, isEnemyArea, index);
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
                    color: bullet.shooter.type == UnitType.player ? Colors.blue : Colors.red,
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

  Widget _buildCell(BattleUnit? unit, bool isEnemy, int index) {
    return GestureDetector(
      onTap: () {
        if (!isEnemy) {  // 只允許在玩家區域操作
          _handleCellTap(unit);
        }
      },
      child: DragTarget<BattleUnit>(
        onWillAccept: (receivedUnit) {
          // 只允许在玩家区域拖放
          return !isEnemy;
        },
        onAccept: (receivedUnit) {
          setState(() {
            // 计算目标位置
            final row = index ~/ cols;
            final col = index % cols;
            final newPosition = Position(row, col);
            
            // 检查是否可以合成
            final targetUnit = battleBoard[newPosition.row][newPosition.col];
            if (targetUnit != null && 
                targetUnit.type == UnitType.player && 
                targetUnit.unitName == receivedUnit.unitName) {
              // 合成
              targetUnit.merge(receivedUnit);
              battleBoard[receivedUnit.position.row][receivedUnit.position.col] = null;
            } else {
              // 普通移动
              battleBoard[receivedUnit.position.row][receivedUnit.position.col] = null;
              battleBoard[newPosition.row][newPosition.col] = receivedUnit;
              receivedUnit.updatePosition(newPosition);
            }
          });
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            margin: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              color: _getCellColor(unit, isEnemy),
            ),
            child: unit != null
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    childWhenDragging: Container(),
                    child: GestureDetector(
                      onTap: () {
                        if (!isEnemy) {
                          _handleCellTap(unit);
                        }
                      },
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                unit.type == UnitType.player ? unit.unitName : 'E',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${unit.health}',
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
          );
        },
      ),
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

  void _handleCellTap(BattleUnit? unit) {
    setState(() {
      if (unit != null && unit.type == UnitType.player) {
        print('角色被点击: 类型=${unit.type}, 位置=(${unit.position.row}, ${unit.position.col})');
        
        selectedUnit = selectedUnit == unit ? null : unit;

        Position? target = _findNearestEnemy(unit.position);
        if (target != null) {
          unit.attack(target);
          bullets.add(Bullet(
            shooter: unit,
            position: unit.position,
            damage: unit.attackPower,
            targetPosition: target,
          ));
        }
      } else if (selectedUnit != null) {
        // 移动选中的玩家角色到新的位置
        final newPosition = Position(
          battleBoard.indexWhere((row) => row.contains(unit)),
          battleBoard.firstWhere((row) => row.contains(unit)).indexOf(unit),
        );
        battleBoard[selectedUnit!.position.row][selectedUnit!.position.col] = null;
        battleBoard[newPosition.row][newPosition.col] = selectedUnit;
        selectedUnit!.updatePosition(newPosition);
        selectedUnit = null;
      }
    });
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
        _battleResult = "胜利！";
        coins += victoryReward;
        _isBattleStarted = false;
        _updatePlayerMaxUnitLevel();
        _winStreak++;
      });
    } else if (!hasPlayer) {
      setState(() {
        _gameOver = true;
        _battleResult = "失败！";
        _isBattleStarted = false;
        _restoreBattleState();
        _winStreak = 0;
      });
    }
  }
}

// 關卡配置類
class LevelConfig {
  final int level;
  final List<EnemyConfig> enemies;
  final int reward;

  LevelConfig({
    required this.level,
    required this.enemies,
    required this.reward,
  });
}

// 敵人配置類
class EnemyConfig {
  final int row;
  final int col;
  final String unitName;
  final double statBonus; // 屬性加成

  EnemyConfig({
    required this.row,
    required this.col,
    required this.unitName,
    this.statBonus = 1.0,
  });
} 