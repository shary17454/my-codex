# App Store Privacy Answers

Use these answers for the App Store Connect privacy form for Kharayem.

## Data Not Used for Tracking

The app does not track users across apps or websites.

## Data Types Collected

### Location

- Precise Location: Yes
- Linked to user: Yes
- Used for tracking: No
- Purpose: App Functionality
- Reason: navigation, trip planning, distance, altitude, weather and air-quality alerts.

### User Content

- Photos or Videos: Yes, if the user attaches place photos.
- Other User Content: Yes, hidden place notes, trip notes, and community submissions.
- Linked to user: Yes
- Used for tracking: No
- Purpose: App Functionality

### Identifiers

- User ID: Yes, through iCloud/CloudKit account association for private sync and review submissions.
- Linked to user: Yes
- Used for tracking: No
- Purpose: App Functionality

## Data Shared With Third Parties

- Weather and air-quality requests send latitude/longitude to the configured REST provider.
- CloudKit stores user submissions and trip/share data in iCloud.

## Permissions Copy

- Location When In Use: used for map navigation, compass, altitude, distance, trip planning, and environment alerts.
- Location Always: requested only when the user enables background trip updates.
- Photo Library: used only when attaching photos to hidden places.

## Notes Before Submission

If a production API provider changes from Open-Meteo to another service, update this privacy form and `PrivacyInfo.xcprivacy` before submission.
