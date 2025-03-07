import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../running_game.dart';

class Coin extends PositionComponent with CollisionCallbacks, HasGameRef<RunningGame> {
  static const double coinSize = 30;
  bool isCollected = false;
  
  Coin() : super(size: Vector2.all(coinSize)) {
    add(CircleHitbox());
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
  
  void collect() {
    if (!isCollected) {
      isCollected = true;
      removeFromParent();
      // TODO: 增加分數
    }
  }
} 