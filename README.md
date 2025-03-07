# BarBuddy
BarBuddy is a mobile app designed to promote safer drinking habits by tracking alcohol consumption, estimating blood alcohol content (BAC), and providing safety features.

# BarBuddy

## Your Personal Drinking Companion

BarBuddy is a mobile application designed to promote safer drinking habits by tracking alcohol consumption, estimating blood alcohol content (BAC), and providing essential safety features for users who consume alcohol.

![BarBuddy Logo](frontend/assets/images/logo.png)

## Features

### Core Functionality
- **Real-time Drink Logging**: Easily log beers, wine, liquor, and mixed drinks
- **BAC Estimation**: Get reliable estimates of your current BAC level
- **Safe-to-Drive Timer**: Know when it's safe to drive again
- **Emergency Contact System**: Set up trusted contacts who can be notified

### Advanced Features
- **Smart Notifications**: Receive hydration reminders, low battery alerts, and more
- **Ride-Share Integration**: Easy access to Uber, Lyft and other ride services
- **Drink History**: View your consumption patterns with nightly, weekly, monthly summaries
- **Check-in System**: Automatic texts to let loved ones know you got home safely

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Android Studio or VS Code with Flutter extensions
- iOS development tools (if building for iOS)

### Installation

1. Clone the repository
   ```
   git clone https://github.com/yourusername/barbuddy.git
   ```

2. Navigate to the project directory
   ```
   cd barbuddy/frontend
   ```

3. Install dependencies
   ```
   flutter pub get
   ```

4. Run the app
   ```
   flutter run
   ```

## Project Structure

```
📦 BarBuddy
│── 📁 frontend/ (Flutter App)
│   ├── 📁 lib/
│   │   ├── 📁 screens/  # All app screens
│   │   ├── 📁 widgets/  # Reusable UI components
│   │   ├── 📁 models/  # Data models
│   │   ├── 📁 services/  # Core functionality
│   │   ├── 📁 utils/  # Utility functions
│   │   ├── 📁 assets/  # Images, fonts, icons
│   │   ├── main.dart  # Flutter app entry point
│   │   └── routes.dart  # Handles app navigation
│
│── 📁 backend/ (If Needed)
│   ├── 📁 database/
│   ├── 📁 api/  # Backend services
│   ├── 📁 scripts/
│   ├── config.yaml
│   ├── requirements.txt
│   └── server.py (FastAPI Backend)
│
│── 📁 landing_page/ (Marketing Website)
│── 📁 marketing_assets/
│── 📁 documentation/
│── README.md
│── LICENSE
│── .gitignore
```

## Development Plan

### Phase 1: Core Features
- Real-time drink logging
- BAC estimation & safe-to-drive timer
- Emergency contact system

### Phase 2: Advanced Tracking & Summaries
- Live total drinks counter
- Nightly, weekly, monthly summaries
- Graphical and text-based drink history

### Phase 3: Safety & Disclaimers
- Double acknowledgment screen
- Smart notifications
- Safety alerts

### Phase 4: App Store Optimization & Launch
- SEO-optimized landing page
- Social media strategy
- Beta testing

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## Disclaimer

BarBuddy provides BAC estimates for informational purposes only. Many factors can affect individual BAC levels, and the app should not be used as a definitive guide for determining whether you are legally fit to drive. Always err on the side of caution and arrange alternative transportation if you have been drinking.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Statistics & Why BarBuddy Matters

- Over 10,000 people die each year in the U.S. due to alcohol-impaired driving (NHTSA)
- 28% of all traffic-related deaths in the U.S. involve alcohol (CDC)
- In some cities, DUI rates dropped by 10–15% after rideshare services became available

## Contact

For support or inquiries, please contact:
- Email: support@barbuddy.app
- Twitter: @BarBuddyApp