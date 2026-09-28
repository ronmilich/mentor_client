# Mentor client

Flutter application with a persistent bottom navigation bar: Today, Levels,
Tasks, Journal, and More. Today is the default screen. Levels connects to the
local Nest backend; the other tabs are placeholders.

## Structure

- `lib/main.dart`: application entry point.
- `lib/app.dart`: application theme and router lifecycle.
- `lib/models/`: UI-independent models, including the ordered tab definitions.
- `lib/routing/`: `go_router` configuration and view-model composition.
- `lib/config/`: local API address and optional development user selection.
- `lib/data/services/`: shared HTTP transport, timeouts, and server errors.
- `lib/data/repositories/`: typed Levels API operations and change notifications.
- `lib/ui/main/views/`: the main shell and bottom navigation.
- `lib/ui/main/view_models/`: navigation presentation state and commands.
- `lib/ui/<feature>/views/`: separate views for each tab.
- `lib/ui/core/`: shared presentation widgets.

The main screen follows MVVM: `AppTab` describes destinations,
`MainViewModel` exposes selection and navigation commands, and `MainScreen`
renders the UI. The view model does not depend on Flutter or `go_router`.
The router supplies an immutable view-model snapshot whenever the route changes,
keeping deep links and the selected tab synchronized.

Levels uses `ChangeNotifier` view models for loading, saving, errors, and duplicate
submission protection. Views render the state; the repository handles API calls
and model decoding. Repository change notifications refresh mounted detail and
history views after mutations. Dependencies are injected for tests.

`StatefulShellRoute.indexedStack` gives each tab an independent navigator and
retains visited tabs when switching. Selecting the active tab is a no-op.
Routes are `/today`, `/levels`, `/tasks`, `/journal`, and `/more`; `/` redirects
to `/today`. Each route is also named after its tab in lowercase.

## Development

```sh
flutter pub get
flutter run
flutter analyze
flutter test
```

## Local backend

Start the sibling `mentor-backend` project with `npm run dev` (its actual watch
script), with PostgreSQL configured by that project's `.env`. The server listens
on port 3000 by default. This implementation adds workflow endpoints to that
backend because it previously exposed only level CRUD.

```sh
# Android emulator: connects to the host at http://10.0.2.2:3000 by default
flutter run -d emulator-5554

# Physical Android device on the same network: supply the development PC address
flutter run --dart-define=API_BASE_URL=http://YOUR_PC_LAN_IP:3000

# Optional: preselect a development profile by its existing backend UUID
flutter run --dart-define=MENTOR_USER_ID=YOUR_USER_UUID
```

HTTP is enabled for Android debug builds. Other platforms default to
`http://localhost:3000`. A physical device requires the PC firewall to allow the
local server. The project currently targets Android; Flutter web hosting and
backend CORS are not configured.

The profile selector loads existing `/users`. A single profile is selected
automatically. This matches the current local backend, whose authentication
guard is disabled; profile selection is not authentication. No user IDs or
credentials are embedded in the app.

## Levels navigation

All pages stay within the Levels tab and support direct routes and back navigation.

| Screen | Route |
| --- | --- |
| Levels | `/levels` |
| Create level | `/levels/create?userId=UUID` |
| Level detail | `/levels/:levelId` |
| Edit level | `/levels/:levelId/edit` |
| Add/edit item | `/levels/:levelId/edit/items/new` or `/items/:itemId` |
| Start confirmation | `/levels/:levelId/start` |
| Restart confirmation | `/levels/:levelId/restart` |
| Attempt history | `/levels/:levelId/attempts` |
| Attempt detail | `/levels/:levelId/attempts/:attemptId` |
| Historical day | `/levels/:levelId/attempts/:attemptId/days/:dayId` |

Create the level definition first, then add DO/AVOID items. Items have a title,
optional description, display order, and active flag. Items are deactivated
rather than deleted so historical references remain intact.

Starting requires at least one active item and creates Day 1 using the device's
calendar date. One attempt may be active per user. Restart marks the expected
active attempt `ABANDONED`, retains its history, and creates a new attempt in a
single transaction. Stale/duplicate starts and restarts return conflicts.

Attempts snapshot required days; day results snapshot item titles and types.
Editing a definition never rewrites recorded history. Daily evaluation,
day rollover/completion, and failed-attempt-limit enforcement belong to the
future Today workflow; this change stores the existing maximum-failed-attempts
setting but does not introduce those policies.

## Backend workflow endpoints

Existing `/levels` CRUD is retained. Added endpoints:

- `GET /levels/:id/overview` — definition, items, and attempts.
- `POST /levels/:id/items` and `PATCH /levels/:id/items/:itemId` — save an item.
- `POST /levels/:id/start` — `{ "date": "YYYY-MM-DD" }`.
- `POST /levels/:id/restart` — date plus expected `attemptId`.
- `GET /levels/:id/attempts` — history with recorded days.
- `GET /levels/:id/attempts/:attemptId` — attempt detail.
- `GET /levels/:id/attempts/:attemptId/days/:dayId` — immutable day snapshots.

## Verification

`flutter test` covers navigation, forms, nested pages, errors, and confirmation
flows with injected HTTP responses. Backend Levels tests run with:

```sh
npm test -- --runInBand --testPathPatterns=levels
```

For an end-to-end check against the running local database and server, run from
the Flutter project:

```powershell
powershell -NoProfile -File tool/verify_levels_backend.ps1
```

This exercises the actual Dart repository against the API using a disposable
profile. The wrapper deletes only that profile's test records afterward, using
the sibling backend's local database configuration. If interrupted, run
`node tool/cleanup_levels_smoke.cjs` before rerunning. The receipt in
`.dart_tool/levels-smoke-receipt.json` identifies the exact test profile.
