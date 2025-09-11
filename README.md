<img width="1920" height="1080" alt="QHReleaseGraphic" src="https://github.com/user-attachments/assets/6508c5ea-df61-4e51-aeb9-f82e0f094729" />


# QuickHire
![Static Badge](https://img.shields.io/badge/dart-grey?style=for-the-badge&logo=dart&logoColor=skyblue)
![Static Badge](https://img.shields.io/badge/Flutter-grey?style=for-the-badge&logo=flutter&logoColor=skyblue)
![Static Badge](https://img.shields.io/badge/Firebase-grey?style=for-the-badge&logo=firebase&logoColor=orange)

## 🚀 Bridging the Gap Between Job Seekers and Employers in Malaysia
QuickHire is a comprehensive mobile application designed to revolutionize the job market in Malaysia by connecting job seekers with employers through location-based job posting and real-time applications. The app empowers employers to post jobs with precise locations, manage applications efficiently, and communicate directly with candidates. Job seekers can discover opportunities near them, apply with personalized messages, and track their application status in real-time. With Firebase integration for seamless authentication and data management, Google Sign-in for quick access, and map-based job search functionality, QuickHire provides an intuitive platform that caters to both casual job seekers and professional recruiters. This application is developed with a focus on user experience, creating a valuable resource that streamlines the hiring process for the Malaysian job market.

## ✨ Features
### 👔 For Employers
- Post detailed job listings with location-based mapping and job categories
- Manage incoming applications with accept/reject functionality and employer messages
- View comprehensive application analytics and candidate information
- Real-time messaging with potential candidates
- Job posting management with active/inactive status controls

### 👤 For Job Seekers
- Browse and search jobs by location, category, and salary range
- Apply to jobs with personalized application messages
- Track application status with real-time updates and notifications
- Location-based job discovery using interactive maps
- View detailed job information and employer profiles

### 🔧 General Features
- Firebase Authentication with Google Sign-in integration
- Real-time notifications for application updates
- Interactive map-based location selection and job search
- Comprehensive search and filtering system
- In-app messaging between employers and job seekers
- Responsive design optimized for mobile devices

## 🖼️ Screenshots
<img width="1080" height="1920" alt="QHSC1" src="https://github.com/user-attachments/assets/a75bbe51-5ab5-44f8-beca-1460ac1b66eb" />
<img width="1080" height="1920" alt="QHSC2" src="https://github.com/user-attachments/assets/a50dfef7-3e6c-4a67-86f5-be0d7a67774f" />
<img width="1080" height="1920" alt="QHSC3" src="https://github.com/user-attachments/assets/35f16c0e-2304-45a9-9260-0ea3b9f02cea" />


## 📝 How to Build

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.7.2 or higher)
- [Android Studio](https://developer.android.com/studio) or [Xcode](https://developer.apple.com/xcode/) for mobile development
- [Firebase account](https://console.firebase.google.com) for backend services
- [Git](https://git-scm.com/) for version control

### Setup Instructions
To build the app, follow these steps:
```shell
# Ensure Flutter is installed and properly configured
flutter doctor

# Clone the repository
git clone https://github.com/Developed-by-Mo/QuickHire.git

# Navigate to the project directory
cd QuickHire

# Run 'flutter pub get' to get dependencies
flutter pub get

# Set up Firebase:
# 1. Create a new Firebase project at https://console.firebase.google.com
# 2. Enable Authentication with Google Sign-in provider
# 3. Create a Firestore database in production mode
# 4. Add Android and iOS apps to your Firebase project with these package names:
#    - Android: com.example.quickhire (or change in android/app/build.gradle.kts)
#    - iOS: com.example.quickhire (or change in ios/Runner.xcodeproj)
# 5. Download and place the configuration files:
#    - Download google-services.json and place it in android/app/
#    - Download GoogleService-Info.plist and place it in ios/Runner/
# 6. Run the FlutterFire CLI to generate firebase_options.dart:
#    dart pub global activate flutterfire_cli
#    flutterfire configure --project=your-firebase-project-id

# Generate splash screen
dart run flutter_native_splash:create

# Build and run the project
flutter run
```

### Firestore Security Rules
Don't forget to set up proper Firestore security rules in the Firebase console. Here's a basic example:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Job listings are readable by all authenticated users
    match /job_listings/{document} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == resource.data.poster_uid;
    }
    
    // Applications are readable by applicant and job poster
    match /job_applications/{jobId}/applications/{applicationId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.applicantUid || 
         request.auth.uid == resource.data.employerUid);
    }
  }
}
```

### 🔧 Troubleshooting

**Common Issues:**

1. **Firebase configuration errors:**
   - Ensure `google-services.json` and `GoogleService-Info.plist` are in the correct locations
   - Verify package names match between Firebase console and your app configuration
   - Run `flutterfire configure` if you're getting Firebase initialization errors

2. **Flutter build errors:**
   - Run `flutter clean && flutter pub get` to clean dependencies
   - Check that your Flutter version matches the SDK requirements in `pubspec.yaml`
   - Ensure all required development tools are installed with `flutter doctor`

3. **Google Sign-in issues:**
   - Verify Google Sign-in is enabled in Firebase Authentication
   - Check that the SHA-1 fingerprint is added to your Firebase Android app (for Android)
   - Ensure proper URL schemes are configured (for iOS)

4. **Location permissions:**
   - The app requires location permissions for map functionality
   - Grant location permissions when prompted on first launch

**Need help?** Feel free to [open an issue](https://github.com/Developed-by-Mo/QuickHire/issues) if you encounter any problems!

## 🏗️ Project Structure
```
lib/
├── core/                    # Core utilities and shared components
│   ├── model/              # Data models (JobListing, LocationData, etc.)
│   ├── services/           # Core services (AuthService, JobService, etc.)
│   ├── theme/              # App theming and color palette
│   └── views/              # Shared widgets and components
├── features/               # Feature-based modules
│   ├── auth/               # Authentication (login, registration)
│   ├── home/               # Home screens for employers and employees
│   ├── job/                # Job viewing and details
│   ├── job_application/    # Application management system
│   ├── job_posting/        # Job creation and posting
│   ├── messaging/          # In-app messaging system
│   ├── notifications/      # Push notifications
│   ├── onboarding/         # App onboarding flow
│   ├── profile/            # User profile management
│   └── search/             # Job search and filtering
└── firebase_options.dart   # Firebase configuration
```

## 🤝 Contributing
Contributions to the QuickHire app are welcomed. If you would like to contribute to the development, please follow these guidelines:

1. Fork the repository.

2. Create a new branch for your feature or bug fix.

3. Make your changes and commit them with descriptive messages.

4. Push your changes to your fork.

5. Submit a pull request to the main repository.

## Dependencies used
### Core Dependencies
* flutter_riverpod - State management
* go_router - Navigation and routing
* firebase_core - Firebase initialization
* firebase_auth - Authentication
* cloud_firestore - Database
* google_sign_in - Google authentication

### UI & Animation
* smooth_page_indicator - Page indicators
* lottie - Lottie animations
* flutter_native_splash - Splash screen
* skeletonizer - Loading skeletons

### Location & Maps
* flutter_map - Interactive maps
* latlong2 - Latitude/longitude utilities
* geolocator - Location services

### Utilities
* connectivity_plus - Network connectivity
* http - HTTP requests
* image_picker - Image selection
* url_launcher - URL launching
* timeago - Time formatting
* shared_preferences - Local storage

## Support
If you find this project useful, please consider giving it a star on [GitHub](https://github.com/Developed-by-Mo/QuickHire). Your support is greatly appreciated!

<a href="https://buymeacoffee.com/developedbymo" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="32" width="140"></a>

## License
- Please reach out to me at mostafasalama.my@gmail.com for further information.
