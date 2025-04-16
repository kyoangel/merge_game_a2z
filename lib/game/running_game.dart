import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'dart:math' show Random;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_manager.dart';
import 'components/player.dart';
import 'components/road.dart';
import 'components/coin.dart';
import 'components/obstacle.dart';

typedef GameStateCallback = void Function({
  required int coins,
  required int winStreak,
  required int currentLevel,
});

class RunningGame extends FlameGame with DragCallbacks, HasCollisionDetection {
  late final Player player;
  late final Road road;
  double gameSpeed = 400;
  final Random random = Random();
  
  // 遊戲狀態
  double _gameTime = 0;
  int score = 0;
  static const double gameDuration = 10;
  static const double finishLinePosition = gameDuration * 400;
  double distanceTraveled = 0;
  
  // 遊戲進度
  int coins = 0;
  int winStreak = 0;
  int currentLevel = 1;
  static const int coinValue = 50;
  
  // 生成間隔
  static const double coinSpawnInterval = 0.5;
  static const double obstacleSpawnInterval = 0.8;
  double _lastCoinSpawnTime = 0;
  double _lastObstacleSpawnTime = 0;
  
  // 回調函數
  final GameStateCallback onGameComplete;
  final VoidCallback? onGameStateChanged;
  
  RunningGame({
    required this.onGameComplete,
    this.onGameStateChanged,
    this.coins = 0,
    this.winStreak = 0,
    this.currentLevel = 1,
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
    
    if (_gameTime - _lastCoinSpawnTime >= coinSpawnInterval) {
      spawnCoin();
      _lastCoinSpawnTime = _gameTime;
    }
    
    if (_gameTime - _lastObstacleSpawnTime >= obstacleSpawnInterval) {
      spawnObstacle();
      _lastObstacleSpawnTime = _gameTime;
    }
    
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
  
  void collectCoin() {
    coins += coinValue;
    addScore(10);
  }
  
  void gameOver() {
    pauseEngine();
    // 遊戲失敗時也進入戰鬥場景，但不增加連勝
    onGameComplete(
      coins: coins,
      winStreak: 0, // 失敗時重置連勝
      currentLevel: currentLevel,
    );
    onGameStateChanged?.call(); // 通知遊戲狀態變更
  }
  
  void victory() {
    pauseEngine();
    // 直接調用回調函數，進入戰鬥場景
    onGameComplete(
      coins: coins,
      winStreak: winStreak + 1, // 勝利時增加連勝
      currentLevel: currentLevel + 1, // 勝利時增加關卡
    );
    onGameStateChanged?.call(); // 通知遊戲狀態變更
  }
  
  @override
  void restart() {
    children.whereType<Coin>().forEach((coin) => coin.removeFromParent());
    children.whereType<Obstacle>().forEach((obstacle) => obstacle.removeFromParent());
    
    player.reset();
    
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

class GameInfoOverlay extends PositionComponent with HasGameRef<RunningGame> {
  @override
  Future<void> onLoad() async {
    position = Vector2(0, 0);
    size = Vector2(gameRef.size.x, 50);
  }
  
  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = Colors.black.withOpacity(0.7),
    );
    
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