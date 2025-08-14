# UTeM Reporter - Application Modules Documentation

## 📋 Overview

UTeM Reporter is a comprehensive cross-platform mobile application built with Flutter/Dart, designed specifically for the Universiti Teknikal Malaysia Melaka (UTeM) community. The application serves as a centralized platform for reporting and managing campus-related issues, facilitating communication between students, staff, and administration.

## 🏗️ Architecture Overview

The application follows a modular architecture with clear separation of concerns, built on the following technical stack:

- **Frontend**: Flutter/Dart for cross-platform mobile development
- **Backend**: Firebase ecosystem (Authentication, Firestore, Storage, Messaging)
- **Additional Services**: Google Maps API, Machine Learning prediction service
- **Platforms**: iOS, Android, Web, Windows, macOS, Linux

## 📂 Module Structure

The application consists of **30 Dart files** organized into **6 main module categories**:

---

## 🔐 1. Authentication & User Management Module

**Purpose**: Handles user authentication, authorization, and session management

### Core Files:
- **`auth_page.dart`** - Main authentication router between login and registration
- **`login_page.dart`** - User login interface with email/password authentication
- **`register_page.dart`** - New user registration with role selection (Student/Staff)
- **`user_service.dart`** - User role management and profile services
- **`biometric_service.dart`** - Fingerprint and face ID authentication support
- **`session_manager.dart`** - Automatic session timeout and security management
- **`auth_token_service.dart`** - Token-based authentication and refresh handling

### Key Features:
- Role-based access control (Student vs Staff permissions)
- Biometric authentication for enhanced security
- Automatic session timeout (30 minutes)
- Secure token management
- Firebase Authentication integration

---

## 📝 2. Core Reporting System Module

**Purpose**: Manages the creation, submission, tracking, and resolution of campus issue reports

### Core Files:
- **`report_page.dart`** - Issue reporting form with category selection and location mapping
- **`report_detail_page.dart`** - Comprehensive report viewing and management interface
- **`staff_report_detail_page.dart`** - Staff-specific report handling and resolution tools
- **`student_report_detail_page.dart`** - Student view for tracking submitted reports
- **`report_status_helper.dart`** - Utilities for report status management and workflow

### Key Features:
- Three main report categories: Dormitory, Faculty, Campus
- Interactive map integration for precise location reporting
- Photo attachment for visual evidence
- ML-powered automatic category prediction
- Real-time status tracking (Pending, In Progress, Completed)
- Staff workflow for report assignment and resolution
- WhatsApp integration for direct communication

---

## 🏠 3. User Interface & Navigation Module

**Purpose**: Provides role-specific dashboards and navigation experiences

### Core Files:
- **`main.dart`** - Application entry point and global configuration
- **`welcome_page.dart`** - Onboarding and app introduction screen
- **`student_home_page.dart`** - Student dashboard with reporting shortcuts and personal report history
- **`staff_home_page.dart`** - Staff dashboard with assigned reports and management tools
- **`ticket_history_page.dart`** - Comprehensive report history and filtering

### Key Features:
- Animated welcome screen with branding
- Role-specific dashboards optimized for different user workflows
- Quick access reporting buttons for different campus areas
- Report statistics and progress tracking
- Intuitive navigation with modern Material Design 3

---

## 🔔 4. Notification System Module

**Purpose**: Handles real-time notifications, alerts, and communication

### Core Files:
- **`notification_service.dart`** - Core notification handling and Firebase messaging integration
- **`notification_model.dart`** - Data models for different notification types
- **`notifications_page.dart`** - Notification center and history interface
- **`notification_settings_page.dart`** - User preferences for notification management
- **`notification_badge.dart`** - UI components for notification indicators
- **`notification_test_utils.dart`** - Testing utilities for notification functionality

### Key Features:
- Real-time push notifications via Firebase Cloud Messaging
- Local notifications for offline scenarios
- Customizable notification preferences
- Report status update notifications
- Assignment notifications for staff
- Badge counters for unread notifications

---

## 🌐 5. External Services & APIs Module

**Purpose**: Integrates with external services and third-party APIs

### Core Files:
- **`api_service.dart`** - Machine learning API integration for automatic report categorization

### Key Features:
- ML-powered text analysis for automatic issue categorization
- HTTP client for external API communication
- Fallback mechanisms for API failures
- Support for multiple languages (English/Malay)
- Smart category mapping and suggestions

---

## 🛠️ 6. Utilities & Helpers Module

**Purpose**: Provides supporting functionality and utilities

### Core Files:
- **`activity_detector.dart`** - User activity monitoring for session management
- **`notification_test_utils.dart`** - Testing utilities and debugging tools

### Key Features:
- Automatic session management based on user activity
- Development and testing utilities
- Performance monitoring helpers

---

## 🌍 Cross-Platform Support

The application is designed for deployment across multiple platforms:

- **Mobile**: iOS and Android with native performance
- **Web**: Progressive Web App capabilities
- **Desktop**: Windows, macOS, and Linux support
- **Responsive Design**: Adaptive UI for different screen sizes

---

## 🔧 Technical Dependencies

### Core Flutter Packages:
- **firebase_core** - Firebase SDK initialization
- **firebase_auth** - User authentication
- **cloud_firestore** - Real-time database
- **firebase_storage** - File storage
- **firebase_messaging** - Push notifications

### Feature-Specific Packages:
- **google_maps_flutter** - Interactive maps
- **image_picker** - Photo capture and selection
- **geolocator** - Location services
- **local_auth** - Biometric authentication
- **easy_localization** - Multi-language support
- **flutter_local_notifications** - Local notification handling

---

## 🎯 User Workflows

### Student Workflow:
1. Register/Login with student role
2. Navigate to report categories (Dorm/Faculty/Campus)
3. Select location on interactive map
4. Add description and photos
5. Submit report and receive confirmation
6. Track report status and receive updates
7. View report history and statistics

### Staff Workflow:
1. Login with staff credentials
2. View assigned reports dashboard
3. Review report details and evidence
4. Update report status and add work notes
5. Communicate with reporters via WhatsApp
6. Upload completion evidence
7. Mark reports as resolved

---

## 🔐 Security Features

- **Firebase App Check** - Protection against abuse
- **Biometric Authentication** - Enhanced login security
- **Session Management** - Automatic timeout and refresh
- **Secure Storage** - Encrypted local data storage
- **Role-based Access Control** - Permission-based feature access

---

## 🌟 Key Innovations

1. **ML-Powered Categorization** - Automatic issue classification using natural language processing
2. **Interactive Campus Mapping** - Precise location reporting with Google Maps integration
3. **Real-time Collaboration** - Live updates between students and staff
4. **Cross-platform Consistency** - Unified experience across all devices
5. **Offline Capability** - Core functionality available without internet connection

---

## 📱 Supported Features by Platform

| Feature | Android | iOS | Web | Desktop |
|---------|---------|-----|-----|---------|
| Report Creation | ✅ | ✅ | ✅ | ✅ |
| Photo Capture | ✅ | ✅ | ✅ | ✅ |
| Push Notifications | ✅ | ✅ | ✅ | ✅ |
| Biometric Auth | ✅ | ✅ | ❌ | ❌ |
| Maps Integration | ✅ | ✅ | ✅ | ✅ |
| Offline Mode | ✅ | ✅ | Limited | ✅ |

---

This modular architecture ensures maintainability, scalability, and efficient development workflows while providing a robust solution for campus issue management at UTeM.