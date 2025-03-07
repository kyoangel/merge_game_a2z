import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/running_game.dart';

class RunningScreen extends StatelessWidget {
  const RunningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: RunningGame(),
        overlayBuilderMap: {
          'score': (context, game) {
            return const Positioned(
              top: 40,
              left: 20,
              child: Text(
                '分數: 0',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            );
          },
          'gameOver': (context, game) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                color: Colors.black54,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '遊戲結束',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('返回主選單'),
                    ),
                  ],
                ),
              ),
            );
          },
        },
      ),
    );
  }
} 