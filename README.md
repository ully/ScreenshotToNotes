# ScreenshotToNotes

[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Automatically extract text from screenshots and save to Apple Notes with intelligent categorization.

[中文文档](README_CN.md)

## Features

- ✨ **Auto-trigger**: Shortcuts automation triggers processing after screenshot
- 🔍 **Smart Extraction**: Vision OCR for Chinese and English text
- 🏷️ **Auto-categorization**: Content-based classification (Insight/HowTo/Task/Receipt/Contact/Product)
- ⚡ **Lightweight UI**: Quick category selection with auto-save timeout
- 📝 **Structured Save**: Extracts title, summary, tags, and entities
- 📂 **Folder Mapping**: Auto-save to corresponding Notes folders
- 🔄 **Fallback Monitor**: PhotoKit monitoring as backup

## Requirements

- iOS 17.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Quick Start

### 1. Build the Project

```bash
cd ScreenshotToNotes
open ScreenshotToNotes.xcodeproj
```

In Xcode:
1. Select your development team (Signing & Capabilities)
2. Connect iOS device or select simulator
3. Click Run (⌘R)

### 2. Initial Setup

#### Step 1: Import Shortcut

On first launch, the app guides you to import the official Shortcut:

1. Tap "Import Shortcut" button
2. Switches to Shortcuts app
3. Tap "Add Shortcut"

**Shortcut Logic:**
```
Get Latest Screenshot
  ↓
Run App Intent "Process Latest Screenshot"
  ↓
(App opens automatically and shows category selection)
```

#### Step 2: Create Automation

1. Open Shortcuts app
2. Go to "Automation" tab
3. Tap `+` → "Create Personal Automation"
4. Select "When I Take a Screenshot"
5. Tap "Add Action"
6. Search and select the imported "Save Screenshot to Notes" shortcut
7. **Important**: Turn OFF "Ask Before Running"
8. Tap "Done"

#### Step 3: Grant Permissions

- **Photos**: Required to read new screenshots
- **Notifications**: Optional for save confirmations

#### Step 4: Test Run

1. Take a screenshot (Volume+ and Power button)
2. Category selection sheet should appear automatically
3. Select category or wait for auto-save timeout
4. Check Notes app for saved note

### 3. Alternative Triggers (Optional)

Besides "When Taking Screenshot" automation:

#### AssistiveTouch

1. Settings → Accessibility → Touch → AssistiveTouch
2. Customize Top Level Menu, add "Screenshot"
3. Or add "Shortcuts" → Select "Save Screenshot to Notes"

#### Back Tap

1. Settings → Accessibility → Touch → Back Tap
2. Select "Double Tap" or "Triple Tap"
3. Select "Shortcuts" → "Save Screenshot to Notes"

## Usage

### Main Flow

```
Screenshot (System) 
  ↓
Automation triggers Shortcut
  ↓
App opens + OCR recognition
  ↓
Category selection (6s countdown)
  ↓
Save to Notes folder
```

### Categories

| Category | Description | Trigger Keywords | Notes Folder |
|----------|-------------|------------------|--------------|
| Insight | Quotes, opinions, ideas | quote, insight, idea | Insight |
| HowTo | Tutorials, guides | tutorial, steps, how to | HowTo |
| Task | TODOs, reminders | todo, task, need, deadline | Task |
| Receipt | Orders, invoices | order, payment, amount, invoice | Receipt |
| Contact | Phone, WeChat, email | phone, wechat, email, address | Contact |
| Product | Product info | price, purchase, product | Product |
| Inbox | Low confidence content | (default category) | Inbox |

### Note Format

Notes saved include:

```markdown
# Title (first line or summary)

> Summary (content overview)

**Category:** Insight
**Tags:** #screenshot #insight #other-tags
**Screenshot Time:** Sep 6, 2024 12:00 PM
**Saved Time:** Sep 6, 2024 12:01 PM

---

Body content (full OCR text)

---

**Structured Info**
- Dates: 2024-09-06
- Amounts: $299.00
- Contacts: 138****5678
- IDs: ORDER123456

**Source:** User screenshot (suspected Douyin/WeChat/Twitter)
```

## Architecture

### Module Structure

```
ScreenshotToNotes/
├── App/
│   ├── ScreenshotToNotesApp.swift    # App entry
│   ├── ContentView.swift             # Main view
│   └── Models.swift                  # Data models
├── Onboarding/
│   └── OnboardingView.swift          # Onboarding flow
├── Capture/
│   ├── CaptureManager.swift          # Screenshot manager
│   └── PhotoKitMonitor.swift         # Photo monitoring
├── Extract/
│   ├── OCRService.swift              # OCR service
│   └── CategoryClassifier.swift      # Classifier
├── FilterUI/
│   └── FilterSheetView.swift         # Category selection
├── Notes/
│   └── NotesWriter.swift             # Notes writer
├── History/
│   └── HistoryView.swift             # History view
├── Settings/
│   └── SettingsView.swift            # Settings
└── AppIntents/
    └── ProcessScreenshotIntent.swift # App Intent
```

## Apple Notes Integration

### Current Implementation: URL Scheme

Uses `mobilenotes://` URL Scheme to create notes.

**Pros:**
- No private APIs
- Simple and reliable
- App Store friendly

**Limitations:**
- Cannot specify folder (iOS limitation)
- Cannot get created note ID
- Cannot update existing notes

**Code Example:**
```swift
let url = "mobilenotes://action=append&note=\(encodedContent)"
UIApplication.shared.open(URL(string: url)!)
```

### Folder Mapping Limitation

Due to iOS restrictions, public APIs cannot specify Notes folders. Current approach:

1. Note title includes category: `[Insight] Title`
2. Users can manually move notes in Notes app
3. Documentation clarifies this limitation

## Testing

### Run Unit Tests

```bash
# Xcode
⌘U

# Command line
xcodebuild test -project ScreenshotToNotes.xcodeproj -scheme ScreenshotToNotes -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Test Coverage

- ✅ Classifier tests (CategoryClassifierTests)
- ✅ Entity extraction tests (ScreenshotToNotesTests)

## Known Limitations

### System Limitations

1. **Cannot specify Notes folder** - iOS public API limitation
2. **Shortcuts "Ask Before Running"** - Easy to miss during setup
3. **PhotoKit delay** - 1-2 second monitoring delay

### App Limitations

1. **Classification accuracy** - Heuristic-based, not LLM
2. **OCR recognition** - Vision Framework dependent
3. **Source detection** - Keyword-based matching

## Troubleshooting

### Automation not triggering

1. Check Shortcuts app → Automation
2. Confirm "When Taking Screenshot" automation exists
3. Confirm "Ask Before Running" is **OFF**
4. Try deleting and recreating automation

### Cannot access screenshots

1. Check Settings → ScreenshotToNotes → Photos
2. Confirm "All Photos" or "Selected Photos" is granted

### Notes not created

1. Check if Notes app opens normally
2. Try manually creating a note in Notes app
3. Check error messages in app history

## Roadmap

### v1.0 (Current)

- [x] Shortcuts integration
- [x] OCR recognition
- [x] Heuristic classification
- [x] Notes writing
- [x] History
- [x] Settings

### v1.1 (Planned)

- [ ] Batch processing
- [ ] LLM classification (optional)
- [ ] Custom categories
- [ ] iCloud settings sync
- [ ] iPad optimization

## Contributing

Issues and Pull Requests are welcome!

## License

MIT License

## Acknowledgments

- [Vision Framework](https://developer.apple.com/documentation/vision) - OCR
- [App Intents](https://developer.apple.com/documentation/appintents) - Shortcuts integration
- [PhotoKit](https://developer.apple.com/documentation/photokit) - Photo access

---

**Note**: This is an MVP implementation. Notes API integration is limited by iOS system constraints. Folder specification depends on future Apple public APIs.
