import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../running_game.dart';

class Obstacle extends PositionComponent with CollisionCallbacks, HasGameRef<RunningGame> {
  static const double obstacleSize = 40;
  final _paint = Paint()..color = Colors.red;
  
  Obstacle() : super(size: Vector2.all(obstacleSize)) {
    add(RectangleHitbox());
  }
  
  @override
  Future<void> onLoad() async {
    position = Vector2(
      (gameRef.size.x - size.x) * gameRef.random.nextDouble(),
      -size.y,
    );
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    position.y += gameRef.gameSpeed * dt;
    
    if (position.y > gameRef.size.y) {
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      _paint,
    );
  }
} 