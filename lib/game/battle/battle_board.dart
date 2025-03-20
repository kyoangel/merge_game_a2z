import 'package:flutter/material.dart';
import 'battle_unit.dart';
import 'bullet.dart';
import 'dart:async';

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
  
  @override
  void initState() {
    super.initState();
    _initializeBoard();
    _startAutoAttack();
  }
  
  void _initializeBoard() {
    // 初始化为一个 5x6 的空棋盘
    battleBoard = List.generate(totalRows, (row) {
      return List.generate(cols, (col) => null);
    });
    
    // 在敌方区域中间位置放置一个单位
    battleBoard[1][2] = BattleUnit(
      type: UnitType.enemy,
      position: Position(1, 2),
    );
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
    // 遍历整个棋盘
    for (var row = 0; row < totalRows; row++) {
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
            print('子弹生成: 从(${unit.position.row}, ${unit.position.col}) 射向 (${targetPos.row}, ${targetPos.col})');
          }
        }
      }
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
    // 简单实现：返回第一个找到的玩家位置
    for (var row in battleBoard) {
      for (var unit in row) {
        if (unit != null && unit.isAlive) {
          return unit.position;
        }
      }
    }
    return null;
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
        // 移除死亡单位
        if (bullet.shooter.type == UnitType.player) {
          battleBoard[bullet.position.row][bullet.position.col] = null;
        } else {
          battleBoard[bullet.position.row][bullet.position.col] = null;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: _buildBoard(
                  constraints: constraints,
                  borderColor: Colors.grey,
                ),
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
        // 打印出格子的编号
        print('点击了格子: ${index + 1}');
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

            // 更新棋盘和单位位置
            battleBoard[receivedUnit.position.row][receivedUnit.position.col] = null;
            battleBoard[newPosition.row][newPosition.col] = receivedUnit;
            receivedUnit.updatePosition(newPosition);
          });
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            margin: const EdgeInsets.all(4.0), // 增加格子間距
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
                            unit.type == UnitType.player ? 'P' : 'E',
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
                        if (!isEnemy) {  // 只允許在玩家區域操作
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
                                unit.type == UnitType.player ? 'P' : 'E',
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
    setState(() {
      // 在玩家区域（后3行）寻找空位
      for (int row = playerStartRow; row < totalRows; row++) {
        for (int col = 0; col < cols; col++) {
          if (battleBoard[row][col] == null) {
            battleBoard[row][col] = BattleUnit(
              type: UnitType.player,
              position: Position(row, col),
            );
            return;
          }
        }
      }
    });
  }

  void _startBattle() {
    setState(() {
      _isBattleStarted = true; // 设置战斗状态为开始
      _buttonsVisible = false; // 隐藏按钮
      _generateBullets(); // 开始战斗时生成子弹
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
} 