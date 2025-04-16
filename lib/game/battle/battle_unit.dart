import 'bullet.dart';
import 'dart:math';

class Position {
  final int row;
  final int col;
  
  Position(this.row, this.col);

  Map<String, dynamic> toJson() => {
    'row': row,
    'col': col,
  };

  factory Position.fromJson(Map<String, dynamic> json) => Position(
    json['row'] as int,
    json['col'] as int,
  );
}

enum UnitType {
  player,
  enemy,
}

class BattleUnit {
  final UnitType type;
  Position position;
  late int health;
  late int attackPower;
  String unitName; // 單位名稱 (A-Z)
  int level; // 單位等級
  
  // 基礎屬性計算公式
  static int calculateHealth(String unitName) {
    final baseHealth = 50; // 降低基礎生命值
    final growthRate = 1.6; // 提高成長率
    final level = unitName.codeUnitAt(0) - 'A'.codeUnitAt(0);
    
    // 使用指數增長，讓高等級單位更強
    return (baseHealth * pow(growthRate, level)).round();
  }
  
  static int calculateAttack(String unitName) {
    final baseAttack = 5; // 降低基礎攻擊力
    final growthRate = 1.3; // 提高成長率
    final level = unitName.codeUnitAt(0) - 'A'.codeUnitAt(0);
    
    // 使用指數增長，讓高等級單位更強
    return (baseAttack * pow(growthRate, level)).round();
  }

  // 獲取單位等級的數值表示（用於顯示和計算）
  static int getUnitLevel(String unitName) {
    return unitName.codeUnitAt(0) - 'A'.codeUnitAt(0) + 1;
  }
  
  // 獲取下一個等級的單位名稱
  static String getNextUnitName(String currentName) {
    if (currentName == 'Z') return 'Z'; // 最高等級
    return String.fromCharCode(currentName.codeUnitAt(0) + 1);
  }

  // 獲取單位的屬性描述
  String getStatsDescription() {
    return 'HP: $health\nATK: $attackPower';
  }
  
  BattleUnit({
    required this.type,
    required this.position,
    this.unitName = 'A',
    this.level = 1,
  }) {
    // 根據單位名稱計算基礎屬性
    health = calculateHealth(unitName);
    attackPower = calculateAttack(unitName);
  }
  
  void takeDamage(int damage) {
    health -= damage;
    if (health < 0) health = 0;
  }
  
  bool get isAlive => health > 0;

  void updatePosition(Position newPosition) {
    position = newPosition;
  }

  // 合成升級
  void merge(BattleUnit other) {
    if (unitName == 'Z') return; // 最高等級不能合成
    
    final nextName = getNextUnitName(unitName);
    unitName = nextName;
    level++;
    
    // 更新屬性
    health = calculateHealth(nextName);
    attackPower = calculateAttack(nextName);
  }

  void attack(Position targetPosition) {
    // 生成子弹
    Bullet bullet = Bullet(
      shooter: this,
      position: position,
      damage: attackPower,
      targetPosition: targetPosition,
    );
    // 打印子弹生成信息
    print('子弹生成: shooter=${unitName}, position=(${position.row}, ${position.col}), target=(${targetPosition.row}, ${targetPosition.col})');
    // 需要通过某种方式访问 BattleBoard 的 bullets 列表
    // 例如，通过回调或事件系统将子弹添加到 BattleBoard
  }

  Map<String, dynamic> toJson() => {
    'type': type.toString(),
    'position': position.toJson(),
    'health': health,
    'attackPower': attackPower,
    'unitName': unitName,
    'level': level,
  };

  factory BattleUnit.fromJson(Map<String, dynamic> json) {
    final unit = BattleUnit(
      type: UnitType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      position: Position.fromJson(json['position'] as Map<String, dynamic>),
      unitName: json['unitName'] as String,
      level: json['level'] as int,
    );
    unit.health = json['health'] as int;
    unit.attackPower = json['attackPower'] as int;
    return unit;
  }
} 