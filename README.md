# የግጥም መደብ (Poem Pad)

An offline-only, high-performance Flutter poetry and lyrics editor designed for Amharic and English writers on Android and Desktop platforms.

---

## ✨ Features

* 📏 **Real-Time Syllable Counting**
  * Accurately counts Amharic ሳድስ (6th order) syllables and English lexical vowel clusters.

* 🎨 **Dynamic Color Themes**
  * 7 customizable accent themes: **Red, Yellow, Green, Blue, Purple, Orange, Teal**.
  * Dynamic background and surface tinting with custom dim pill color palettes.

* 💾 **Offline SQLite Storage & Backup**
  * Full CRUD operations, title/content search, and tag filtering.
  * Soft-delete trash with 30-day automatic purge and instant restoration.
  * Full JSON backup and restore (merge/replace).

* 📄 **Export & Sharing Options**
  * Export poems directly to **TXT**, formatted **PDF**, or copy to clipboard.

* 🌐 **Bilingual Localization**
  * Instant runtime language switching between **Amharic (አማርኛ)** and **English**.

---

## 🛠️ Tech Stack

* **Framework:** Flutter 3.x / Dart 3.x
* **Database:** SQLite (`sqflite` on Android, `sqflite_common_ffi` on Desktop)
* **Preferences:** `shared_preferences`
* **PDF & Export:** `pdf`, `share_plus`, `file_picker`

---

## 🚀 Getting Started

### Prerequisites
* Flutter SDK (3.12.x or later)
* Android Studio or VS Code with Flutter extension
* Android SDK (API 34)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/poem-pad.git
   cd poem-pad
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run static analysis & test suite:
   ```bash
   flutter analyze
   flutter test
   ```

4. Launch the application:
   ```bash
   flutter run
   ```

---

## 📄 License
This project is licensed under the MIT License.
