# Mansa - Flutter Authentication & Subscription App

A complete Flutter application with Arabic RTL support featuring authentication and subscription flows with a beautiful dark theme.

## Features

### Authentication Flow
- **Login Screen** - Email and password authentication
- **Sign Up Screen** - User registration with name, email, phone, and password
- **Forget Password Flow** - 3-step process:
  1. Email input for password reset
  2. OTP verification (mock: use `123456`)
  3. New password setup

### Subscription Flow
- **Plans Screen** - Display subscription plans with features and pricing
- **Payment Screen** - Mock Stripe integration with card details form

### UI/UX Features
- **Arabic RTL Support** - Complete right-to-left layout
- **Dark Theme** - Custom dark theme with blue and purple accents
- **Material 3 Design** - Modern, clean interface
- **Responsive Design** - Works on all screen sizes
- **Loading States** - Proper loading indicators and overlays
- **Error Handling** - User-friendly error messages

## Project Structure

```
lib/
├── main.dart                 # App entry point with theme and RTL setup
├── router/
│   └── app_router.dart      # GoRouter configuration
├── providers/
│   ├── auth_provider.dart   # Authentication state management
│   └── subscription_provider.dart # Subscription state management
├── services/
│   └── api_service.dart     # Mock API service with placeholder methods
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   ├── forget_password_screen.dart
│   │   ├── otp_verification_screen.dart
│   │   └── reset_password_screen.dart
│   ├── subscription/
│   │   ├── plans_screen.dart
│   │   └── payment_screen.dart
│   └── home_screen.dart
└── widgets/
    ├── custom_button.dart
    ├── custom_text_field.dart
    ├── plan_card.dart
    └── loading_overlay.dart
```

## Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / VS Code with Flutter extensions

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd mansa
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## Mock Data & Testing

### Authentication
- **Login**: Use any email format (e.g., `test@example.com`) and any password
- **Sign Up**: All fields are validated, password must be 6+ characters
- **OTP Verification**: Use `123456` for testing

### Payment
- **Card Number**: `4242424242424242`
- **Expiry Date**: `12/25`
- **CVV**: `123`
- **Cardholder Name**: Any name

## Theme Colors

- **Background**: `#000000` (Black)
- **Cards/Containers**: `#1C1C1E` (Dark Grey)
- **Primary**: `#0A84FF` (Blue)
- **Secondary**: `#8E44AD` (Purple)
- **Text**: White (`#FFFFFF`) and Light Grey (`#B0B0B0`)

## State Management

The app uses **Provider** for state management with two main providers:

- **AuthProvider**: Handles authentication state, user data, and auth operations
- **SubscriptionProvider**: Manages subscription plans, selected plan, and payment processing

## Navigation

Uses **GoRouter** for navigation with the following routes:

- `/login` - Login screen
- `/signup` - Sign up screen
- `/forget-password` - Password reset request
- `/otp` - OTP verification
- `/reset-password` - New password setup
- `/plans` - Subscription plans
- `/payment` - Payment processing
- `/home` - Main dashboard

## API Integration Ready

The `ApiService` class contains mock methods that are structured to be easily replaced with real API calls:

- `login()` - User authentication
- `signup()` - User registration
- `requestPasswordReset()` - Send OTP
- `verifyOtp()` - Verify OTP code
- `resetPassword()` - Reset user password
- `getPlans()` - Fetch subscription plans
- `payWithStripe()` - Process payment

## Future Integration

To integrate with real backend and Stripe:

1. **Replace API Service**: Update `lib/services/api_service.dart` with real HTTP calls
2. **Add Environment Variables**: Use `flutter_dotenv` for API keys and endpoints
3. **Stripe Integration**: Replace mock payment with Stripe SDK
4. **Error Handling**: Implement proper error handling for network requests
5. **Token Management**: Add secure token storage and refresh logic

## Dependencies

- `go_router`: Navigation
- `provider`: State management
- `shared_preferences`: Local storage
- `flutter_localizations`: RTL support

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.
