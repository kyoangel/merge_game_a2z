import 'bullet.dart';

class Position {
  final int row;
  final int col;
  
  Position(this.row, this.col);
}

enum UnitType {
  player,
  enemy,
}

class BattleUnit {
  final UnitType type;
  Position position;
  late int health;
  late int attackPower;
  String unitName; // 單位名稱 (A, B, C...)
  int level; // 單位等級
  
  // 基礎屬性
  static const Map<String, Map<String, int>> unitStats = {
    'A': {'health': 100, 'attack': 10},
    'B': {'health': 150, 'attack': 15},
    'C': {'health': 225, 'attack': 22},
    'D': {'health': 337, 'attack': 33},
    'E': {'health': 505, 'attack': 50},
    'F': {'health': 757, 'attack': 75},
    'G': {'health': 1135, 'attack': 113},
    'H': {'health': 1702, 'attack': 170},
    'I': {'health': 2553, 'attack': 255},
    'J': {'health': 3829, 'attack': 382},
  };
  
  // 獲取下一個等級的單位名稱
  static String getNextUnitName(String currentName) {
    if (currentName == 'J') return 'J'; // 最高等級
    return String.fromCharCode(currentName.codeUnitAt(0) + 1);
  }
  
  BattleUnit({
    required this.type,
    required this.position,
    this.unitName = 'A',
    this.level = 1,
  }) {
    // 根據單位名稱設置基礎屬性
    final stats = unitStats[unitName]!;
    health = stats['health']!;
    attackPower = stats['attack']!;
  }
  
  void takeDamage(int damage) {
    health -= damage;
    if (health < 0) health = 0;
  }
  
  bool get isAlive => health > 0;

  void updatePosition(Position newPosition) {
    position = newPosition;
  }

  // 合成升級
  void merge(BattleUnit other) {
    if (unitName == 'J') return; // 最高等級不能合成
    
    final nextName = getNextUnitName(unitName);
    unitName = nextName;
    level++;
    
    // 更新屬性
    final stats = unitStats[nextName]!;
    health = stats['health']!;
    attackPower = stats['attack']!;
  }

  void attack(Position targetPosition) {
    // 生成子弹
    Bullet bullet = Bullet(
      shooter: this,
      position: position,
      damage: attackPower,
      targetPosition: targetPosition,
    );
    // 打印子弹生成信息
    print('子弹生成: shooter=${unitName}, position=(${position.row}, ${position.col}), target=(${targetPosition.row}, ${targetPosition.col})');
    // 需要通过某种方式访问 BattleBoard 的 bullets 列表
    // 例如，通过回调或事件系统将子弹添加到 BattleBoard
  }
} 