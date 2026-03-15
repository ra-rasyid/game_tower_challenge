// features/game/presentation/pages/tower_detail_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/game_controller.dart';
import 'package:tower_challenge/features/game/domain/entities/tower.dart';

class TowerDetailPage extends StatelessWidget {
  final Tower tower;
  final String team;
  const TowerDetailPage({super.key, required this.tower, required this.team});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GameController>();

    return Scaffold(
      backgroundColor: const Color(0xFF9E86FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Get.back()),
                    _buildHeaderBox("TOWER TIME", controller.towerTimerValue), // Timer 15s individu
                    _buildHeaderBox("MOVES", controller.movesCount),
                  ],
                ),
                const SizedBox(height: 30),
                Obx(() {
                  double progress = (controller.currentValue.value / tower.targetValue).clamp(0.0, 1.0);
                  Color barColor = controller.currentValue.value >= 800 ? const Color(0xFF6A1B9A) : const Color(0xFF4DD0E1);
                  return Column(
                    children: [
                      Text("${controller.currentValue.value}", style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      // TOMBOL RESET INDIVIDU
                      TextButton.icon(
                        onPressed: () => controller.resetSingleTower(tower, team),
                        icon: const Icon(Icons.restore, color: Colors.white70),
                        label: const Text("Reset Tower", style: TextStyle(color: Colors.white70)),
                      ),
                      const SizedBox(height: 10),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 100,
                        height: 300 * progress,
                        decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white, width: 3)),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: _buildOpButton(
                        "+10", 
                        const Color(0xFFD39B6F), 
                        () => controller.applyOperation(false, tower, team), // Ganti ke applyOperation
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildOpButton(
                        "X2", 
                        const Color(0xFFD4C16E), 
                        () => controller.applyOperation(true, tower, team), // Ganti ke applyOperation
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBox(String label, RxInt rxValue) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
          Obx(() => Text("${rxValue.value}s", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildOpButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20), boxShadow: [const BoxShadow(color: Colors.black26, offset: Offset(0, 4))]),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF4E342E))),
      ),
    );
  }
}