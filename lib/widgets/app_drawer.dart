import 'package:flutter/material.dart';
import '../models/category.dart';

enum TaskFilterType { all, starred, category }
typedef FilterCallback = void Function(TaskFilterType type, {int? categoryId});

class AppDrawer extends StatelessWidget {
  final List<Category> categories;
  final int allTasksCount;
  final int starredTasksCount;
  final FilterCallback onFilterSelected;
  final VoidCallback onAddCategory;
  
  // Callback KHUSUS untuk buka halaman Bintang
  final VoidCallback onOpenStarredPage; 

  final bool isKategoriExpanded;
  final Function(bool) onKategoriToggled;

  const AppDrawer({
    Key? key,
    required this.categories,
    required this.allTasksCount,
    required this.starredTasksCount,
    required this.onFilterSelected,
    required this.onAddCategory,
    required this.onOpenStarredPage, // <--- Tambahkan ini
    required this.isKategoriExpanded,
    required this.onKategoriToggled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const UserAccountsDrawerHeader(
            accountName: Text("To Do Me"),
            accountEmail: Text("Atur semua tugasmu"),
            decoration: BoxDecoration(color: Colors.purple), // Sesuaikan warna header
          ),

          // --- MENU BINTANGI TUGAS (DIUBAH) ---
          ListTile(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: const Text('Bintangi Tugas'),
            trailing: Text(starredTasksCount.toString()),
            onTap: () {
              Navigator.pop(context); // Tutup drawer dulu
              onOpenStarredPage(); // Panggil fungsi navigasi
            },
          ),

          const Divider(),

          // --- MENU KATEGORI ---
          ExpansionTile(
            leading: const Icon(Icons.category),
            title: const Text('Kategori'),
            initiallyExpanded: isKategoriExpanded,
            onExpansionChanged: onKategoriToggled,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.only(left: 32.0, right: 16.0),
                leading: const Icon(Icons.all_inbox_outlined),
                title: const Text('Semua'),
                trailing: Text(allTasksCount.toString()),
                onTap: () {
                  onFilterSelected(TaskFilterType.all);
                  // Navigator.pop(context); // AppDrawer handle pop via MainScreen atau disini, terserah logika sebelumnya.
                  // Agar aman dan konsisten dengan MainScreen yang sudah diperbaiki sebelumnya:
                  // Biarkan MainScreen yang menangani state, tapi Drawer harus tutup.
                  Navigator.pop(context);
                },
              ),
              ...categories.map((category) {
                return ListTile(
                  contentPadding: const EdgeInsets.only(left: 32.0, right: 16.0),
                  leading: const Icon(Icons.label_outline),
                  title: Text(category.name),
                  trailing: Text(category.tasksCount.toString()),
                  onTap: () {
                    onFilterSelected(TaskFilterType.category, categoryId: category.id);
                    Navigator.pop(context);
                  },
                );
              }).toList(),

              ListTile(
                contentPadding: const EdgeInsets.only(left: 32.0, right: 16.0),
                leading: const Icon(Icons.add, color: Colors.green),
                title: const Text('Tambah Kategori', style: TextStyle(color: Colors.green)),
                onTap: () {
                  Navigator.pop(context);
                  onAddCategory();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}