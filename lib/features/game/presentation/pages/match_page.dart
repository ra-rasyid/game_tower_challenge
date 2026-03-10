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
      body: Stack(
        children: [
          // INI INTI GAME-NYA: Flame Engine
          GameWidget(
            game: TowerChallengeGame(),
          ),

          // Overlay Flutter (Untuk Scoreboard & Timer)
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() => Text("Team A: ${controller.teamAScore}", 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                Obx(() => Text("Time: ${controller.timeLeft}s", 
                    style: TextStyle(fontSize: 20, color: Colors.red))),
                Obx(() => Text("Team B: ${controller.teamBScore}", 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}