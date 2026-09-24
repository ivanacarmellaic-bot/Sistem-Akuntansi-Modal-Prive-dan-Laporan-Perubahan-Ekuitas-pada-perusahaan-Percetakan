# PressLedger

Sistem akuntansi modal, prive, dan laporan perubahan ekuitas untuk perusahaan percetakan.

## Struktur

```text
frontend/
  index.html
  style.css
  app.js
backend/
  database.sql
```

## Menjalankan lokal

Dari root proyek, jalankan server statis sederhana:

```powershell
npx serve .
```

Kemudian buka `http://localhost:3000/frontend/index.html`.

## Supabase

1. Buka Supabase SQL Editor.
2. Jalankan seluruh isi `backend/database.sql`.
3. Isi `SUPABASE_URL` dan `SUPABASE_ANON_KEY` di `frontend/app.js`.
4. Pastikan status aplikasi berubah menjadi `Supabase tersambung`.

Aplikasi menggunakan publishable/anon key di frontend. Jangan pernah menaruh `service_role` key di `app.js` atau mengunggahnya ke GitHub. Policy SQL saat ini terbuka untuk aplikasi internal; tambahkan autentikasi dan policy berbasis user sebelum dipakai publik.

Jika konfigurasi Supabase belum diisi, aplikasi berjalan dalam mode demo lokal menggunakan `localStorage`.
# Sistem-Akuntansi-Modal-Prive-dan-Laporan-Perubahan-Ekuitas-pada-perusahaan-Percetakan
# Sistem-Akuntansi-Modal-Prive-dan-Laporan-Perubahan-Ekuitas-pada-perusahaan-Percetakan
