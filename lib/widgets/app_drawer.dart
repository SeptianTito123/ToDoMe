import 'package:flutter/material.dart';
import '../models/category.dart';

// Enum untuk tipe filter
enum TaskFilterType { all, starred, category }

// Callback untuk memberitahu MainScreen filter apa yang dipilih
typedef FilterCallback = void Function(TaskFilterType type, {int? categoryId});

class AppDrawer extends StatelessWidget {
  final List<Category> categories;
  final int allTasksCount;
  final int starredTasksCount;
  final FilterCallback onFilterSelected;
  final VoidCallback onAddCategory;

  // --- PARAMETER BARU ---
  final bool isKategoriExpanded;
  final Function(bool) onKategoriToggled;

  const AppDrawer({
    Key? key,
    required this.categories,
    required this.allTasksCount,
    required this.starredTasksCount,
    required this.onFilterSelected,
    required this.onAddCategory,
    // --- TAMBAHKAN KE CONSTRUCTOR ---
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
          ),

          ListTile(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: const Text('Bintangi Tugas'),
            trailing: Text(starredTasksCount.toString()),
            onTap: () {
              onFilterSelected(TaskFilterType.starred);
              Navigator.pop(context);
            },
          ),

          const Divider(),

          // --- Filter Kategori (ExpansionTile) ---
          ExpansionTile(
            leading: const Icon(Icons.category),
            title: const Text('Kategori'),

            // Gunakan initiallyExpanded (bukan isExpanded)
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
