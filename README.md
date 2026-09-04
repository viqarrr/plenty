<div align="center">
  <img src="assets/images/light_logo_plenty.png" alt="Plenty Logo" width="220" />

  # Plenty 🌿
  ### *Turn plant care into a more enjoyable habit.*

  [![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
  [![SQLite](https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)](https://www.sqlite.org/)
  [![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green?style=for-the-badge)]()

  <p align="center">
    Aplikasi asisten berkebun cerdas berbasis Flutter dengan pendekatan gamifikasi untuk membantu pecinta tanaman merawat, memantau pertumbuhan, dan membangun kebiasaan merawat tanaman hias secara konsisten dan menyenangkan.
  </p>
</div>

---

## 📖 Tentang Plenty

**Plenty** lahir dari kebutuhan para pemilik tanaman yang kerap lupa menyiram, bingung dengan kebutuhan cahaya/nutrisi tanaman, atau kesulitan memantau perkembangan tanamannya dari waktu ke waktu. 

Dengan memadukan **habit tracker**, **gamifikasi (XP & Level)**, **sistem badge penghargaan**, **pencatatan pertumbuhan dengan visualisasi grafik**, dan **jejaring komunitas**, Plenty mengubah aktivitas perawatan tanaman harian menjadi rutinitas interaktif yang memuaskan dan mempererat ikatan antara pemilik dan tanaman kesayangannya.

---

## ✨ Fitur Utama

### 1. 🪴 Manajemen Kebun & Pengelompokan Area (*Garden & Sites*)
- **Katalog Tanaman Terintegrasi**: Cari dan pilih tanaman dari ribuan database botani melalui **Perenual API** atau pilih koleksi tanaman lokal (*seed catalog* offline).
- **Tambah Tanaman Kustom**: Fleksibilitas menambahkan tanaman sendiri lengkap dengan foto galeri/kamera, nama panggilan (*nickname*), tinggi awal, preferensi sinar matahari, dan interval penyiraman.
- **Zonasi Ruangan (*Sites*)**: Kelompokkan tanaman berdasarkan ruangan penempatan (Ruang Tamu, Kamar Tidur, Balkon, Dapur, Teras, atau area kustom buatan Anda).
- **Profil Detail Tanaman**: Informasi komprehensif mulai dari taksonomi famili, siklus hidup (*perennial/annual*), tingkat kemudahan (*care level*), petunjuk pemangkasan, hingga informasi keamanan toksisitas terhadap anak dan hewan peliharaan (*pet-friendly check*).

### 2. 💧 Rutinitas Harian & Pelacak Kebiasaan (*Daily Care & Streak*)
- **Tugas Perawatan Terjadwal**: Daftar tugas harian otomatis untuk:
  - 🚿 **Siram**: Pengingat penyiraman sesuai siklus masing-masing tanaman.
  - 🧹 **Bersih**: Rutinitas pembersihan daun dan pengecekan media tanam.
  - 📏 **Monitor**: Pengecekan kondisi kesehatan dan pencatatan perkembangan.
- **Streak Tracker**: Lacak konsistensi harian Anda tanpa putus untuk membentuk kebiasaan merawat kebun yang disiplin.
- **Riwayat Perawatan**: Catatan riwayat aksi perawatan yang terstruktur untuk melihat riwayat aktivitas sebelumnya.

### 3. 📈 Pemantauan Pertumbuhan & Visualisasi (*Growth Tracker*)
- **Log Pertumbuhan Berkala**: Catat tinggi tanaman dalam centimeter (`cm`) dan pertambahan jumlah helai daun.
- **Grafik Interaktif**: Pantau tren perkembangan fisik tanaman dari waktu ke waktu melalui grafik garis interaktif (`fl_chart`).

### 4. ⏳ Kapsul Waktu (*Time Capsule*)
- Simpan kenangan, foto awal adopsi tanaman, dan pesan harapan Anda ke dalam kapsul waktu digital yang terkunci dan dapat dibuka kembali pada tanggal yang telah ditentukan di masa mendatang.

### 5. 🏆 Gamifikasi & Sistem Penghargaan (*Gamification & Badges*)
- **XP & Leveling System**: Dapatkan poin pengalaman (*Experience Points / XP*) setiap kali menyelesaikan tugas perawatan harian dan tingkatkan level profil kebun Anda.
- **Koleksi Lencana (*Badges*)**: Buka berbagai lencana pencapaian berdasarkan milestone aktivitas, seperti:
  - 🌱 *Adopsi Pertama*: Mengadopsi tanaman pertama.
  - 💧 *Penyiram Setia*: Menyiram tanaman tepat waktu berturut-turut.
  - ⏳ *Kapsul Waktu*: Membuat pesan kapsul waktu pertama.
  - 🌳 *Kolektor Rimbun*: Mengoleksi tanaman aktif di kebun virtual.
  - 🩺 *Dokter Tanaman*: Rajin mencatat jurnal kesehatan tanaman.
  - ☀️ *Pencari Cahaya*: Menempatkan tanaman di pencahayaan ideal.

### 6. 👥 Komunitas Penggemar Tanaman (*Community Feed*)
- Bagikan pencapaian (*milestones*), foto perkembangan tanaman, atau tips perawatan kepada sesama pengguna.
- Berikan apresiasi berupa **Kudos** (suka) dan jalin interaksi dalam ekosistem pecinta tanaman.

### 7. 🔐 Onboarding Cerdas & Keamanan Data
- **Onboarding Personalisasi**: Kuesioner awal untuk menyesuaikan rekomendasi berdasarkan tingkat pengalaman (*beginner/intermediate/expert*), waktu luang harian, dan kondisi rumah (anak/hewan peliharaan).
- **Keamanan Akun**: Penyimpanan lokal aman dengan hashing kata sandi berbasis algoritma **BCrypt**.
- **Offline-First Storage**: Penyimpanan basis data lokal andal menggunakan **SQLite** via `sqflite`.

---

## 🛠️ Arsitektur & Teknologi

Plenty dibangun dengan prinsip **Clean Architecture & Feature-First Structure** yang memisahkan tanggung jawab kode menjadi lapisan *Data*, *Domain*, dan *Presentation* untuk kemudahan pengujian (*testability*) dan skalabilitas.

### Tech Stack:
| Komponen | Teknologi | Keterangan |
| :--- | :--- | :--- |
| **Framework** | [Flutter](https://flutter.dev) (SDK ^3.12.2) | Cross-platform mobile app framework |
| **Bahasa** | [Dart](https://dart.dev) | Modern typed language |
| **Database Lokal** | [sqflite](https://pub.dev/packages/sqflite) | SQLite database untuk penyimpanan offline-first |
| **Database Viewer** | [sqlite_viewer2](https://pub.dev/packages/sqlite_viewer2) | Inspeksi database lokal saat masa pengembangan |
| **State Management** | MVC / Controller with `ChangeNotifier` & `ListenableBuilder` | Manajemen status responsif & efisien tanpa boilerplate berlebih |
| **Networking** | [Dio](https://pub.dev/packages/dio) & [Retrofit](https://pub.dev/packages/retrofit) | Klien HTTP terstruktur untuk integrasi REST API |
| **Enkripsi & Keamanan** | [bcrypt](https://pub.dev/packages/bcrypt) | Hashing aman untuk kredensial pengguna |
| **Grafik & Visualisasi** | [fl_chart](https://pub.dev/packages/fl_chart) | Komponen grafik visualisasi data pertumbuhan |
| **Animasi & UI** | [lottie](https://pub.dev/packages/lottie), [google_fonts](https://pub.dev/packages/google_fonts) | Animasi interaktif & tipografi modern |
| **Media & Gambar** | [image_picker](https://pub.dev/packages/image_picker) | Pengambilan foto tanaman dari kamera dan galeri |
| **Penyimpanan Key-Value**| [shared_preferences](https://pub.dev/packages/shared_preferences) | Manajemen sesi & preferensi aplikasi |
| **Environment Config** | [flutter_dotenv](https://pub.dev/packages/flutter_dotenv) | Pengelolaan API keys & environment variables |
| **External API** | [Perenual API](https://perenual.com/docs/api) | Database spesies tanaman, panduan perawatan, dan gambar botani |

---

## 📁 Struktur Direktori Proyek

```plaintext
plenty/
├── assets/
│   ├── animations/       # File animasi Lottie (.json)
│   ├── data/             # Data awal offline (seed_plants.json)
│   ├── icons/            # Ikon aplikasi & launcher icons
│   └── images/           # Ilustrasi & logo aplikasi
├── lib/
│   ├── core/             # Modul inti & dependensi global
│   │   ├── constants/    # Warna tema, gambar, tipe task, XP config, API endpoints
│   │   ├── database/     # DatabaseHelper & skema tabel SQLite
│   │   ├── di/           # Dependency injection / Service locator
│   │   ├── error/        # Failure & Result handling
│   │   ├── network/      # Konfigurasi Dio & API Client
│   │   ├── storage/      # PreferenceHandler (SharedPreferences)
│   │   ├── theme/        # AppTheme & Typography
│   │   ├── utils/        # Unit converter, botanical translator, debouncer, extensions
│   │   └── widgets/      # Komponen UI global (CustomButton, CustomTextField)
│   ├── features/         # Fitur modular (Feature-First Clean Architecture)
│   │   ├── auth/         # Registrasi, login, dan manajemen autentikasi
│   │   ├── community/    # Feed komunitas, posting, dan interaksi sosial
│   │   ├── daily_care/   # Rutinitas perawatan harian, habit tasks, riwayat
│   │   ├── garden/       # Beranda kebun, katalog Perenual, tambah tanaman, detail tanaman
│   │   ├── onboarding/   # Splash screen, welcome flow, kuesioner preferensi
│   │   └── profile/      # Halaman profil pengguna, daftar lencana (badges), edit profil
│   └── main.dart         # Entry point aplikasi Plenty
├── test/                 # Pengujian unit, widget, dan repository
├── .env                  # Konfigurasi kunci API & endpoint lingkungan
├── pubspec.yaml          # Spesifikasi paket dan dependensi Flutter
└── README.md             # Dokumentasi proyek
```

---

## 🚀 Panduan Memulai (*Getting Started*)

### Prasyarat:
Pastikan perangkat pengembangan Anda telah terinstal:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi 3.24.x atau yang lebih baru)
- Dart SDK (^3.12.2)
- Android Studio / VS Code dengan ekstensi Flutter & Dart
- Emulator Android atau perangkat fisik dengan USB Debugging aktif

### Langkah Instalasi:

1. **Clone repositori ini**:
   ```bash
   git clone https://github.com/viqarrr/plenty.git
   cd plenty
   ```

2. **Pasang dependensi Flutter**:
   ```bash
   flutter pub get
   ```

3. **Konfigurasi Environment (`.env`)**:
   Pastikan file `.env` berada di direktori utama (*root*) proyek dengan konfigurasi:
   ```env
   PERENUAL_BASE_URL=https://perenual.com/api
   API_KEY=your_perenual_api_key_here
   ```
   *(Daftarkan akun di [Perenual API](https://perenual.com/docs/api) untuk mendapatkan API key).*

4. **Jalankan Build Runner (Opsional jika memperbarui serialisasi/Retrofit)**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

5. **Jalankan Aplikasi**:
   ```bash
   flutter run
   ```

---

## 🧪 Pengujian (*Testing*)

Proyek Plenty dilengkapi dengan rangkaian pengujian unit dan pengujian widget untuk memastikan stabilitas logika bisnis dan antarmuka:

Untuk menjalankan seluruh rangkaian pengujian:
```bash
flutter test
```

Untuk menjalankan pengujian dengan laporan cakupan (*coverage*):
```bash
flutter test --coverage
```

---

## 🤝 Kontribusi

Kontribusi selalu terbuka dan diapresiasi! Untuk berkontribusi:
1. Fork repositori ini.
2. Buat branch fitur baru (`git checkout -b feature/FiturKeren`).
3. Lakukan commit perubahan Anda (`git commit -m 'Menambahkan fitur perawatan tanaman baru'`).
4. Push ke branch Anda (`git push origin feature/FiturKeren`).
5. Buat Pull Request baru.

---

## 📄 Lisensi

Proyek ini dibuat dan dikembangkan untuk keperluan aplikasi Plenty. Hak cipta dilindungi.
Lihat lisensi proyek pada berkas terkait jika tersedia.
