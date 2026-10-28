# HMS implementation

## 1. Firestore schema

All money values are integer INR paise. Student document IDs and room occupants are **Auth UIDs**, not roll numbers. Roll numbers are trimmed/lowercased. Dates use Firestore timestamps.

| Collection / document | Fields |
|---|---|
| `users/{uid}` | `role: admin/student`, `name`, `rollNo` (student), `mustChangePassword`, `provisioning` |
| `students/{uid}` | `authUid`, `rollNo`, `email`, `name`, `fatherName`, `contact`, `fatherContact`, `branch`, `year: 1..4`, `caste`, `address`, `roomId` (nullable), `block`, `roomNumber`, `feeTotal`, `manualPaid`, `onlinePaid`, `feeStatus: paid/unpaid/partial`, `createdAt` |
| `rollNumbers/{normalizedRoll}` | `uid`, `state: pending/ready`, `createdBy`, `createdAt` — unique roll reservation |
| `rooms/{hashOfBlockAndNumber}` | `block`, `number`, `capacity`, `occupantIds: uid[]`, `occupied` |
| `complaints/{id}` | `studentId: uid`, `title`, `description`, `attachmentPath`, `status: open/resolved`, `remark`, `createdAt`, optional `resolvedAt` |
| `notices/{id}` | `title`, `body`, `attachmentPath`, `postedBy: uid`, `createdAt` |
| `feedback/{id}` | `studentId: uid`, `category`, `rating: 1..5`, `message`, `createdAt` — preserved existing feature |
| `devices/{tokenHash}` | `uid`, `role`, `token`, `updatedAt` — server-only |
| `paymentOrders/{razorpayOrderId}` | `uid`, `amount`, `currency`, `receipt`, `status`, `createdAt`, optional `paymentId` |
| `payments/{razorpayPaymentId}` | `uid`, `orderId`, `amount`, `currency`, `receipt`, `status: captured`, `paidAt`, `createdAt` |
| `paymentLocks/{uid}` | Temporary order creation lease / reusable pending order — server-only |
| `feeAdjustments/{id}` | `uid`, `feeTotal`, `manualPaid`, `by: adminUid`, `createdAt` |

Blocks are grouped from live room documents; a separate block collection is unnecessary. Students can see occupancy but cannot read other occupants' personal records. Administrators can inspect occupant details.

## 2. Rules

- `firestore.rules`: requires both custom claim and matching user role; own student data only; first-login users can only read their account document. Complaints enforce ownership, initial status, limits, timestamps, and attachment paths.
- `storage.rules`: private complaint attachments, student-readable notices; JPG/PNG/PDF/TXT only, up to 5 MB; no executable uploads or replacement of existing attachments.
- Administrator workflows have full business access through callables. Role, occupancy, provisioning, and payment writes remain Admin SDK-only, including for admin clients, to preserve invariants.
- `firestore.indexes.json`: complaint/payment history indexes.
- Attachments are downloaded using authenticated Storage reads, not permanent public download URLs. `storage.cors.json` lists web origins; add your production domain before applying it.

## 3. Cloud Functions

Node 22, second-generation functions, region `asia-south1`.

| Function | Purpose |
|---|---|
| `allotStudent` | Validate, transactionally reserve room/roll, create Auth account with Admin SDK, set student claim and first-login flag |
| `changePassword` | Require recent reauthentication, update password, clear first-login flag, revoke old sessions |
| `saveRoom` | Optional server equivalent; the app saves room metadata through a restricted Firestore transaction |
| `moveStudent` | Transactional room change or vacancy; reads current assignment inside transaction |
| `updateFee` | Change total/manual payment, calculate status, save audit record |
| `registerDevice` | Register/remove device and subscribe students to topic `students`, including web |
| `complaintNotification` | Notify registered admin devices when a complaint is created |
| `noticeNotification` | Notify topic `students` when a notice is created |
| `createPaymentOrder` | Calculate outstanding balance server-side and create/reuse a Razorpay order |
| `razorpayWebhook` | Validate raw-body HMAC, check order amount/currency, atomically settle once by payment ID |

Provisioning spans Auth and Firestore, which cannot share a transaction. Pending reservations are explicit. Retry the **same roll number** to resume after a network failure; the original saved details/password remain authoritative. An existing conflicting Auth email requires administrator reconciliation. Never delete pending profiles or room occupants independently.

Payment callbacks only close checkout. A signed `payment.captured` or `order.paid` webhook changes the balance. Duplicate deliveries are idempotent. Missing order records return HTTP 500 so Razorpay retries. Changed fees or late payments can produce a credit, displayed to the student for administrator reconciliation. Refund processing is outside this implementation; reconcile refunds with a separate audited workflow.

