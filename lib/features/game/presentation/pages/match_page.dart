// features/game/presentation/pages/match_page.dart
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:get/get.dart';
import '../controllers/game_controller.dart';
import '../flame/tower_challenge_game.dart';
import '../../data/datasources/bot_simulation_service.dart'; // Sesuaikan path ini

class MatchPage extends StatelessWidget {
  const MatchPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Memastikan Controller sudah terinisialisasi
    final controller = Get.put(GameController());
    final botService = BotSimulationService();

    return Scaffold(
      backgroundColor: const Color(0xFF81C784),
      body: Stack(
        children: [
          // 1. FLAME ENGINE LAYER
          GameWidget(game: TowerChallengeGame()),

          // 2. SCOREBOARD OVERLAY (Atas)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _scoreTile("TEAM A", controller.teamAScore, Colors.greenAccent),
                  Column(
                    children: [
                      const Text("TIME LEFT", 
                        style: TextStyle(color: Colors.white70, fontSize: 10)),
                      Obx(() => Text(
                        _formatDuration(controller.timeLeft.value),
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 20, 
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Courier'
                        ),
                      )),
                    ],
                  ),
                  _scoreTile("TEAM B", controller.teamBScore, Colors.yellowAccent),
                ],
              ),
            ),
          ),

          // 3. TEAM INDICATOR (Kiri Bawah)
          Positioned(
            bottom: 100,
            left: 20,
            child: Obx(() => Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "YOUR TEAM: ${controller.userTeam.value}",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )),
          ),
        ],
      ),

      // 4. FLOATING ACTION BUTTONS (Controls)
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Tombol Pilih Tim (Toggle A/B)
          FloatingActionButton.small(
            heroTag: "btn_team",
            onPressed: () {
              controller.userTeam.value = (controller.userTeam.value == "A") ? "B" : "A";
              Get.snackbar("TEAM CHANGED", "You are now in Team ${controller.userTeam.value}");
            },
            backgroundColor: Colors.orange,
            child: const Icon(Icons.group_add),
          ),
          const SizedBox(height: 10),
          
          // Tombol Launch Bots (MANDATORY: Simulation Mode)
          FloatingActionButton.extended(
            heroTag: "btn_bot",
            onPressed: () {
              botService.startSimulation(7, controller.userTeam.value);
              Get.snackbar("SIMULATION", "7 Bots have joined the match!");
            },
            label: const Text("LAUNCH BOTS"),
            icon: const Icon(Icons.smart_toy),
            backgroundColor: Colors.blueAccent,
          ),
          const SizedBox(height: 10),

          // Tombol Reset Global
          FloatingActionButton.extended(
            heroTag: "btn_reset",
            onPressed: () {
              botService.stopSimulation();
              controller.initializeMatch();
            },
            label: const Text("GLOBAL RESET"),
            icon: const Icon(Icons.refresh),
            backgroundColor: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  // Widget Helper untuk Score
  Widget _scoreTile(String label, RxInt val, Color col) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
        Obx(() => Text(
          "${val.value}", 
          style: TextStyle(color: col, fontSize: 28, fontWeight: FontWeight.bold)
        )),
      ],
    );
  }

  // Helper Format Waktu (MM:SS)
  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}