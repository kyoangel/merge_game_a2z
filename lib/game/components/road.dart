import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../running_game.dart';

class Road extends PositionComponent with HasGameRef<RunningGame> {
  @override
  Future<void> onLoad() async {
    size = Vector2(gameRef.size.x, gameRef.size.y);
    position = Vector2.zero();
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0xFF333333),
    );
  }
} 