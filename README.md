Fixcity: منصة البلاغات الموحدة (Unified Reporting Platform)
Project Overview:
Fixcity is a cross-platform application (Mobile App and Web Dashboard) designed to empower Egyptian citizens to report non-emergency street and infrastructure problems directly to municipal authorities. This project was developed as a graduation requirement and serves as a proof-of-concept for enhancing civic engagement and local governance efficiency.

Key Features
Geolocation: Users can pinpoint the exact location of the issue using an interactive map.
Photo Evidence: Users can upload photos to verify the problem.
Public Tracking: Citizens can track the real-time status of their report using a unique tracking code.
Admin Dashboard (Web): Authorities can view, filter, assign, and update the status of all incoming reports in a single interface.
Authentication: Users can sign up and view a history of their submitted reports.

Technical Stack
This project is built on a modern, cross-platform architecture utilizing a free, scalable backend.
Component, Technology, Description
Frontend, Flutter/Dart, "Single codebase for the native iOS, Android, and Web Admin Panel."
Backend/DB, Supabase (PostgreSQL), "Secure, open-source alternative to Firebase, used for Database (Postgres), Authentication, and File Storage."
Mapping, Flutter Map (Leaflet), Open-source mapping solution to ensure zero API costs.
File Storage, Supabase Storage, "Handles anonymous user photo uploads (e.g., potholes, trash)."

Getting Started (Setup for Developers)

To run and contribute to this project locally, follow these steps:

1. Prerequisites

You must have the following installed on your development machine:
Flutter SDK (>=3.0.0)
Git
Node.js / npm (required for the Firebase/Supabase CLI)

2. Clone the Repository

Copy and Paste these, one by one, into your terminal:
git clone (https://github.com/moatazahmedshaker/Fixcity.git
cd fixcity/app/fixcity

3. Install Dependencies

Navigate to the project root (fixcity/app/fixcity) and install the packages:

Terminal:
flutter pub get

4. Configure Supabase Connection

You must have a Supabase project created.

Go to the Supabase Dashboard -> Settings -> API.

Copy your Project URL and Anon Public Key.

Open lib/main.dart and paste the values into the constants:

const supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL_HERE'; 
const supabaseAnonKey = 'YOUR_SUPABASE_ANON_PUBLIC_KEY_HERE';

For the sake of this project, it's linked to my Supabase Dashboard.

5. Run the Application

Mobile App:
Terminal:
flutter run

Web Admin Panel:
Terminal:
flutter run -d chrome

To Access Admin Dashboard: Navigate to http://localhost:[port]/#/admin in your browser.

🔒 Supabase Configuration Checklist

For the app to run correctly, you must configure these settings in your Supabase Dashboard:

Database Tables: Ensure the following tables exist in the public schema with RLS enabled:

reports (Includes columns for report_code, photo_url, latitude, longitude, user_id, etc.)
status_updates (Includes report_id linking to the reports table)

Storage: Create a bucket named reports_bucket.

Security Policies (RLS):

Reports Table (reports): Policies must allow INSERT and SELECT for both anon (anonymous) and authenticated roles.
Status Updates Table (status_updates): Policies must allow SELECT for both anon and authenticated roles.
Storage Bucket (reports_bucket): Policies must allow INSERT and SELECT for anon and authenticated roles.

✍️ Contribution and Licensing

Project Lead/Developer: Ahmed Wael Ali / Moataz Ahmed Shaker - 

Institution: Badr University in Cairo

Contribution
All contributions must be made via Feature Branches and Pull Requests to the main branch.

License
[PLACE HOLDER]
