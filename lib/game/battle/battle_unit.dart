class Position {
  final int row;
  final int col;
  
  Position(this.row, this.col);
}

enum UnitType {
  player,
  enemy,
}

class BattleUnit {
  final UnitType type;
  Position position;
  int health = 100;
  int attack = 10;
  
  BattleUnit({
    required this.type,
    required this.position,
  });
  
  void takeDamage(int damage) {
    health -= damage;
    if (health < 0) health = 0;
  }
  
  bool get isAlive => health > 0;

  void updatePosition(Position newPosition) {
    position = newPosition;
  }
} 