// features/game/presentation/controllers/game_controller.dart
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../domain/entities/tower.dart';
import 'package:firebase_core/firebase_core.dart';

class GameController extends GetxController {
  // Masukkan URL yang kamu copy tadi di sini
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://towerchallenge3008-default-rtdb.asia-southeast1.firebasedatabase.app/',
  );
  
  // State variables yang reaktif
  var teamAScore = 0.obs;
  var teamBScore = 0.obs;
  var towersA = <Tower>[].obs;
  var towersB = <Tower>[].obs;
  var timeLeft = 300.obs; // 5 menit dalam detik

  @override
  void onInit() {
    super.onInit();
    listenToMatchData();
  }

  void listenToMatchData() {
    // Listen skor dan tower secara realtime dari Firebase
    _db.ref('liveMatches/match123/teams/A').onValue.listen((event) {
      // Nanti kita mapping data snapshot ke List<Tower> di sini
      print("Data Team A update!");
    });
  }

  // Fungsi untuk klaim tower (Menggunakan Transaction)
  Future<void> claimTower(String towerId, String team) async {
    final towerRef = _db.ref('liveMatches/match123/teams/$team/towers/$towerId');
    
    try {
      await towerRef.runTransaction((Object? tower) {
        if (tower == null) return Transaction.abort();
        
        Map<String, dynamic> towerData = Map<String, dynamic>.from(tower as Map);
        
        // Cek apakah sudah diklaim orang lain
        if (towerData['state'] != 'available') {
          return Transaction.abort();
        }

        // Update status jadi claimed
        towerData['state'] = 'claimed';
        towerData['claimedBy'] = 'user_ragil'; // Nanti pakai ID user asli
        towerData['claimExpiresAt'] = ServerValue.timestamp;

        return Transaction.success(towerData);
      });
    } catch (e) {
      Get.snackbar("Gagal", "Tower sudah diambil orang lain!");
    }
  }
}