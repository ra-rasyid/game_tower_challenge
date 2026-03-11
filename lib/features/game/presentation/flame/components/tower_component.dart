// features/game/presentation/flame/components/tower_component.dart
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../../domain/entities/tower.dart';

class TowerComponent extends PositionComponent with TapCallbacks {
  final Tower tower;
  final String team;
  final Function(String, String) onClaim;

  TowerComponent({
    required this.tower,
    required this.team,
    required this.onClaim,
  }) : super(size: Vector2(60, 180)); // Ukuran tower lebih tinggi

  @override
  void render(Canvas canvas) {
    // 1. Gambar Background Tower (Warna Ungu Gelap sesuai desain)
    final bgPaint = Paint()..color = const Color(0xFF6A1B9A);
    final bgRect = RRect.fromRectAndRadius(
      size.toRect(),
      const Radius.circular(12),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // 2. Hitung Tinggi Progress (Max 1000)
    double progressRatio = (tower.startValue / tower.targetValue).clamp(0.0, 1.0);
    double progressHeight = size.y * progressRatio;

    // 3. Gambar Isi Progress (Warna Tosca/Biru Muda)
    final progressPaint = Paint()..color = const Color(0xFF4DD0E1);
    final progressRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.y - progressHeight, size.x, progressHeight),
      const Radius.circular(12),
    );
    canvas.drawRRect(progressRect, progressPaint);

    // 4. Gambar Teks Target (1000) di pojok kiri atas tower
    _drawText(canvas, "1000", const Offset(5, 5), fontSize: 10, color: Colors.white70);

    // 5. Gambar Nilai Sekarang (Di atas batang progress)
    _drawText(
      canvas, 
      "${tower.startValue}", 
      Offset(size.x / 2 - 12, size.y - progressHeight - 25),
      fontSize: 14,
      isBold: true
    );
    
    // 6. Gambar Label Tim (Opsional)
    if (tower.status == TowerStatus.claimed) {
      _drawText(canvas, "CLAIMED", Offset(5, size.y - 20), fontSize: 8, color: Colors.yellow);
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, {double fontSize = 12, bool isBold = false, Color color = Colors.white}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'Arial',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, offset);
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Hanya bisa di-tap jika statusnya available atau sedang diklaim user ini
    if (tower.status != TowerStatus.solved) {
      onClaim(tower.id, team);
    }
  }
}