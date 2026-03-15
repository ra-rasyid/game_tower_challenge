// features/game/data/datasources/bot_simulation_service.dart
import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';

class BotSimulationService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final List<Timer> _botTimers = [];

  void startSimulation(int count, String userTeam) {
    stopSimulation();
    
    // Jika user di Tim A, maka: 3 Bot di Tim A, 4 Bot di Tim B (Total 8 player)
    int teamABots = (userTeam == "A") ? 3 : 4;
    int teamBBots = (userTeam == "B") ? 3 : 4;

    for (int i = 0; i < teamABots; i++) _spawnBot("bot_A_$i", "A");
    for (int i = 0; i < teamBBots; i++) _spawnBot("bot_B_$i", "B");
  }

  void _spawnBot(String botId, String team) {
    _botTimers.add(Timer.periodic(Duration(seconds: 5 + Random().nextInt(5)), (timer) async {
      // 1. Cari tower available
      final snapshot = await _db.ref('liveMatches/match123/teams/$team/towers').get();
      if (!snapshot.exists) return;

      Map towers = snapshot.value as Map;
      var availableTowers = towers.entries.where((e) => e.value['state'] == 'available').toList();

      if (availableTowers.isNotEmpty) {
        var targetTower = availableTowers[Random().nextInt(availableTowers.length)];
        _simulateSolve(botId, team, targetTower.key, targetTower.value['startValue']);
      }
    }));
  }

  void _simulateSolve(String botId, String team, String towerId, int startValue) async {
    // Simulasikan delay berpikir manusia
    await Future.delayed(Duration(seconds: 2 + Random().nextInt(3)));
    
    // Langsung update ke Firebase (Sederhananya bot selalu optimal)
    await _db.ref('liveMatches/match123/teams/$team/towers/$towerId').update({
      "state": "solved",
      "solvedBy": botId,
      "startValue": 1000,
    });
    
    await _db.ref('liveMatches/match123/teams/$team/score').runTransaction((score) {
      return Transaction.success((score as int? ?? 0) + 10);
    });
  }

  void stopSimulation() {
    for (var t in _botTimers) t.cancel();
    _botTimers.clear();
  }
}