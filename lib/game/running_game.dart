import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'dart:math' show Random;
import 'package:flutter/material.dart';
import 'components/player.dart';
import 'components/road.dart';
import 'components/coin.dart';
import 'components/obstacle.dart';

// 添加回調函數類型定義
typedef VoidCallback = void Function();

class RunningGame extends FlameGame with DragCallbacks, HasCollisionDetection {
  late final Player player;
  late final Road road;
  double gameSpeed = 400; // 增加遊戲速度
  final Random random = Random();
  
  // 遊戲狀態
  double _gameTime = 0;
  int score = 0;
  static const double gameDuration = 10; // 縮短遊戲時間到10秒
  static const double finishLinePosition = gameDuration * 400; // 調整終點線位置
  double distanceTraveled = 0;
  
  // 遊戲進度
  int coins = 0;
  int winStreak = 0;
  int currentLevel = 1;
  static const int coinValue = 50; // 每個金幣的價值
  
  // 生成間隔
  static const double coinSpawnInterval = 0.5; // 每0.5秒生成一個金幣
  static const double obstacleSpawnInterval = 0.8; // 每0.8秒生成一個障礙物
  double _lastCoinSpawnTime = 0;
  double _lastObstacleSpawnTime = 0;
  
  // 回調函數
  VoidCallback? onVictory;
  
  // 構造函數，接收初始狀態和回調函數
  RunningGame({
    this.coins = 0,
    this.winStreak = 0,
    this.currentLevel = 1,
    this.onVictory,
  });
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.zoom = 1.0;
    
    // 添加道路
    road = Road();
    await add(road);
    
    // 添加玩家
    player = Player();
    await add(player);
    
    // 添加資訊欄
    await add(GameInfoOverlay());
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    _gameTime += dt;
    distanceTraveled += gameSpeed * dt;
    
    // 動態生成金幣和障礙物
    if (_gameTime - _lastCoinSpawnTime >= coinSpawnInterval) {
      spawnCoin();
      _lastCoinSpawnTime = _gameTime;
    }
    
    if (_gameTime - _lastObstacleSpawnTime >= obstacleSpawnInterval) {
      spawnObstacle();
      _lastObstacleSpawnTime = _gameTime;
    }
    
    // 檢查是否到達終點
    if (distanceTraveled >= finishLinePosition) {
      victory();
    }
  }
  
  void spawnCoin() {
    if (!isMounted) return;
    final coin = Coin();
    add(coin);
  }
  
  void spawnObstacle() {
    if (!isMounted) return;
    final obstacle = Obstacle();
    add(obstacle);
  }
  
  void addScore(int points) {
    score += points;
  }
  
  // 收集金幣
  void collectCoin() {
    coins += coinValue;
    addScore(10);
  }
  
  void gameOver() {
    pauseEngine();
    overlays.add('gameOver');
  }
  
  void victory() {
    pauseEngine();
    overlays.add('victory');
    
    // 調用回調函數，進入戰鬥畫面
    if (onVictory != null) {
      onVictory!();
    }
  }
  
  @override
  void restart() {
    children.whereType<Coin>().forEach((coin) => coin.removeFromParent());
    children.whereType<Obstacle>().forEach((obstacle) => obstacle.removeFromParent());
    
    player.reset();
    
    overlays.remove('gameOver');
    overlays.remove('victory');
    _gameTime = 0;
    _lastCoinSpawnTime = 0;
    _lastObstacleSpawnTime = 0;
    score = 0;
    distanceTraveled = 0;
    resumeEngine();
  }
  
  @override
  void onDragUpdate(DragUpdateEvent event) {
    player.moveHorizontally(event.delta.x);
  }
}

// 資訊欄組件
class GameInfoOverlay extends PositionComponent with HasGameRef<RunningGame> {
  @override
  Future<void> onLoad() async {
    position = Vector2(0, 0);
    size = Vector2(gameRef.size.x, 50);
  }
  
  @override
  void render(Canvas canvas) {
    // 繪製背景
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = Colors.black.withOpacity(0.7),
    );
    
    // 繪製文字
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '金幣: ${gameRef.coins}   ',
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: '連勝: ${gameRef.winStreak}   ',
            style: const TextStyle(
              color: Colors.yellow,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: '關卡: ${gameRef.currentLevel}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, (size.y - textPainter.height) / 2));
  }
} 