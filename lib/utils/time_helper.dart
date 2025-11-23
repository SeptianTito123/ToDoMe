import 'package:intl/intl.dart';
import '../models/task.dart';

class TimeHelper {
  // Fungsi utama: Menerima objek Task lengkap
  static String getTaskStatusText(Task task) {
    if (task.deadline == null) {
      return ''; 
    }

    final deadline = task.deadline!;
    
    // --- LOGIKA KUNCI ---
    // Jika tugas SUDAH SELESAI, waktu pembandingnya adalah 'updatedAt' (saat diceklist).
    // Jika BELUM SELESAI, waktu pembandingnya adalah 'DateTime.now()' (sekarang).
    final comparisonTime = task.statusSelesai ? task.updatedAt : DateTime.now();

    final difference = deadline.difference(comparisonTime);

    // 1. KASUS TERLAMBAT (Difference negatif)
    if (difference.isNegative) {
      // Kita ubah durasi negatif jadi positif biar enak dibaca
      final lateDuration = difference.abs(); 
      final timeString = _formatDuration(lateDuration);

      if (task.statusSelesai) {
        // Sudah diceklist, tapi ternyata checklistnya telat
        return 'Selesai terlambat $timeString';
      } else {
        // Belum diceklist dan sudah lewat deadline
        return 'Terlambat $timeString';
      }
    }

    // 2. KASUS TEPAT WAKTU (Masih ada sisa waktu / Selesai on-time)
    
    // Jika sudah selesai dan tidak terlambat
    if (task.statusSelesai) {
      return 'Selesai tepat waktu';
    }

    // Jika belum selesai (Menampilkan sisa waktu seperti kode lamamu)
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Batas waktu segera';
        }
        return 'Kurang ${difference.inMinutes} menit';
      }
      return 'Hari ini, Pukul ${DateFormat('HH:mm').format(deadline.toLocal())}';
    }

    if (difference.inDays == 1) {
      return 'Besok, Pukul ${DateFormat('HH:mm').format(deadline.toLocal())}';
    }

    return 'Kurang ${difference.inDays} hari';
  }

  // Helper kecil untuk format durasi (misal: "2 hari", "5 jam")
  static String _formatDuration(Duration duration) {
    if (duration.inDays >= 1) {
      return '${duration.inDays} hari';
    } else if (duration.inHours >= 1) {
      return '${duration.inHours} jam';
    } else {
      return '${duration.inMinutes} menit';
    }
  }
}