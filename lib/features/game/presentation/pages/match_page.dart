// features/game/presentation/pages/match_page.dart
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:get/get.dart';
import '../controllers/game_controller.dart';
import '../flame/tower_challenge_game.dart';

class MatchPage extends StatelessWidget {
  const MatchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(GameController());

    return Scaffold(
      backgroundColor: const Color(0xFF81C784),
      body: Stack(
        children: [
          GameWidget(game: TowerChallengeGame()),
          Positioned(
            top: 50, left: 30, right: 30,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _score("TEAM A", controller.teamAScore, Colors.greenAccent),
                  const Text("VS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  _score("TEAM B", controller.teamBScore, Colors.yellowAccent),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => controller.initializeMatch(), // Reset Global
        label: const Text("GLOBAL RESET"),
        icon: const Icon(Icons.refresh),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Widget _score(String label, RxInt val, Color col) => Column(children: [Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)), Obx(() => Text("${val.value}", style: TextStyle(color: col, fontSize: 24, fontWeight: FontWeight.bold)))]);
}