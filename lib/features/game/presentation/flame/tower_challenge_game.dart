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
    // Karena panel skor tingginya 120, kita mulai Arena A di y: 120
    double headerHeight = 120.0;
    double arenaHeight = (size.y - headerHeight) / 2;

    // Area Team A (Atas - Di bawah panel skor)
    add(TeamArenaComponent(
      team: 'A',
      size: Vector2(size.x, arenaHeight),
      position: Vector2(0, headerHeight),
    ));

    // Area Team B (Bawah)
    add(TeamArenaComponent(
      team: 'B',
      size: Vector2(size.x, arenaHeight),
      position: Vector2(0, headerHeight + arenaHeight),
    ));
  }
}