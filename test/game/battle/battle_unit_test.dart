import 'package:flutter_test/flutter_test.dart';
import 'dart:math';
import 'package:merge_game_a2z/game/battle/battle_unit.dart';
import 'package:merge_game_a2z/game/battle/battle_board.dart'; // Assuming Position and UnitType are in battle_board.dart or a shared file

// Mock or actual implementation of calculateHealth and calculateAttack if they are not in BattleUnit itself
// For this example, let's assume simple implementations for testing purposes
int calculateHealth(String unitName) {
  final baseHealth = 50; // 降低基礎生命值
    final growthRate = 1.6; // 提高成長率
    final level = unitName.codeUnitAt(0) - 'A'.codeUnitAt(0);
    
    // 使用指數增長，讓高等級單位更強
    return (baseHealth * pow(growthRate, level)).round();
}

int calculateAttack(String unitName) {
  final baseAttack = 5; // 降低基礎攻擊力
    final growthRate = 1.3; // 提高成長率
    final level = unitName.codeUnitAt(0) - 'A'.codeUnitAt(0);
    
    // 使用指數增長，讓高等級單位更強
    return (baseAttack * pow(growthRate, level)).round();
}

String getNextUnitName(String currentName) {
    if (currentName == 'Z') return 'Z';
    return String.fromCharCode(currentName.codeUnitAt(0) + 1);
}


void main() {
  group('BattleUnit Merge Tests', () {

    // Test case 1: Merging two units of the same level (A + A -> B)
    test('should merge two units of the same level and stack attributes', () {
      // Arrange
      // Assuming initial health and attack are calculated based on level 'A'
      final unitA = BattleUnit(type: UnitType.player, position: Position(0, 0), unitName: 'A', level: 1);
      unitA.health = calculateHealth('A'); // Initialize health based on level A
      unitA.attackPower = calculateAttack('A'); // Initialize attack based on level A


      final unitB = BattleUnit(type: UnitType.player, position: Position(0, 1), unitName: 'A', level: 1);
      unitB.health = calculateHealth('A'); // Initialize health based on level A
      unitB.attackPower = calculateAttack('A'); // Initialize attack based on level A


      // Act
      unitA.merge(unitB); // Merge unitB into unitA

      // Assert
      // Expected level after merging A+A is 2
      expect(unitA.level, 2);
      // Expected unit name after merging A+A is B
      expect(unitA.unitName, 'B');

      expect(unitA.health, calculateHealth('B'));

      expect(unitA.attackPower, calculateAttack('B'));
    });

    // Test case 2: Merging units of different levels (should not merge based on the updated logic)
    // However, based on your requirement, merge should only happen if levels are the same.
    // The board logic handles preventing merge if levels are different.
    // This unit test focuses on the merge method itself, assuming it's called with valid units to be merged.
    // We can add a test to ensure merge doesn't happen if the target is max level.
     test('should not merge if the target unit is max level (Z)', () {
      // Arrange
      final unitZ = BattleUnit(type: UnitType.player, position: Position(0, 0), unitName: 'Z', level: 26);
      unitZ.health = calculateHealth('Z');
      unitZ.attackPower = calculateAttack('Z');

      final unitA = BattleUnit(type: UnitType.player, position: Position(0, 1), unitName: 'A', level: 1);
      unitA.health = calculateHealth('A');
      unitA.attackPower = calculateAttack('A');


      // Act
      unitZ.merge(unitA); // Attempt to merge unitA into unitZ

      // Assert
      // Unit Z should remain at level 26 and its stats should not change
      expect(unitZ.level, 26);
      expect(unitZ.unitName, 'Z');
      expect(unitZ.health, calculateHealth('Z')); // Health should remain unchanged
      expect(unitZ.attackPower, calculateAttack('Z')); // Attack should remain unchanged
    });

    // Test case 3: Merging units of a higher level (e.g., B + B -> C)
     test('should merge two units of a higher level (B+B -> C) and stack attributes', () {
      // Arrange
      final unitB1 = BattleUnit(type: UnitType.player, position: Position(0, 0), unitName: 'B', level: 2);
      unitB1.health = calculateHealth('B');
      unitB1.attackPower = calculateAttack('B');

      final unitB2 = BattleUnit(type: UnitType.player, position: Position(0, 1), unitName: 'B', level: 2);
      unitB2.health = calculateHealth('B');
      unitB2.attackPower = calculateAttack('B');


      // Act
      unitB1.merge(unitB2); // Merge unitB2 into unitB1

      // Assert
      // Expected level after merging B+B is 3
      expect(unitB1.level, 3);
      // Expected unit name after merging B+B is C
      expect(unitB1.unitName, 'C');

      // Expected health after merging: calculateHealth('C') + unitB2.health
       expect(unitB1.health, calculateHealth('C'));

      // Expected attack power after merging: calculateAttack('C') + unitB2.attackPower
      expect(unitB1.attackPower, calculateAttack('C'));
    });
  });
}

// Define Position and UnitType if they are not in a file that's already imported
// Assuming they are defined elsewhere and accessible.
// If not, you might need to mock them or import the correct file.

// Example placeholder if needed:
/*
class Position {
  final int row;
  final int col;
  Position(this.row, this.col);
}

enum UnitType { player, enemy }
*/
