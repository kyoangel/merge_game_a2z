import 'package:flutter/material.dart';
import 'battle_unit.dart';

class BattleBoard extends StatefulWidget {
  const BattleBoard({super.key});

  @override
  State<BattleBoard> createState() => _BattleBoardState();
}

class _BattleBoardState extends State<BattleBoard> {
  static const int rows = 3;
  static const int cols = 5;
  
  // 上方敵人的棋盤
  List<List<BattleUnit?>> enemyBoard = [];
  // 下方玩家的棋盤
  List<List<BattleUnit?>> playerBoard = [];
  
  BattleUnit? selectedUnit; // 用于跟踪选中的玩家角色
  
  @override
  void initState() {
    super.initState();
    _initializeBoards();
  }
  
  void _initializeBoards() {
    // 初始化為空棋盤
    enemyBoard = List.generate(rows, (row) {
      return List.generate(cols, (col) => null);
    });
    
    playerBoard = List.generate(rows, (row) {
      return List.generate(cols, (col) => null);
    });
    
    // 示例：在中間位置放置一個單位
    enemyBoard[1][2] = BattleUnit(
      type: UnitType.enemy,
      position: Position(1, 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 計算合適的棋盤大小
        final availableHeight = constraints.maxHeight;
        final boardHeight = (availableHeight - 40) / 2; // 40是分隔線和間距的高度
        
        return SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: availableHeight,
              maxWidth: constraints.maxWidth,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: SizedBox(
                    height: boardHeight,
                    child: _buildBoard(
                      board: enemyBoard,
                      isEnemy: true,
                      borderColor: Colors.red,
                    ),
                  ),
                ),
                
                // 分隔線
                Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.yellow.shade700, Colors.black, Colors.yellow.shade700],
                    ),
                  ),
                ),
                
                Expanded(
                  child: SizedBox(
                    height: boardHeight,
                    child: _buildBoard(
                      board: playerBoard,
                      isEnemy: false,
                      borderColor: Colors.blue,
                    ),
                  ),
                ),
                
                // 新增玩家角色按钮
                ElevatedButton(
                  onPressed: _addPlayerUnit,
                  child: const Text('新增玩家角色'),
                ),
                
                // 开战按钮
                ElevatedButton(
                  onPressed: _startBattle,
                  child: const Text('开战'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBoard({
    required List<List<BattleUnit?>> board,
    required bool isEnemy,
    required Color borderColor,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: AspectRatio(
            aspectRatio: cols / rows,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                childAspectRatio: 1.0,
                crossAxisSpacing: 2.0,
                mainAxisSpacing: 2.0,
              ),
              itemCount: rows * cols,
              itemBuilder: (context, index) {
                final row = index ~/ cols;
                final col = index % cols;
                return _buildCell(board[row][col], isEnemy, index);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCell(BattleUnit? unit, bool isEnemy, int index) {
    return DragTarget<BattleUnit>(
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
          playerBoard[receivedUnit.position.row][receivedUnit.position.col] = null;
          playerBoard[newPosition.row][newPosition.col] = receivedUnit;
          receivedUnit.updatePosition(newPosition);
        });
      },
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () {
            if (!isEnemy) {  // 只允許在玩家區域操作
              _handleCellTap(unit);
            }
            // 打印出格子的编号
            print('点击了格子: ${index + 1}');
          },
          child: Container(
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
                  )
                : null,
          ),
        );
      },
    );
  }

  void _addPlayerUnit() {
    setState(() {
      // 在玩家棋盘的第一个空位置新增一个玩家角色
      for (int row = 0; row < rows; row++) {
        for (int col = 0; col < cols; col++) {
          if (playerBoard[row][col] == null) {
            playerBoard[row][col] = BattleUnit(
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
    // TODO: 实现开战逻辑
    print('开战！');
  }

  void _handleCellTap(BattleUnit? unit) {
    setState(() {
      if (unit != null && unit.type == UnitType.player) {
        // 选中或取消选中玩家角色
        selectedUnit = selectedUnit == unit ? null : unit;
      } else if (selectedUnit != null) {
        // 移动选中的玩家角色到新的位置
        final newPosition = Position(
          playerBoard.indexWhere((row) => row.contains(unit)),
          playerBoard.firstWhere((row) => row.contains(unit)).indexOf(unit),
        );
        playerBoard[selectedUnit!.position.row][selectedUnit!.position.col] = null;
        playerBoard[newPosition.row][newPosition.col] = selectedUnit;
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