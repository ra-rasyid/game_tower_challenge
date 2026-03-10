// features/game/domain/entities/tower.dart
enum TowerStatus { available, claimed, solved }

class Tower {
  final String id;
  final int startValue;
  final int targetValue;
  final TowerStatus status;
  final String? claimedBy;
  final String? solvedBy;
  final int? movesTaken;
  final int? optimalMoves;
  final DateTime? claimExpiresAt;

  Tower({
    required this.id,
    required this.startValue,
    required this.targetValue,
    this.status = TowerStatus.available,
    this.claimedBy,
    this.solvedBy,
    this.movesTaken,
    this.optimalMoves,
    this.claimExpiresAt,
  });

  // Untuk mengubah data Tower tanpa merusak object lama (Immutability)
  Tower copyWith({TowerStatus? status, String? claimedBy}) {
    return Tower(
      id: id,
      startValue: startValue,
      targetValue: targetValue,
      status: status ?? this.status,
      claimedBy: claimedBy ?? this.claimedBy,
    );
  }
}