import 'battle_unit.dart';

class Bullet {
  final BattleUnit shooter;
  Position position;
  final int damage;

  Bullet({
    required this.shooter,
    required this.position,
    required this.damage,
  });

  void moveTowards(Position target) {
    // 简单的移动逻辑，假设每次移动一格
    if (position.row < target.row) {
      position = Position(position.row + 1, position.col);
    } else if (position.row > target.row) {
      position = Position(position.row - 1, position.col);
    }

    if (position.col < target.col) {
      position = Position(position.row, position.col + 1);
    } else if (position.col > target.col) {
      position = Position(position.row, position.col - 1);
    }
  }
} 