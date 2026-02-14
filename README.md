# 2026-bookruang-mobile
# BookRuang Mobile

## Description
BookRuang Mobile adalah aplikasi flutter untuk sistem peminjaman ruangan yang terhubung dengan backend ASP.NET API. Aplikasi ini memungkinkan pengguna untuk menambah, melihat, mengedit, dan menghapus data peminjaman ruangan secara langsung dari perangkat mobile.

## Feature
- Tambah peminjaman ruangan
- Lihat daftar peminjaman
- Edit data peminjaman
- Hapus peminjaman
- Terhubung langsung ke REST API backend

## Tech Stack
- Flutter 
- Dart
- HTTP Package
- ASP.NET Core API (backend)

## Requirements
- Flutter SDK
- Backend BookRuang API sudah berjalan 

## Installation

1. Clone repository: 
```bash 
git clone <repo-url>
cd bookruang_mobile 

2. Install dependencies: 
flutter pub get

3. Jalankan aplikai 
flutter run

## API Configuration 
http://localhost:5021/api/RoomLoans

example: 
final String apiUrl = "http://10.0.2.2:5021/api/RoomLoans";

## Project Structure
lib/
 |
 ------main.dart # UI dan logic utama aplikasi

 ## Author
 Dika-Informatics Engineering Student

 