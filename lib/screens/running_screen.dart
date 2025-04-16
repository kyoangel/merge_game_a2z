import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flame/game.dart';
import '../game/game_manager.dart';
import '../game/running_game.dart';
import 'battle_screen.dart';

class RunningScreen extends StatelessWidget {
  const RunningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameManager = context.read<GameManager>();
    
    return Scaffold(
      body: SafeArea(
        child: GameWidget(
          game: RunningGame(
            coins: gameManager.coins,
            onGameComplete: ({required int coins}) {
              // 更新遊戲管理器中的金幣
              gameManager.addCoins(coins - gameManager.coins);
              
              // 進入戰鬥場景
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => BattleScreen(
                    coins: gameManager.coins,
                    winStreak: gameManager.winStreak,
                    currentLevel: gameManager.currentLevel,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
} 