import 'package:intl/intl.dart';

class TimeHelper {
  // Fungsi ini mengubah DateTime menjadi string "Kurang X hari"
  static String getRemainingTime(DateTime? deadline) {
    if (deadline == null) {
      return ''; // Tidak ada deadline
    }

    final now = DateTime.now();
    final difference = deadline.difference(now);

    // Jika terlambat
    if (difference.isNegative) {
      return 'Terlambat';
    }

    // Jika hari ini
    if (difference.inDays == 0) {
      // Jika kurang dari 1 jam
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Batas waktu segera';
        }
        return 'Kurang ${difference.inMinutes} menit';
      }
      // Jika hari ini, tampilkan jam
      return 'Hari ini, Pukul ${DateFormat('HH:mm').format(deadline.toLocal())}';
    }

    // Jika besok
    if (difference.inDays == 1) {
      return 'Besok, Pukul ${DateFormat('HH:mm').format(deadline.toLocal())}';
    }

    // Jika di masa depan
    return 'Kurang ${difference.inDays} hari';
  }
}