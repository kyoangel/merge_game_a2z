import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class GameManager extends ChangeNotifier {
  int coins = 0;
  int currentLevel = 1;
  bool isRunning = false;
  bool isBattling = false;

  void addCoins(int amount) {
    coins += amount;
    notifyListeners();
  }

  void startRunning() {
    isRunning = true;
    isBattling = false;
    notifyListeners();
  }

  void startBattle() {
    isRunning = false;
    isBattling = true;
    notifyListeners();
  }

  void endGame() {
    isRunning = false;
    isBattling = false;
    notifyListeners();
  }
} 