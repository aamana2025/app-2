# App Icon Setup Instructions

## Current Status
✅ Native splash screen has been generated successfully
✅ App icon image has been copied to `assets/images/app_icon.png`

## Next Steps for App Icon

### Option 1: Use flutter_launcher_icons (Recommended)
Add this to your `pubspec.yaml` under `dev_dependencies`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  flutter_native_splash: ^2.3.5
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/app_icon.png"
  remove_alpha_ios: true
  min_sdk_android: 21
  web:
    generate: true
    image_path: "assets/images/app_icon.png"
    background_color: "#hexcode"
    theme_color: "#hexcode"
  windows:
    generate: true
    image_path: "assets/images/app_icon.png"
    icon_size: 48
  macos:
    generate: true
    image_path: "assets/images/app_icon.png"
```

Then run:
```bash
flutter pub get
flutter pub run flutter_launcher_icons:main
```

### Option 2: Manual Setup (Alternative)

#### For Android:
1. Create different icon sizes in `android/app/src/main/res/`:
   - `mipmap-mdpi/ic_launcher.png` (48x48)
   - `mipmap-hdpi/ic_launcher.png` (72x72)
   - `mipmap-xhdpi/ic_launcher.png` (96x96)
   - `mipmap-xxhdpi/ic_launcher.png` (144x144)
   - `mipmap-xxxhdpi/ic_launcher.png` (192x192)

#### For iOS:
1. Create different icon sizes in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`:
   - `Icon-App-20x20@1x.png` (20x20)
   - `Icon-App-20x20@2x.png` (40x40)
   - `Icon-App-20x20@3x.png` (60x60)
   - `Icon-App-29x29@1x.png` (29x29)
   - `Icon-App-29x29@2x.png` (58x58)
   - `Icon-App-29x29@3x.png` (87x87)
   - `Icon-App-40x40@1x.png` (40x40)
   - `Icon-App-40x40@2x.png` (80x80)
   - `Icon-App-40x40@3x.png` (120x120)
   - `Icon-App-60x60@2x.png` (120x120)
   - `Icon-App-60x60@3x.png` (180x180)
   - `Icon-App-76x76@1x.png` (76x76)
   - `Icon-App-76x76@2x.png` (152x152)
   - `Icon-App-83.5x83.5@2x.png` (167x167)
   - `Icon-App-1024x1024@1x.png` (1024x1024)

## Current Configuration

### Native Splash Screen
- **Splash Image**: `assets/images/logo.png` (Frame_16_1.png)
- **App Icon for Android 12+**: `assets/images/app_icon.png` (school-svgrepo-com_1_1.png)
- **Background Color**: White (#ffffff)
- **Platforms**: Android, iOS

### Assets Structure
```
assets/
└── images/
    ├── logo.png          (Splash screen image)
    └── app_icon.png      (App icon image)
```

## Testing
1. Run `flutter clean`
2. Run `flutter pub get`
3. Run `flutter run` to test the splash screen
4. Check both Android and iOS platforms

## Notes
- The splash screen will show the logo image on a white background
- For Android 12+, it will use the app icon image
- The splash screen will automatically hide when the app loads
- Make sure your images are high quality and properly sized
