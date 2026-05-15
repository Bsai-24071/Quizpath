# 🧠 QuizPath

> **A Flutter quiz app where knowledge meets competition.**  
> Challenge yourself, battle the AI, or go head-to-head with your friends — all powered by real-time Firebase magic.

---

## 📖 About the Project

QuizPath started as a simple idea: *what if a quiz app actually felt fun?*

Most quiz apps are boring. You answer questions, see a score, close the app. QuizPath is different. It lets you compete with friends in real-time, analyze your strengths and weaknesses through aptitude tracking, and even go head-to-head against an AI opponent that adapts to different difficulty levels.

Built entirely with **Flutter** and backed by **Firebase**, QuizPath works on Android, iOS, and Web — from a single codebase.

---

## ✨ Features

### 🎮 Three Game Modes
- **Play Solo** — Pick a category, answer trivia questions, and beat your own high score.
- **Vs Computer** — Choose Easy, Medium, or Hard and go up against an AI opponent that actually fights back.
- **Vs Friends** — Send a match challenge to a friend, play in real-time, and see who comes out on top.

### 🤝 Social & Friends System
- Search for users and send friend requests
- Accept or decline incoming requests
- View your friends list with online/offline status indicators
- Send match challenges directly from the friends screen

### 📊 Aptitude Analysis
- After enough quiz sessions, QuizPath tracks your performance per category
- Visual breakdown of your strengths and weak spots
- Helps you focus your learning where it actually matters

### 👤 Profile & Personalization
- Upload a profile picture
- View your overall stats (matches played, wins, accuracy)
- Track your history over time

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter (Dart) |
| **Authentication** | Firebase Auth |
| **Database** | Cloud Firestore |
| **Realtime Sync** | Firebase Realtime Database |
| **Trivia API** | Open Trivia DB (via HTTP) |
| **State Management** | Stateful Widgets + Services |
| **Animations** | `flutter_animate` |
| **Image Handling** | `image_picker` |

---

## 📁 Project Structure

```
lib/
├── main.dart                     # App entry point, lifecycle management
├── firebase_options.dart         # Firebase platform config
│
├── models/
│   ├── user_model.dart           # User data structure
│   └── friend_model.dart         # Friend relationship model
│
├── screens/
│   ├── splash_screen.dart        # Animated launch screen
│   ├── login_screen.dart         # Sign in with email/password
│   ├── signup_screen.dart        # New account creation
│   ├── home_screen.dart          # Main menu (solo / AI / friends)
│   ├── profile_screen.dart       # User profile & stats
│   ├── auth_wrapper.dart         # Auth state router
│   │
│   ├── quiz/
│   │   ├── category_screen.dart          # Pick a trivia category
│   │   ├── difficulty_screen.dart        # Choose difficulty (AI mode)
│   │   ├── quiz_screen.dart              # Solo quiz game loop
│   │   ├── quiz_vs_computer.dart         # AI opponent game loop
│   │   ├── computer_difficulty.dart      # AI logic per difficulty
│   │   └── result_screen.dart            # Post-game results & score
│   │
│   └── friends/
│       ├── friends_screen.dart           # Friends list & online status
│       ├── add_friend_screen.dart        # Search & add friends
│       ├── friend_requests_screen.dart   # Pending requests inbox
│       ├── match_lobby_screen.dart       # Pre-match waiting room
│       ├── friend_match_screen.dart      # Live 1v1 match screen
│       ├── friend_match_result_screen.dart # Match outcome
│       └── match_challenges_screen.dart  # Incoming challenges
│
├── features/
│   └── aptitude/
│       ├── aptitude_screen.dart          # Performance dashboard
│       ├── aptitude_service.dart         # Analysis logic
│       └── aptitude_model.dart           # Data model
│
├── services/
│   ├── auth_service.dart          # Login, signup, logout
│   ├── firestore_service.dart     # Firestore helpers
│   ├── friend_service.dart        # Friends, requests, online status
│   ├── friend_match_service.dart  # Match challenge flow
│   ├── profile_service.dart       # Profile data & image upload
│   └── trivia_service.dart        # Trivia API integration
│
└── utils/
    └── app_theme.dart             # Colors, typography, spacing tokens
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.9.0`
- A Firebase project with **Auth**, **Firestore**, and **Realtime Database** enabled
- Android Studio or VS Code with the Flutter plugin

### Setup

1. **Clone the repo**
   ```bash
   git clone https://github.com/Bsai-24071/Quizpath.git
   cd Quizpath/app_project
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable Email/Password auth, Firestore, and Realtime Database
   - Run `flutterfire configure` to auto-generate `firebase_options.dart`
   - Deploy `firestore.rules` to your project:
     ```bash
     firebase deploy --only firestore:rules
     ```

4. **Run the app**
   ```bash
   flutter run
   ```

---

## 🔐 Firestore Security Rules

The app ships with battle-tested Firestore rules that ensure:
- Users can only read/write their own data
- Friend requests can be created by any authenticated user (so others can send you one)
- Match challenges are accessible to both participants
- Aptitude data stays completely private

See [`firestore.rules`](./firestore.rules) for the full rule set.

---

## 🌐 API Used

QuizPath fetches trivia questions from the free **[Open Trivia Database](https://opentdb.com/)**. Questions are fetched per-session in the selected category and difficulty.

---


## 🤔 Why I Built This

This project was built to sharpen my skills in:
- **Full-stack mobile development** with Flutter and Firebase
- **Real-time data sync** for competitive multiplayer features
- **Clean architecture** — separating concerns across models, services, and screens
- **User-centered design** — making something people would actually want to use

It's not just a quiz app. It's a playground for everything I've learned about building production-quality Flutter applications.

---

## 👨‍💻 Author

**Bsai-24071**  
Artifical Intelligence Student  

[![GitHub](https://img.shields.io/badge/GitHub-Bsai--24071-181717?style=flat&logo=github)](https://github.com/Bsai-24071)

---

## 📄 License

This project is open source and available for educational purposes.

---

<p align="center">
  Made with ❤️ and way too much caffeine
</p>
