# FixCity — Unified Civic Reporting Platform

> A cross-platform application that lets Egyptian citizens report non-emergency street and infrastructure problems directly to municipal authorities — with real-time status tracking.

**Graduation project · Badr University in Cairo · 2025–2026**
**Accepted into Google's Gemini for Graduation Projects program.**

---

## What it does

Citizens can open the app, drop a pin on a map, upload a photo, and submit a report in under a minute. Each report gets a unique tracking code. Authorities manage everything from a web admin dashboard — viewing, filtering, assigning, and updating report statuses in one place.

**Google Gemini AI** automatically classifies incoming reports by category, reducing manual triage work for municipal staff.

---

## Tech stack

| Layer | Technology |
|---|---|
| Mobile + Web frontend | Flutter / Dart (single codebase) |
| Backend & database | Supabase (PostgreSQL) |
| Geospatial queries | PostGIS |
| Mapping | Flutter Map (Leaflet — no API costs) |
| File storage | Supabase Storage |
| AI classification | Google Gemini AI |
| Auth | Supabase Auth |

---

## Key features

- **Geolocation** — interactive map pinpointing with PostGIS-backed precision
- **Photo evidence** — anonymous upload to Supabase Storage
- **Public tracking** — unique report code lets citizens follow their submission
- **Admin dashboard** — web panel for authorities to view, filter, assign, and update reports
- **AI triage** — Gemini AI classifies report type automatically on submission
- **User accounts** — optional sign-up to view personal report history

---

## Architecture

```
Flutter App (Mobile + Web)
        │
        ▼
  Supabase Client
        │
   ┌────┴────┐
   │         │
PostgreSQL  Supabase     Gemini AI
+ PostGIS   Storage      (classification)
```

The app and admin dashboard share a single Flutter codebase. Row-level security (RLS) is enabled on all tables. The admin route is accessible only to authenticated users with an admin role.

---

## Running locally

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Git
- A Supabase project ([supabase.com](https://supabase.com))

### Setup

```bash
git clone https://github.com/DoctorJhin/Fixcity.git
cd Fixcity/app/fixcity
flutter pub get
```

Open `lib/main.dart` and add your Supabase credentials:

```dart
const supabaseUrl = 'YOUR_SUPABASE_URL';
const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### Run

```bash
# Mobile
flutter run

# Web admin panel
flutter run -d chrome
# Then navigate to http://localhost:[port]/#/admin
```

---

## Supabase configuration checklist

**Database tables** (public schema, RLS enabled):
- `reports` — report_code, photo_url, latitude, longitude, user_id, category, status
- `status_updates` — report_id (FK), status, updated_at

**Storage:**
- Bucket: `reports_bucket`

**RLS policies:**
- `reports` → INSERT + SELECT for `anon` and `authenticated`
- `status_updates` → SELECT for `anon` and `authenticated`
- `reports_bucket` → INSERT + SELECT for `anon` and `authenticated`

---

## Developer notes

- All geospatial data is stored and queried via PostGIS — location precision is maintained throughout the stack
- Gemini AI output is validated before writing to the database to prevent misclassification from polluting reports
- The admin dashboard is Flutter Web — no separate frontend codebase needed

---

## Credits

**Developer:** Ahmed Wael Ali ([github.com/DoctorJhin](https://github.com/DoctorJhin))
**Institution:** Badr University in Cairo — Business Information Systems
**License:** MIT
