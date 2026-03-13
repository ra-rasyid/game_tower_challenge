// features/game/presentation/controllers/game_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../domain/entities/tower.dart';
import '../pages/tower_detail_page.dart';

class GameController extends GetxController {
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://towerchallenge3008-default-rtdb.asia-southeast1.firebasedatabase.app/',
  );

  var teamAScore = 0.obs;
  var teamBScore = 0.obs;
  var towersA = <Tower>[].obs;
  var towersB = <Tower>[].obs;
  var timeLeft = 300.obs;
  
  var currentValue = 0.obs;
  var movesCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    listenToMatchData();
  }

  // Generate Data Awal
  Future<void> initializeMatch() async {
    final matchRef = _db.ref('liveMatches/match123');
    Map<String, dynamic> towers = {};
    for (int i = 1; i <= 20; i++) {
      towers["tower_$i"] = {"startValue": (i * 12) + 5, "state": "available"};
    }

    await matchRef.set({
      "meta": {"status": "running", "durationSec": 300},
      "teams": {
        "A": {"targetValue": 1000, "score": 0, "towers": towers},
        "B": {"targetValue": 1000, "score": 0, "towers": towers}
      }
    });
  }

  void listenToMatchData() {
    _db.ref('liveMatches/match123/teams/A').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        teamAScore.value = data['score'] ?? 0;
        towersA.value = _parseTowers(data['towers'], data['targetValue'] ?? 1000);
      }
    });

    _db.ref('liveMatches/match123/teams/B').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        teamBScore.value = data['score'] ?? 0;
        towersB.value = _parseTowers(data['towers'], data['targetValue'] ?? 1000);
      }
    });
  }

  List<Tower> _parseTowers(Map? towerMap, int target) {
    if (towerMap == null) return [];
    List<Tower> list = [];
    towerMap.forEach((key, value) {
      list.add(Tower(
        id: key,
        startValue: value['startValue'] ?? 0,
        targetValue: target,
        status: _parseStatus(value['state']),
      ));
    });
    list.sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  TowerStatus _parseStatus(String? s) {
    if (s == 'claimed') return TowerStatus.claimed;
    if (s == 'solved') return TowerStatus.solved;
    return TowerStatus.available;
  }

  void openAttemptOverlay(Tower tower, String team) {
    currentValue.value = tower.startValue;
    movesCount.value = 0;
    Get.to(() => TowerDetailPage(tower: tower, team: team));
  }

  // FUNGSI HITUNG DI DETAIL
  void calculateInDetail(int val, Tower tower, String team, bool isMul) {
    if (isMul) currentValue.value *= val; else currentValue.value += val;
    movesCount.value++;

    if (currentValue.value == tower.targetValue) {
      Get.back(); // Tutup halaman detail
      Get.snackbar("BERHASIL!", "Tower diselesaikan!", 
          backgroundColor: Colors.green, colorText: Colors.white);
      solveTower(tower.id, team, movesCount.value);
    } else if (currentValue.value > 200000) {
      Get.back();
      Get.snackbar("Gagal", "Melebihi limit!");
    }
  }

  // FUNGSI UPDATE FIREBASE (FIXED)
  Future<void> solveTower(String towerId, String team, int moves) async {
    final ref = _db.ref('liveMatches/match123/teams/$team');
    
    await ref.runTransaction((Object? teamData) {
      if (teamData == null) return Transaction.abort();
      
      Map<String, dynamic> data = Map<String, dynamic>.from(teamData as Map);
      
      // Update Skor Tim (+10)
      data['score'] = (data['score'] ?? 0) + 10;
      
      // Kunci nilai tower di 1000 dan ubah status ke solved
      if (data['towers'] != null && data['towers'][towerId] != null) {
        data['towers'][towerId]['startValue'] = 1000;
        data['towers'][towerId]['state'] = 'solved';
      }
      
      return Transaction.success(data);
    });
  }
}