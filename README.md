# FixCity — منصة البلاغات البلدية

A cross-platform civic reporting app built with Flutter and Supabase. Citizens can report infrastructure problems (potholes, trash, lighting, sewage, water, etc.), track their reports in real time, and receive status updates — all in Arabic or English.

Developed as a graduation project at **Badr University in Cairo**.

---

## Features

### Citizen App
- **Submit reports** — pick a category, write a description, attach a photo, and pin the location on an interactive map
- **Track reports** — look up any report by its unique code and follow status updates live
- **My Reports** — logged-in users see a full history of their own submissions
- **Achievements** — points and badges for active reporters
- **Bilingual UI** — full Arabic (RTL) and English support, switchable at runtime
- **Push-style notifications** — in-app notification center for report status changes

### Admin Dashboard
- Secure admin login (separate from citizen accounts)
- View, filter, and search all submitted reports
- Update report status (Pending → In Progress → Resolved)
- Leave notes and status-update history per report

### Governor Dashboard
- Governor-level login with a separate portal
- Overview of reports grouped by district/category
- Drill down into individual report details

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter / Dart (iOS, Android, Web) |
| Backend & DB | Supabase (PostgreSQL + Auth + Storage) |
| Maps | flutter\_map (OpenStreetMap — zero API cost) |
| Geolocation | geolocator |
| Image upload | image\_picker + Supabase Storage |
| Localisation | flutter\_localizations + intl |

---

## Project Structure

```
app/
└── lib/
    ├── main.dart                  # App entry, routing, Supabase init
    ├── main_scaffold.dart         # Bottom nav scaffold
    ├── theme.dart                 # Shared colours & constants
    ├── translations.dart          # AR/EN string map
    ├── home_page.dart             # Home feed with stats & quick-launch
    ├── report_page.dart           # Submit a new report
    ├── track_page.dart            # Track a report by code
    ├── my_reports_page.dart       # User's own reports list
    ├── profile_page.dart          # Account info & settings
    ├── settings_page.dart         # Language, account, about
    ├── notifications_page.dart    # In-app notifications
    ├── achievements_page.dart     # Points & badges
    ├── login_page.dart            # Auth — login
    ├── signup_page.dart           # Auth — register
    ├── splash_page.dart           # Onboarding + language picker
    ├── admin/
    │   ├── admin_login_page.dart
    │   ├── admin_dashboard_page.dart
    │   └── report_details_page.dart
    └── governor/
        ├── governor_login_page.dart
        ├── governor_dashboard_page.dart
        └── governor_report_page.dart
```

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- Dart SDK (bundled with Flutter)
- Git
- A Supabase project (or use the existing one — see below)

### Clone & install

```bash
git clone https://github.com/moatazahmedshaker/Fixcity.git
cd Fixcity/app
flutter pub get
```

### Supabase configuration

The app is already wired to a live Supabase project. If you want to use your own, open [app/lib/main.dart](app/lib/main.dart) and replace the two constants at the top:

```dart
const supabaseUrl     = 'YOUR_PROJECT_URL';
const supabaseAnonKey = 'YOUR_ANON_KEY';
```

Your Supabase project needs the following:

**Tables** (public schema, RLS enabled)

| Table | Key columns |
|---|---|
| `reports` | `id`, `report_code`, `user_id`, `category`, `description`, `status`, `lat`, `lng`, `address`, `photo_url`, `created_at` |
| `status_updates` | `id`, `report_id`, `status`, `note`, `created_at` |
| `profiles` | `id` (= auth user id), `full_name`, `phone`, `points`, `sms_enabled` |
| `notifications` | `id`, `user_id`, `message`, `is_read`, `created_at` |

**Storage bucket:** `reports_bucket` (public read, authenticated write)

**RLS policies:** allow `INSERT` and `SELECT` for `anon` and `authenticated` on `reports`; `SELECT` for both on `status_updates`; `SELECT` + `UPDATE` for `authenticated` on `profiles`.

### Run

```bash
# Mobile (with a device/emulator connected)
flutter run

# Web
flutter run -d chrome

# Specific platform
flutter run -d android
flutter run -d ios
```

To access the Admin Dashboard on web, navigate to `http://localhost:<port>/#/admin` after launching.

---

## Team

| Name | Role |
|---|---|
| Ahmed Wael Ali | Developer |
| Moataz Ahmed Shaker | Developer |
| Shehab Elamir | Developer |
| Mohamed Salaheldin | Developer |
| Mohamed Ahmed Abdelsalam | Developer |
| George Armia | Developer |

**Institution:** Badr University in Cairo

---

## License

All rights reserved © 2025–2026 FixCity Team, Badr University in Cairo.
