import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:provider/provider.dart';
import '../game/running_game.dart';
import '../game/battle/battle_board.dart';
import '../game/game_manager.dart';
import 'battle_screen.dart';

class RunningScreen extends StatelessWidget {
  const RunningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameManager = context.watch<GameManager>();
    
    return GameWidget(
      game: RunningGame(
        coins: gameManager.coins,
        winStreak: gameManager.winStreak,
        currentLevel: gameManager.currentLevel,
        onGameComplete: ({
          required int coins,
          required int winStreak,
          required int currentLevel,
        }) {
          // 更新 GameManager 的狀態
          gameManager.addCoins(coins - gameManager.coins);
          gameManager.updateWinStreak(winStreak);
          gameManager.currentLevel = currentLevel;
          
          // 切換到戰鬥場景
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => BattleScreen(
                coins: coins,
                winStreak: winStreak,
                currentLevel: currentLevel,
              ),
            ),
          );
        },
      ),
    );
  }
} 