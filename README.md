# LexiLearn

A Flutter mobile app for learning vocabulary through flashcards, quizzes, and favorites management.

## Features

### 🏠 Home Screen
- Clean, minimal Material 3 design
- Three main navigation options: Flashcards, Quiz, and Favorites
- Modern UI with smooth animations

### 🧠 Flashcard Screen
- Interactive vocabulary cards with flip animation
- Front shows English word, back shows Bengali meaning and English definition
- Navigation controls: Previous/Next buttons
- Shuffle functionality to randomize word order
- Add/Remove words from favorites
- Progress indicator showing current position

### 📝 Quiz Screen
- Multiple-choice questions with 4 options
- Random word selection for varied practice
- Real-time feedback on correct/incorrect answers
- Score tracking and final results summary
- Progress bar showing quiz completion
- Restart functionality for continuous learning

### ⭐ Favorites Screen
- View all saved favorite words
- Remove individual words or clear all favorites
- Study favorites as flashcards
- Word details with Bengali meaning and English definition
- Empty state with helpful guidance

## Technical Features

### 📱 Offline-First Design
- Completely offline functionality
- No internet connection required
- Local JSON data storage in `assets/vocab.json`
- SharedPreferences for user data persistence

### 🎨 Modern UI/UX
- Material 3 design system
- Google Fonts (Lexend) for typography
- Consistent color scheme with primary blue (#1132D4)
- Smooth animations and transitions
- Responsive design for different screen sizes

### 💾 Data Management
- Vocabulary model with JSON serialization
- Service layer for data loading and management
- Favorites persistence using SharedPreferences
- Quiz score tracking and history

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── vocabulary.dart      # Vocabulary data model
├── services/
│   ├── vocab_loader.dart    # Vocabulary data loading service
│   └── favorites_service.dart # Favorites management service
├── screens/
│   ├── home_screen.dart     # Main home screen
│   ├── flashcard_screen.dart # Flashcard learning screen
│   ├── quiz_screen.dart     # Quiz testing screen
│   └── favorites_screen.dart # Favorites management screen
└── widgets/                 # Reusable UI components
assets/
└── vocab.json              # Vocabulary data (20 sample words)
```

## Dependencies

- `flutter`: SDK
- `google_fonts`: Custom typography
- `shared_preferences`: Local data persistence
- `flip_card`: Card flip animations
- `cupertino_icons`: iOS-style icons

## Getting Started

1. **Prerequisites**
   - Flutter SDK (3.9.2 or higher)
   - Dart SDK
   - Android Studio / VS Code with Flutter extensions

2. **Installation**
   ```bash
   # Clone the repository
   git clone <repository-url>
   cd lexilearn
   
   # Install dependencies
   flutter pub get
   
   # Run the app
   flutter run
   ```

3. **Building for Production**
   ```bash
   # Android APK
   flutter build apk --release
   
   # iOS (requires macOS)
   flutter build ios --release
   ```

## Vocabulary Data Format

The app uses a JSON file (`assets/vocab.json`) with the following structure:

```json
[
  {
    "word": "Abate",
    "bengali_meaning": "দূর করা, হ্রাস পাওয়া, কমা, প্রশমিত করা",
    "english_definition": "subside, or moderate"
  }
]
```

## Features in Detail

### Flashcard Learning
- Tap cards to flip between English word and Bengali meaning
- Swipe or use buttons to navigate between words
- Shuffle option for randomized learning
- Add words to favorites for later review

### Quiz System
- 5 questions per quiz session
- Random word selection from vocabulary pool
- Multiple choice with 4 options (1 correct, 3 incorrect)
- Immediate feedback on answer selection
- Final score display with percentage
- Option to retake quiz

### Favorites Management
- Save words during flashcard study
- View all saved words in organized list
- Remove individual words or clear all
- Study only favorite words as flashcards
- Word details with full definitions

## Customization

### Adding New Vocabulary
1. Edit `assets/vocab.json`
2. Add new vocabulary objects following the existing format
3. Restart the app to load new data

### UI Customization
- Colors: Modify color constants in theme files
- Fonts: Change Google Fonts family in `main.dart`
- Layout: Adjust spacing and sizing in individual screen files

## Future Enhancements

- Dark mode support
- Multiple language support
- Audio pronunciation
- Spaced repetition algorithm
- Progress tracking and statistics
- Export/import vocabulary lists
- Offline dictionary integration

## License

This project is created for educational purposes. Feel free to use and modify as needed.

## Support

For issues or questions, please check the Flutter documentation or create an issue in the repository.