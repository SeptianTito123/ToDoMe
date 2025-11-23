# To Do Me – Frontend (Flutter)

To Do Me adalah aplikasi manajemen produktivitas (To-Do List) berbasis **Flutter** yang terhubung dengan **Laravel Backend API**.  
Dokumen ini berisi panduan setup lengkap front-end agar berjalan dengan baik di lingkungan lokal.

---

## 1. Ringkasan Fitur Utama

### 1.1 Sistem Autentikasi Hibrida

#### Register Manual (Strict Mode)
- Input wajib: Nama, Email, Password  
- Email Verification **wajib**  
- Akun **tidak dapat login** sebelum diverifikasi  

#### Google Sign-In (Android Native)
- Login 1 sentuhan melalui Google  
- Jika user baru → diarahkan ke halaman *Set Password Aplikasi*  
- Logout aman: melakukan `GoogleSignIn.disconnect()` + menghapus token JWT dari `flutter_secure_storage`  

---

### 1.2 Manajemen Tugas
- Membuat, menyunting, menghapus tugas  
- Subtasks (Checklist)  
- Kategori tugas  
- Filter: Aktif, Terlambat, Selesai  
- Sorting + tampilan expandable  

---

### 1.3 Dashboard Statistik
- Grafik mingguan (Line Chart)  
- Pie Chart completion rate  
- Summary Cards (total tugas, selesai, tertunda)

---

## 2. Persyaratan Environment (Wajib)

### 2.1 Software Utama
- Flutter SDK versi **3.x.x** atau lebih baru  
- VS Code atau Android Studio  
- Backend Laravel (`todome_backend`) berjalan:  
  ```bash
  php artisan serve
  ```

### 2.2 Perangkat
- Android Emulator (AVD)  
- HP fisik (USB Debugging ON)  
- Chrome/Edge (untuk testing Web)

### 2.3 Google Sign-In Requirements
- Akses Google Cloud Console  
- SHA-1 fingerprint  
- OAuth 2.0 Client ID (Android)

---

## 3. Instalasi Project

### 3.1 Clone Repo
```bash
git clone https://github.com/SeptianTito123/todome.git
cd todome
```

### 3.2 Install Dependencies
```bash
flutter pub get
```

Jika error:
```bash
flutter pub upgrade
```

---

## 4. Menjalankan Backend Laravel

Pastikan backend berjalan sebelum menjalankan frontend.

```bash
cd C:\laragon\www\todome_backend
php artisan serve
```

Default URL backend:

```
http://127.0.0.1:8000
```

---

## 5. Konfigurasi Koneksi API

Semua endpoint API diatur di:

```
lib/services/api_service.dart
```

Kode otomatis mendeteksi platform:

```dart
static String get _baseUrl {
  if (kIsWeb) {
    return "http://127.0.0.1:8000/api";
  } else if (defaultTargetPlatform == TargetPlatform.android) {
    return "http://10.0.2.2:8000/api";
  } else {
    return "http://127.0.0.1:8000/api";
  }
}
```

**Jika menggunakan HP Fisik**, ubah menjadi IP Laptop:

```
http://192.168.1.xx:8000/api
```

---

## 6. Setup Google Sign-In (Penting)

Tanpa setup ini, login Google akan error:

> ApiException: 10 – DEVELOPER_ERROR

### 6.1 Ambil SHA-1 Fingerprint

Masuk folder android:

```bash
cd android
```

Windows:
```bash
.\gradlew signingReport
```

Mac/Linux:
```bash
./gradlew signingReport
```

Cari:
```
Variant: debug
SHA1: XX:XX:XX:...
```

### 6.2 Daftarkan di Google Cloud Console
- Masuk ke *API & Services → Credentials*  
- Pilih **OAuth Client ID (Android)**  
- Isi:
  - Package Name (sesuai `build.gradle`)  
  - SHA-1 fingerprint  

---

## 7. Menjalankan Aplikasi Flutter

Pastikan:
- Backend aktif  
- Emulator/Device menyala  

Jalankan:
```bash
flutter run
```

---

## 8. Alur Verifikasi Email (Mode Development)

Karena backend berjalan di laptop (localhost):

1. User register dari HP/Emulator  
2. Email verifikasi masuk ke Gmail  
3. **Link verifikasi hanya dapat dibuka di Laptop**, bukan HP  
4. Klik tombol verifikasi  
5. Setelah sukses, kembali ke HP → Login berhasil  

Jika dibuka dari HP → akan gagal (127.0.0.1 mengarah ke HP, bukan laptop)

---

## 9. Struktur Folder

```
lib/
 ├─ screens/
 │   ├─ login_screen.dart
 │   ├─ register_screen.dart
 │   ├─ google_setup_screen.dart
 │   ├─ home_screen.dart
 │   ├─ task_detail_screen.dart
 │   └─ profile_screen.dart
 │
 ├─ services/
 │   ├─ api_service.dart
 │   └─ google_auth_service.dart
 │
 └─ models/
     ├─ task.dart
     ├─ category.dart
     └─ subtask.dart
```

---

## 10. Package Penting

### http  
Untuk seluruh komunikasi API (GET, POST, PUT, DELETE).

### flutter_secure_storage  
Menyimpan token login secara aman dan terenkripsi.

### intl  
Digunakan untuk format tanggal dan waktu.

---

## 11. Troubleshooting

### A. Manifest Merger Failed  
Solusi:
```xml
package="com.example.todome"
```

### B. ApiException: 10 (Google Login)
Penyebab:
- SHA-1 belum terdaftar  
- Package name tidak cocok  

### C. Error: Ambiguous import: Category  
Solusi:
```dart
import 'package:flutter/foundation.dart' hide Category;
```

### D. Link Email Verification Invalid  
Tambahkan pada Laravel:

```php
URL::forceRootUrl('http://127.0.0.1:8000');
```

---
