// features/game/presentation/controllers/game_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../domain/entities/tower.dart';

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

  // --- FUNGSI GENERATE DATA AWAL ---
  Future<void> initializeMatch() async {
    final matchRef = _db.ref('liveMatches/match123');
    Map<String, dynamic> towers = {};
    for (int i = 1; i <= 20; i++) {
      towers["tower_$i"] = {"startValue": (i * 10) + 5, "state": "available"};
    }

    await matchRef.set({
      "meta": {"status": "running", "durationSec": 300},
      "teams": {
        "A": {"targetValue": 1000, "score": 0, "towers": towers},
        "B": {"targetValue": 1000, "score": 0, "towers": towers}
      }
    });
    Get.snackbar("Selesai", "Data A dan B sudah siap di Firebase!");
  }

  // --- SYNC REALTIME KEDUA TIM ---
  void listenToMatchData() {
    // Stream Team A
    _db.ref('liveMatches/match123/teams/A').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        teamAScore.value = data['score'] ?? 0;
        towersA.value = _parseTowers(data['towers'], data['targetValue'] ?? 1000);
      }
    });

    // Stream Team B
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
    list.sort((a, b) => a.id.compareTo(b.id)); // Urutkan biar ga gerak-gerak
    return list;
  }

  TowerStatus _parseStatus(String? s) {
    if (s == 'claimed') return TowerStatus.claimed;
    if (s == 'solved') return TowerStatus.solved;
    return TowerStatus.available;
  }

  // --- MODAL DETAIL (DENGAN SCROLL BIAR GA OVERFLOW) ---
  void openAttemptOverlay(Tower tower, String team) {
    currentValue.value = tower.startValue;
    movesCount.value = 0;

    Get.bottomSheet(
      Container(
        height: Get.height * 0.75,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF7E57C2),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView( // <--- ANTI OVERFLOW
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoBox("Timer", "${timeLeft.value}s"),
                  _infoBox("Moves", "${movesCount.value}"),
                ],
              ),
              const SizedBox(height: 40),
              Text("Target: ${tower.targetValue}", style: const TextStyle(color: Colors.white70)),
              Obx(() => Text("${currentValue.value}", 
                  style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold))),
              const SizedBox(height: 50),
              Row(
                children: [
                  Expanded(child: _opBtn("+10", const Color(0xFFD39B6F), () => _calc(10, tower, team, false))),
                  const SizedBox(width: 20),
                  Expanded(child: _opBtn("X2", const Color(0xFFD4C16E), () => _calc(2, tower, team, true))),
                ],
              ),
              const SizedBox(height: 30),
              TextButton(onPressed: () => Get.back(), child: const Text("BATAL", style: TextStyle(color: Colors.white))),
            ],
          ),
        ),
      ),
      isDismissible: false,
    );
  }

  Widget _infoBox(String l, String v) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
    child: Column(children: [Text(l, style: const TextStyle(color: Colors.white, fontSize: 10)), Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
  );

  Widget _opBtn(String l, Color c, VoidCallback t) => GestureDetector(
    onTap: t,
    child: Container(
      height: 100,
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(20), boxShadow: [const BoxShadow(color: Colors.black26, offset: Offset(0, 5))]),
      alignment: Alignment.center,
      child: Text(l, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF4E342E))),
    ),
  );

  void _calc(int v, Tower t, String team, bool mul) {
    if (mul) currentValue.value *= v; else currentValue.value += v;
    movesCount.value++;
    if (currentValue.value == t.targetValue) {
      Get.back();
      _db.ref('liveMatches/match123/teams/$team').runTransaction((obj) {
        if (obj == null) return Transaction.abort();
        Map d = Map.from(obj as Map);
        d['score'] = (d['score'] ?? 0) + 10;
        d['towers'][t.id]['state'] = 'solved';
        return Transaction.success(d);
      });
    }
  }
}