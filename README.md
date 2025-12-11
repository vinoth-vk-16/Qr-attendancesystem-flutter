<div align="center">

# 📱 QR Attendance System
### *qr_code_generator*

### *Smart, Secure, and Seamless Attendance Management*

[![Flutter](https://img.shields.io/badge/Flutter-3.5.1-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Private-red?style=for-the-badge)](LICENSE)

*A modern Flutter-based attendance management system using QR code technology with Firebase backend integration.*

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Tech Stack](#-tech-stack) • [Contributing](#-contributing)

</div>

---

## 📋 Table of Contents

- [✨ Features](#-features)
- [🛠️ Tech Stack](#️-tech-stack)
- [📦 Installation](#-installation)
- [🚀 Usage](#-usage)
- [📁 Project Structure](#-project-structure)
- [🔐 Authentication](#-authentication)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)
- [💬 Support](#-support)

---

## ✨ Features

<details open>
<summary><b>Core Functionality</b></summary>

### 🎯 Attendance Management
- **Dynamic QR Code Generation** - Automatically generates time-sensitive QR codes for each session
- **QR Code Scanning** - Students scan QR codes to mark attendance with mobile scanner integration
- **Real-time Validation** - QR codes expire after 20 seconds to prevent fraudulent attendance
- **Duplicate Prevention** - System prevents students from scanning the same session multiple times

### 👥 User Management
- **Firebase Authentication** - Secure email/password authentication system
- **User Registration** - Add new users with name, roll number, and email
- **Role-based Access** - Different features for administrators and students
- **Password Recovery** - Forgot password functionality for account recovery

### 📅 Session Management
- **Create Sessions** - Schedule sessions by day with start and end times
- **Conflict Detection** - Automatically detects and prevents overlapping sessions
- **Active Session Tracking** - System maintains current active session in real-time
- **Session History** - View all past and scheduled sessions

### 🔒 Security Features
- **Biometric Authentication** - Fingerprint authentication for enhanced security
- **Device Binding** - IMEI-based device verification to prevent unauthorized access
- **Token-based QR Codes** - Each QR code contains unique tokens for validation
- **Timestamp Verification** - Time-bound QR codes ensure attendance is marked during session time

### 📊 Attendance Tracking
- **Personal Dashboard** - Students view their own attendance records
- **Attendance Requests** - Manual attendance request system for exceptions
- **Request Management** - Administrators can approve/decline attendance requests
- **Detailed Records** - Track session ID, student email, timestamp, and attendance status

</details>

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|-----------|
| **Framework** | ![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white) Flutter 3.5.1 |
| **Language** | ![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white) Dart SDK 3.5.1 |
| **Backend** | ![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black) Firebase Suite |
| **Database** | ![Firestore](https://img.shields.io/badge/Firestore-FFCA28?logo=firebase&logoColor=black) Cloud Firestore |
| **Authentication** | ![Firebase Auth](https://img.shields.io/badge/Firebase_Auth-FFCA28?logo=firebase&logoColor=black) Firebase Authentication |
| **State Management** | StatefulWidget (Built-in Flutter) |

### 📚 Key Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.6.0           # Firebase initialization
  cloud_firestore: ^5.4.4         # NoSQL cloud database
  firebase_auth: ^5.3.1           # User authentication
  firebase_database: ^11.0.4      # Firebase Realtime Database
  qr_flutter: ^4.0.0              # QR code generation
  mobile_scanner: ^5.2.3          # QR code scanning
  local_auth: ^2.3.0              # Biometric authentication
  device_info_plus: ^9.0.0        # Device information
  url_launcher: ^6.3.0            # URL launching capability
  intl: ^0.17.0                   # Internationalization
  cupertino_icons: ^1.0.8         # iOS style icons
```

---

## 📦 Installation

### Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.5.1 or higher) - [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (3.5.1 or higher) - Included with Flutter
- **Android Studio** or **VS Code** with Flutter extensions
- **Firebase Account** - [Create Firebase Project](https://console.firebase.google.com)
- **Git** - For version control

### 🔧 Setup Steps

<details>
<summary><b>1. Clone the Repository</b></summary>

```bash
git clone https://github.com/vinoth-vk-16/Qr-attendancesystem-flutter.git
cd Qr-attendancesystem-flutter
```
</details>

<details>
<summary><b>2. Install Dependencies</b></summary>

```bash
flutter pub get
```

**Expected Output:**
```
Running "flutter pub get" in Qr-attendancesystem-flutter...
Resolving dependencies... 
Got dependencies!
```
</details>

<details>
<summary><b>3. Firebase Configuration</b></summary>

**Step 3.1:** Create a Firebase project at [Firebase Console](https://console.firebase.google.com)

**Step 3.2:** Add Android/iOS apps to your Firebase project

**Step 3.3:** Download configuration files:
- **Android:** Download `google-services.json` → Place in `android/app/`
- **iOS:** Download `GoogleService-Info.plist` → Place in `ios/Runner/`

**Step 3.4:** Enable Firebase services:
- **Authentication:** Enable Email/Password sign-in method
- **Firestore Database:** Create database in production mode
- **Set up Firestore security rules** (see [Security Rules](#security-rules))

</details>

<details>
<summary><b>4. Run the Application</b></summary>

```bash
# Check connected devices
flutter devices

# Run on connected device
flutter run

# Or build for release
flutter build apk --release  # Android
flutter build ios --release  # iOS
```
</details>

### 🔐 Security Rules

<details>
<summary><b>Firestore Security Rules (Click to expand)</b></summary>

Configure your Firestore with these security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User Info Collection
    match /User_Info/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Sessions Collection
    match /sessions/{sessionId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Attendance Collection
    match /attendance/{attendanceId} {
      allow read: if request.auth != null && 
                     request.auth.token.email == resource.data.studentMail;
      allow write: if request.auth != null;
    }
    
    // Active Session Collection
    match /Active_Session/{docId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Attendance Requests Collection
    match /attendance_requests/{requestId} {
      allow read, write: if request.auth != null;
    }
  }
}
```
</details>

---

## 🚀 Usage

### 🎓 For Students

<details>
<summary><b>Marking Attendance</b></summary>

1. **Login** with your registered email and password
2. **Navigate** to the Home page to view your attendance history
3. **Authenticate** using fingerprint (first-time setup binds device)
4. **Scan** the QR code displayed by the instructor
5. **Confirm** attendance - you'll see a success message

**Note:** QR codes are valid for only 20 seconds and can be scanned once per session.
</details>

<details>
<summary><b>Viewing Attendance Records</b></summary>

The home screen displays your personal attendance records in a table format:
- **Session ID** - The class/session identifier
- **Student Email** - Your registered email
- **Attendance Status** - Present/Absent
- **Date** - When attendance was marked

</details>

### 👨‍🏫 For Administrators/Instructors

<details>
<summary><b>Generating QR Codes</b></summary>

1. **Login** with administrator credentials
2. Open the **sidebar menu** (hamburger icon)
3. Select **"Generate QR"**
4. The system automatically:
   - Identifies the current day
   - Finds active sessions
   - Generates a time-sensitive QR code
   - Refreshes every 10 seconds

**Display the QR code** for students to scan during the session.
</details>

<details>
<summary><b>Managing Sessions</b></summary>

**Create a New Session:**
1. Go to **Menu → Add new Session**
2. Fill in the details:
   - **Day:** Select day of the week
   - **Session ID:** Unique identifier (e.g., "CS101-Lecture")
   - **Start Time:** Session start time
   - **End Time:** Session end time
3. Click **"Add Session"**

The system will:
- ✅ Validate no time conflicts exist
- ✅ Store session in Firestore
- ✅ Display in the session list

**Delete a Session:**
- Tap the **delete icon** next to any session in the list
</details>

<details>
<summary><b>Adding Users</b></summary>

1. Navigate to **Menu → Add User**
2. Enter user details:
   - Name
   - Roll Number
   - Email Address
   - Password (minimum 6 characters)
   - Confirm Password
3. Click **"Add User"**

The system creates:
- Firebase Authentication account
- User profile in Firestore `User_Info` collection
</details>

<details>
<summary><b>Managing Attendance Requests</b></summary>

1. Go to **Menu → AttendanceManagement**
2. View pending attendance requests
3. For each request:
   - ✅ **Accept** - Marks attendance for that session
   - ❌ **Decline** - Rejects the request

Accepted requests automatically:
- Update request status to "accepted"
- Create attendance record in the database
- Link to the active session
</details>

---

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point & login screen
├── HomePage.dart             # Student dashboard with attendance list
├── qrGenerator.dart          # QR code generation logic
├── scan_code_page.dart       # QR scanner with validation
├── addSession.dart           # Session management interface
├── adduser.dart              # User registration screen
├── attManagement.dart        # Attendance request approvals
├── attRequestPage.dart       # Student attendance requests
├── fingerprint.dart          # Biometric authentication
└── forgot_pass.dart          # Password recovery

Firestore Collections:
├── User_Info                 # User profiles (name, email, roll_no, IMEI_no)
├── sessions                  # Session schedules (day, startTime, endTime, sessionId)
├── attendance                # Attendance records (sessionId, studentMail, scanTime)
├── Active_Session            # Current active session tracking
└── attendance_requests       # Manual attendance requests (roll_no, status)
```

---

## 🔐 Authentication

### Email/Password Authentication
- Powered by **Firebase Authentication**
- Secure password hashing
- Email verification support
- Password reset functionality

### Biometric Authentication
- **Fingerprint scanning** using `local_auth` package
- **Device binding** with IMEI verification
- First scan registers device IMEI to user account
- Subsequent scans verify device matches registered IMEI
- Prevents attendance marking from unauthorized devices

### Session Validation
```dart
// QR Code Structure
{
  "session_id": "CS101-Monday",
  "timestamp": "2025-12-11T10:30:00.000Z",
  "token": "unique_base64_token"
}
```

**Validation Checks:**
1. QR code format is valid JSON
2. Contains required fields (session_id, timestamp, token)
3. Timestamp is within 20 seconds of current time
4. Student hasn't already scanned this session
5. Session is currently active



---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

<details>
<summary><b>Development Guidelines</b></summary>

1. **Fork** the repository
2. **Create** a feature branch
   ```bash
   git checkout -b feature/AmazingFeature
   ```
3. **Commit** your changes
   ```bash
   git commit -m 'Add some AmazingFeature'
   ```
4. **Push** to the branch
   ```bash
   git push origin feature/AmazingFeature
   ```
5. **Open** a Pull Request

### Code Style
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use meaningful variable and function names
- Add comments for complex logic
- Test your changes before submitting

### Areas for Contribution
- 🐛 Bug fixes
- ✨ New features
- 📝 Documentation improvements
- 🎨 UI/UX enhancements
- ⚡ Performance optimizations
- 🌐 Localization (i18n)

</details>

---

## 📄 License

This project is **private** and not currently licensed for public use. Please contact the repository owner for permissions.

---

## 💬 Support

<div align="center">

### Need Help?

If you encounter any issues or have questions:

- 📧 **Email:** imvinothvk521@gmail.com
- 🐛 **Issues:** [Open an issue](https://github.com/vinoth-vk-16/Qr-attendancesystem-flutter/issues)
- 💡 **Discussions:** [Start a discussion](https://github.com/vinoth-vk-16/Qr-attendancesystem-flutter/discussions)

### Useful Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)

---

**⭐ Star this repository if you find it useful!**

*Made with ❤️ using Flutter & Firebase*

</div>
