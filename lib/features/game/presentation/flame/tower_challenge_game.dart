// features/game/presentation/flame/tower_challenge_game.dart
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:get/get.dart';
import '../controllers/game_controller.dart';
import 'components/team_arena_component.dart';

class TowerChallengeGame extends FlameGame {
  final GameController controller = Get.find<GameController>();

  @override
  Future<void> onLoad() async {
    // Area Team A (Setengah Layar Atas)
    add(TeamArenaComponent(
      team: 'A',
      size: Vector2(size.x, size.y / 2),
      position: Vector2(0, 0),
    ));

    // Area Team B (Setengah Layar Bawah)
    add(TeamArenaComponent(
      team: 'B',
      size: Vector2(size.x, size.y / 2),
      position: Vector2(0, size.y / 2),
    ));
  }
}