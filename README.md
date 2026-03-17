🏰 Tower Challenge - Multiplayer Real-time Mini-game

🎯 Overview
A competitive multiplayer mini-game built with Flutter and Flame Engine. Players are divided into two teams (Team A & Team B) to race in solving 20 active towers. The goal is to reach a Target of 1000 starting from a random startValue using only two mathematical operations: +10 and x2.

🏗️ Architecture & Tech Stack
    ➖Flame Engine: Powering the game board rendering, tower components, and real-time animations.
    ➖GetX State Management: Ensuring reactive synchronization between Firebase Realtime Database and the Flutter UI.
    ➖Clean Architecture: Organised into Data (Firebase & Bot Service), Domain (Entities), and Presentation (GetX Controllers & Flame Components) layers.
    ➖Firebase Realtime Database (RTDB): The "Source of Truth" for synchronized match states across all players.

🚀 Setup & Installation
1. Clone the Repository:
git clone https://github.com/yourusername/tower-challenge.git
cd tower-challenge

2. Firebase Configuration:
    ➖ Create a project on the Firebase Console.
    ➖ Enable Realtime Database (Location: asia-southeast1 recommended).
    ➖ Configure your app using FlutterFire CLI or manually add google-services.json (Android) / GoogleService-Info.plist (iOS).
    ➖ Ensure database rules allow read/write access for authenticated users.

3. Install Dependencies:
flutter pub get

4. Run the App:
flutter run

🎮 How to Play
1. Initialize Match: Press the GLOBAL RESET button to generate the 20 initial towers on Firebase.
2. Simulation Mode: Press LAUNCH BOTS to fill the match with 7 automated bot players (simulating an 8-player environment).
3. Solving Towers: * Click a tower marked with a [+] icon to claim it.
    ➖ In the overlay, use +10 and X2 to reach exactly 1000.
    ➖ If you exceed 1000, use the Reset Tower button to start over for that specific tower.
4. Win Condition: The team that completes all 20 towers first (marked with 🚗) wins the match.

🧠 Technical Features
1. BFS Shortest Path Solver
The game implements a Breadth-First Search (BFS) algorithm to calculate the most efficient path to 1000, ensuring all towers are solvable and providing "Optimal Move" metadata.
2. Concurrency Control
Using Firebase Transactions, the system ensures that only one player can claim a specific tower at a time, preventing data conflicts in a fast-paced environment.
3. AFK Detection & Auto-Release
Player activity is tracked via a lastSeenAt heartbeat every 5 seconds. If a player claims a tower but remains inactive, the system automatically releases the tower back to "Available" status after 15 seconds.