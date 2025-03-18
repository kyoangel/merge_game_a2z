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
                SizedBox(
                  height: boardHeight,
                  child: _buildBoard(
                    board: enemyBoard,
                    isEnemy: true,
                    borderColor: Colors.red,
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
                
                SizedBox(
                  height: boardHeight,
                  child: _buildBoard(
                    board: playerBoard,
                    isEnemy: false,
                    borderColor: Colors.blue,
                  ),
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
                return _buildCell(board[row][col], isEnemy);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCell(BattleUnit? unit, bool isEnemy) {
    return GestureDetector(
      onTap: () {
        if (!isEnemy) {  // 只允許在玩家區域操作
          _handleCellTap(unit);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          color: _getCellColor(unit, isEnemy),
        ),
        child: unit != null
            ? FittedBox(
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
              )
            : null,
      ),
    );
  }

  void _handleCellTap(BattleUnit? unit) {
    // TODO: 處理玩家區域的點擊事件
    print('點擊了玩家區域的格子');
  }

  Color _getCellColor(BattleUnit? unit, bool isEnemy) {
    if (unit == null) {
      return isEnemy ? Colors.red[50]! : Colors.blue[50]!;
    }
    return unit.type == UnitType.player ? Colors.blue[100]! : Colors.red[100]!;
  }
} 