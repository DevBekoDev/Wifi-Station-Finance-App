# WSFM — Wi-Fi Station Finance Manager

WSFM is a Flutter-based finance management application designed for Wi-Fi service centers.  
The system helps administrators and center managers track sales, expenses, centers, managers, reports, and financial performance in one organized platform.

The project also includes an AI Finance Assistant that allows users to ask finance-related questions based on their role and access level.

---

## Overview

WSFM was built to simplify financial tracking for Wi-Fi stations by providing:

- Role-based access for Admins and Managers
- Center and manager management
- Sales tracking
- Expense tracking
- Financial reports
- Firebase Authentication
- Cloud Firestore database
- AI-powered finance assistant
- Clean and responsive Flutter UI

---

## Main Roles

### Admin

The Admin can:

- Create and manage centers
- Create and manage managers
- View all centers
- View total sales and expenses
- Access all financial reports
- Edit center and manager information
- Ask the AI Assistant about all available finance data

### Manager

The Manager can:

- Access only their assigned center
- Add sales records
- Edit sales records
- Delete sales with a reason
- View center reports
- Ask the AI Assistant only about their own center data

---

## Features

### Authentication

- Firebase Email/Password login
- User session checking
- Role-based navigation
- Logout system
- Manager activation flow

### Admin Dashboard

- Total centers
- Total managers
- Monthly revenue
- Monthly expenses
- Center performance overview
- Quick access to center and manager management

### Manager Dashboard

- Assigned center overview
- Sales management
- Expense management
- Reports access
- AI Assistant access

### Sales Management

- Add sales
- Edit sales
- Delete sales with reason
- Track quantity and amount
- Store sales by center

### Reports

- Sales reports
- Expense reports
- Center-based reports
- Admin-level reports
- Manager-level reports
- Data filtering by center and date

### AI Finance Assistant

- Integrated AI assistant for finance questions
- Uses role-based finance context
- Admin can ask about all centers
- Manager can ask only about assigned center
- Floating AI button available on allowed screens
- Access control prevents managers from seeing other centers’ data

---

## Tech Stack

| Technology | Purpose |
|---|---|
| Flutter | Mobile app development |
| Dart | Programming language |
| Firebase Authentication | User login and session management |
| Cloud Firestore | Database |
| Firebase Security Rules | Role-based database protection |
| Gemini API | AI Finance Assistant |
| BLoC / Cubit | State management |
| Git & GitHub | Version control |

---

## Project Structure

```txt
lib/
│
├── main.dart
├── app.dart
│
├── routes/
│   └── app_routes.dart
│
├── screens/
│   ├── splash/
│   ├── start/
│   ├── login/
│   ├── admin_dashboard/
│   ├── manager_dashboard/
│   ├── centers/
│   ├── managers/
│   ├── sales/
│   ├── expenses/
│   ├── reports/
│   └── ai_assistant/
│
├── widgets/
│   ├── logout_button.dart
│   ├── custom_appbar.dart
│   ├── ai_assistant_overlay.dart
│   └── shared_widgets.dart
│
├── models/
│   ├── user_model.dart
│   ├── center_model.dart
│   ├── sale_model.dart
│   └── expense_model.dart
│
├── services/
│   ├── firebase_auth_service.dart
│   ├── firestore_service.dart
│   ├── finance_ai_context_service.dart
│   └── gemini_assistant_service.dart
│
├── cubits/
│   ├── auth/
│   ├── sales/
│   ├── admin_dashboard/
│   ├── admin_reports/
│   └── create_center/
│
└── utils/
    ├── app_theme.dart
    ├── constants.dart
    ├── date_helper.dart
    └── app_navigator_key.dart
```

---

## Firestore Database Structure

```txt
users/
  userId/
    email
    role
    centerId
    createdAt

centers/
  centerId/
    name
    location
    managerName
    managerEmail
    createdAt

sales/
  saleId/
    centerId
    itemName
    quantity
    amount
    createdAt
    createdBy

expenses/
  expenseId/
    centerId
    category
    amount
    description
    createdAt
    createdBy
```

---

## Role-Based Access

WSFM uses role-based access to protect user data.

### Admin Access

Admins can access:

- All users
- All centers
- All sales
- All expenses
- All reports

### Manager Access

Managers can access:

- Only their own user data
- Only their assigned center
- Only sales and expenses linked to their center

This access control is handled both inside the Flutter application and through Firebase Security Rules.

---

## AI Assistant Access Logic

The AI Finance Assistant does not receive all data for every user.

The finance context is prepared based on the logged-in user:

- If the user is an Admin, the AI receives all center finance data.
- If the user is a Manager, the AI receives only the assigned center data.
- If the Manager asks about another center, the app blocks the request.

This protects sensitive financial information between centers.

---

---

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/DevBekoDev/Wifi-Station-Finance-App
cd Wifi-Station-Finance-App
```

### 2. Install Flutter Packages

```bash
flutter pub get
```

### 3. Configure Firebase

Create a Firebase project and enable:

- Firebase Authentication
- Cloud Firestore
- Android app configuration
- iOS app configuration if needed

Then add the Firebase configuration files:

```txt
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

### 4. Run the App

```bash
flutter run
```

---


## Development Timeline

The project was developed over 12 weeks.

| Weeks | Work Completed |
|---|---|
| Weeks 1–8 | Main finance management system |
| Weeks 9–12 | AI Finance Assistant integration |

---

## Main Code Concepts

The project includes important implementation areas such as:

- Firebase initialization
- Login and session checking
- Role-based navigation
- Add sales function
- Edit sales function
- Delete sales with reason
- Admin edit center and manager
- Edit card stock for each center
- AI finance context service
- Gemini assistant service
- AI floating button visibility

---

## Security Notes

- Managers cannot access other centers’ data.
- Admins have full access.
- Firestore rules protect sensitive data.
- AI context is filtered before being sent to the assistant.
- API keys should not be committed to GitHub.

---

## Future Improvements

Planned improvements include:

- Live voice AI assistant
- Advanced charts and analytics
- PDF report export
- CSV export
- Push notifications
- More detailed manager performance reports
- Offline support
- Improved AI memory per user

---

## Project Status

The project is functional and includes the main finance management system with AI assistant support.

Current status:

- Authentication completed
- Admin and Manager roles completed
- Sales management completed
- Reports completed
- Firebase integration completed
- AI Assistant integrated
- Role-based AI access implemented

---

## License

This project is for educational and portfolio purposes.

---

## Author

Developed by **[Abubakr Ezalden Alameen Nasir](https://github.com/DevBekoDev) , [MOHAMEDELBAGIR ADIL ELJUNID ELBAKRI](https://github.com/mo7a3dil)**
