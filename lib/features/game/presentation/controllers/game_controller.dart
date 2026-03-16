// features/game/presentation/controllers/game_controller.dart
import 'dart:async';
import 'dart:math';
import 'dart:collection';
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

  final String userId = "user_ragil"; 
  var userTeam = "A".obs; 
  var players = {}.obs;
  
  var currentValue = 0.obs;
  var movesCount = 0.obs;
  var towerTimerValue = 15.obs; 
  
  Timer? _matchTimer;
  Timer? _presenceTimer;
  Timer? _individualTimer;
  Timer? _botEngineTimer; 

  static const int MAX_VALUE = 200000;
  static const int TARGET = 1000;

  @override
  void onInit() {
    super.onInit();
    listenToMatchData();
    listenToPlayersPresence();
    startMatchTimer();
    startPresenceUpdates();
    _startBotEngine();
  }

  int calculateOptimalMoves(int start, int target) {
    if (start == target) return 0;
    Queue<int> queue = Queue()..add(start);
    Map<int, int> dist = {start: 0};
    while (queue.isNotEmpty) {
      int current = queue.removeFirst();
      int d = dist[current]!;
      for (int next in [current + 10, current * 2]) {
        if (next == target) return d + 1;
        if (next > 0 && next <= MAX_VALUE && !dist.containsKey(next)) {
          dist[next] = d + 1;
          queue.add(next);
        }
      }
    }
    return -1; 
  }

  Future<void> openAttemptOverlay(Tower tower, String team) async {
    if (team != userTeam.value) {
      Get.snackbar("ACCESS DENIED", "Anda di Tim ${userTeam.value}!");
      return;
    }
    if (timeLeft.value <= 0 || tower.status == TowerStatus.solved) return;
    if (tower.status == TowerStatus.claimed && tower.claimedBy != userId) {
      Get.snackbar("FAILED", "Tower sedang dikerjakan pemain lain!");
      return;
    }
    if (tower.claimedBy == userId) {
      _enterTower(tower, team);
      return;
    }
    final towerRef = _db.ref('liveMatches/match123/teams/$team/towers/${tower.id}');
    final result = await towerRef.runTransaction((Object? towerData) {
      if (towerData == null) return Transaction.abort();
      Map<String, dynamic> data = Map<String, dynamic>.from(towerData as Map);
      if (data['state'] == 'available') {
        data['state'] = 'claimed';
        data['claimedBy'] = userId;
        data['claimedAt'] = ServerValue.timestamp;
        return Transaction.success(data);
      }
      return Transaction.abort();
    });
    if (result.committed) {
      _enterTower(tower, team);
    }
  }

  void _enterTower(Tower tower, String team) {
    currentValue.value = tower.startValue;
    movesCount.value = 0; 
    startIndividualTimer(tower.id, team);
    Get.to(() => TowerDetailPage(tower: tower, team: team));
  }

  void _startBotEngine() {
    _botEngineTimer?.cancel();
    _botEngineTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (timeLeft.value <= 0) return;
      _runBotLogic("A");
      _runBotLogic("B");
    });
  }

  void _runBotLogic(String team) async {
    final towers = (team == "A") ? towersA : towersB;
    var available = towers.where((t) => t.status == TowerStatus.available).toList();
    
    if (available.isNotEmpty) {
      var targetTower = available[Random().nextInt(available.length)];
      String botName = "Bot_${team}_${Random().nextInt(100)}";

      await _db.ref('liveMatches/match123/teams/$team/towers/${targetTower.id}').update({
        "state": "claimed",
        "claimedBy": botName,
        "claimedAt": ServerValue.timestamp
      });

      int currentVal = targetTower.startValue;
      int movesNeeded = calculateOptimalMoves(currentVal, TARGET);
      
      for (int i = 0; i < movesNeeded; i++) {
        await Future.delayed(Duration(milliseconds: 1500 + Random().nextInt(2000)));
        if (currentVal * 2 <= TARGET && (TARGET - (currentVal * 2)) < (TARGET - (currentVal + 10))) {
          currentVal *= 2;
        } else {
          currentVal += 10;
        }
        await _db.ref('liveMatches/match123/teams/$team/towers/${targetTower.id}').update({
          "startValue": currentVal
        });
      }
      _finishSolveByBot(targetTower, team, botName, movesNeeded);
    }
  }

  void _finishSolveByBot(Tower tower, String team, String botName, int moves) async {
    await _db.ref('liveMatches/match123/teams/$team/towers/${tower.id}').update({
      "state": "solved",
      "solvedBy": botName,
      "movesTaken": moves,
      "optimalMoves": moves,
      "startValue": 1000
    });

    await _db.ref('liveMatches/match123/teams/$team/score').runTransaction((score) {
      return Transaction.success((score as int? ?? 0) + 1); // Skor berdasarkan jumlah tower solved
    });
    // REVISI: Regenerasi dihapus agar tower tetap di situ
  }

  void applyOperation(bool isMultiply, Tower tower, String team) {
    if (currentValue.value >= TARGET) return;
    int nextValue = isMultiply ? currentValue.value * 2 : currentValue.value + 10;
    if (nextValue > MAX_VALUE) return;
    
    currentValue.value = nextValue;
    movesCount.value++;
    towerTimerValue.value = 15; 
    
    _db.ref('liveMatches/match123/teams/$team/towers/${tower.id}').update({"startValue": currentValue.value});
    
    if (currentValue.value >= TARGET) {
      _finishSolve(tower, team);
    }
  }

  Future<void> resetSingleTower(Tower tower, String team) async {
    int newStartValue = (Random().nextInt(18) + 2) * 5;
    await _db.ref('liveMatches/match123/teams/$team/towers/${tower.id}').update({
      "startValue": newStartValue, "state": "claimed", "claimedBy": userId
    });
    currentValue.value = newStartValue;
    movesCount.value = 0;
    towerTimerValue.value = 15;
  }

  Future<void> _finishSolve(Tower tower, String team) async {
    _individualTimer?.cancel();
    int optimal = calculateOptimalMoves(tower.startValue, TARGET);
    await _db.ref('liveMatches/match123/teams/$team/towers/${tower.id}').update({
      "state": "solved", "solvedBy": userId, "movesTaken": movesCount.value, "optimalMoves": optimal, "startValue": 1000
    });
    await _db.ref('liveMatches/match123/teams/$team/score').runTransaction((score) => Transaction.success((score as int? ?? 0) + 1));
    // REVISI: Regenerasi dihapus agar tower tidak berganti
    Future.delayed(const Duration(milliseconds: 800), () => Get.back());
  }

  void startMatchTimer() {
    _matchTimer?.cancel();
    _matchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft.value > 0) timeLeft.value--;
    });
  }

  void startIndividualTimer(String towerId, String team) {
    towerTimerValue.value = 15;
    _individualTimer?.cancel();
    _individualTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (towerTimerValue.value > 0) {
        towerTimerValue.value--;
      } else {
        _db.ref('liveMatches/match123/teams/$team/towers/$towerId').update({"state": "available", "claimedBy": null});
        if (Get.currentRoute.contains('TowerDetailPage')) Get.back();
        timer.cancel();
      }
    });
  }

  void listenToMatchData() {
    _db.ref('liveMatches/match123/teams/A').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        teamAScore.value = data['score'] ?? 0;
        towersA.value = _parseTowers(data['towers']);
      }
    });
    _db.ref('liveMatches/match123/teams/B').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        teamBScore.value = data['score'] ?? 0;
        towersB.value = _parseTowers(data['towers']);
      }
    });
  }

  List<Tower> _parseTowers(Map? towerMap) {
    if (towerMap == null) return [];
    List<Tower> list = [];
    towerMap.forEach((key, value) {
      list.add(Tower(
        id: key,
        startValue: value['startValue'] ?? 0,
        targetValue: TARGET,
        status: value['state'] == 'solved' ? TowerStatus.solved : (value['state'] == 'claimed' ? TowerStatus.claimed : TowerStatus.available),
        claimedBy: value['claimedBy'],
      ));
    });
    list.sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  void startPresenceUpdates() {
    _presenceTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _db.ref('liveMatches/match123/players/$userId').update({"lastSeenAt": ServerValue.timestamp, "name": "Ragil", "team": userTeam.value});
    });
  }

  void listenToPlayersPresence() {
    _db.ref('liveMatches/match123/players').onValue.listen((event) {
      if (event.snapshot.value != null) players.value = Map.from(event.snapshot.value as Map);
    });
  }

  Future<void> initializeMatch() async {
    final matchRef = _db.ref('liveMatches/match123');
    Map<String, dynamic> towers = {};
    for (int i = 1; i <= 20; i++) {
      int val = (Random().nextInt(18) + 2) * 5;
      towers["tower_$i"] = {"startValue": val, "state": "available"};
    }
    await matchRef.set({
      "meta": {"status": "running", "durationSec": 300},
      "teams": {"A": {"score": 0, "towers": towers}, "B": {"score": 0, "towers": towers}}
    });
    timeLeft.value = 300;
  }

  @override
  void onClose() {
    _matchTimer?.cancel();
    _presenceTimer?.cancel();
    _individualTimer?.cancel();
    _botEngineTimer?.cancel();
    super.onClose();
  }
}