# CUT Clinic Appointment Management System - Flutter student app

Student mobile app for the ITC327W project (Group: All Safe Tech). It talks to the
shared Supabase backend that the ASP.NET Core staff web app also uses.

## Quick start (about 10 minutes)

### 1. Supabase
1. Create a project at supabase.com.
2. Open **SQL Editor -> New query**, paste all of `supabase/schema.sql`, click **Run**.
3. **Authentication -> Providers -> Email**: turn **off** "Confirm email" for the demo
   (otherwise students must click an email link before they can log in).
4. **Project Settings -> API**: copy the **Project URL** and the **anon public** key.
   Never use the `service_role` key in the app.

### 2. Flutter
Requires Flutter 3.22+ (Dart 3.4+) and an Android phone or emulator.

```bash
# Windows (PowerShell)         # macOS / Linux
./setup.ps1                    ./setup.sh
```
This generates the Android project files, adds the INTERNET permission, creates
`env.json` and runs `flutter pub get`. Put your Supabase URL and anon key in `env.json`, then:

```bash
flutter run --dart-define-from-file=env.json
```

Build an APK: `flutter build apk --dart-define-from-file=env.json`

`env.json` is git-ignored (SRS NFR5/R05). Commit only `env.example.json`.

### 3. Try the full flow
1. Register a student (9-digit student number, SA cell number).
2. Request an appointment -> status **Pending review**.
3. Create a staff user (instructions at the bottom of `schema.sql`), then in the SQL
   editor approve it and assign a slot:
   ```sql
   update public.appointments
      set status = 'approved', appointment_date = current_date + 1, appointment_time = '09:30'
    where status = 'pending';
   ```
   The app updates live and a notification appears. Change the date/time to see the
   "rescheduled" notification; run `select public.queue_day_before_reminders();` to
   see the day-before reminder (the appointment must be tomorrow).

## Project structure
```
lib/
  main.dart, app.dart          entry point, auth gate
  core/                        config, theme, validators, friendly errors
  models/                      Appointment, StudentProfile, AppNotification
  services/clinic_service.dart ALL Supabase calls (auth, appointments, notifications)
  widgets/common.dart          shared UI pieces
  screens/
    auth/                      login, register, student gate
    home/                      bottom-nav shell + dashboard
    appointment/               request -> review -> my appointment (+ cancel)
    notifications/             notification list
    profile/                   details + appointment history + log out
supabase/schema.sql            tables, RLS, RPCs, notification triggers, reminders
test/widget_test.dart          model + validator unit tests (`flutter test`)
```

## SRS traceability
| Requirement | Where |
|---|---|
| FR1-FR3 register as CUT student | `register_screen.dart`, `students` table + `handle_new_user` trigger |
| FR4, FR7 login / logout | `login_screen.dart`, `profile_page.dart` |
| FR6, IR15 students cannot use staff functions | RLS: students have no write policies; staff accounts refused in `student_gate.dart` |
| FR8, FR9 request + record time | `request_appointment` RPC, `created_at` |
| FR14, NFR24 one active appointment | partial unique index + RPC check |
| FR13 no double-booked slot | `no_double_booked_slot` index |
| FR15, FR16 status, date, time | `my_appointment_page.dart` |
| FR17 student cancel | `cancel_appointment` RPC + confirm dialog |
| FR18 staff cancel/reschedule | staff update policy (web app) |
| FR20-FR25 notifications + reminder | `queue_appointment_notifications` trigger, `queue_day_before_reminders()` |
| FR30 history | `profile_page.dart` |
| NFR2 own data only | RLS `appointments_select` |
| NFR4 no plaintext passwords | Supabase Auth |
| NFR14, NFR22, NFR26 clear errors / network failures | `core/errors.dart`, `ErrorView` |
| IR9, IR25 staff changes reach student app | Supabase Realtime streams |

## Prototype limitations (match SRS section 29)
- **SMS/email delivery is simulated.** The database queues `SMS` and `Email` rows
  (`status = 'queued'`). A real sender (Supabase Edge Function + SMS/email provider)
  would pick them up and mark them `sent`/`failed`. The app shows each event once.
- **Student number is format-checked only** (9 digits). Validation against CUT systems is
  out of scope. Registration-proof upload is not implemented (Document table is optional).
- Added beyond the ERD, with reason: status `completed` (frees the "one active" slot after
  the visit), `notifications.created_at` (queue time, since `sent_at` is only set on delivery).
- Android only (SR8). Push notifications are postponed per the SRS.
