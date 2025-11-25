import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';

class UnfinishedPieChart extends StatelessWidget {
  final List<Task> tasks;

  const UnfinishedPieChart({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    // 1. Filter tugas belum selesai
    final unfinished = tasks.where((t) => !t.statusSelesai).toList();

    // 2. Group by Kategori
    Map<String, int> categoryCounts = {};
    int noCategoryCount = 0;

    for (var task in unfinished) {
      if (task.categories != null && task.categories!.isNotEmpty) {
        // Ambil kategori pertama saja untuk simplifikasi chart
        String catName = task.categories!.first.name;
        categoryCounts[catName] = (categoryCounts[catName] ?? 0) + 1;
      } else {
        noCategoryCount++;
      }
    }
    if (noCategoryCount > 0) categoryCounts['Lainnya'] = noCategoryCount;

    // 3. Generate Data Section
    List<Color> colors = [
      Colors.blue, Colors.orange, Colors.purple, Colors.green, Colors.red, Colors.teal
    ];
    
    int colorIndex = 0;
    List<PieChartSectionData> sections = [];

    categoryCounts.forEach((key, value) {
      sections.add(
        PieChartSectionData(
          value: value.toDouble(),
          color: colors[colorIndex % colors.length],
          title: "$value", // Tampilkan angka jumlah
          radius: 50,
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
      colorIndex++;
    });

    // Handle jika kosong
    if (sections.isEmpty) {
      sections.add(PieChartSectionData(value: 1, title: "0", color: Colors.grey[300], radius: 50));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Tugas belum selesai",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text("${unfinished.length} Total", style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              // CHART
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 150,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      sections: sections,
                    ),
                  ),
                ),
              ),
              // LEGEND (Keterangan Warna)
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: categoryCounts.entries.map((e) {
                    int idx = categoryCounts.keys.toList().indexOf(e.key);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        children: [
                          Container(width: 10, height: 10, color: colors[idx % colors.length]),
                          const SizedBox(width: 4),
                          Expanded(child: Text(e.key, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}