// features/game/presentation/flame/components/tower_component.dart
import 'package:flame/components.dart';
import 'package:flame/events.dart'; // Penting untuk TapCallbacks
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
  }) : super(size: Vector2(80, 100));

  @override
  void render(Canvas canvas) {
    // 1. Gambar Background Kotak
    final paint = Paint();
    if (tower.status == TowerStatus.available) paint.color = Colors.green;
    if (tower.status == TowerStatus.claimed) paint.color = Colors.yellow;
    if (tower.status == TowerStatus.solved) paint.color = Colors.grey;

    canvas.drawRect(size.toRect(), paint);

    // 2. Gambar Teks (startValue)
    // Kita pisah supaya tidak pakai cascade (..) yang bikin error
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${tower.startValue}',
        style: const TextStyle(
          color: Colors.white, 
          fontSize: 16, 
          fontWeight: FontWeight.bold
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    
    // Taruh teks di tengah kotak secara matematis
    final textOffset = Offset(
      (size.x - textPainter.width) / 2,
      (size.y - textPainter.height) / 2,
    );
    
    textPainter.paint(canvas, textOffset);
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Di Flame 1.x, onTapDown tipenya void, bukan bool
    if (tower.status == TowerStatus.available) {
      onClaim(tower.id, team);
    }
  }
}