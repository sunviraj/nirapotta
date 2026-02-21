# Project Nirapotta V3: Comprehensive System Documentation

## Executive Summary
Project Nirapotta is an intelligent, multi-tier personal safety application. It moves beyond standard "panic button" apps by utilizing background device sensors to autonomously detect emergencies (falls, impacts, distress sounds) and gather necessary evidence (photos, sensor logs) without requiring user interaction during a crisis.

## Part 1: Completed Implementation (Phase 1 & Phase 2)

### 1. Sanviraj: Gesture Intelligence, UI/UX, & AI Data Setup
**Focus**: *Motion Detection, User Interface, and Data structuring.*
*   **Gesture Intelligence (`gesture_service.dart`)**: Upgraded the basic accelerometer to use **Vector Magnitude Analysis** ($\sqrt{x^2 + y^2 + z^2}$). It now distinguishes between:
    *   *Shake*: Sustained acceleration > 15.0 $m/s^2$ (e.g., struggling/panic).
    *   *Impact/Fall*: Sudden, high G-force spike > 45.0 $m/s^2$ (e.g., dropping or falling).
*   **User Interface (`main.dart`, `alert_screen.dart`)**: Designed the modern "Dark/Red" aesthetics. Added the pulsing shield animation to indicate active monitoring, and implemented the **"Slide to Cancel"** mechanism to prevent the user from accidentally dismissing a real emergency alert due to panic.
*   **AI Data Structure (`sensor_repository.dart`)**: Built the core "Brain Memory" using a 10-second Circular Buffer.
*   **Repo Maintenance**: Act as the Git Master, managing branches and merging Sifat's upcoming communication code into the stable `main` branch.

### 2. Adnan: Dual Tier & Sound Analysis
**Focus**: *Acoustic Verification.*
*   **Acoustic Detection (`sound_service.dart`)**: Implemented the `noise_meter` plugin to act as a secondary verification tier.
*   **Logic**: The system constantly measures ambient decibels (dB) natively. If the microphone detects a volume > 85dB (the acoustic threshold for a scream or loud distress shout), it triggers a Major Alert.
*   **Refinement**: Engineered a 1-second "warm-up delay" during microphone initialization to completely filter out electrical "pops" and prevent false-positive alarms.

### 3. Saiful: Evidence & Storage Pipeline
**Focus**: *Visual Proof and Permanent Records.*
*   **Unified CSV Logging**: Upgraded Sanviraj's memory buffer using a **Zero-Order Hold (ZOH)** algorithm. This aligns the asynchronous data from the accelerometer (50Hz) and the microphone into a single, time-perfect matrix.
*   **Public Data Export**: Linked the memory buffer to the phone's public `Downloads` directory, allowing raw `.csv` sensor data to be easily exported for AI Machine Learning training.
*   **Automated Camera Capture (`camera_service.dart`)**: When a Major Alert is triggered by the sensors, the app silently initializes the rear camera in the background, snaps a high-resolution photo, saves it directly to the user's **Gallery/Pictures**, and immediately shuts the camera down to save battery.

## Part 2: Future Milestones (Phase 3 & Phase 4)

### 4. Eva: Alert Decision System & Repo Management
**Focus**: *The Core Logic Gate and Version Control.*
*   **Current State**: The app currently triggers alerts independently (e.g., a loud sound triggers an alert, or a shake triggers an alert).
*   **Eva's Task (The Logic Gate)**: She will implement the complex decision matrix that categorizes incidents into **Minor** or **Major**.
    *   *Example Logic*: IF `Minor Shake` is detected -> Notify user on screen. IF `Minor Shake` + `Loud Noise` (within 5 seconds) -> Escalate to `Major Alert`.

### 5. Sifat: GPS & Telemetry Communication
**Focus**: *Response capabilities and Location tracking.*
*   **Current State**: The system detects the emergency and gathers evidence, but does not yet call for help.
*   **Sifat's Task (Location Services)**: Implement real-time GPS tracking hooks (`geolocator` plugin).
*   **Sifat's Task (SMS/Call Module)**: Build the automated response system. Upon Eva's system declaring a "Major Alert," Sifat's module will:
    1.  Automatically dispatch an SMS to predefined emergency contacts containing a Google Maps link of the current GPS coordinates.
    2.  Initiate an automated phone call to emergency services or an emergency contact.
    3.  *(Optional)* Implement the "Friend Finder" UI logic, allowing users to broadcast their location to nearby app users if a backend server is later integrated.
