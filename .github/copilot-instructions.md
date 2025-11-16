## Fixcity — Agent instructions

Objective
- Make safe, targeted changes to the Flutter app under `app/fixcity/` only. The `website/` folder is obsolete; ignore it.

Big picture (what this repo is)
- A multi-platform Flutter app (mobile, web, desktop) lives in `app/fixcity/`.
- Entry point: `lib/main.dart`. It initializes Supabase and registers routes.
- Core flow: user creates a report -> image is uploaded to Supabase Storage (`reports_bucket`) -> a record is inserted into the `reports` table with fields such as `report_code`, `photo_url`, `latitude`, `longitude`, `status`, `user_id`.
- Mapping: `lib/report_page.dart` uses `flutter_map` (OpenStreetMap) + `geolocator` to pick location.
- Auth & users: Supabase Auth is used (`Supabase.instance.client`) and referenced across several pages (`login_page.dart`, `signup_page.dart`, admin pages).

Key files to read before editing
- `lib/main.dart` — routes, Supabase initialization, RTL Directionality enforcer.
- `lib/report_page.dart` — image picking, upload to `reports_bucket`, report insert logic (preserve `_submitReport` behavior).
- `lib/home_page.dart`, `lib/login_page.dart`, `lib/signup_page.dart` — UI flows and auth calls.
- `lib/admin/*` — admin login, dashboard, and `report_details_page.dart` (server-side admin flows are still in-app via Supabase).
- `pubspec.yaml` — dependency list (supabase_flutter, flutter_map, geolocator, image_picker, random_string).

Project-specific patterns and conventions
- Text is primarily Arabic; UI uses RTL direction by wrapping app widgets in Directionality.rtl (see `main.dart`).
- Supabase is the single backend: avoid adding a second persistent backend without updating all data flows.
- Storage bucket name is hard-coded as `reports_bucket` in `report_page.dart`; changing it requires updating both upload and public URL retrieval.
- Report tracking codes are generated with `random_string` and stored as `report_code`. Keep that generation logic when refactoring.

Developer workflows (essential commands)
- From repository root run these in PowerShell (targeting the Flutter app):

```powershell
cd .\app\fixcity
flutter pub get
flutter analyze
flutter run -d windows   # or -d chrome, -d web-server, -d <device id>
```

Notes for editing and safety
- Do not remove or commit the Supabase keys in `lib/main.dart` without replacing them with environment-based access. If you must change keys, mark it and ask the maintainer.
- Preserve public method and widget signatures where other files reference them (for example: `ReportPage`, `_submitReport`, route names like `/admin/report/<id>`).
- If you change the shape of the `reports` record (rename/add fields), update every place that reads/writes it (UI pages and admin views).
- When adding native capabilities (location, camera), update platform manifests: `android/app/src/main/AndroidManifest.xml` and iOS `Info.plist`.

Integration points & externals
- Supabase: URL and anon key in `lib/main.dart`. Storage bucket `reports_bucket`; table `reports`.
- Map tiles: OpenStreetMap tile URL is used in `flutter_map` layers.
- Image uploads: `image_picker` used to obtain images and upload via `supabase.storage.uploadBinary`.

Quick examples (search these in code)
- Route registration: see `initialRoute` and `routes` map in `lib/main.dart` (includes `/report`, `/track`, `/admin`, etc.).
- Upload + insert (in `report_page.dart`): uploadBinary -> `getPublicUrl(fileName)` -> `supabase.from('reports').insert({...})`.

If tests or build fail
- Run `flutter analyze` first, fix lint/static errors. There are no unit tests in the app currently.

When to ask for clarification
- If a change touches Supabase schema, keys, or the storage bucket name — stop and ask. These are cross-cutting and need owner approval.

Contacts & next steps
- Start by running the app locally and opening `lib/report_page.dart`, `lib/main.dart`, and `lib/admin/report_details_page.dart` to understand the data flow before any behavior changes.

Thank you — leave a short PR description listing which files you changed and a one-line reason.
