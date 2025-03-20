import 'dart:math'; // 导入 dart:math 库
import 'battle_unit.dart';

class Bullet {
  final BattleUnit shooter;
  double x;
  double y;
  final int damage;
  final Position targetPosition; // 新增：保存目标位置

  Bullet({
    required this.shooter,
    required Position position,
    required this.damage,
    required this.targetPosition, // 新增：构造函数需要目标位置
  }) : x = position.col.toDouble(),
       y = position.row.toDouble();

  void moveTowards(Position target) {
    // 计算方向向量
    final dx = targetPosition.col - shooter.position.col;
    final dy = targetPosition.row - shooter.position.row;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance > 0) {
      // 标准化方向向量并设置速度
      final speed = 0.1; // 调整速度
      final dirX = dx / distance;
      final dirY = dy / distance;

      // 更新位置
      x += dirX * speed;
      y += dirY * speed;
    }
  }

  bool hasReachedTarget() {
    final dx = x - targetPosition.col;
    final dy = y - targetPosition.row;
    return sqrt(dx * dx + dy * dy) < 0.1;
  }

  Position get position => Position(y.round(), x.round());
} 