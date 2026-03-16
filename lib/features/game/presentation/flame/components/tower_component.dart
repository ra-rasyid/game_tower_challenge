// features/game/presentation/flame/components/tower_component.dart
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../../domain/entities/tower.dart';

class TowerComponent extends PositionComponent with TapCallbacks {
  final Tower tower;
  final String team;
  final Function(String, String) onClaim;

  // Variabel untuk animasi loading titik-titik
  double _timer = 0;
  int _dotCount = 0;

  TowerComponent({
    required this.tower,
    required this.team,
    required this.onClaim,
  }) : super(size: Vector2(60, 180));

  @override
  void update(double dt) {
    super.update(dt);
    // Logika animasi: update titik setiap 0.5 detik jika status sedang Claimed
    if (tower.status == TowerStatus.claimed) {
      _timer += dt;
      if (_timer > 0.5) {
        _dotCount = (_dotCount + 1) % 4; // Berputar dari 0 sampai 3 titik
        _timer = 0;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // 1. Background Tower
    final bgPaint = Paint()..color = const Color(0xFF6A1B9A);
    final bgRect = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(12));
    canvas.drawRRect(bgRect, bgPaint);

    // 2. Progress Bar
    double progressRatio = (tower.startValue / tower.targetValue).clamp(0.0, 1.0);
    double progressHeight = size.y * progressRatio;
    Color barColor = (tower.status == TowerStatus.solved) ? const Color(0xFF9C27B0) : const Color(0xFF4DD0E1);

    final progressPaint = Paint()..color = barColor;
    final progressRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.y - progressHeight, size.x, progressHeight),
      const Radius.circular(12),
    );
    canvas.drawRRect(progressRect, progressPaint);

    // 3. Teks Nilai (Start Value)
    _drawText(canvas, "${tower.startValue}", Offset(size.x / 2 - 12, size.y - progressHeight - 25), fontSize: 14, isBold: true);

    // --- 4. ANIMASI LOADING TITIK-TITIK (FITUR BARU) ---
    if (tower.status == TowerStatus.claimed) {
      String dots = "." * _dotCount;
      _drawText(
        canvas, 
        dots, 
        Offset(size.x / 2 - 5, size.y - progressHeight - 15), // Posisinya pas di atas bar
        fontSize: 20, 
        color: Colors.white, 
        isBold: true
      );
    }

    // 5. LOGIKA VISUAL STATUS
    if (tower.status == TowerStatus.available) {
      final plusPaint = Paint()..color = Colors.white.withOpacity(0.3);
      canvas.drawCircle(Offset(size.x / 2, size.y - 25), 15, plusPaint);
      _drawIcon(canvas, Icons.add, Colors.white, 20, Offset(size.x / 2 - 10, size.y - 35));
      
    } else if (tower.status == TowerStatus.claimed) {
      final avatarPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(size.x / 2, size.y - 25), 18, avatarPaint);

      bool isUser = tower.claimedBy == "user_ragil";
      IconData avatarIcon;
      Color iconColor;

      if (isUser) {
        avatarIcon = Icons.person; 
        iconColor = Colors.orange;
      } else {
        List<IconData> botIcons = [Icons.face, Icons.outlet, Icons.adb, Icons.emoji_emotions, Icons.pets];
        int iconIndex = tower.id.hashCode % botIcons.length;
        avatarIcon = botIcons[iconIndex];
        iconColor = Colors.blueGrey;
      }

      _drawIcon(canvas, avatarIcon, iconColor, 20, Offset(size.x / 2 - 10, size.y - 35));
      String displayName = isUser ? "YOU" : (tower.claimedBy?.split('_').last ?? "BOT");
      _drawText(canvas, displayName, Offset(5, size.y - 5), fontSize: 8, color: Colors.white70);

    } else if (tower.status == TowerStatus.solved) {
      _drawText(canvas, "✅ DONE", Offset(5, size.y - 20), fontSize: 10, color: Colors.yellow, isBold: true);
    }
  }

  void _drawIcon(Canvas canvas, IconData icon, Color color, double size, Offset offset) {
    TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(color: color, fontSize: size, fontFamily: 'MaterialIcons'),
      ),
      textDirection: TextDirection.ltr,
    )..layout()..paint(canvas, offset);
  }

  void _drawText(Canvas canvas, String text, Offset offset, {double fontSize = 12, bool isBold = false, Color color = Colors.white}) {
    TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
      ),
      textDirection: TextDirection.ltr,
    )..layout()..paint(canvas, offset);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (tower.status == TowerStatus.solved) return;
    onClaim(tower.id, team);
  }
}