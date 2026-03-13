// features/game/presentation/flame/components/team_arena_component.dart
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'tower_component.dart';
import 'package:get/get.dart';
import '../../controllers/game_controller.dart';

class TeamArenaComponent extends PositionComponent with DragCallbacks {
  final String team;
  final GameController controller = Get.find();
  late PositionComponent towerContainer;
  int _lastCount = 0;

  TeamArenaComponent({required this.team, required Vector2 size, required Vector2 position}) 
      : super(size: size, position: position);

  @override
  Future<void> onLoad() async {
    towerContainer = PositionComponent();
    add(towerContainer);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    double nextX = towerContainer.x + event.localDelta.x;
    // Limit geser agar tidak hilang dari layar
    towerContainer.x = nextX.clamp(-(20 * 95.0) + size.x, 0); 
  }

  @override
  void update(double dt) {
    super.update(dt);
    final currentData = team == 'A' ? controller.towersA : controller.towersB;
    
    if (currentData.length != _lastCount || (currentData.isNotEmpty && towerContainer.children.isEmpty)) {
      _refresh(currentData);
      _lastCount = currentData.length;
    }
  }

  void _refresh(newData) {
    towerContainer.removeAll(towerContainer.children.whereType<TowerComponent>());
    for (int i = 0; i < newData.length; i++) {
      towerContainer.add(TowerComponent(
        tower: newData[i],
        team: team,
        onClaim: (id, t) => controller.openAttemptOverlay(newData[i], t),
      )..size = Vector2(65, size.y * 0.75)
       ..position = Vector2(20 + (i * 95.0), size.y * 0.15));
    }
  }
}