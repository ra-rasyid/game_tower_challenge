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
    // Inisialisasi controller agar bisa diakses di seluruh widget tree ini
    final controller = Get.put(GameController());

    return Scaffold(
      body: Stack(
        children: [
          // 1. INTI GAME: Flame Engine sebagai background
          GameWidget(
            game: TowerChallengeGame(),
          ),

          // 2. OVERLAY UI: Scoreboard & Timer
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skor Team A
                  Column(
                    children: [
                      const Text("TEAM A", style: TextStyle(color: Colors.white, fontSize: 12)),
                      Obx(() => Text(
                        "${controller.teamAScore}", 
                        style: const TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold)
                      )),
                    ],
                  ),

                  // Timer
                  Column(
                    children: [
                      const Text("TIME", style: TextStyle(color: Colors.white, fontSize: 12)),
                      Obx(() => Text(
                        "${controller.timeLeft}s", 
                        style: const TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold)
                      )),
                    ],
                  ),

                  // Skor Team B
                  Column(
                    children: [
                      const Text("TEAM B", style: TextStyle(color: Colors.white, fontSize: 12)),
                      Obx(() => Text(
                        "${controller.teamBScore}", 
                        style: const TextStyle(color: Colors.yellow, fontSize: 24, fontWeight: FontWeight.bold)
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // 3. SEEDING BUTTON: Untuk mengisi data awal ke Firebase
      // Klik tombol ini jika layar masih hitam/kosong
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => controller.initializeMatch(),
        label: const Text("Reset/Generate Match"),
        icon: const Icon(Icons.refresh),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}