## 4. Flutter files

```text
lib/
  main.dart                         Firebase init, persistent auth, role/first-login gate
  firebase_options.dart             Generated real Firebase configurations
  models/account.dart               Typed account model
  providers/session_provider.dart   Auth/profile streams and password/session lifecycle
  services/
    hms_service.dart                Firestore streams, callables, private attachments
    notification_service.dart       Permission, token refresh, server topic subscription
    checkout.dart                  Conditional platform export
    checkout_native.dart           razorpay_flutter (Android/iOS)
    checkout_web.dart              Standard Razorpay Checkout via JS interop
  screens/
    auth_screen.dart                Login and required/optional password change
    home_screen.dart                Responsive navigation rail/bottom navigation
    students_screen.dart            Allotment, details, room moves, fee editing
    rooms_screen.dart               Live blocks → rooms → occupants
    posts_screen.dart               Notices, complaints, attachment viewing, resolution
    payments_screen.dart            Balance and verified payment history
    feedback_screen.dart            Student ratings/comments and admin live feedback
  widgets/live_list.dart             Stream/error/empty states, async actions
functions/
  index.js                          Callable functions and triggers
  domain.js                         Validation, occupancy and HMAC helpers
  payments.js                       Idempotent transactional settlement
  bootstrap-admin.js                Trusted operator-only admin setup
  test/                             Domain, rules, Storage and transaction tests
web/checkout.js                     Browser checkout adapter
web/firebase-messaging-sw.js         Generated background messaging worker
tool/generate_fcm_worker.js          Regenerate worker after FlutterFire configuration
```

## 5. Setup / run

1. **Firebase project:** `hostel-iert`. Android and web registrations were verified; iOS was registered and generated with FlutterFire. Enable Email/Password in Authentication. Create Firestore and Storage. Functions/Storage require a billing-enabled plan. Add your web domain and localhost to Auth authorized domains as needed.
2. **Configuration regeneration, when needed:**

   ```powershell
   firebase login
   flutterfire configure --project=hostel-iert --platforms=android,ios,web --android-package-name=com.example.hms --ios-bundle-id=com.example.hms
   node tool/generate_fcm_worker.js
   flutter pub get
   ```

