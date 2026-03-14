// features/game/presentation/controllers/game_controller.dart
import 'dart:async';
import 'dart:math';
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
  var timeLeft = 30.obs;

  final String userId = "user_ragil"; 
  var players = {}.obs; 
  var afkTimeSeconds = 0.obs;
  
  var currentValue = 0.obs;
  var movesCount = 0.obs;
  var towerTimerValue = 15.obs; // Timer AFK individu per tower
  DateTime? towerStartTime;

  Timer? _matchTimer;
  Timer? _presenceTimer;
  Timer? _individualTowerTimer; 

  @override
  void onInit() {
    super.onInit();
    listenToMatchData();
    listenToPlayersPresence();
    startMatchTimer();
    startPresenceUpdates(); 
  }

  // --- FITUR: RESET GLOBAL & ANGKA KELIPATAN 5/10 ---
  Future<void> initializeMatch() async {
    final matchRef = _db.ref('liveMatches/match123');
    Map<String, dynamic> towers = {};
    final random = Random();

    for (int i = 1; i <= 20; i++) {
      int base = random.nextInt(18) + 2; 
      int generatedValue = base * 5; // Menghasilkan 10, 15, 20, dll.

      towers["tower_$i"] = {
        "startValue": generatedValue, 
        "state": "available"
      };
    }

    await matchRef.set({
      "meta": {"status": "running", "durationSec": 30},
      "teams": {
        "A": {"targetValue": 1000, "score": 0, "towers": towers},
        "B": {"targetValue": 1000, "score": 0, "towers": towers}
      }
    });
    
    timeLeft.value = 30;
    startMatchTimer();
    Get.snackbar("GLOBAL RESET", "Pertandingan dimulai ulang!");
  }

  // --- FITUR: RESET TOWER INDIVIDU ---
  Future<void> resetSingleTower(Tower tower, String team) async {
    final random = Random();
    int base = random.nextInt(18) + 2; 
    int newStartValue = base * 5;

    await _db.ref('liveMatches/match123/teams/$team/towers/${tower.id}').update({
      "startValue": newStartValue,
      "state": "claimed",
      "claimedBy": userId
    });

    currentValue.value = newStartValue;
    movesCount.value = 0;
    towerTimerValue.value = 15; // Reset timer individu
    
    Get.snackbar("TOWER RESET", "Angka tower diacak ulang!");
  }

  void startPresenceUpdates() {
    _presenceTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (timeLeft.value <= 0) return;
      _db.ref('liveMatches/match123/players/$userId').update({
        "lastSeenAt": ServerValue.timestamp,
        "name": "Ragil",
        "isAFK": false,
      });
    });
  }

  void listenToPlayersPresence() {
    _db.ref('liveMatches/match123/players').onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map data = Map.from(event.snapshot.value as Map);
        int now = DateTime.now().millisecondsSinceEpoch;
        data.forEach((key, value) {
          int lastSeen = value['lastSeenAt'] ?? 0;
          bool currentlyAFK = (now - lastSeen) > 30000;
          if (key == userId && currentlyAFK && value['isAFK'] != true) {
             _handleSelfAFK();
          }
          value['isAFK'] = currentlyAFK;
        });
        players.value = data;
      }
    });
  }

  void _handleSelfAFK() {
    _individualTowerTimer?.cancel(); 
    if (Get.currentRoute.contains('TowerDetailPage')) {
      Get.back();
      Get.snackbar("AFK DETECTED", "Tower dilepaskan!");
    }
  }

  void startMatchTimer() {
    _matchTimer?.cancel();
    _matchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft.value > 0) {
        timeLeft.value--;
      } else {
        _timerFinish();
      }
    });
  }

  void _timerFinish() {
    _matchTimer?.cancel();
    _individualTowerTimer?.cancel();
    if (Get.currentRoute.contains('TowerDetailPage')) Get.back();
    Get.snackbar("FINISH", "Waktu Habis!");
  }

  void openAttemptOverlay(Tower tower, String team) {
    if (timeLeft.value <= 0) return;
    if (tower.status == TowerStatus.claimed && tower.claimedBy != userId) return;

    currentValue.value = tower.startValue;
    movesCount.value = 0;
    towerStartTime = DateTime.now();

    _db.ref('liveMatches/match123/teams/$team/towers/${tower.id}').update({
      "state": "claimed",
      "claimedBy": userId,
      "claimedAt": ServerValue.timestamp
    });

    startIndividualTowerTimer(tower.id, team);
    Get.to(() => TowerDetailPage(tower: tower, team: team));
  }

  void startIndividualTowerTimer(String towerId, String team) {
    _individualTowerTimer?.cancel();
    towerTimerValue.value = 15;
    _individualTowerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (towerTimerValue.value > 0) {
        towerTimerValue.value--;
      } else {
        timer.cancel();
        _releaseTower(towerId, team);
        if (Get.currentRoute.contains('TowerDetailPage')) Get.back();
      }
    });
  }

  void calculateInDetail(int val, Tower tower, String team, bool isMul) {
    towerTimerValue.value = 15; // Reset timer tiap klik
    if (isMul) currentValue.value *= val; else currentValue.value += val;
    movesCount.value++;

    _db.ref('liveMatches/match123/players/$userId').update({"lastSeenAt": ServerValue.timestamp});
    updateTowerProgress(tower.id, team, currentValue.value);

    if (currentValue.value == tower.targetValue) {
      _individualTowerTimer?.cancel();
      _finishSolve(tower, team);
    }
  }

  void _releaseTower(String towerId, String team) {
    _db.ref('liveMatches/match123/teams/$team/towers/$towerId').update({
      "state": "available",
      "claimedBy": null,
      "claimedAt": null
    });
  }

  Future<void> _finishSolve(Tower tower, String team) async {
    await _db.ref('liveMatches/match123/teams/$team/towers/${tower.id}').update({
      "state": "solved",
      "startValue": 1000
    });
    // Update Score Tim
    final teamRef = _db.ref('liveMatches/match123/teams/$team');
    await teamRef.runTransaction((Object? data) {
      if (data == null) return Transaction.abort();
      Map<String, dynamic> teamData = Map<String, dynamic>.from(data as Map);
      teamData['score'] = (teamData['score'] ?? 0) + 10;
      return Transaction.success(teamData);
    });
    Get.back();
  }

  Future<void> updateTowerProgress(String towerId, String team, int val) async {
    await _db.ref('liveMatches/match123/teams/$team/towers/$towerId').update({"startValue": val});
  }

  void listenToMatchData() {
    _db.ref('liveMatches/match123/teams/A').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        teamAScore.value = data['score'] ?? 0;
        towersA.value = _parseTowers(data['towers'], 1000, 'A');
      }
    });
    _db.ref('liveMatches/match123/teams/B').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        teamBScore.value = data['score'] ?? 0;
        towersB.value = _parseTowers(data['towers'], 1000, 'B');
      }
    });
  }

  List<Tower> _parseTowers(Map? towerMap, int target, String team) {
    if (towerMap == null) return [];
    List<Tower> list = [];
    towerMap.forEach((key, value) {
      list.add(Tower(
        id: key,
        startValue: value['startValue'] ?? 0,
        targetValue: target,
        status: value['state'] == 'solved' ? TowerStatus.solved : (value['state'] == 'claimed' ? TowerStatus.claimed : TowerStatus.available),
        claimedBy: value['claimedBy'],
      ));
    });
    list.sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  @override
  void onClose() {
    _presenceTimer?.cancel();
    _matchTimer?.cancel();
    _individualTowerTimer?.cancel();
    super.onClose();
  }
}