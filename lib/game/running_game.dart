import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'dart:math' show Random;
import 'components/player.dart';
import 'components/road.dart';
import 'components/coin.dart';
import 'components/obstacle.dart';

class RunningGame extends FlameGame with DragCallbacks, HasCollisionDetection {
  late final Player player;
  late final Road road;
  double gameSpeed = 300; // 遊戲速度（像素/秒）
  final Random random = Random();  // 添加隨機數生成器
  
  // 添加計時器和分數
  double _gameTime = 0;
  int score = 0;
  static const double gameDuration = 60; // 遊戲時長（秒）
  static const double finishLinePosition = gameDuration * 300; // 終點線位置
  double distanceTraveled = 0;
  
  @override
  Future<void> onLoad() async {
    // 關閉調試模式
    debugMode = false;
    
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.zoom = 1.0;
    
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
  
  @override
  void update(double dt) {
    super.update(dt);
    _gameTime += dt;
    distanceTraveled += gameSpeed * dt;
    
    // 更新分數顯示
    overlays.remove('score');
    overlays.add('score');
    
    // 檢查是否到達終點
    if (distanceTraveled >= finishLinePosition) {
      victory();
    }
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
  
  void addScore(int points) {
    score += points;
  }
  
  void gameOver() {
    // 遊戲結束邏輯
    pauseEngine();
    overlays.add('gameOver');
  }
  
  void victory() {
    pauseEngine();
    overlays.add('victory');
  }
  
  @override
  void restart() {
    // 移除所有現有的金幣和障礙物
    children.whereType<Coin>().forEach((coin) => coin.removeFromParent());
    children.whereType<Obstacle>().forEach((obstacle) => obstacle.removeFromParent());
    
    // 重置玩家位置
    player.reset();
    
    // 重置遊戲狀態
    overlays.remove('gameOver');
    overlays.remove('victory');
    _gameTime = 0;
    score = 0;
    distanceTraveled = 0;
    resumeEngine();
    
    // 重新開始生成金幣和障礙物
    spawnCoins();
    spawnObstacles();
  }
  
  @override
  void onDragUpdate(DragUpdateEvent event) {
    player.moveHorizontally(event.delta.x);
  }
} 