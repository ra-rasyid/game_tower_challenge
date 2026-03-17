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
    // Logika animasi loading titik-titik saat tower sedang diklaim
    if (tower.status == TowerStatus.claimed) {
      _timer += dt;
      if (_timer > 0.5) {
        _dotCount = (_dotCount + 1) % 4;
        _timer = 0;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // 1. Gambar Background Tower (Warna Ungu Tua)
    final bgPaint = Paint()..color = const Color(0xFF6A1B9A);
    final bgRect = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(12));
    canvas.drawRRect(bgRect, bgPaint);

    // 2. Hitung Progress Bar
    double progressRatio = (tower.startValue / tower.targetValue).clamp(0.0, 1.0);
    double progressHeight = size.y * progressRatio;
    Color barColor = (tower.status == TowerStatus.solved) ? const Color(0xFF9C27B0) : const Color(0xFF4DD0E1);

    final progressPaint = Paint()..color = barColor;
    final progressRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.y - progressHeight, size.x, progressHeight),
      const Radius.circular(12),
    );
    canvas.drawRRect(progressRect, progressPaint);

    // 3. Teks Nilai Berjalan (Ikut naik bersama bar)
    _drawText(canvas, "${tower.startValue}", Offset(size.x / 2 - 12, size.y - progressHeight - 25), fontSize: 14, isBold: true);

    // 4. LOGIKA VISUAL STATUS
    
    // --- STATUS: AVAILABLE (Belum dikerjakan) ---
    if (tower.status == TowerStatus.available) {
      final plusPaint = Paint()..color = Colors.white.withOpacity(0.3);
      canvas.drawCircle(Offset(size.x / 2, size.y - 25), 15, plusPaint);
      _drawIcon(canvas, Icons.add, Colors.white, 20, Offset(size.x / 2 - 10, size.y - 35));
      
    } 
    // --- STATUS: CLAIMED (Sedang dikerjakan User/Bot) ---
    else if (tower.status == TowerStatus.claimed) {
      // Gambar Animasi Loading Titik-titik di atas Bar
      String dots = "." * _dotCount;
      _drawText(canvas, dots, Offset(size.x / 2 - 5, size.y - progressHeight - 15), fontSize: 20, isBold: true);

      // Gambar PP/Avatar
      final avatarPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(size.x / 2, size.y - 25), 18, avatarPaint);

      bool isUser = tower.claimedBy == "user_ragil";
      IconData avatarIcon;
      Color iconColor;

      if (isUser) {
        avatarIcon = Icons.person; 
        iconColor = Colors.orange;
      } else {
        // Variasi icon bot
        List<IconData> botIcons = [Icons.face, Icons.outlet, Icons.adb, Icons.emoji_emotions, Icons.pets];
        int iconIndex = tower.id.hashCode % botIcons.length;
        avatarIcon = botIcons[iconIndex];
        iconColor = Colors.blueGrey;
      }

      _drawIcon(canvas, avatarIcon, iconColor, 20, Offset(size.x / 2 - 10, size.y - 35));
      String displayName = isUser ? "YOU" : (tower.claimedBy?.split('_').last ?? "BOT");
      _drawText(canvas, displayName, Offset(5, size.y - 5), fontSize: 8, color: Colors.white70);

    } 
    // --- STATUS: SOLVED (Selesai/DONE) ---
    else if (tower.status == TowerStatus.solved) {
      // REVISI: ICON MOBIL DI PUNCAK TOWER
      
      // 1. Gambar lingkaran background kuning di atap tower
      final carBgPaint = Paint()..color = Colors.yellow;
      canvas.drawCircle(Offset(size.x / 2, 10), 15, carBgPaint);
      
      // 2. Gambar icon mobil (🚗) pas di tengah lingkaran
      _drawIcon(canvas, Icons.directions_car, const Color(0xFF6A1B9A), 18, Offset(size.x / 2 - 9, 1));

      // 3. Teks DONE di bawah mobil
      _drawText(canvas, "DONE", Offset(size.x / 2 - 15, 30), fontSize: 10, color: Colors.yellow, isBold: true);
      
      // Angka 1000 di dalam bar
      _drawText(canvas, "1000", Offset(size.x / 2 - 15, size.y - 25), fontSize: 14, isBold: true);
    }
  }

  // Helper menggambar Icon Material
  void _drawIcon(Canvas canvas, IconData icon, Color color, double size, Offset offset) {
    TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(color: color, fontSize: size, fontFamily: 'MaterialIcons'),
      ),
      textDirection: TextDirection.ltr,
    )..layout()..paint(canvas, offset);
  }

  // Helper menggambar Teks
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
    // Proteksi: Jika sudah selesai tidak bisa diklik lagi
    if (tower.status == TowerStatus.solved) return;
    onClaim(tower.id, team);
  }
}