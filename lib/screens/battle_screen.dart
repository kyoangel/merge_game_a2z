import 'package:flutter/material.dart';
import '../game/battle/battle_board.dart';

class BattleScreen extends StatelessWidget {
  final int coins;
  final int winStreak;
  final int currentLevel;

  const BattleScreen({
    super.key,
    required this.coins,
    required this.winStreak,
    required this.currentLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('戰鬥'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BattleBoard(
        coins: coins,
        winStreak: winStreak,
        currentLevel: currentLevel,
      ),
    );
  }
} 