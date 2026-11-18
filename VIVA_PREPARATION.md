# CampusFix – Viva Preparation Guide

Answers in simple English, with **বাংলা** explanations where they help.
Every answer points to the real file in this project, so you can open it and show the code.

---

## Part A – Core Concepts

### 1. What is Swift?
Swift is Apple's modern programming language for iOS, macOS, watchOS and tvOS apps. It is **type-safe**: it catches many mistakes, such as using `nil` by accident, while you compile. It is fast, and it supports structs, classes, enums, protocols, closures and async/await.

> বাংলা: Swift হলো Apple-এর তৈরি প্রোগ্রামিং ভাষা, যা দিয়ে iPhone অ্যাপ বানানো হয়। এটি নিরাপদ (safe) ও দ্রুত।

### 2. What is SwiftUI?
SwiftUI is Apple's **declarative** UI framework. You describe *what* the screen should look like for the current data, and SwiftUI redraws it automatically when the data changes. You don't update labels by hand.
Example: `Text("\(issue.upvoteCount)")` updates by itself when the count changes.

> বাংলা: SwiftUI-তে আমরা বলি "স্ক্রিন দেখতে কেমন হবে", আর ডেটা বদলালে SwiftUI নিজেই স্ক্রিন আপডেট করে।

### 3. What is Firebase?
Firebase is Google's **Backend-as-a-Service**. It gives us a ready-made server: user login (Authentication), a cloud database (Firestore), and security rules. (Photos are hosted on ImgBB, because Firebase Storage needs a paid plan.) We don't have to write or host our own server.

> বাংলা: Firebase হলো Google-এর রেডিমেড ব্যাকএন্ড। নিজের সার্ভার না বানিয়েই লগইন, ডেটাবেস আর ছবি রাখার সুবিধা পাওয়া যায়।

### 4. What is Firebase Authentication?
It manages user accounts. We use **email/password** sign-in:
- `createUser(withEmail:password:)` registers a user (`AuthService.register`)
- `signIn(withEmail:password:)` logs in (`AuthService.login`)
- `signOut()` logs out (`AuthService.logout`)
- `addStateDidChangeListener` tells us whenever the user logs in or out. Firebase also **remembers the session**, so the user stays logged in after restarting the app.

Each user gets a unique **UID**. We use the UID as the Firestore document ID in `users/{uid}`.

### 5. What is Firestore?
Cloud Firestore is a **NoSQL document database**. Data is stored as **documents** (like JSON objects) inside **collections**. It supports **real-time listeners**: when data changes on the server, every connected phone is notified instantly.

Our structure:
```
users/{userId}                  profile + role
issues/{issueId}                complaint
issues/{issueId}/votes/{userId} one upvote per user
```

> বাংলা: Firestore হলো ক্লাউড ডেটাবেস। কালেকশনের ভেতরে ডকুমেন্ট থাকে। কেউ ডেটা বদলালে সব ফোনে সাথে সাথে আপডেট চলে যায়।

### 6. What is JSON?
**JavaScript Object Notation**, a text format for structured data. It uses `{ }` for objects, `[ ]` for arrays, and `"key": value` pairs. It is easy for humans to read and easy for programs to parse.
Our file: `Resources/campus_data.json` holds the lists of buildings and categories.

### 7. What is Codable?
`Codable` is a Swift protocol (`Encodable` + `Decodable` together). If a struct conforms to `Codable` and its property names match the JSON keys, Swift can **automatically** convert JSON to the struct and back. We don't write any manual parsing.
```swift
struct CampusData: Codable {
    let buildings: [String]
    let categories: [String]
}
```
We also use Codable with Firestore: `snapshot.data(as: Issue.self)` and `Firestore.Encoder().encode(issue)`.

> বাংলা: Codable থাকলে JSON থেকে Swift struct বানানো (decode) আর struct থেকে JSON বানানো (encode) স্বয়ংক্রিয়ভাবে হয়।

### 8. What is JSONDecoder?
The Swift class that **turns JSON `Data` into Swift objects**:
```swift
let campusData = try JSONDecoder().decode(CampusData.self, from: data)
```
If the JSON doesn't match the model (a missing key or the wrong type), it **throws an error**. We catch that error and show a message (`JSONService.swift`).

