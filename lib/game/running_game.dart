import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'dart:math' show Random;
import 'components/player.dart';
import 'components/road.dart';
import 'components/coin.dart';
import 'components/obstacle.dart';

class RunningGame extends FlameGame with DragCallbacks {
  late final Player player;
  late final Road road;
  double gameSpeed = 300; // 遊戲速度（像素/秒）
  final Random random = Random();  // 添加隨機數生成器
  
  @override
  Future<void> onLoad() async {
    // 設置相機和視口
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.zoom = 1.0;  // 設置縮放比例
    
    // 添加道路
    road = Road();
    add(road);
    
    // 添加玩家
    player = Player();
    add(player);
    
    // 定期生成金幣和障礙物
    spawnCoins();
    spawnObstacles();
  }
  
  void spawnCoins() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!isMounted) return;
      
      final coin = Coin();
      add(coin);
      spawnCoins();
    });
  }
  
  void spawnObstacles() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!isMounted) return;
      
      final obstacle = Obstacle();
      add(obstacle);
      spawnObstacles();
    });
  }
  
  void gameOver() {
    // 遊戲結束邏輯
    pauseEngine();
    overlays.add('gameOver');
  }
  
  @override
  void onDragUpdate(DragUpdateEvent event) {
    player.moveHorizontally(event.delta.x);
  }
} 