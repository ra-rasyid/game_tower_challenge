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
  }) : super(size: Vector2(60, 180));

  @override
  void render(Canvas canvas) {
    // 1. Gambar Background Tower (Warna Ungu Gelap)
    final bgPaint = Paint()..color = const Color(0xFF6A1B9A);
    final bgRect = RRect.fromRectAndRadius(
      size.toRect(),
      const Radius.circular(12),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // 2. Hitung Tinggi Progress (Max 1000)
    double progressRatio = (tower.startValue / tower.targetValue).clamp(0.0, 1.0);
    double progressHeight = size.y * progressRatio;

    // 3. LOGIKA WARNA DINAMIS: 
    // Jika sudah SOLVED atau nilai >= 800 (80%), pakai warna UNGU TERANG
    // Jika belum, pakai warna BIRU TOSCA
    Color barColor = (tower.status == TowerStatus.solved || tower.startValue >= 800)
        ? const Color(0xFF9C27B0) // Ungu Terang
        : const Color(0xFF4DD0E1); // Biru Tosca

    final progressPaint = Paint()..color = barColor;
    final progressRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.y - progressHeight, size.x, progressHeight),
      const Radius.circular(12),
    );
    canvas.drawRRect(progressRect, progressPaint);

    // 4. Gambar Teks Target (1000)
    _drawText(canvas, "1000", const Offset(5, 5), fontSize: 10, color: Colors.white70);

    // 5. Gambar Nilai Sekarang
    _drawText(
      canvas, 
      "${tower.startValue}", 
      Offset(size.x / 2 - 12, size.y - progressHeight - 25),
      fontSize: 14,
      isBold: true
    );
    
    // 6. Indikator Status
    if (tower.status == TowerStatus.solved) {
      _drawText(canvas, "DONE", Offset(size.x / 2 - 15, size.y - 20), fontSize: 10, color: Colors.yellow, isBold: true);
    } else if (tower.status == TowerStatus.claimed) {
      _drawText(canvas, "CLAIMED", Offset(5, size.y - 20), fontSize: 8, color: Colors.orange);
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
    // PROTEKSI: Jika status sudah solved, tower tidak bisa di-klik lagi
    if (tower.status != TowerStatus.solved) {
      onClaim(tower.id, team);
    }
  }
}