### 9. What is MVVM?
**Model – View – ViewModel**, a way to organise code:
| Layer | Job | Example |
|-------|-----|---------|
| Model | Plain data | `Issue`, `AppUser` |
| View | Shows UI, forwards taps | `ReportIssueView` |
| ViewModel | State + logic, talks to services | `ReportIssueViewModel` |

(We also have a **Service** layer, `FirestoreService` and friends, so the ViewModels don't contain raw Firebase code.)

**Why use it?** The code is cleaner, easier to test, and a view never contains database logic.

> বাংলা: View শুধু দেখায়, ViewModel কাজ/লজিক করে, Model হলো ডেটা। এতে কোড গুছানো থাকে।

### 10. What is @State?
A property wrapper for **simple local data owned by one view**. When it changes, the view redraws.
```swift
@State private var email = ""        // LoginView.swift
@State private var filter = IssueFilter()   // AllIssuesView.swift
```
Use it for form input, search text, selected filters and sheet visibility. Mark it `private`, because only that view owns it.

### 11. What is @Binding?
A **two-way connection** to a `@State` owned by a **parent** view. The child can read and change the parent's value without owning it.
```swift
// Parent: StudentTabView
@State private var selectedTab: StudentTab = .home
StudentDashboardView(issueViewModel: issueViewModel, selectedTab: $selectedTab)

// Child: StudentDashboardView
@Binding var selectedTab: StudentTab
Button { selectedTab = .report }   // switches the parent's tab!
```
Other examples: `AppTextField(text: $email)`, `IssueFilterBar(filter: $filter)`, `ImagePicker(selectedImage: $selectedImage)`.

> বাংলা: @Binding দিয়ে চাইল্ড ভিউ প্যারেন্টের ডেটা পড়তে ও বদলাতে পারে। `$` চিহ্ন দিয়ে binding পাঠানো হয়।

### 12. What is @StateObject?
It **creates and owns** an `ObservableObject` (usually a ViewModel). SwiftUI keeps the same instance alive even when the view redraws.
```swift
@StateObject private var issueViewModel = IssueViewModel()   // StudentTabView.swift
```
Rule: use `@StateObject` in the view that **creates** the object.

### 13. What is @ObservedObject?
It **observes an existing object that someone else created**. The view redraws when its `@Published` properties change, but it does **not** own it.
```swift
@ObservedObject var issueViewModel: IssueViewModel   // StudentDashboardView.swift
```
**Difference:** `@StateObject` = "I create it and keep it". `@ObservedObject` = "my parent gave it to me".
If you used `@ObservedObject` to create a ViewModel, it could be recreated on every redraw and lose its data.

> বাংলা: @StateObject নিজে অবজেক্ট বানায় ও রাখে; @ObservedObject অন্য কারো বানানো অবজেক্ট শুধু দেখে।

### 14. What is ObservableObject?
A protocol for **classes** whose changes SwiftUI should watch. Properties marked `@Published` notify the views when they change.
```swift
@MainActor
final class IssueViewModel: ObservableObject {
    @Published private(set) var issues: [Issue] = []
}
```
`@MainActor` makes sure UI updates happen on the main thread.

### 15. What is NavigationStack?
SwiftUI's container for **push navigation** (screen → next screen, with a back button). We navigate using values:
```swift
NavigationLink(value: IssueRoute(issueId: id)) { IssueCardView(issue: issue) }
.navigationDestination(for: IssueRoute.self) { route in
    IssueDetailView(issueId: route.issueId)
}
```
Each tab has its own `NavigationStack`. The Login screen uses one to push the Register screen.

### 16. What is onAppear?
A modifier whose closure runs **when the view appears on screen**. We use it to start loading:
- `StudentTabView`: `issueViewModel.startListening()` starts the Firestore listener
- `ReportIssueView`: `viewModel.loadCampusData()` decodes the JSON
- `IssueDetailView`: `viewModel.start(issueId:userId:)` listens to one complaint

### 17. What is onDisappear?
Runs **when the view is removed from the screen**. We use it for cleanup, mainly **removing Firestore listeners** so they don't keep using network and memory:
```swift
.onDisappear { viewModel.stop() }   // IssueDetailView → listener?.remove()
```
**Important:** you can't assume `onDisappear` runs at a particular moment (for example, switching tabs also triggers it). So our `start()` functions check `guard listener == nil`, which makes it safe to call them again on the next `onAppear`. Listener lifetimes are managed explicitly.

> বাংলা: onAppear-এ লিসেনার চালু করি, onDisappear-এ বন্ধ করি, যাতে অপ্রয়োজনে ডেটা না আসে।

### 18. What is the delegate pattern?
A design pattern where one object **hands responsibility to another object (the delegate)** and **reports events back** to it through methods defined in a protocol.

**In CampusFix** (`Views/Components/ImagePicker.swift`):
1. `UIImagePickerController` (UIKit) shows the camera or photo library, but it doesn't know what our app wants to do with the photo.
2. We set `picker.delegate = context.coordinator`.
3. Our `Coordinator` class conforms to `UIImagePickerControllerDelegate`.
4. When the user picks a photo, UIKit **calls** `imagePickerController(_:didFinishPickingMediaWithInfo:)` on the coordinator.
5. The coordinator sends the image back to SwiftUI through the `@Binding selectedImage`, then dismisses the picker.
6. If the user cancels, UIKit calls `imagePickerControllerDidCancel(_:)`.

**Why use it?** It keeps the picker reusable: UIKit's picker works for any app because each app supplies its own delegate. It is also how UIKit components talk back to their owners.

`UIViewControllerRepresentable` is the bridge that lets a UIKit view controller be used inside SwiftUI.

> বাংলা: Delegate মানে "প্রতিনিধি"। ছবি বাছাই শেষ হলে UIImagePickerController নিজে কিছু না করে তার delegate (আমাদের Coordinator)-কে জানায়, আর Coordinator ছবিটা SwiftUI-তে পাঠায়।

---

## Part B – How CampusFix Works

### 19. How does Firebase work in this application?
1. **Launch:** `CampusFixApp.init()` → `FirebaseService.configureIfPossible()` reads `GoogleService-Info.plist` and connects to our Firebase project. If the file is missing, the app shows a setup screen instead of crashing.
2. **Session:** `AuthViewModel.startSessionMonitoring()` adds an Auth state listener. If a saved session exists, Firebase logs the user in automatically.
3. **Profile + role:** after login, a Firestore listener on `users/{uid}` loads the profile. `AppCoordinator` shows `AdminTabView` if `role == "admin"`, and `StudentTabView` otherwise.
4. **Complaints:** `IssueViewModel.startListening()` attaches `addSnapshotListener` to `issues`, ordered by `reportedAt`. Every add or change is pushed to the app instantly.
5. **Security:** `firestore.rules` runs on Google's servers and check every request. Even a modified app can't make itself an admin or change a complaint's status.

### 20. How does the complaint submission process work?
(`ReportIssueView` → `ReportIssueViewModel.submit` → services)
1. The student fills in the form. The values live in `@State` variables.
2. They tap **Submit**, and the view builds an `IssueDraft` struct.
3. `validate()` checks the title, description length, category, building and location. If anything is wrong, a red banner appears and **nothing is sent**.
4. If a photo was chosen, it is uploaded to ImgBB first (see Q21) to get its public URL.
5. An `Issue` is created with `status = .pending`, `upvoteCount = 0` and `reportedBy = uid`. `reportedAt` uses `@ServerTimestamp`, so the **server's clock** is used.
6. `FirestoreService.createIssue` encodes it with `Firestore.Encoder` and `await`s `setData`.
7. The success alert appears **only after Firestore confirms the save**. If it fails, the uploaded photo is deleted and the real error is shown.
8. Every device's listener receives the new complaint automatically.

### 21. How does image uploading work?
(`Services/ImageUploadService.swift` → `ImgBBService.uploadImage`)

Photos are hosted on **ImgBB**, a free image-hosting service, because Firebase Storage needs the paid Blaze plan. Firestore stores **only the image's public URL**.
1. The `ImagePicker` (delegate pattern) gives us a `UIImage`.
2. We **resize** it to at most 1600 px and **compress** it to JPEG at 70% quality, which keeps uploads fast and small. Then we check that it is ≤ 5 MB.
3. We build a **multipart/form-data HTTP POST** request to `https://api.imgbb.com/1/upload?key=…`, with the JPEG in the `image` field.
4. `try await URLSession.shared.data(for: request)` sends it (async/await).
5. ImgBB replies with **JSON**. We decode it with `JSONDecoder` into a `Codable` struct (`ImgBBResponse`) and read `data.url`, for example `https://i.ibb.co/abc123/photo.jpg`.
6. That URL is saved as `imageURL` in the Firestore complaint.
7. The details screen shows it with `AsyncImage(url:)`.

**Errors** (missing key, no internet, ImgBB rejects the image, bad response) are thrown as `ImageUploadError` and shown in a red banner. Nothing is saved.

**Where is the API key?** It's not in the code. It's in the **git-ignored `.env` file**. `Config/CampusFix.xcconfig` includes `.env` at build time, `Config/Info.plist` copies `$(IMGBB_API_KEY)` into the app, and `ImgBBService` reads it with `Bundle.main.object(forInfoDictionaryKey:)`.

**Security:** `firestore.rules` only accepts an `imageURL` that matches `https://i.ibb.co/…`, so nobody can attach arbitrary links. Limitation: a key inside a mobile app can be extracted, which is acceptable for a free demo key.

**Protocol:** `ImgBBService` conforms to the `ImageHostingService` protocol, and the ViewModel only knows the protocol. To switch to another image host, you write one new class and nothing else changes.

> বাংলা: ছবি Firebase-এ না রেখে ImgBB নামের ফ্রি সার্ভিসে আপলোড করি। ImgBB একটি পাবলিক লিংক (URL) দেয়, আর আমরা শুধু সেই লিংকটা Firestore-এ সেভ করি। API key কোডে নেই, `.env` ফাইলে আছে, যা gitignore করা।

### 22. How does JSON parsing work?
(`JSONService.load(_:fromFile:)`)
```swift
guard let url = Bundle.main.url(forResource: "campus_data", withExtension: "json")  // 1. find file in app bundle
let data = try Data(contentsOf: url)                                                // 2. read bytes
let result = try JSONDecoder().decode(CampusData.self, from: data)                  // 3. decode to struct
```
- The function is **generic** (`<T: Decodable>`), so the same code also decodes `[SampleIssue]` from `sample_issues.json`.
- Errors are turned into `JSONServiceError` (file not found, unreadable, invalid format, empty).
- `ReportIssueViewModel` catches the error, shows an orange warning, and uses `CampusData.fallback`, so the app never crashes.
- The decoded `buildings` and `categories` arrays fill the `MenuPickerField` menus through `ForEach`.

> বাংলা: অ্যাপের ভেতরে থাকা JSON ফাইল পড়ে JSONDecoder দিয়ে Swift struct-এ রূপান্তর করি, তারপর সেই তালিকা মেনুতে দেখাই। ফাইল না থাকলে অ্যাপ ক্র্যাশ না করে সতর্কবার্তা দেখায়।

### 23. How does upvoting prevent duplicates?
- The vote is stored at `issues/{issueId}/votes/{userId}`. Because the document ID is the user ID, there can be only one per user.
- `FirestoreService.upvote` uses a **transaction**: it reads the vote doc, and if it exists it throws "already upvoted". Otherwise it creates the vote **and** increments `upvoteCount` by 1, both or neither.
- `firestore.rules` checks on the server: the counter must go up by exactly 1, the vote must not have existed before, and it must exist after.
- The UI also disables the button once you've voted (`hasUpvoted`).

### 24. How is role-based access enforced?
At **three levels** (see Part F for details):
1. **Navigation:** `AppCoordinator` shows `StudentTabView`, `StaffTabView` or `AdminTabView` based on `user.role`.
2. **App logic:** every protected ViewModel function checks `user.can(.permission)` before calling Firebase.
3. **Server (the real security):** `firestore.rules` reads the caller's role from `users/{uid}` and allows only what that role may do:
```
function hasActiveRole(role) {
  return isSignedIn() && exists(userPath(request.auth.uid))
    && me().role == role && me().get('isActive', true) == true;
}
```
On registration the rules require `role == 'student'`. Staff can only be created by an admin. Admin can only be set in the Firebase Console.

### 25. What is async/await? Where is it used?
It lets us write asynchronous code (network calls) that **reads like normal top-to-bottom code**, without nested callbacks. `await` pauses the function until the result arrives, without freezing the UI.
```swift
let url = try await imageService.uploadImage(image, userId: uid)
try await firestoreService.createIssue(issue)
```
Used in: login, register, profile update, image upload, complaint creation, upvote, and admin update.

### 26. Struct vs class – which did you use where?
- **struct** (value type, copied): Models (`Issue`, `AppUser`, `CampusData`) and all SwiftUI Views. They are simple and safe.
- **class** (reference type, shared): ViewModels (`ObservableObject` must be a class), Services, and the `Coordinator` (UIKit delegates must be `NSObject` classes).

### 27. Where are protocols used?
- Custom: `BadgeDisplayable`, adopted by `IssueStatus` and `IssuePriority`, so one generic `BadgeView<Item: BadgeDisplayable>` shows both.
- System: `Codable`, `Identifiable`, `CaseIterable`, `Hashable`, `LocalizedError`, `ObservableObject`, `View`, `UIViewControllerRepresentable`, `UIImagePickerControllerDelegate`.

### 28. Where are closures used?
- Button actions: `PrimaryButton(title: "Log In") { ... }`
- Collection operations: `issues.filter { $0.status == .pending }`, `.sorted { $0.upvoteCount > $1.upvoteCount }`
- Firebase callbacks: `addSnapshotListener { snapshot, error in ... }`
- `[weak self]` in listener closures prevents memory leaks (retain cycles).

### 29. How is error handling done?
- Each service has its own `enum ...Error: LocalizedError` with friendly messages.
- `do { try await ... } catch { errorMessage = error.localizedDescription }` in the ViewModels.
- Views show `errorMessage` in a red `MessageBanner`.
- There are no fake successes: success alerts appear only after the server confirms.

### 30. What are Firebase listeners and why remove them?
A listener (`addSnapshotListener`) keeps a live connection, and Firestore calls our closure every time the data changes. It returns a `ListenerRegistration`. Calling `.remove()` stops it. If we never removed it, it would keep downloading data and could fail with "permission denied" after logout.

---

## Part C – Important Files and Their Functions

### App
| File | Function | Purpose |
|------|----------|---------|
| `CampusFixApp.swift` | `init()` | Configures Firebase |
| | `body` | Creates the window and injects `AuthViewModel` as an environment object |
| `AppCoordinator.swift` | `body` / `sessionContent` | Shows Splash → Setup / Login / Student / Admin, based on `sessionState` |

### Services
| File | Function | Purpose |
|------|----------|---------|
| `FirebaseService` | `configureIfPossible()` | Calls `FirebaseApp.configure()` only if the plist exists |
| `AuthService` | `register`, `login`, `logout` | Firebase Auth calls |
| | `addAuthStateListener` | Notifies on login/logout, restores the session |
| | `AuthServiceError.friendly` | Converts Firebase error codes to readable messages |
| `FirestoreService` | `createUserProfile` / `updateUserProfile` | Write `users/{uid}` |
| | `listenToUserProfile` | Live profile (role changes apply instantly) |
| | `listenToIssues` / `listenToIssue` | Live complaint list / single complaint |
| | `createIssue` | Saves a new complaint |
| | `updateIssueByAdmin` | Status, remarks, notes (admin only) |
| | `hasUpvoted` / `upvote` | Vote check / transactional vote |
| `ImageUploadService` | `ImgBBService.uploadImage` | Resize, compress, multipart POST to ImgBB, decode the JSON, return the public URL |
| | `deleteImage` | Cleans up if saving the complaint fails |
| `JSONService` | `load<T>` | Generic bundle JSON decoding |
| | `loadCampusData` / `loadSampleIssues` | Specific files, with an empty-data check |

### ViewModels
| File | Key functions |
|------|---------------|
| `AuthViewModel` | `startSessionMonitoring`, `login`, `validateRegistration`, `register` (undoes the Auth account if saving the profile fails), `updateProfile`, `logout` |
| `IssueViewModel` | `startListening`, `stopListening`, `loadCategories`, `filteredIssues(using:)`, `issues(reportedBy:)`, `recentIssues`, `statistics` |
| `ReportIssueViewModel` | `loadCampusData`, `validate`, `submit` |
| `IssueDetailViewModel` | `start`, `stop`, `upvote` |
| `AdminViewModel` | `updateIssue` (status + priority; requires notes for Resolved), `assign(issue:to:by:)`, `seedSampleIssues` |
| `StaffTaskViewModel` | `acceptTask`, `updateProgress` (only In Progress / Resolved, only if assigned and accepted) |
| `UserManagementViewModel` | `startListening`, `users(withRole:matching:)`, `activeStaff`, `createStaffAccount`, `updateAccess` (role student↔staff, active flag), `canEdit` |

### Models
| File | Contents |
|------|----------|
| `Issue.swift` | `Issue` (Codable, `@DocumentID`, `@ServerTimestamp`, assignment fields), `TaskStage` (Unassigned → New Task → Accepted → Completed), `IssueRoute` |
| `User.swift` | `Role` enum (student / staff / admin), `Permission` enum, `Role.can(_:)`, `AppUser` (+ `isActive`) |
| `IssueStatus.swift` | `BadgeDisplayable` protocol, `IssueStatus` (colours: orange/blue/green), `IssuePriority` |
| `IssueStatistics.swift` | Counts for both dashboards |
| `CampusData.swift` | `CampusData`, `SampleIssue` for JSON |

### Reusable components
`AppTextField` (@Binding text), `PrimaryButton` (closure action), `MenuPickerField`, `BadgeView` (generic), `IssueCardView`, `StatCard`, `EmptyStateView`, `MessageBanner`, `LoadingView`, `IssueImageView` (AsyncImage), `ImagePicker` (delegate).

---

## Part D – Likely "Modify It Live" Requests (and exactly how)

| Instructor asks | What to change |
|-----------------|----------------|
| "Add a new building" | Add it to `buildings` in `Resources/campus_data.json` and run again |
| "Add a new category with an icon" | Add it to `categories` in the JSON, then add a `case` in `CategoryIcon.name(for:)` in `Extensions.swift` |
| "Change the Pending colour to yellow" | `IssueStatus.color` in `IssueStatus.swift` → `case .pending: return .yellow` |
| "Change the primary colour" | `AppTheme.navy` in `AppConstants.swift` |
| "Make the description need 20 characters" | `AppConstants.minDescriptionLength = 20` (and update `firestore.rules` to match) |
| "Change the splash time" | `Task.sleep(for: .seconds(1.5))` in `AppCoordinator.swift` |
| "Show 10 recent complaints" | `issueViewModel.recentIssues(limit: 10)` in `StudentDashboardView.swift` |
| "Add a new sort option" | Add a case to `IssueSortOption` and handle it in `filteredIssues(using:)` |
| "Add a new status, e.g. Rejected" | Add a case in `IssueStatus` (title, colour, icon) and add `'Rejected'` to the status list in `firestore.rules` |
| "Change the tagline" | `AppConstants.tagline` |
| "Let staff also change priority" | Add `.changePriority` to the staff set in `Role.permissions` (`User.swift`) **and** add `'priority'` to Rule B's `hasOnly` list in `firestore.rules`. Point out that changing only the app is not enough! |
| "Hide the Users tab" | Remove the `UserManagementView()` tab in `AdminTabView.swift` |
| "Show staff phone number" | Add `var phone: String? = nil` to `AppUser`, a field in `CreateStaffAccountView`, and `'phone'` to the users `hasOnly` list in the rules |
| "Require a photo" | In `ReportIssueViewModel.submit`, add `guard image != nil else { errorMessage = "..."; return false }` |

---

## Part E – Quick-Fire Questions

- **Why `@MainActor` on ViewModels?** UI must update on the main thread, and `@MainActor` guarantees it.
- **Why `[weak self]` in listeners?** To avoid a retain cycle (memory leak) between the ViewModel and the closure.
- **Why `@ServerTimestamp`?** A phone's clock can be wrong. The server time is trustworthy and the same for everyone.
- **Why is the vote document ID the user ID?** It makes duplicate votes impossible by design.
- **Why a transaction for upvotes?** Two writes (the vote and the counter) must succeed or fail together, even if many users vote at the same moment.
- **Why navigate with `IssueRoute(issueId:)` instead of the whole `Issue`?** The details screen listens to the live document, so it always shows the latest status.
- **What happens without internet?** Firestore shows cached data. Writes and uploads report an error, and nothing pretends to succeed.
- **Why is there no admin registration?** Security: anyone could become an admin. Admins are promoted in the Firebase Console, and the rules block self-promotion.
- **Where is the password stored?** Only in Firebase Authentication, which stores it securely as a hash. It is never stored in Firestore or in the code.
- **What is `GoogleService-Info.plist`?** A configuration file that tells the app which Firebase project to connect to. It is not a secret password, but we still keep it out of public repositories.

---

## Part F – Role-Based Access Control (3 Roles)

### F1. What is RBAC?
**Role-Based Access Control** means permissions are given to **roles**, not to individual people, and each user gets one role. In CampusFix:

| Role | Main job |
|------|----------|
| **Student** | Report, upload a photo, upvote, track their own reports |
| **Maintenance Staff** | Accept assigned tasks, update progress, resolve with notes |
| **Admin** | Manage all complaints, assign staff, change priority, manage accounts |

> বাংলা: RBAC মানে প্রত্যেক ব্যবহারকারীর একটি ভূমিকা (role) থাকে, আর সেই ভূমিকা অনুযায়ী সে কী করতে পারবে তা ঠিক করা থাকে।

### F2. Where is the role stored? Where is the Role enum?
In Firestore, as `users/{uid}.role` with the value `"student"`, `"staff"` or `"admin"`. In Swift (`Models/User.swift`):
```swift
enum Role: String, Codable, CaseIterable {
    case student, staff, admin
    func can(_ permission: Permission) -> Bool { permissions.contains(permission) }
}
```
`Permission` is another enum that lists every protected action (`.reportIssue`, `.assignComplaints`, `.manageUsers`, …). `Role.can` is **one central permission table**.

### F3. How does role-based navigation work?
`AppCoordinator.swift`: after login, the profile listener loads the user, then:
```swift
switch user.role {
case .student: StudentTabView()
case .staff:   StaffTabView()
case .admin:   AdminTabView()
}
```
Each role sees a completely different dashboard and set of tabs. Because the profile is a **live listener**, an admin changing someone's role switches their screen instantly.

### F4. Why is hiding buttons not enough?
Anyone can modify an app, or call Firestore's REST API directly. So the **server** must check permissions. We protect every action three times:
1. **UI:** buttons appear only if `user.can(...)` is true.
2. **ViewModel:** for example, `AdminViewModel.authorize(actor, for: .assignComplaints)` runs before calling Firebase.
3. **Firestore rules:** the real security. The server reads the caller's role and rejects anything else with *permission denied*.

> বাংলা: শুধু বাটন লুকালে নিরাপত্তা হয় না, কারণ কেউ অ্যাপ পরিবর্তন করে সরাসরি ডেটাবেসে লিখতে পারে। তাই আসল যাচাই Firebase সার্ভারের Security Rules-এ হয়।

### F5. How do you stop someone from making themselves admin or staff?
- The Register screen has no role picker. `AuthViewModel.register` always uses `.student`.
- `firestore.rules`: self-created profiles **must** have `role == 'student'`.
- A user can update only `name` and `studentId` on their own profile. `role` and `isActive` are locked.
- A profile with `role: 'staff'` can only be created or set by an **active admin**.
- No rule anywhere lets a client write `role: 'admin'`. Admin is set **only in the Firebase Console** (trusted administrative process).

### F6. How does the admin create a staff account without being logged out?
Firebase's `createUser` automatically signs in as the new user. To avoid that, `AuthService.createAccountForAnotherUser` creates a **second, temporary FirebaseApp instance** and makes the account there. The admin's main session then writes the `role: "staff"` profile, so the rules can verify `isAdmin()`. If writing the profile fails, the new Auth account is deleted again. Finally, the temporary session is signed out.

### F7. Explain the assignment workflow.
1. Student reports → `status: Pending`, no `assignedTo` → stage **Unassigned**.
2. Admin → **Assign to Staff** (`AssignStaffView`) → `assignedTo`, `assignedToName`, `assignedAt` are set → stage **New Task**.
3. Staff → **Accept Task** → `acceptedAt` is set → stage **Accepted**.
4. Staff → **Update Progress** → `In Progress` + `workDescription`.
5. Staff → **Resolved** + `resolutionNotes` (required) → stage **Completed**.
6. Every device updates instantly (snapshot listeners), so the student sees the final status.

`TaskStage` (in `Issue.swift`) is **computed** from these fields. It isn't stored, so it can never get out of sync.

### F8. What exactly can a staff member NOT do? How is it enforced?
In `firestore.rules`, Rule B lets staff update an issue only if:
- `resource.data.assignedTo == request.auth.uid` (it is **their** task),
- only `status`, `workDescription`, `resolutionNotes`, `acceptedAt` and `updatedAt` change (no priority, assignment or remarks),
- `acceptedAt` can be set only once,
- the status can only become `In Progress` or `Resolved`, and only after accepting,
- `Resolved` requires non-empty `resolutionNotes`.

Staff also can't read the users list (rules allow listing users for admins only), can't upload photos (the app only lets students report), and can't upvote.

### F9. How does deactivation work?
The admin sets `isActive = false`. Then:
- The deactivated user's profile listener fires, and `AuthViewModel` shows "Your account has been deactivated" instead of the app.
- In the rules, `hasActiveRole()` requires `isActive == true`, so every action is denied on the server too.
- Limitation: the Firebase Auth login still exists. The project owner can disable it fully in Firebase Console → Authentication.

### F10. Why can an admin not edit another admin?
To stop one admin account (perhaps a stolen one) from removing or creating other admins. The rule `resource.data.role != 'admin'` blocks it, and `UserManagementViewModel.canEdit` hides the controls.

### F11. Why does reassigning clear `acceptedAt`?
The new staff member hasn't agreed to the task yet. Clearing `acceptedAt` puts it back to **New Task** for them, and the rules require acceptance before any progress update.

### F12. New files for RBAC
| File | Purpose |
|------|---------|
| `Models/User.swift` | `Role`, `Permission`, `AppUser.isActive`, `can(_:)` |
| `Models/Issue.swift` | Assignment fields, `TaskStage` |
| `ViewModels/StaffTaskViewModel.swift` | Accept task, update progress |
| `ViewModels/UserManagementViewModel.swift` | Users list, create staff, roles, deactivate |
| `Views/Staff/StaffTabView.swift` | Staff tab bar |
| `Views/Staff/StaffDashboardView.swift` | Maintenance Staff dashboard |
| `Views/Staff/AssignedComplaintsView.swift` | Assigned Complaints screen |
| `Views/Staff/StaffUpdateSheet.swift` | Progress form |
| `Views/Admin/AssignStaffView.swift` | Complaint Assignment screen |
| `Views/Admin/UserManagementView.swift` | User Management screen + role/active sheet |
| `Views/Admin/CreateStaffAccountView.swift` | Create staff account form |
| `firestore.rules` | Server-side RBAC (+ ImgBB-only image URLs) |
| `Services/ImageUploadService.swift`, `.env`, `Config/` | ImgBB photo hosting + secret key handling |
