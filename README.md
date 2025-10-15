# 🚨 Hızır Acil – Emergency Response App

A cross-platform **Flutter** application built with **Dart** and powered by **Firebase**.  
The app allows **users to report emergencies** instantly, while **drivers** (such as ambulance or firetruck operators) and **response centers** can monitor, respond, and coordinate emergency activities in real-time.

---

## 🚀 Features

- 🆘 **Emergency Reporting** – Users can sign in and quickly send an emergency alert with a single tap.  
- 🚑 **Driver Login & Interface** – Emergency vehicle drivers (ambulance, firetruck, etc.) can log in through the same screen and access their dedicated dashboard (in development).  
- 🗺️ **Control Center Dashboard** – Centers can log in to view a real-time **map** displaying active emergencies, including **user locations** and **emergency types**.  
- 📍 **Firebase Integration** – Secure authentication, data storage, and location-based synchronization powered by Firebase.  
- 🔐 **Role-Based Access** – Different interfaces and permissions for users, drivers, and centers.  
- ⚙️ **Scalable Architecture** – Built with Flutter and Firebase for smooth cross-platform performance.  

---

## 🔮 Future Roadmap

- 👷 **Employee Assignment System** – Allow control centers to assign emergency workers to specific incidents.  
- 🧭 **Navigation Support** – Drivers will receive **optimized route guidance** from their current position to the emergency location.  
- 📶 **Bluetooth Location Enhancement** – Improve location precision using Bluetooth-based proximity detection.  
- 🔊 **Secure Communication** – Implement encrypted **Bluetooth-based messaging** and **voice calling** between users and drivers.  

---

## 🧠 Tech Stack

| Technology | Description |
|-------------|-------------|
| **Flutter (Dart)** | Cross-platform mobile UI framework |
| **Firebase** | Backend for authentication, Firestore database, and storage |
| **Google Maps API** | Real-time location and mapping |
| **Flutter Dotenv** | Environment configuration and variable management |
| **Provider / Riverpod** | State management for reactive updates |

---

## 🛠️ Getting Started

Follow these steps to run the project locally.

### 1. Clone the Repository

```bash
git clone https://github.com/Onur-Aba/Emergency-Notification-App.git
cd Emergency-Notification-App
```
2. Install Dependencies

```bash
flutter pub get
```
3. Configure Firebase
Create a Firebase project in the Firebase Console
and add your configuration to an .env file inside the assets directory:

```bash

FIREBASE_API_KEY=your_api_key
FIREBASE_APP_ID=your_app_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_storage_bucket
FIREBASE_AUTH_DOMAIN=your_auth_domain
FIREBASE_MEASUREMENT_ID=your_measurement_id
```
4. After these, you need to replace the end of the variable 
```bash
"https://maps.googleapis.com/maps/api/js?key=%GOOGLE_API_KEY_WEB%" 
```
in the 41st line of the index.html file with your own API key.


5. Run the App
```bash

flutter run
```
You can also specify a device:

```bash

flutter run -d chrome     # for Web
flutter run -d android    # for Android
flutter run -d ios        # for iOS
```

## 📈 Development Status
The app is currently under active development.

✅ User authentication & emergency alert system implemented

⚙️ Driver and center dashboards under construction

🚧 Bluetooth and route guidance features in planning