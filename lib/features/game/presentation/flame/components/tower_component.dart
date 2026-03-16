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
    final bgPaint = Paint()..color = const Color(0xFF6A1B9A);
    final bgRect = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(12));
    canvas.drawRRect(bgRect, bgPaint);

    double progressRatio = (tower.startValue / tower.targetValue).clamp(0.0, 1.0);
    double progressHeight = size.y * progressRatio;

    // Warna Ungu Terang jika DONE, Biru Tosca jika belum
    Color barColor = (tower.status == TowerStatus.solved)
        ? const Color(0xFF9C27B0) 
        : const Color(0xFF4DD0E1);

    final progressPaint = Paint()..color = barColor;
    final progressRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.y - progressHeight, size.x, progressHeight),
      const Radius.circular(12),
    );
    canvas.drawRRect(progressRect, progressPaint);

    _drawText(canvas, "${tower.startValue}", Offset(size.x / 2 - 12, size.y - progressHeight - 25), fontSize: 14, isBold: true);

    if (tower.status == TowerStatus.solved) {
      _drawText(canvas, "✅ DONE", Offset(5, size.y - 20), fontSize: 10, color: Colors.yellow, isBold: true);
    } else if (tower.status == TowerStatus.claimed) {
      _drawText(canvas, "🟡 CLAIMED", Offset(5, size.y - 30), fontSize: 8, color: Colors.orange);
      if (tower.claimedBy != null) {
        _drawText(canvas, tower.claimedBy!, Offset(5, size.y - 15), fontSize: 9, color: Colors.white);
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, {double fontSize = 12, bool isBold = false, Color color = Colors.white}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  void onTapDown(TapDownEvent event) {
    // PROTEKSI TOTAL: Jika status sudah SOLVED, abaikan semua klik
    if (tower.status == TowerStatus.solved) return;
    
    // Kirim perintah claim ke controller
    onClaim(tower.id, team);
  }
}