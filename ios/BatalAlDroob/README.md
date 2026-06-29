# Batal Al-Droob iOS

This is the iOS wrapper for Batal Al-Droob.

It loads the bundled web app from:

`BatalAlDroob/Web/index.html`

The app works offline with the bundled catalog export:

`BatalAlDroob/Web/data/y60_app_catalog.json`

## Open

Open:

`BatalAlDroob.xcodeproj`

## Before Archive

Set your Apple Developer Team in Xcode:

`Target > Signing & Capabilities > Team`

Bundle ID:

`com.batalaldroob.parts`

## Notes

If you update the web app, copy the updated web files into `BatalAlDroob/Web/` before archiving.
