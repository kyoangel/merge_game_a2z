import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../running_game.dart';
import 'player.dart';

class Coin extends PositionComponent with CollisionCallbacks, HasGameRef<RunningGame> {
  static const double coinSize = 30;
  static const int pointValue = 10;
  bool isCollected = false;
  final _paint = Paint()..color = Colors.yellow;  // 金幣顏色
  
  Coin() : super(size: Vector2.all(coinSize)) {
    add(CircleHitbox(
      radius: coinSize * 0.4,
      position: Vector2.all(coinSize * 0.1),
    ));
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
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      _paint,
    );
  }
  
  void collect() {
    if (!isCollected) {
      isCollected = true;
      gameRef.addScore(pointValue);  // 增加分數
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    
    if (other is Player) {
      collect();
    }
  }
} 