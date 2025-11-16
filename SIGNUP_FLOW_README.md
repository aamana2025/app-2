# Mansa - Flutter App with Payment Integration

## New Signup Flow with Payment Integration

This Flutter app now includes a complete signup flow with Stripe payment integration. Here's how it works:

### Flow Overview

1. **Signup Form** → User fills out registration form
2. **Create Pending User** → Backend creates a pending user account
3. **Select Plan** → User chooses a subscription plan
4. **Payment** → Stripe checkout session is created
5. **WebView Payment** → User completes payment in Stripe's secure interface
6. **Account Activation** → Backend activates the account after successful payment
7. **Login** → User can now log in with their credentials

### Key Features

- **Secure Storage**: Pending user ID is stored securely using `flutter_secure_storage`
- **Real API Integration**: All API calls go to `https://class-room-backend-nodejs.vercel.app`
- **Stripe Integration**: Secure payment processing through Stripe checkout
- **WebView Payment**: Native WebView for Stripe payment interface
- **Status Checking**: Automatic checking of account activation status
- **Arabic RTL Support**: Full Arabic language support with RTL layout

### API Endpoints Used

- `POST /api/auth/pending` - Create pending user
- `GET /api/plans` - Get available subscription plans
- `POST /api/payment/checkout` - Create Stripe checkout session
- `GET /api/auth/status/{pendingId}` - Check signup status
- `POST /api/auth/login` - User login

### Dependencies Added

- `webview_flutter: ^4.4.2` - For Stripe payment WebView
- `flutter_secure_storage: ^9.0.0` - For secure storage of pending ID
- `http: ^1.1.0` - For API calls

### File Structure

```
lib/
├── screens/
│   ├── auth/
│   │   └── signup_with_payment_screen.dart  # New signup form
│   └── subscription/
│       ├── plans_screen.dart                # Plans selection
│       └── payment_screen.dart              # Stripe WebView payment
├── providers/
│   └── auth_provider.dart                   # Updated with new methods
├── services/
│   └── api_service.dart                     # Updated with real API calls
├── utils/
│   └── signup_status_checker.dart          # Status checking utility
└── router/
    └── app_router.dart                      # Updated routing
```

### Usage

1. User navigates to `/signup` (now uses new signup flow)
2. User fills out the registration form
3. System creates pending user and stores pending ID securely
4. User is redirected to `/plans` to select a subscription plan
5. User selects a plan and is redirected to `/payment` with Stripe checkout URL
6. User completes payment in Stripe's secure WebView
7. On successful payment, user is redirected to login screen
8. System automatically checks for account activation

### Security Features

- Pending user ID stored in secure storage
- All API calls use HTTPS
- Stripe handles sensitive payment data
- Automatic cleanup of pending data after activation

### Error Handling

- Network error handling for all API calls
- Payment cancellation handling
- Account activation status checking
- User-friendly error messages in Arabic
