// features/game/presentation/pages/tower_detail_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/game_controller.dart';
import 'package:tower_challenge/features/game/domain/entities/tower.dart'; // Sesuaikan package name-mu

class TowerDetailPage extends StatelessWidget {
  final Tower tower;
  final String team;
  const TowerDetailPage({super.key, required this.tower, required this.team});

  @override
  Widget build(BuildContext context) {
    // Pakai Get.find untuk ambil controller yang sudah ada
    final controller = Get.find<GameController>();

    return Scaffold(
      backgroundColor: const Color(0xFF9E86FF),
      body: SafeArea(
        child: SingleChildScrollView( // Agar tidak overflow
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                    _buildHeaderBox("TIME", controller.timeLeft), // Kirim RxInt-nya langsung
                    _buildHeaderBox("MOVES", controller.movesCount),
                  ],
                ),
                
                const SizedBox(height: 30),
                Text("Target: ${tower.targetValue}", 
                    style: const TextStyle(color: Colors.white70, fontSize: 18)),

                // TOWER VISUAL
                const SizedBox(height: 20),
                Obx(() {
                  // Sekarang Obx aman karena kita manggil controller.currentValue.value
                  double progress = (controller.currentValue.value / tower.targetValue).clamp(0.0, 1.0);
                  
                  // Warna Ungu jika mau sampai 1000, jika tidak Hijau/Tosca
                  Color barColor = controller.currentValue.value >= 800 
                      ? const Color(0xFF6A1B9A) 
                      : const Color(0xFF4DD0E1);

                  return Column(
                    children: [
                      Text("${controller.currentValue.value}", 
                          style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 100,
                        height: 300 * progress, // Tower naik turun
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ],
                  );
                }),

                const SizedBox(height: 40),
                // TOMBOL OPERASI
                Row(
                  children: [
                    Expanded(child: _buildOpButton("+10", const Color(0xFFD39B6F), 
                        () => controller.calculateInDetail(10, tower, team, false))),
                    const SizedBox(width: 20),
                    Expanded(child: _buildOpButton("X2", const Color(0xFFD4C16E), 
                        () => controller.calculateInDetail(2, tower, team, true))),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget pembantu Header dengan Obx internal
  Widget _buildHeaderBox(String label, RxInt rxValue) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
          Obx(() => Text("${rxValue.value}", // Panggil .value di sini
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildOpButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80, // Ukuran diperkecil dikit biar pas
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [const BoxShadow(color: Colors.black26, offset: Offset(0, 4))],
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF4E342E))),
      ),
    );
  }
}