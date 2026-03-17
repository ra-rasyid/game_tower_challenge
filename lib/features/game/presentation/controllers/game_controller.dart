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
  var timeLeft = 600.obs; 

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
      int maxBotsA = (userTeam.value == "A") ? 3 : 4;
      int maxBotsB = (userTeam.value == "B") ? 3 : 4;
      int activeBotsA = towersA.where((t) => t.status == TowerStatus.claimed && t.claimedBy != null && t.claimedBy!.startsWith("Bot_A")).length;
      int activeBotsB = towersB.where((t) => t.status == TowerStatus.claimed && t.claimedBy != null && t.claimedBy!.startsWith("Bot_B")).length;
      if (activeBotsA < maxBotsA) _runBotLogic("A");
      if (activeBotsB < maxBotsB) _runBotLogic("B");
    });
  }

  void _runBotLogic(String team) async {
    final towers = (team == "A") ? towersA : towersB;
    Tower? targetTower;
    try {
      targetTower = towers.firstWhere((t) => t.status == TowerStatus.available);
    } catch (e) { targetTower = null; }
    if (targetTower != null) {
      int botNum = 1;
      while (towers.any((t) => t.claimedBy == "Bot_${team}_$botNum")) { botNum++; }
      String botName = "Bot_${team}_$botNum";
      await _db.ref('liveMatches/match123/teams/$team/towers/${targetTower.id}').update({
        "state": "claimed", "claimedBy": botName, "claimedAt": ServerValue.timestamp
      });
      int currentVal = targetTower.startValue;
      while (currentVal != TARGET) {
        await Future.delayed(Duration(milliseconds: 1500 + Random().nextInt(2000)));
        if (timeLeft.value <= 0) return;
        if (currentVal * 2 <= TARGET) {
          currentVal *= 2;
        } else if (currentVal + 10 <= TARGET) {
          currentVal += 10;
        } else {
          // Jika bot kelebihan, bot akan melakukan reset mandiri
          int newStartValue = (Random().nextInt(18) + 2) * 5;
          currentVal = newStartValue;
        }
        await _db.ref('liveMatches/match123/teams/$team/towers/${targetTower.id}').update({"startValue": currentVal});
      }
      _finishSolveByBot(targetTower, team, botName);
    }
  }

  void _finishSolveByBot(Tower tower, String team, String botName) async {
    await _db.ref('liveMatches/match123/teams/$team/towers/${tower.id}').update({
      "state": "solved", "solvedBy": botName, "startValue": 1000
    });
    await _db.ref('liveMatches/match123/teams/$team/score').runTransaction((score) {
      int newScore = (score as int? ?? 0) + 1;
      if (newScore >= 20) _showWinnerDialog("TIM $team");
      return Transaction.success(newScore);
    });
  }

  // --- REVISI: APPLY OPERATION (Biarkan melebihi 1000, notifikasi dihapus) ---
  void applyOperation(bool isMultiply, Tower tower, String team) {
    if (currentValue.value == TARGET) return;

    int nextValue = isMultiply ? currentValue.value * 2 : currentValue.value + 10;
    
    // Batas maksimal sistem tetap dijaga agar tidak crash
    if (nextValue > MAX_VALUE) return;

    currentValue.value = nextValue;
    movesCount.value++;
    towerTimerValue.value = 15; 
    
    _db.ref('liveMatches/match123/teams/$team/towers/${tower.id}').update({"startValue": currentValue.value});
    
    // Hanya finish jika angkanya PAS 1000
    if (currentValue.value == TARGET) {
      _finishSolve(tower, team);
    }
  }

  Future<void> _finishSolve(Tower tower, String team) async {
    _individualTimer?.cancel();
    await _db.ref('liveMatches/match123/teams/$team/towers/${tower.id}').update({
      "state": "solved", "solvedBy": userId, "startValue": 1000
    });
    await _db.ref('liveMatches/match123/teams/$team/score').runTransaction((score) {
      int newScore = (score as int? ?? 0) + 1;
      if (newScore >= 20) _showWinnerDialog("TIM $team");
      return Transaction.success(newScore);
    });
    Future.delayed(const Duration(milliseconds: 800), () => Get.back());
  }

  void _showWinnerDialog(String winnerName) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF6A1B9A),
        title: const Text("MATCH ENDED", textAlign: TextAlign.center, style: TextStyle(color: Colors.yellow)),
        content: Text("SELAMAT!\n$winnerName MENANG!", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
        actions: [TextButton(onPressed: () { Get.close(2); initializeMatch(); }, child: const Text("MAIN LAGI"))],
      ),
      barrierDismissible: false,
    );
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
      "meta": {"status": "running", "durationSec": 600},
      "teams": {"A": {"score": 0, "towers": towers}, "B": {"score": 0, "towers": towers}}
    });
    timeLeft.value = 600;
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