3. **Windows:** enable Settings → System → Advanced → Developer Mode if Flutter reports missing symlink support. This is needed for plugin tooling. Supported app targets here are Android, iOS and web.
4. **Android:** `android/app/google-services.json` and Google Services Gradle plugin are configured; Internet/notification permissions are included. Use a device/emulator with Google Play services. Configure release signing before distribution. Kotlin incremental compilation is disabled in `android/gradle.properties` because this workspace is on E: and its Pub cache is on C:, which caused cross-drive cache failures. This trades some incremental build speed for reliable compilation; see [Kotlin compilation settings](https://kotlinlang.org/docs/gradle-compilation-and-caches.html).
5. **iOS (Mac/Xcode required):** deployment target is iOS 15.0; Podfile and bundled `GoogleService-Info.plist` are included. Run `pod install` in `ios`, open `Runner.xcworkspace`, select your Apple signing team, enable Push Notifications and Background Modes → Remote notifications, and upload your APNs authentication key to Firebase Cloud Messaging. Keep Firebase method swizzling enabled. Build/test on a physical iPhone.
6. **Web FCM:** create a Web Push certificate in Firebase Console → Project Settings → Cloud Messaging. Use its **public** VAPID key with `--dart-define=FCM_VAPID_KEY=...`. Serve over HTTPS or localhost. The root `firebase-messaging-sw.js` is auto-registered by Firebase Messaging. Press the bell button after login to grant permission/register the device. Foreground updates show a snackbar; background notifications use FCM.
7. **Storage CORS:** review allowed origins in `storage.cors.json`, then run:

   ```powershell
   gcloud storage buckets update gs://hostel-iert.firebasestorage.app --cors-file=storage.cors.json
   ```

8. **Backend dependencies/secrets:** use Node 22 for deployment. Never put Razorpay secrets into Flutter, Git, or chat.

   ```powershell
   npm --prefix functions ci
   firebase functions:secrets:set RAZORPAY_KEY_ID --project hostel-iert
   firebase functions:secrets:set RAZORPAY_KEY_SECRET --project hostel-iert
   firebase functions:secrets:set RAZORPAY_WEBHOOK_SECRET --project hostel-iert
   ```

9. **Admin:** `rishabhyadav2400@gmail.com` was explicitly selected and configured with the admin custom claim and matching user profile; email/password provider was verified. Sign out/in to refresh claims. For another explicitly approved administrator, set Application Default Credentials and `GOOGLE_CLOUD_PROJECT=hostel-iert` on a trusted operator machine, then run `node functions/bootstrap-admin.js AUTH_UID_OR_EMAIL`. Do not grant roles based on the legacy `admins` collection; old rules allowed users to self-create admin documents.
10. **Existing data:** this schema is incompatible with old roll-keyed students/rooms/fees. Export/backup before deployment. Migrate student document IDs and references to Auth UIDs, normalize rolls, change student Auth emails to `<roll>@hms.app`, create matching role profiles/claims, convert money to paise, and reconstruct room occupants from assignments. Preserve historical payments as migrated records; do not invent Razorpay IDs or count them twice. Review roles from a trusted roster. No live records were migrated or deleted by this refactor.
11. **Deploy after migration and secret configuration:**

   ```powershell
   firebase deploy --only "firestore,storage,functions" --project hostel-iert
   flutter build web --dart-define=FCM_VAPID_KEY=YOUR_PUBLIC_VAPID_KEY
   firebase deploy --only hosting --project hostel-iert
   ```

12. **Razorpay dashboard:** enable automatic capture. Add the deployed `razorpayWebhook` URL (from deploy output; default `https://asia-south1-hostel-iert.cloudfunctions.net/razorpayWebhook`), subscribe to `payment.captured` and `order.paid`, and use the same webhook secret. Verify with test keys before live keys. Both event deliveries are intentionally safe.
13. **Run / verify:**

   ```powershell
   flutter analyze
   flutter test
   firebase emulators:exec --project demo-hms --only "firestore,auth,storage" "npm --prefix functions test"
   flutter run -d chrome --web-port 8085 --dart-define=FCM_VAPID_KEY=YOUR_PUBLIC_VAPID_KEY
   # Or: flutter run -d YOUR_ANDROID_DEVICE
   ```

14. **Acceptance:** admin creates two rooms; allots a student; student logs in using roll/contact and must change password; admin/student in separate sessions verify live complaint → resolution and notice → notification; concurrently attempt the final bed; move/vacate; make a Razorpay test payment and replay its webhook to confirm a single payment record and balance update.

FCM delivery can be delayed, denied by device permission, or duplicated by event retries; Firestore remains the authoritative live state. Push registration failures are shown without blocking login. File uploads that succeed before an interrupted post write may leave orphan objects; reconcile against document attachment paths before periodic cleanup.

References: [Firebase Flutter setup](https://firebase.google.com/docs/flutter/setup), [custom claims](https://firebase.google.com/docs/auth/admin/custom-claims), [Flutter FCM](https://firebase.google.com/docs/cloud-messaging/flutter/get-started), [Razorpay webhook validation](https://razorpay.com/docs/webhooks/validate-test/), [Razorpay Flutter](https://pub.dev/packages/razorpay_flutter).

## Verification

- Firestore rules deployed to `hostel-iert` on 27 October 2026 and the active release verified against `firestore.rules`. This fixes the login profile permission error caused by the legacy rules. Cloud Functions, Storage rules, indexes, and Hosting still require the deployment steps above.

- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub`: 6 tests passed, including legacy student rendering and room form validation.
- Full Auth/Firestore/Storage emulator suite: 13 tests passed, including concurrent final-bed allotments, room changes/vacancy, duplicate payment settlement, ownership checks, first-login restrictions, attachments, and feedback validation.
- `flutter build web --no-pub`: passed, including Razorpay web interop.
- `flutter build apk --debug --no-pub`: passed; APK at `build/app/outputs/flutter-apk/app-debug.apk`. This is a debug build, not a signed production release.
- Backend npm installation audit: 0 reported vulnerabilities. Firebase app/compat overrides keep the test SDK on one compatible module instance; the gRPC override addresses the reported vulnerable transitive version.
- Real Razorpay settlement, APNs/FCM delivery, production data migration, and live deployment still require the setup above. iOS compilation requires Xcode on macOS.

## Student display and room save fixes

Older student documents are displayed using legacy field names where available. Missing or malformed fee amounts show Not recorded; they are never assumed to be zero. Records requiring migration cannot initiate accounting or room-move operations.

Room creation and capacity editing now use an admin-only Firestore transaction with deterministic IDs shared with the backend. Rules allow creating empty rooms and changing capacity, but prohibit client changes to occupants or occupied counts. This feature works without Cloud Functions. The attempted Functions deployment was blocked because hostel-iert requires a Blaze upgrade; student account provisioning, room moves, fee adjustments, payments, and push functions still need that deployment. Billing was not changed.

