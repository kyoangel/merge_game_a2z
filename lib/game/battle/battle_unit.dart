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
  int health = 100;
  int attackPower = 10;
  
  BattleUnit({
    required this.type,
    required this.position,
  });
  
  void takeDamage(int damage) {
    health -= damage;
    if (health < 0) health = 0;
  }
  
  bool get isAlive => health > 0;

  void updatePosition(Position newPosition) {
    position = newPosition;
  }

  void attack(Position targetPosition) {
    // 生成子弹
    Bullet bullet = Bullet(
      shooter: this,
      position: position,
      damage: attackPower,
    );
    // 将子弹添加到 BattleBoard 的 bullets 列表中
    // 需要通过某种方式访问 BattleBoard 的 bullets 列表
    print('子弹生成: shooter=${type}, position=(${position.row}, ${position.col}), target=(${targetPosition.row}, ${targetPosition.col})');
  }
} 