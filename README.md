# 🐍 Neon Snake Pro - AAA Mobile Game

A premium, production-quality Snake Game built with Flutter, following Clean Architecture and SOLID principles.

## 🚀 Key Features

- **Premium AAA Visuals**: Glassmorphism UI, Neon Aesthetic, and smooth animations using `flutter_animate`.
- **Scalable Architecture**: Feature-first modular structure with Riverpod for state management.
- **Professional Game Engine**: High-performance custom painting for the game board with smooth movement and collision logic.
- **Monetization Ready**: Full Google Mobile Ads integration (Banner, Interstitial, and Rewarded Ads).
- **Immersive Experience**: Haptic feedback support and custom sound effects.
- **Customization**: Persistent settings for snake color, food style, and game speed.

## 🛠 Tech Stack

- **Framework**: Flutter (Latest Stable)
- **State Management**: Riverpod
- **Local Storage**: Shared Preferences
- **Ads**: Google Mobile Ads SDK
- **UI**: Google Fonts, Glassmorphism, Flutter Animate
- **Audio**: AudioPlayers

## 📂 Project Structure

```text
lib/
├── core/               # Constants, Errors, Utils
├── config/             # App Config, Routing, DI
├── services/           # AdManager, Audio, Vibration, Storage
├── features/           # Feature-based modules (Splash, Menu, Game, Settings, GameOver)
├── shared/             # Reusable UI components, Themes, Animations
├── providers/          # Global Riverpod providers
└── main.dart           # Entry point
```

## ⚙️ AdMob Setup Instructions

To replace the test ads with real ones:

1. Go to the [Google AdMob Console](https://admob.google.com/).
2. Create a new app for Android and iOS.
3. Create the following ad units:
   - **Banner Ad**
   - **Interstitial Ad**
   - **Rewarded Ad**
4. Open `lib/core/constants/app_constants.dart`.
5. Replace `bannerAdUnitId`, `interstitialAdUnitId`, and `rewardedAdUnitId` with your actual unit IDs.
6. Add your AdMob App ID to your platform-specific files:
   - **Android**: `AndroidManifest.xml`
   - **iOS**: `Info.plist`

## 📦 Running the Application

1. Clone the repository.
2. Run `flutter pub get`.
3. Ensure you have assets in the following paths:
   - `assets/audio/eat.mp3`
   - `assets/audio/click.mp3`
   - `assets/audio/game_over.mp3`
   - `assets/images/logo.png`
4. Run the app: `flutter run`.

## 🏆 Production Quality Checklist

- [x] Null Safety enabled
- [x] Clean Architecture implemented
- [x] Responsive Layouts (Android/iOS)
- [x] Optimized rebuilds with Riverpod
- [x] Immersive UI mode (Full screen)
- [x] Proper lifecycle management for Ads and Timers
