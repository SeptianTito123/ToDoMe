import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class WeeklyLineChart extends StatelessWidget {
  final List<Task> tasks;

  const WeeklyLineChart({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    // 1. Siapkan Data 7 Hari Terakhir
    final now = DateTime.now();
    List<FlSpot> spots = [];
    List<String> dayLabels = [];
    double maxCount = 0;

    // Warna Chart (Ungu)
    const Color mainColor = Color(0xFF9C27B0); 
    
    // --- LOOOPING DATA (Pastikan ini tidak terhapus) ---
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      
      // Format Hari (Sen, Sel, Rab)
      // Menggunakan try-catch agar jika format gagal, aplikasi tidak crash
      String dayName = "";
      try {
        dayName = DateFormat('E', 'id_ID').format(date);
      } catch (e) {
        // Fallback jika locale error: Pakai format Inggris
        dayName = DateFormat('E').format(date); 
      }
      dayLabels.add(dayName);

      // Hitung tugas selesai
      int count = tasks.where((t) {
        if (!t.statusSelesai) return false;
        return t.updatedAt.year == date.year &&
               t.updatedAt.month == date.month &&
               t.updatedAt.day == date.day;
      }).length;

      if (count > maxCount) maxCount = count.toDouble();
      spots.add(FlSpot((6 - i).toDouble(), count.toDouble()));
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Produktifitas Minggu Ini",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "${tasks.where((t) => t.statusSelesai).length} Tugas Selesai Total",
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          
          AspectRatio(
            aspectRatio: 1.70,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxCount < 4 ? 4 : maxCount + 1,
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        // --- BAGIAN ANTI CRASH (SAFETY CHECK) ---
                        int index = value.toInt();
                        // Cek apakah index valid dan list tidak kosong
                        if (index >= 0 && index < dayLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              dayLabels[index], 
                              style: TextStyle(
                                fontSize: 12, 
                                color: Colors.grey[400], 
                                fontWeight: FontWeight.w500
                              )
                            ),
                          );
                        }
                        return const SizedBox.shrink(); // Jangan tampilkan apa-apa jika error
                        // ----------------------------------------
                      },
                    ),
                  ),
                ),
                
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: mainColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true, 
                      gradient: LinearGradient(
                        colors: [
                          mainColor.withOpacity(0.3),
                          mainColor.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}