import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_manager.dart';
import '../screens/running_screen.dart';
import '../screens/battle_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameManager = context.watch<GameManager>();
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ElevatedButton(
            //   onPressed: () {
            //     context.read<GameManager>().startBattle();
            //     Navigator.of(context).push(
            //       MaterialPageRoute(
            //         builder: (context) => BattleScreen(
            //           coins: gameManager.coins,
            //           winStreak: gameManager.winStreak,
            //           currentLevel: gameManager.currentLevel,
            //         ),
            //       ),
            //     );
            //   },
            //   child: const Text('戰鬥畫面'),
            // ),
            const SizedBox(height: 30),
            const Text(
              '進化跑酷',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                context.read<GameManager>().startRunning();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RunningScreen(),
                  ),
                );
              },
              child: const Text('開始遊戲'),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                // TODO: 顯示設置選項
              },
              child: const Text('設置'),
            ),
          ],
        ),
      ),
    );
  }
} 