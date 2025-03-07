import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../running_game.dart';
import 'coin.dart';
import 'obstacle.dart';

class Player extends PositionComponent with CollisionCallbacks, HasGameRef<RunningGame> {
  static const double playerSize = 50;
  static const double moveSpeed = 300;
  final _paint = Paint()..color = Colors.blue;
  
  Player() : super(size: Vector2.all(playerSize)) {
    add(RectangleHitbox(
      size: Vector2.all(playerSize * 0.9),
      position: Vector2.all(playerSize * 0.05),
    ));
  }
  
  @override
  Future<void> onLoad() async {
    position = Vector2(
      gameRef.size.x / 2 - size.x / 2,
      gameRef.size.y - size.y - 50,
    );
  }
  
  void moveHorizontally(double delta) {
    final newX = position.x + delta;
    position.x = newX.clamp(
      0,
      gameRef.size.x - size.x,
    );
  }
  
  void reset() {
    position = Vector2(
      gameRef.size.x / 2 - size.x / 2,
      gameRef.size.y - size.y - 50,
    );
  }
  
  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    
    if (other is Coin) {
      other.collect();
    } else if (other is Obstacle) {
      gameRef.gameOver();
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