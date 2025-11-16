# Testing Splash Screen and App Icon

## What's Been Set Up

### ✅ Native Splash Screen
- **Splash Image**: `assets/images/logo.png` (Frame_16_1.png)
- **App Icon for Android 12+**: `assets/images/app_icon.png` (school-svgrepo-com_1_1.png)
- **Background Color**: White (#ffffff)
- **Platforms**: Android, iOS

### ✅ App Icons Generated
- **Android**: All required sizes (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- **iOS**: All required sizes (20x20 to 1024x1024)
- **Web**: Favicon and app icons
- **Windows**: Desktop icon

## How to Test

### 1. Clean and Rebuild
```bash
flutter clean
flutter pub get
```

### 2. Test on Android
```bash
flutter run -d android
```
- The splash screen should show your logo on a white background
- The app icon should appear in the app drawer and home screen
- For Android 12+, the splash screen will use the app icon

### 3. Test on iOS
```bash
flutter run -d ios
```
- The splash screen should show your logo on a white background
- The app icon should appear on the home screen

### 4. Test on Web
```bash
flutter run -d web
```
- The web app should have the proper favicon and app icons

## Expected Behavior

### Splash Screen
1. **App Launch**: Shows immediately when app starts
2. **Logo Display**: Your logo image centered on white background
3. **Auto Hide**: Disappears when the app finishes loading
4. **Smooth Transition**: Fades to your app's main screen

### App Icon
1. **Home Screen**: Shows your school icon
2. **App Drawer**: Shows your school icon
3. **Recent Apps**: Shows your school icon
4. **Settings**: Shows your school icon

## Troubleshooting

### If Splash Screen Doesn't Show
1. Make sure you ran `flutter clean` and `flutter pub get`
2. Check that `assets/images/logo.png` exists
3. Verify the image is not corrupted
4. Try rebuilding the app completely

### If App Icon Doesn't Show
1. Make sure you ran `flutter clean` and `flutter pub get`
2. Check that `assets/images/app_icon.png` exists
3. Verify the image is square and high quality
4. Try uninstalling and reinstalling the app

### If Icons Look Blurry
1. Make sure your source images are high resolution
2. Use PNG format for best quality
3. Ensure images are square (1:1 aspect ratio)

## File Structure Created
```
android/app/src/main/res/
├── mipmap-mdpi/ic_launcher.png
├── mipmap-hdpi/ic_launcher.png
├── mipmap-xhdpi/ic_launcher.png
├── mipmap-xxhdpi/ic_launcher.png
└── mipmap-xxxhdpi/ic_launcher.png

ios/Runner/Assets.xcassets/AppIcon.appiconset/
├── Icon-App-20x20@1x.png
├── Icon-App-20x20@2x.png
├── Icon-App-20x20@3x.png
├── Icon-App-29x29@1x.png
├── Icon-App-29x29@2x.png
├── Icon-App-29x29@3x.png
├── Icon-App-40x40@1x.png
├── Icon-App-40x40@2x.png
├── Icon-App-40x40@3x.png
├── Icon-App-60x60@2x.png
├── Icon-App-60x60@3x.png
├── Icon-App-76x76@1x.png
├── Icon-App-76x76@2x.png
├── Icon-App-83.5x83.5@2x.png
└── Icon-App-1024x1024@1x.png

web/
├── favicon.png
├── icons/
│   ├── Icon-192.png
│   ├── Icon-512.png
│   ├── Icon-maskable-192.png
│   └── Icon-maskable-512.png
└── manifest.json (updated)

windows/runner/
└── app_icon.ico
```

## Next Steps
1. Test the app on different devices
2. Verify the splash screen and icons look good
3. If needed, adjust the images and regenerate
4. Build and test the release version

## Regenerating Icons
If you need to change the images:
1. Replace the images in `assets/images/`
2. Run `flutter pub run flutter_launcher_icons:main`
3. Run `flutter pub run flutter_native_splash:create`
4. Clean and rebuild: `flutter clean && flutter pub get`
