// test/solver_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tower_challenge/core/utils/solver_util.dart'; // Sesuaikan dengan nama projectmu

void main() {
  group('BFS Solver Test', () {
    test('Harus menemukan langkah tersedikit untuk 10 -> 40', () {
      // Jalur optimal: 10 * 2 = 20, 20 * 2 = 40 (2 moves)
      // Jalur lain: 10+10+10+10 (3 moves)
      final moves = SolverUtil.calculateOptimalMoves(10, 40);
      expect(moves, 2); 
    });

    test('Harus menemukan langkah untuk 10 -> 30', () {
      // 10 + 10 + 10 (2 moves) ATAU 10 * 2 + 10 (2 moves)
      final moves = SolverUtil.calculateOptimalMoves(10, 30);
      expect(moves, 2);
    });

    test('Harus return null jika target tidak mungkin dicapai', () {
      // Karena hanya bisa tambah dan kali, tidak mungkin ke angka lebih kecil
      final moves = SolverUtil.calculateOptimalMoves(50, 20);
      expect(moves, null);
    });
  });
}