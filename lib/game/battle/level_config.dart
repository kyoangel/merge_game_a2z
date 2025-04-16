class LevelConfig {
  final int level;
  final List<EnemyConfig> enemies;
  final int reward;

  LevelConfig({
    required this.level,
    required this.enemies,
    required this.reward,
  });
}

class EnemyConfig {
  final int row;
  final int col;
  final String unitName;
  final double statBonus;

  EnemyConfig({
    required this.row,
    required this.col,
    required this.unitName,
    this.statBonus = 1.0,
  });

  Map<String, dynamic> toJson() => {
    'row': row,
    'col': col,
    'unitName': unitName,
    'statBonus': statBonus,
  };

  factory EnemyConfig.fromJson(Map<String, dynamic> json) => EnemyConfig(
    row: json['row'] as int,
    col: json['col'] as int,
    unitName: json['unitName'] as String,
    statBonus: (json['statBonus'] as num).toDouble(),
  );
} 