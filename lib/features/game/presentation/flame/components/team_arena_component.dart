// features/game/presentation/flame/components/team_arena_component.dart
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
  
  // Hapus _lastCount karena kita ingin update setiap ada perubahan nilai startValue
  // Kita akan membandingkan data mentah untuk re-render

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
    towerContainer.x = nextX.clamp(-(20 * 95.0) + size.x, 0); 
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Observe perubahan data dari GetX secara realtime
    final currentData = team == 'A' ? controller.towersA : controller.towersB;
    
    // Refresh jika jumlah tower berubah atau isi startValue tower berubah
    _refreshIfChanged(currentData);
  }

  void _refreshIfChanged(List currentData) {
    // Logika sederhana: jika jumlah anak berbeda atau kita ingin sinkronisasi nilai
    // Di produksi, sebaiknya gunakan perbandingan ID dan Value yang lebih spesifik
    if (towerContainer.children.length != currentData.length) {
      _refresh(currentData);
    } else {
      // Update nilai startValue pada TowerComponent yang sudah ada tanpa re-render seluruh list
      final children = towerContainer.children.whereType<TowerComponent>().toList();
      for (int i = 0; i < children.length; i++) {
        if (children[i].tower.startValue != currentData[i].startValue || 
            children[i].tower.status != currentData[i].status) {
          _refresh(currentData); // Re-render jika ada nilai yang tidak sinkron
          break;
        }
      }
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