// features/game/presentation/flame/tower_challenge_game.dart
import 'package:flame/game.dart';
import 'package:get/get.dart';
import '../controllers/game_controller.dart';
import 'components/team_arena_component.dart';
import 'package:flame/events.dart';



class TowerChallengeGame extends FlameGame with TapCallbacks {
  // Hubungkan Flame dengan GetX Controller kita
  final GameController controller = Get.find<GameController>();

  @override
  Future<void> onLoad() async {
    // 1. Tambahkan Arena untuk Team A (Atas)
    add(TeamArenaComponent(
      team: 'A',
      size: Vector2(size.x, size.y / 2),
      position: Vector2(0, 0),
    ));

    // 2. Tambahkan Arena untuk Team B (Bawah)
    add(TeamArenaComponent(
      team: 'B',
      size: Vector2(size.x, size.y / 2),
      position: Vector2(0, size.y / 2),
    ));
  }
}
