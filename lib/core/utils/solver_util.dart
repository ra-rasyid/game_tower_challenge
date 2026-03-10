// core/utils/solver_util.dart
class SolverUtil {
  static const int maxRange = 200000;

  /// Menghitung langkah minimum dari start ke target menggunakan BFS
  /// Returns null jika target tidak bisa dicapai dalam range 0..200.000
  static int? calculateOptimalMoves(int start, int target) {
    if (start == target) return 0;
    if (start > target || start < 0) return null;

    // Queue untuk BFS: [currentValue, moveCount]
    List<List<int>> queue = [[start, 0]];
    // Set untuk mencatat angka yang sudah dikunjungi agar tidak looping selamanya
    Set<int> visited = {start};

    int head = 0;
    while (head < queue.length) {
      var current = queue[head++];
      int val = current[0];
      int moves = current[1];

      // Kemungkinan 1: Tambah 10
      int nextAdd = val + 10;
      if (nextAdd == target) return moves + 1;
      if (nextAdd < maxRange && !visited.contains(nextAdd)) {
        visited.add(nextAdd);
        queue.add([nextAdd, moves + 1]);
      }

      // Kemungkinan 2: Kali 2
      int nextMul = val * 2;
      if (nextMul == target) return moves + 1;
      if (nextMul < maxRange && !visited.contains(nextMul)) {
        visited.add(nextMul);
        queue.add([nextMul, moves + 1]);
      }
    }

    return null; // Tidak ketemu jalannya
  }
}