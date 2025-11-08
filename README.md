# BookSwap App 📚

A simple book trading app where people can swap books with each other. Built with Flutter and Firebase.

## What does this app do?

BookSwap lets you:
- **List books** you want to trade away
- **Browse books** other people are offering
- **Request swaps** with other users
- **Chat** with people about book trades
- **Get notifications** when someone wants your books

## Screenshots

*Add screenshots of your app here when ready*

## How to set up this app

### What you need first

1. **Flutter** - Download from [flutter.dev](https://flutter.dev/docs/get-started/install)
2. **Android Studio** or **VS Code** with Flutter plugin
3. **Firebase account** - Sign up at [firebase.google.com](https://firebase.google.com)

### Step 1: Get the code

```bash
git clone <your-repo-url>
cd bookswap_app
```

### Step 2: Install Flutter packages

```bash
flutter pub get
```

### Step 3: Set up Firebase

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project called "BookSwap"
3. Add an Android app (and iOS if needed)
4. Download the config files:
   - `google-services.json` → put in `android/app/`
   - `GoogleService-Info.plist` → put in `ios/Runner/` (if using iOS)

### Step 4: Enable Firebase services

In your Firebase project, turn on:
- **Authentication** (Email/Password)
- **Firestore Database** 
- **Storage** (for book photos)
- **Cloud Messaging** (for notifications)

### Step 5: Set up Firestore rules

Go to Firestore → Rules and paste this:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Anyone can read books, only owners can write
    match /books/{bookId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == resource.data.ownerId;
    }
    
    // Chat messages - only participants can access
    match /chats/{chatId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participants;
    }
  }
}
```

### Step 6: Run the app

```bash
flutter run
```

## How to use the app

### First time setup
1. **Sign up** with your email
2. **Verify your email** (check your inbox)
3. **Log in** to start using the app

### Adding books to trade
1. Tap the **+ button** on the home screen
2. Fill in book details (title, author, condition)
3. Take a photo of your book
4. Say what you want in return
5. Tap **Post Book**

### Finding books to swap
1. Browse the **Home** tab to see all available books
2. Use the **search bar** to find specific books or authors
3. Tap **Request Swap** on books you want
4. Wait for the owner to respond

### Managing your books
1. Go to **My Listings** tab
2. See books you've posted
3. Check **incoming requests** from other users
4. Accept or decline swap requests

### Chatting with traders
1. Go to **Chats** tab
2. Start conversations with people you're trading with
3. Arrange meetup details
4. Confirm when trades are complete

## App structure

```
lib/
├── models/          # Data structures (Book, User, etc.)
├── providers/       # State management
├── screens/         # App pages
│   ├── auth/        # Login, signup, email verification
│   ├── home/        # Browse books, post books
│   ├── chat/        # Messaging
│   └── settings/    # User settings
├── services/        # Firebase connections
└── widgets/         # Reusable UI components
```

## Technologies used

- **Flutter** - Mobile app framework
- **Firebase Auth** - User login/signup
- **Firestore** - Database for books and chats
- **Firebase Storage** - Store book photos
- **Provider** - State management
- **Cloud Messaging** - Push notifications

## Common problems and fixes

### "Firebase not configured" error
- Make sure you added `google-services.json` to `android/app/`
- Run `flutter clean` then `flutter pub get`

### App crashes on startup
- Check if Firebase project is set up correctly
- Make sure all Firebase services are enabled

### Can't upload photos
- Check if Firebase Storage is enabled
- Make sure storage rules allow authenticated users

### No notifications
- Enable Cloud Messaging in Firebase
- Check device notification permissions

## Contributing

Want to help improve BookSwap?

1. Fork this repository
2. Create a new branch: `git checkout -b my-feature`
3. Make your changes
4. Test everything works
5. Submit a pull request

## Future features

Ideas for making the app better:
- [ ] Location-based book discovery
- [ ] Book condition ratings
- [ ] User reviews and ratings
- [ ] Wishlist feature
- [ ] Book recommendations
- [ ] Group swaps (multiple people)

## Need help?

- Check [Flutter documentation](https://flutter.dev/docs)
- Look at [Firebase guides](https://firebase.google.com/docs)
- Create an issue in this repository

## License

This project is open source. Feel free to use and modify it.

---

**Happy book swapping! 📖✨**