// features/game/presentation/flame/components/team_arena_component.dart
import 'package:flame/components.dart';
import 'tower_component.dart';
import '../../../domain/entities/tower.dart';
import 'package:get/get.dart';
import '../../controllers/game_controller.dart';

class TeamArenaComponent extends PositionComponent {
  final String team;
  final GameController controller = Get.find(); // Ambil controller

  TeamArenaComponent({
    required this.team,
    required Vector2 size,
    required Vector2 position,
  }) : super(size: size, position: position);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Grid 4 Kolom x 5 Baris = 20 Tower
    const double spacing = 8.0;
    final double towerWidth = (size.x - (5 * spacing)) / 4;
    final double towerHeight = (size.y - (6 * spacing)) / 5;

    for (int i = 0; i < 20; i++) {
      int row = i ~/ 4;
      int col = i % 4;

      // Dummy data untuk testing visual
      final towerData = Tower(
        id: 'tower_${team}_$i',
        startValue: (i + 1) * 10,
        targetValue: 1000,
      );

      add(TowerComponent(
        tower: towerData,
        team: team,
        onClaim: (id, teamName) => controller.claimTower(id, teamName),
      )..size = Vector2(towerWidth, towerHeight)
       ..position = Vector2(
          spacing + (col * (towerWidth + spacing)),
          spacing + (row * (towerHeight + spacing)),
       ));
    }
  }
}