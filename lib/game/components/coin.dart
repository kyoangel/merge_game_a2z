import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'dart:math' show Random;
import '../running_game.dart';
import 'player.dart';

class Coin extends PositionComponent with CollisionCallbacks, HasGameRef<RunningGame> {
  static final Random _random = Random();
  bool isCollected = false;
  
  Coin() : super(size: Vector2(20, 20)) {
    add(CircleHitbox());
  }
  
  @override
  Future<void> onLoad() async {
    // 初始化位置
    position = Vector2(
      _random.nextDouble() * (gameRef.size.x - size.x),
      -size.y
    );
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // 向下移動
    position.y += gameRef.gameSpeed * dt;
    
    // 如果超出螢幕底部，移除金幣
    if (position.y > gameRef.size.y) {
      removeFromParent();
    }
  }
  
  void collect() {
    if (!isCollected) {
      isCollected = true;
      gameRef.collectCoin();
      removeFromParent();
    }
  }
  
  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    
    if (other is Player) {
      collect();
    }
  }
  
  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    
    // 繪製金幣
    final paint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset.zero, size.x / 2, paint);
    
    // 添加金幣邊框
    final borderPaint = Paint()
      ..color = Colors.amber.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(Offset.zero, size.x / 2, borderPaint);
    
    canvas.restore();
  }
} 