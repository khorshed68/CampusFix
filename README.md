# CampusFix – Smart Campus Issue Reporting and Management System

> **Report. Track. Improve Your Campus.**

CampusFix is an iOS app, built with **Swift, SwiftUI and Firebase**, for a Mobile Computing course mini project. It has **three roles with role-based access control (RBAC)**:

- **Students** report campus maintenance problems (broken fans, faulty projectors, Wi-Fi problems and so on), upvote problems other students reported, and track each problem until it is fixed.
- **Maintenance Staff** receive assigned complaints, accept them, update progress, and mark them resolved with work notes.
- **Administrators** manage every complaint, assign complaints to staff, change status and priority, and manage student and staff accounts.

Roles are stored in Firestore and **enforced by Firebase Security Rules on the server**. Hiding buttons in the app is only a convenience.

> ⚠️ **Honest build status:** This project was written on Windows, and Windows cannot build iOS apps. It has **not been compiled or run yet.** You need a Mac with Xcode to build and test it (see [How to run](#9-how-to-run-on-macos-with-xcode)). If Xcode shows a compile error, check [Troubleshooting](#troubleshooting).

---

## Table of Contents
1. [Introduction](#1-introduction)
2. [Objectives](#2-objectives)
3. [Features](#3-features)
4. [Technology Stack](#4-technology-stack)
5. [System Architecture (MVVM)](#5-system-architecture-mvvm)
6. [Folder Structure](#6-folder-structure)
7. [Firebase Setup](#7-firebase-setup)
8. [JSON Parsing](#8-json-parsing)
9. [How to Run on macOS with Xcode](#9-how-to-run-on-macos-with-xcode)
10. [Configure an Administrator Account](#10-configure-an-administrator-account)
11. [Screenshots Checklist](#11-screenshots-checklist)
12. [Testing Procedure & Demo Workflow](#12-testing-procedure--demo-workflow)
13. [Known Limitations](#13-known-limitations)
14. [Lab Concepts Checklist](#14-lab-concepts-checklist)
15. [Final Requirements Checklist](#15-final-requirements-checklist)

---

## 1. Introduction

Campus maintenance problems often go unreported, get reported many times over, or nobody follows them up. CampusFix gives students one place to report a problem with a photo, building, location, category and priority. Everyone can see what has already been reported and upvote it instead of sending a duplicate. The status (Pending → In Progress → Resolved) and the administration's notes update in real time on every device.

## 2. Objectives

- Let students report campus problems quickly, with photo evidence.
- Avoid duplicate reports by showing all complaints and allowing upvotes.
- Let students track the status of their own complaints.
- Give administrators a dashboard to prioritise and manage complaints.
- Enforce role-based security **on the server** (Firebase Security Rules), not just in the UI.
- Demonstrate the Mobile Computing lab topics: SwiftUI state management, navigation, JSON parsing, the delegate pattern and Firebase.

## 3. Features

### Student
| # | Feature | Screen / File |
|---|---------|---------------|
| 1 | Register (always as a student) | `RegisterView.swift` |
| 2 | Log in / log out, session persistence | `LoginView.swift`, `ProfileView.swift` |
| 3 | Home dashboard with statistics and recent complaints | `StudentDashboardView.swift` |
| 4 | Submit a complaint (title, description, category, building, location, priority) | `ReportIssueView.swift` |
| 5 | Attach a photo (camera or library) | `ImagePicker.swift` |
| 6 | View all complaints | `AllIssuesView.swift` |
| 7 | Search, filter (category / status / priority), sort (latest / most upvoted / priority) | `IssueFilterBar.swift` |
| 8 | Upvote once per complaint | `IssueDetailView.swift` |
| 9 | My Reports with status and admin remarks | `MyReportsView.swift` |
| 10 | Complaint details, progress tracker, resolution notes | `IssueDetailView.swift` |
| 11 | Edit profile (name, student ID) | `EditProfileView.swift` |

### Maintenance Staff
| # | Feature | Screen / File |
|---|---------|---------------|
| 1 | Log in with an admin-created account | `CreateStaffAccountView.swift` (admin side) |
| 2 | Staff dashboard: assigned, new, accepted, completed | `StaffDashboardView.swift` |
| 3 | Assigned Complaints list (filter by stage, search) | `AssignedComplaintsView.swift` |
| 4 | Accept an assigned task | `IssueDetailView.swift` → `StaffTaskViewModel.acceptTask` |
| 5 | Update progress to In Progress / Resolved, with a work description and resolution notes | `StaffUpdateSheet.swift` |
| 6 | Read-only view of complaints not assigned to them | `IssueDetailView.swift` |

### Admin
| # | Feature | Screen / File |
|---|---------|---------------|
| 1 | Log in with an admin account (role set in the Firebase Console) | `AppCoordinator.swift` |
| 2 | Dashboard: total, pending, in progress, resolved, high-priority, unassigned, awaiting staff, upvotes | `AdminDashboardView.swift` |
| 3 | Complaints-by-category chart and resolution rate | `AdminDashboardView.swift` |
| 4 | Manage all complaints with search and filters | `AllIssuesView.swift` (Complaints tab) |
| 5 | **Assign / reassign / unassign** a complaint to staff | `AssignStaffView.swift` |
| 6 | Change status, **priority**, remarks and resolution notes | `AdminUpdateSheet.swift` |
| 7 | **User Management**: list and filter users, create staff accounts, switch student ↔ staff, deactivate | `UserManagementView.swift`, `CreateStaffAccountView.swift` |
| 8 | Demo tool: load sample complaints from JSON | `AdminDashboardView.swift` |

### Role permission matrix
Defined once in `Role.can(_:)` (`Models/User.swift`) and mirrored in `firestore.rules`:

| Permission | Student | Staff | Admin |
|------------|:------:|:-----:|:-----:|
| Register yourself | ✅ (as student only) | ❌ | ❌ |
| Report complaint / upload photo | ✅ | ❌ | ✅ (seed tool) |
| View all complaints and statuses | ✅ | ✅ (read-only) | ✅ |
| Upvote (once) | ✅ | ❌ | ❌ |
| Accept assigned task | ❌ | ✅ own only | ❌ |
| Set In Progress / Resolved + work notes | ❌ | ✅ own only | ✅ |
| Set any status, change priority, remarks | ❌ | ❌ | ✅ |
| Assign complaints to staff | ❌ | ❌ | ✅ |
| Create staff accounts, change roles, deactivate users | ❌ | ❌ | ✅ (not other admins) |
| Grant admin | ❌ | ❌ | ❌ (Firebase Console only) |

## 4. Technology Stack

| Item | Choice |
|------|--------|
| Language | Swift 5 |
| UI | SwiftUI (iOS 17+) + one UIKit screen (image picker) |
| IDE | Xcode 16 or newer (on macOS) |
| Auth | Firebase Authentication (email/password) |
| Database | Cloud Firestore (real-time listeners) |
| Images | ImgBB (free image hosting, REST API via `URLSession`) – only the public URL is stored in Firestore |
| Local data | JSON (`campus_data.json`, `sample_issues.json`) decoded with `JSONDecoder` |
| Architecture | MVVM |
| Navigation | `NavigationStack` + `TabView` |
| Concurrency | `async/await` |
| Charts | Swift Charts (built into iOS, no download) |
| Dependency manager | Swift Package Manager (Firebase iOS SDK 11.x) |

## 5. System Architecture (MVVM)

```
┌──────────────┐  user taps / types   ┌────────────────┐   calls    ┌───────────────────┐
│    VIEW      │ ───────────────────► │   VIEWMODEL    │ ─────────► │     SERVICES      │
│  (SwiftUI)   │                      │ ObservableObject│           │ AuthService       │
│ LoginView,   │ ◄─────────────────── │ @Published vars │ ◄──────── │ FirestoreService  │
│ ReportIssue… │  UI redraws itself   │ AuthViewModel…  │  results  │ ImgBBService      │
└──────────────┘                      └────────────────┘            │ JSONService       │
                                                                    └─────────┬─────────┘
                                                                              │
                                              Firebase Auth / Firestore / ImgBB API / Bundle JSON
```

- **Model**: plain data (`Issue`, `AppUser`, `CampusData`, `IssueStatus`, …).
- **View**: only shows data and forwards user actions. No Firebase code in views.
- **ViewModel**: holds screen state in `@Published` properties, validates input, and calls services.
- **Service**: the only layer that talks to Firebase or reads files.

### Firestore data model

```
users/{userId}
    name: String
    email: String
    studentId: String          (student ID, or staff ID for staff/admin)
    role: "student" | "staff" | "admin"
    isActive: Bool             (admins can deactivate accounts; missing = active)
    createdAt: Timestamp (server)

issues/{issueId}
    title, description, category, building, location: String
    priority: "Low" | "Medium" | "High" | "Critical"
    status:   "Pending" | "In Progress" | "Resolved"
    imageURL: String (optional – public ImgBB URL, must start with https://i.ibb.co/)
    reportedBy: String (user ID)
    reporterName: String
    reportedAt: Timestamp (server)
    upvoteCount: Int
    adminRemarks: String
    resolutionNotes: String
    updatedAt: Timestamp (server, set by admin/staff updates)
    assignedTo: String?        (staff user ID, set by admin)
    assignedToName: String?
    assignedAt: Timestamp?
    acceptedAt: Timestamp?     (set once by the assigned staff member)
    workDescription: String?   (written by staff)

issues/{issueId}/votes/{userId}
    userId: String
    votedAt: Timestamp (server)

Photos: uploaded to ImgBB (api.imgbb.com); Firestore stores only the returned public URL
```

Because the vote document ID **is** the user ID, one user can only ever have one vote per complaint.

### Maintenance workflow
```
Student reports ─► Pending / Unassigned
Admin assigns   ─► Pending / New Task          (assignedTo = staff)
Staff accepts   ─► Pending / Accepted          (acceptedAt set)
Staff updates   ─► In Progress                 (workDescription)
Staff resolves  ─► Resolved / Completed        (resolutionNotes required)
```
Reassigning a complaint clears `acceptedAt`, so the new staff member has to accept it again.

### Security model (server-side RBAC)
`firestore.rules` enforces the following. Every check uses the caller's **active** role read from `users/{uid}`:
- **Registration:** anyone can create their own profile, but **only** with `role == "student"`. Nobody can register as staff or admin.
- **Staff provisioning:** only an admin can create a profile with `role == "staff"` for another user, or switch an existing user between student and staff.
- **Admin provisioning:** only possible in the Firebase Console. No rule lets a client write `role: "admin"`, and admins can't edit other admins.
- **Own profile:** users can edit only their own `name` and `studentId`. Their `role`, `email` and `isActive` are locked.
- **Deactivated accounts** (`isActive == false`) fail every role check, and the app signs them out immediately.
- **Complaints:** students (and admins, for the seed tool) create them with default values only (`Pending`, 0 votes, no assignment).
- **Admin:** may change status, priority, remarks, resolution notes and assignment. The assignee must be an active staff member.
- **Staff:** may update **only complaints assigned to them**. They can accept once, set status to In Progress or Resolved only after accepting, and Resolved needs notes. They can't touch priority, assignment or remarks.
- **Students:** can upvote exactly +1 once. The vote document's ID is their UID, created in the same transaction. Votes can't be changed or deleted.
- **Photos:** only active students and admins can upload, into their own folder, images only, under 5 MB.

## 6. Folder Structure

```
CampusFix/                         ← open this folder on the Mac
├── CampusFix.xcodeproj            ← double-click to open in Xcode
├── CampusFix/                     ← all app source (auto-synced with Xcode)
│   ├── App/
│   │   ├── CampusFixApp.swift       @main entry point, configures Firebase
│   │   └── AppCoordinator.swift     root view: splash / login / student / admin
│   ├── Models/
│   │   ├── User.swift               AppUser, Role enum, Permission (RBAC table)
│   │   ├── Issue.swift              Issue, TaskStage workflow, IssueRoute
│   │   ├── IssueStatus.swift        IssueStatus, IssuePriority, BadgeDisplayable protocol
│   │   ├── IssueStatistics.swift    dashboard counters
│   │   └── CampusData.swift         Codable models for the JSON files
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift      login, register, session, profile
│   │   ├── IssueViewModel.swift     live complaint list, filter, sort, stats
│   │   ├── ReportIssueViewModel.swift  form validation + submit
│   │   ├── IssueDetailViewModel.swift  single complaint + upvote
│   │   ├── AdminViewModel.swift     status/priority updates, assignment, sample data
│   │   ├── StaffTaskViewModel.swift accept task, update progress (staff)
│   │   └── UserManagementViewModel.swift  users list, create staff, roles, deactivate
│   ├── Services/
│   │   ├── FirebaseService.swift    safe FirebaseApp.configure()
│   │   ├── AuthService.swift        Firebase Authentication
│   │   ├── FirestoreService.swift   Cloud Firestore
│   │   ├── ImageUploadService.swift ImgBB photo upload (multipart POST + JSON)
│   │   └── JSONService.swift        bundle JSON loading + JSONDecoder
│   ├── Views/
│   │   ├── Authentication/  SplashView, LoginView, RegisterView
│   │   ├── Dashboard/       StudentTabView, StudentDashboardView
│   │   ├── Issues/          ReportIssueView, AllIssuesView, IssueFilterBar,
│   │   │                    IssueDetailView, MyReportsView
│   │   ├── Staff/           StaffTabView, StaffDashboardView,
│   │   │                    AssignedComplaintsView, StaffUpdateSheet
│   │   ├── Admin/           AdminTabView, AdminDashboardView, AdminUpdateSheet,
│   │   │                    AssignStaffView, UserManagementView, CreateStaffAccountView
│   │   ├── Profile/         ProfileView, EditProfileView
│   │   └── Components/      ImagePicker (delegate), FormComponents, BadgeView,
│   │                        IssueCardView, CommonViews
│   ├── Resources/
│   │   ├── campus_data.json         buildings + categories
│   │   └── sample_issues.json       demo complaints for the seed tool
│   ├── Utilities/
│   │   ├── AppConstants.swift       colours, sizes, collection names
│   │   └── Extensions.swift         String/Date/View/UIImage helpers
│   ├── Assets.xcassets
│   └── GoogleService-Info.plist     ← YOU add this (not included)
├── firestore.rules                  ← paste into Firebase Console
├── Config/                          CampusFix.xcconfig + Info.plist (inject the ImgBB key)
├── .env                             ← ImgBB API key (git-ignored, NOT committed)
├── .env.example                     template for .env
├── firebase.json                    (only for optional Firebase CLI deploy)
├── GoogleService-Info.example.plist (what the real file looks like – not used)
├── README.md
└── VIVA_PREPARATION.md
```

> **Note:** The project uses Xcode 16's *folder-synchronised groups*. Xcode automatically includes any file you put in the `CampusFix/` folder. You don't need to "Add Files" manually.

## 7. Firebase Setup

You need a free Google account. All of these steps happen in a web browser.

### 7.1 Create the project
1. Go to <https://console.firebase.google.com> → **Add project** → name it `CampusFix`. You can turn Google Analytics off.
2. On the project overview page, click the **iOS+** icon to add an iOS app.
3. **Bundle ID:** `com.example.campusfix`. This must match Xcode's **Signing & Capabilities → Bundle Identifier**. If you change it in Xcode (for example to `com.yourname.campusfix`), register that same ID in Firebase.
4. Click **Register app**, then **Download GoogleService-Info.plist**.
5. Skip the "Add Firebase SDK" and "initialization code" steps. The project already does both.

### 7.2 Add `GoogleService-Info.plist` to the project
1. In Xcode, drag the downloaded file into the **CampusFix** folder (the yellow folder next to `Assets.xcassets`).
2. Tick **Copy items if needed** and make sure the **CampusFix** target is ticked.
3. The file name must be exactly `GoogleService-Info.plist`. If your browser renamed it to `GoogleService-Info (1).plist`, rename it.

If the file is missing, the app does **not** crash. It shows a "Firebase setup required" screen.

### 7.3 Enable Authentication
Firebase Console → **Build → Authentication → Get started → Sign-in method → Email/Password → Enable → Save**.

### 7.4 Create Cloud Firestore
1. **Build → Firestore Database → Create database**.
2. Pick a location near you (for example `asia-south1`). You can't change it later.
3. Start in **production mode**.
4. Open the **Rules** tab, delete everything there, paste the full contents of `firestore.rules`, and click **Publish**.

### 7.5 Image hosting (ImgBB, instead of Firebase Storage)
On new Firebase projects, Firebase Storage needs the paid Blaze plan, so CampusFix hosts complaint photos on **ImgBB** (free). The app uploads the photo to ImgBB, gets back a public URL (`https://i.ibb.co/...`), and saves **only that URL** in the complaint's `imageURL` field in Firestore.

**API key setup (already done in this project):**
1. The key is in the **`.env`** file in the project root:
   ```
   IMGBB_API_KEY=your_key_here
   ```
2. `.env` is listed in **`.gitignore`**, so it is never committed. `.env.example` is the template to share instead.
3. How the key reaches the app:
   `.env` → included by `Config/CampusFix.xcconfig` (`#include? "../.env"`) → `$(IMGBB_API_KEY)` in `Config/Info.plist` → read at runtime by `ImgBBService` via `Bundle.main.object(forInfoDictionaryKey: "ImgBBAPIKey")`.
4. To use a different key, get one at <https://api.imgbb.com> (free account), put it in `.env`, then in Xcode run **Product → Clean Build Folder** and build again.

**When copying the project to the Mac:** `.env` starts with a dot, so Finder hides it. Make sure it is copied too (in Finder, press **⌘⇧.** to show hidden files). If it's missing, the app still runs, but photo upload shows "ImgBB API key missing".

> ⚠️ Any key built into a mobile app can be extracted from the app by a determined person. That is acceptable for a class project and a free ImgBB account. A production app would send uploads through its own server. The security rules also only accept image URLs from `https://i.ibb.co/`.

**Nothing to set up in the Firebase Console for photos.** You can ignore the Storage page.

### 7.6 Firebase SDK (Swift Package Manager)
The project already lists the Firebase iOS SDK (`FirebaseAuth`, `FirebaseFirestore`, version 11.x). The **first time you open it on the Mac**, Xcode downloads the package automatically. This needs internet and takes a few minutes. Nothing was downloaded on your Windows laptop.

If Xcode reports "Missing package product": **File → Packages → Reset Package Caches**, then **File → Packages → Resolve Package Versions**.

## 8. JSON Parsing

**File:** `CampusFix/Resources/campus_data.json`
```json
{ "buildings": ["Academic Building", "Library", ...],
  "categories": ["Electrical", "Furniture", ...] }
```

**Model** (`Models/CampusData.swift`):
```swift
struct CampusData: Codable {
    let buildings: [String]
    let categories: [String]
}
```

**Loading** (`Services/JSONService.swift`):
```swift
guard let url = Bundle.main.url(forResource: "campus_data", withExtension: "json") else { throw ... } // 1. find
let data = try Data(contentsOf: url)                                                             // 2. read
let campusData = try JSONDecoder().decode(CampusData.self, from: data)                           // 3. decode
```

**Where it's used:**
- `ReportIssueViewModel.loadCampusData()` fills the **Building** and **Category** menus on the Report screen.
- `IssueViewModel.loadCategories()` fills the **Category** filter on the All Issues screen.
- `AdminViewModel.seedSampleIssues()` decodes `sample_issues.json` into `[SampleIssue]`, including the `IssuePriority` enum.

**Error handling:** if the file is missing, can't be read, has the wrong format, or is empty, `JSONService` throws a `JSONServiceError` with a clear message. The app then shows a warning banner and falls back to `CampusData.fallback`, so it never crashes.

**Live demo idea:** add `"Medical Centre"` to `buildings` in `campus_data.json` and run again. The new building appears in the menu. To show the error handling, break the JSON (for example delete a `]`), run, and the orange warning banner appears.

## 9. How to Run on macOS with Xcode

**Requirements:** a Mac running a recent macOS, **Xcode 16 or newer** (free from the Mac App Store), and internet access the first time.

1. Copy the whole `CampusFix` folder to the Mac (USB drive, Google Drive or GitHub).
2. Double-click **`CampusFix.xcodeproj`**.
3. Wait for **Package Dependencies** to finish resolving Firebase (progress shows in the Xcode toolbar).
4. Add `GoogleService-Info.plist` (see [7.2](#72-add-googleservice-infoplist-to-the-project)).
5. Select the **CampusFix** target → **Signing & Capabilities**:
   - **Team:** choose your Apple ID (Xcode → Settings → Accounts → add your Apple ID; a free account works for the simulator and your own phone).
   - If you see "bundle identifier is not available", change it to something unique such as `com.yourname.campusfix`, and register **the same ID** in Firebase.
6. Choose a simulator such as **iPhone 16** from the device menu at the top.
7. Press **⌘R** (Run).

**On a real iPhone:** connect it by cable, select it as the run destination, and turn on **Developer Mode** (Settings → Privacy & Security). The first time, trust the developer certificate (Settings → General → VPN & Device Management). Use a real iPhone if you want to demo the camera. The simulator only offers the photo library.

**Adding a photo to the simulator's library:** drag any image from Finder onto the simulator window.

### Troubleshooting
| Problem | Fix |
|---------|-----|
| "Firebase setup required" screen | `GoogleService-Info.plist` is missing or misnamed (see 7.2) |
| "Missing package product FirebaseAuth" | File → Packages → Reset Package Caches, then Resolve Package Versions |
| "You do not have permission to do this" | Rules not published, or the user is not an admin (see 7.4 and section 10) |
| Login says "Incorrect email or password" | Check that Email/Password sign-in is enabled (7.3) |
| Photo upload fails / "ImgBB API key missing" | `.env` missing or wrong key (see 7.5); then Product → Clean Build Folder and run again |
| Project won't open / "future Xcode version" | Use Xcode 16+ (the project uses folder-synchronised groups) |
| Build error mentioning `AuthErrorCode` | Make sure the Firebase package resolved to 11.x (Package Dependencies tab) |

## 10. Configure an Administrator Account

The app has **no** "register as admin" option, and the security rules reject any attempt to self-register as admin. Admins are promoted manually by the project owner in the Firebase Console:

1. Run the app and **register a normal account**, for example `admin.demo@youruniversity.edu` with a password only you know.
2. Firebase Console → **Firestore Database → Data → users** → open the document whose ID matches that user. You can find the UID under **Authentication → Users**.
3. Click the `role` field, change `student` to **`admin`**, and click **Update**.
4. In the app, the screen switches to the **Admin Dashboard** automatically (the profile is a real-time listener). If it doesn't, log out and log in again.

**Why is this secure?** The Firebase Console uses your owner privileges, but the app is bound by `firestore.rules`, which never lets a client set `role` to `admin`. No admin password is stored anywhere in the code.

### Configure a Maintenance Staff account (admin-created)
Staff can't register themselves. An admin provisions them in one of two ways:

**Option A – create a new staff account (recommended):**
1. Log in as admin → **Users** tab → the **person +** button (top right).
2. Enter the name, work email, staff ID and a **temporary password** → **Create Staff Account**.
3. The admin stays logged in. Behind the scenes, the app creates the account on a separate, temporary Firebase instance (`AuthService.createAccountForAnotherUser`), then writes the `role: "staff"` profile **with the admin's session**, so `firestore.rules` can verify the caller is an admin.
4. Give the temporary password to the staff member privately. They log in and see the **Staff Dashboard**.

**Option B – promote an existing user:** Users tab → tap the user → Role: **Maintenance Staff** → Save.

**Deactivating:** Users tab → tap the user → turn off **Account active** → Save. The user is signed out of the app immediately and blocked by the security rules. *(Their Firebase Auth login itself can only be disabled in Firebase Console → Authentication. See Known Limitations.)*

> In a large production system, staff provisioning would normally run in a server-side Cloud Function using the Firebase Admin SDK. This project uses an admin-only client flow guarded by security rules, because Cloud Functions need the paid Blaze plan and extra tooling.

### Sample accounts to create for the demo
| Role | Example email | How it's created |
|------|---------------|------------------|
| Student 1 | `student1@campusfix.test` | Register in the app |
| Student 2 | `student2@campusfix.test` | Register in the app |
| Admin | `admin@campusfix.test` | Register, then set `role: "admin"` in the Firebase Console |
| Staff | `electrician@campusfix.test` | Admin → Users → New Staff Account |

Choose your own passwords (6+ characters).

(Firebase does not send email to these addresses, so made-up addresses are fine for a demo. **Don't** put the passwords in the code or in this README.)

### Sample data
After logging in as admin, open **Dashboard → Demo Tools → Add Sample Complaints**. This reads `sample_issues.json` and creates 5 real `Pending` complaints in Firestore. Each tap adds them again, so tap it once.

## 11. Screenshots Checklist

Take these screenshots on the simulator (**⌘S** saves one to the Desktop) for your report:

- [ ] Splash screen
- [ ] Login screen (with a validation error shown)
- [ ] Registration screen
- [ ] Student dashboard with statistics
- [ ] Report an Issue form (filled in, with a photo)
- [ ] Building/category menu open (from JSON)
- [ ] Success alert after submitting
- [ ] All Issues list
- [ ] Search plus a filter applied
- [ ] Issue details (image, progress tracker, upvote)
- [ ] Upvote button after voting ("Upvoted")
- [ ] My Reports showing an admin remark
- [ ] Profile and Edit Profile
- [ ] Admin dashboard (stats + chart)
- [ ] Manage Complaint sheet (status + priority)
- [ ] Assign Complaint screen (staff list)
- [ ] User Management (role counts, list) + New Staff Account form
- [ ] Staff dashboard
- [ ] Assigned Complaints list
- [ ] Issue details as staff, with the "Accept Task" button
- [ ] Update Task sheet (work description, resolution notes)
- [ ] Student view of the final Resolved complaint with staff notes
- [ ] Firestore `users` doc showing `role: "staff"`
- [ ] Firestore Console showing `users`, `issues`, `votes`
- [ ] Firestore issue document showing an `imageURL` from i.ibb.co
- [ ] Firestore Rules tab (security)

## 12. Testing Procedure & Demo Workflow

Use **two simulators** (for example iPhone 16 and iPhone 16 Pro, via Window → Devices and Simulators, or by running twice with different destinations) to show real-time sync. Alternatively, use one simulator and log in and out.

### Demo script – the 3-role workflow (about 12 minutes)
**Before the demo:** create Student 1, Student 2, the admin (promoted in the console) and one staff account (admin → Users → New Staff Account). Three simulators (Student / Admin / Staff) side by side show the real-time sync best.

| Step | Who | Action | Expected result | Shows |
|------|-----|--------|-----------------|-------|
| 1 | — | Launch the app | Splash → Login | Splash, auth state |
| 2 | — | Tap **Log In** with empty fields | "Please enter a valid email address." | Validation |
| 3 | Student 1 | Log in | **Student** dashboard (5 tabs) | Role-based navigation |
| 4 | Student 1 | **Report** → "Ceiling fan not working", Electrical, Academic Building, Room 304, High, photo → Submit | Success alert after the save | JSON menus, ImgBB upload, Firestore |
| 5 | Student 2 | All Issues → open the fan → **Upvote** | 0 → 1, "Upvoted" (disabled) | Transaction, one vote |
| 6 | Admin | Log in | **Admin** dashboard: *Unassigned (Open)* = 1 | Different dashboard |
| 7 | Admin | Complaints → fan → review → **Manage Complaint** → priority Critical, remark "Assigning electrician" → Save | Priority badge turns red | Admin edits priority |
| 8 | Admin | **Assign to Staff** → choose the electrician → **Assign** | "Assigned to … · awaiting acceptance" | Assignment screen |
| 9 | Staff | Log in | **Staff** dashboard: *New (Not Accepted)* = 1 | Third dashboard |
| 10 | Staff | My Tasks → fan → **Accept Task** | Stage becomes *Accepted* | Staff accepts |
| 11 | Staff | **Update Progress** → In Progress, work: "Checked wiring, replacing capacitor" → Save | Status turns blue on every device | Staff progress |
| 12 | Student 1 | My Reports | *In Progress* + staff work note + admin remark | Real-time sync |
| 13 | Staff | Update Progress → **Resolved** with no notes → Save | Error: notes required | Validation |
| 14 | Staff | Resolved + notes "Capacitor replaced and tested" → Save | Stage *Completed* | Resolution |
| 15 | Student 1 | Open the complaint | Green **Resolved**, full progress tracker, work + resolution notes | Final status |
| 16 | Staff | Open a complaint **not** assigned to them | "Not assigned to you (read-only)", no buttons | RBAC in the UI |
| 17 | Admin | Users → Student 2 → turn off Account active → Save | Student 2 is signed out instantly | User management |
| 18 | — | Firebase Console → Rules Playground: student sets own `role` to `admin` | **Denied** | Server-side RBAC |

### Feature tests
| Test | Steps | Pass if |
|------|-------|---------|
| Session persistence | Log in, quit the app (⌘⇧H twice and swipe up), relaunch | Opens directly on the dashboard |
| Wrong password | Log in with the wrong password | "Incorrect email or password." |
| Duplicate email | Register an existing email | "An account with this email already exists." |
| Password mismatch | Different confirm password | Inline warning and error on submit |
| Offline submit | Turn off the Mac's Wi-Fi, submit | Upload error is shown; no success alert |
| Empty states | New project with no complaints | "No complaints yet" with a Report button |
| Missing JSON | Rename `campus_data.json` and run | Orange warning; "Main Campus" / "Other" fallback |
| Role security | As a student, edit `role` via code or REST | Firestore returns *permission denied* |
| Staff can't assign | Staff opens any complaint | No Assign / Manage buttons; the rules reject an `assignedTo` change |
| Staff only own tasks | Staff opens another staff member's task | Read-only; a forced update is *permission denied* |
| Staff can't reopen | Staff tries Pending (not offered); force it via code | Rule B rejects it (only In Progress / Resolved) |
| Accept before progress | Staff updates before accepting | "Please accept the task…" (and the rules require `acceptedAt`) |
| Reassignment | Admin reassigns an accepted task | The new staff member sees *New Task* (acceptance reset) |
| Assign to non-staff | Force `assignedTo` = a student's UID | Rule A rejects it (`isActiveStaffUser`) |
| Admin can't edit admins | Users → tap an admin | Read-only "managed in the Firebase Console" |
| Create staff keeps admin logged in | Create a staff account | Admin remains on the Users tab, and the new user is listed as Staff |
| Deactivated login | Deactivated user logs in | "Your account has been deactivated…" screen |
| Double upvote | Upvote, leave the screen and come back | Button already shows "Upvoted" |
| Listener cleanup | Open details, go back | `IssueDetailViewModel.stop()` removes the listener |

### Testing the security rules (optional, strong for the viva)
Firebase Console → Firestore → **Rules → Rules Playground**: simulate an `update` on `/users/{uid}` that sets `role: "admin"` while authenticated as that user. The result is **Denied**.

## Brand Identity (logo)

One official logo is used everywhere in the app:

| Where | Asset / component | Notes |
|-------|-------------------|-------|
| Home-screen app icon | `Assets.xcassets/AppIcon` (`AppIcon.png`, 1024×1024, opaque) | iOS rounds the corners itself |
| Splash screen | `CampusFixLogo` on `AppTheme.logoBackground` (#012050) | The logo tile blends into the screen |
| Login & Register | `CampusFixLogo(size:)` | Full logo with name and tagline |
| Student / Staff / Admin dashboards | `CampusFixLogo` in the header card + `BrandNavigationTitle` in the nav bar | `BrandNavigationTitle` uses `CampusFixMark` (emblem without text) because text is unreadable when small |

- **Theme colours** in `AppConstants.swift` were sampled from the logo: navy `#012560`, tile navy `#012050`, pin blue `#0079EF`.
- **Original files** are in `Branding/` (`CampusFix-logo-original.webp`, `CampusFix-logo-1024.png`). Use them in your report or slides.
- **To change the logo:** replace the three PNGs in `Assets.xcassets` (`AppIcon`, `CampusFixLogo`, `CampusFixMark`) and keep the same file names. No code changes are needed.
- If the home-screen icon still shows the old one on the simulator, delete the app from the simulator and run again.

## 13. Known Limitations

- **Not compiled on Windows.** Building needs macOS and Xcode. Fix any build issues on the Mac.
- Search and filters run **on the device** over the live list. That is fine for a campus-sized dataset, but a very large database would need Firestore queries with indexes and pagination.
- An upvote cannot be removed (by design, to keep the counter tamper-proof).
- There are no push notifications. Students see updates through real-time listeners while the app is open.
- Admin accounts are promoted manually in the Firebase Console (by design, for security).
- Staff accounts are created from the admin's app through a temporary second Firebase instance. A production system would use a Cloud Function with the Admin SDK (needs the Blaze plan).
- "Deactivate" blocks the account in the app and in the security rules, but the Firebase Auth login itself stays enabled until you disable it in Firebase Console → Authentication. Admins can't delete accounts from the app.
- Staff get no push notification for new assignments. They appear live while the app is open.
- Staff can't attach completion photos (only students upload photos).
- Complaint photos use Firebase download URLs. Anyone who has the exact URL can open the image, which is standard Firebase behaviour.
- Students cannot edit or delete a complaint after submitting it (admins handle corrections).
- The UI is in English, portrait iPhone only.
- The app icon includes the app name and tagline. That text is very small on the home screen, and Apple's guidelines recommend icons without text. If needed, `Branding/` has everything to make a text-free version.

## 14. Lab Concepts Checklist

| Concept | Where (file → what) |
|---------|---------------------|
| `@State` | `LoginView` (email, password), `ReportIssueView` (form fields, sheet flags), `AllIssuesView` (`filter`), `MyReportsView` (status filter), `AppTextField` (show/hide password) |
| `@Binding` | `AppTextField.text`, `MenuPickerField.selection`, `IssueFilterBar.filter`, `ImagePicker.selectedImage`, `selectedTab` in dashboard/report/my-reports |
| `@StateObject` | `CampusFixApp` (AuthViewModel), `StudentTabView`/`AdminTabView` (IssueViewModel), `ReportIssueView`, `IssueDetailView`, `AdminUpdateSheet` |
| `@ObservedObject` | `StudentDashboardView`, `AllIssuesView`, `MyReportsView`, `AdminDashboardView` receive `IssueViewModel` |
| `ObservableObject` / `@Published` | All 5 ViewModels |
| `@EnvironmentObject` | `AuthViewModel` injected in `CampusFixApp`, read in most views |
| `@Environment` | `\.dismiss` in `ImagePicker`, `AdminUpdateSheet`, `EditProfileView` |
| `NavigationStack` | Every tab, plus `.navigationDestination(for: IssueRoute.self)` |
| `List` + `ForEach` | `AllIssuesView`, `MyReportsView`; `ForEach` in dashboards and filter menus |
| `onAppear` | Start listeners (`StudentTabView`, `IssueDetailView`), load JSON (`ReportIssueView`) |
| `onDisappear` | Remove listeners (`StudentTabView`, `AdminTabView`, `IssueDetailView`) |
| Delegate pattern | `ImagePicker.Coordinator` implements `UIImagePickerControllerDelegate` |
| `UIViewControllerRepresentable` | `ImagePicker` |
| Codable / JSONDecoder | `CampusData`, `SampleIssue`, `JSONService`; Firestore `Issue`/`AppUser` |
| async/await | All service calls, e.g. `try await imageService.uploadImage(...)` |
| Error handling | `JSONServiceError`, `AuthServiceError`, `FirestoreServiceError`, `ImageUploadError`, `do/catch`, banners |
| Protocols | `BadgeDisplayable` (custom), `Identifiable`, `Codable`, `LocalizedError`, delegate protocols |
| Struct vs class | Models/Views are `struct`; ViewModels/Services/Coordinator are `class` |
| Closures | Button actions, `filter`/`sorted`/`map`, Firebase listener callbacks |
| Firebase listeners | `addSnapshotListener` (issues, issue, profile), `addStateDidChangeListener` (auth) |
| Enums | `Role`, `Permission`, `TaskStage`, `IssueStatus`, `IssuePriority`, `SessionState`, `StudentTab`/`StaffTab`/`AdminTab` |
| Role-based access control | `Role.can(_:)` table, ViewModel `authorize(...)` checks, role switch in `AppCoordinator`, `firestore.rules` |
| Generics | `JSONService.load<T: Decodable>`, `BadgeView<Item: BadgeDisplayable>` |

## 15. Final Requirements Checklist

Legend: ✅ code written · 🔥 needs your Firebase project/credentials · 🍎 needs testing on a Mac

| Requirement | Code | Needs |
|-------------|------|-------|
| Xcode project + MVVM structure | ✅ | 🍎 open/build |
| Splash, Login, Register with validation | ✅ | 🔥 🍎 |
| No self-registration as admin (UI + rules) | ✅ | 🔥 publish rules |
| Student dashboard + statistics | ✅ | 🔥 🍎 |
| Report issue + validation + photo (ImgBB) | ✅ | `.env` key 🍎 |
| All Issues: search, filter, sort | ✅ | 🔥 🍎 |
| Issue details + resolution notes | ✅ | 🔥 🍎 |
| One upvote per student (transaction + rules) | ✅ | 🔥 🍎 |
| My Reports + updates | ✅ | 🔥 🍎 |
| Profile + edit + logout | ✅ | 🔥 🍎 |
| Admin dashboard + chart | ✅ | 🔥 admin account 🍎 |
| Admin status/remarks/resolution updates | ✅ | 🔥 🍎 |
| **RBAC:** `Role` enum (student/staff/admin) stored in Firestore | ✅ | 🔥 |
| Role-based navigation: 3 different dashboards | ✅ | 🔥 🍎 |
| Staff dashboard + Assigned Complaints screen | ✅ | 🔥 staff account 🍎 |
| Staff accept task, In Progress / Resolved, work + resolution notes | ✅ | 🔥 🍎 |
| Admin assignment screen (assign / reassign / unassign) | ✅ | 🔥 🍎 |
| Admin changes priority | ✅ | 🔥 🍎 |
| Admin User Management (create staff, roles, deactivate) | ✅ | 🔥 🍎 |
| No self-granted staff/admin (registration + rules) | ✅ | 🔥 publish rules |
| Permissions checked in app AND in backend rules | ✅ | 🔥 publish rules |
| Firestore security rules (incl. ImgBB-only image URLs) | ✅ | 🔥 paste & publish |
| JSON parsing from bundle (+ error handling) | ✅ | 🍎 |
| Delegate pattern (image picker) | ✅ | 🍎 (camera: real iPhone) |
| Sample data seed (from JSON) | ✅ | 🔥 🍎 |
| No secrets in source code | ✅ | — |
| README + VIVA_PREPARATION | ✅ | — |
