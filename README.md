# ScreenshotToNotes

[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Automatically extract text from screenshots and save to Apple Notes with intelligent categorization. **Optimized for video platform screenshots** (Douyin, TikTok, YouTube, etc.).

[中文文档](README_CN.md)

## Features

- ✨ **Auto-trigger**: Shortcuts automation triggers processing after screenshot
- 🔍 **Smart Extraction**: Vision OCR for Chinese and English text
- 🏷️ **Auto-categorization**: Content-based classification
- 🎬 **Video Recognition**: Specialized support for video platforms (Douyin, TikTok, YouTube, Bilibili, Instagram, etc.)
- ⚡ **Lightweight UI**: Quick category selection with auto-save timeout
- 📝 **Structured Save**: Extracts title, summary, tags, and entities
- 🌍 **Global Support**: Both Chinese and international platforms
- 📂 **Folder Mapping**: Auto-save to corresponding Notes folders
- 🔄 **Fallback Monitor**: PhotoKit monitoring as backup

## Video Screenshot Feature 🎬

### Supported Platforms (Domestic + International)

**Chinese Platforms:**
- ✅ **Douyin (抖音)** - Author, Duration, Likes, Comments, Hashtags
- ✅ **Kuaishou (快手)** - Author, Duration, Engagement data
- ✅ **Bilibili (哔哩哔哩)** - UP主, Duration, Coins/Likes data
- ✅ **Xiaohongshu (小红书)** - Author, Hashtags, Engagement
- ✅ **Xigua Video (西瓜视频)** - Basic extraction

**International Platforms:**
- ✅ **YouTube** - Channel, Duration, Likes, Comments, Views
- ✅ **TikTok** - Creator, Duration, Engagement stats
- ✅ **Instagram** - Username, Likes, Comments, Reels
- ✅ **Facebook** - Author, Engagement data
- ✅ **Twitch** - Streamer, Viewers, Live chat
- ✅ **Vimeo** - Creator, Basic stats
- ✅ **Reddit** - User, Upvotes, Comments

### Auto-extraction

- 📝 Author/Creator (@username, UP主, Channel name)
- ⏱️ Video duration (mm:ss)
- 💬 Engagement stats (Likes, Comments, Shares, Views)
- 🏷️ Hashtags (#cooking #tutorial)
- 🎯 Video type (Food/Fitness/Tech/Entertainment, etc.)

### Examples

**Chinese Platform:**
- Douyin: @美食博主 | 3:25 | 12.5万赞 | #美食教程  
  → Auto-classify as "Video Tutorial"

**International Platform:**
- YouTube: @TechReviewer | 15:32 | 125K Likes | #iPhone16  
  → Extract complete metadata to Notes
- TikTok: @creator | 0:45 | 89.2K Likes | #fyp #cooking  
  → Parse all engagement data

Detailed documentation: [Video Screenshot Feature](docs/VIDEO_SCREENSHOT_FEATURE.md)

---

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

#### Import Shortcut

On first launch, the app guides you to import the official Shortcut:

1. Tap "Import Shortcut"
2. Switches to Shortcuts app
3. Tap "Add Shortcut"

#### Create Automation

1. Open Shortcuts app
2. Go to "Automation" → Create Personal Automation
3. Select "When I Take a Screenshot"
4. Add the imported shortcut
5. **Important**: Turn OFF "Ask Before Running"

#### Test

1. Take a screenshot
2. Category selection should appear automatically
3. Select category or wait for auto-save
4. Check Notes app

## Categories

| Category | Description | Trigger Keywords |
|----------|-------------|------------------|
| Insight | Quotes, ideas | quote, insight, idea |
| HowTo | Tutorials, guides | tutorial, steps, how to |
| Task | TODOs, reminders | todo, task, deadline |
| Receipt | Orders, invoices | order, payment, invoice |
| Contact | Phone, email | phone, email, address |
| Collection | Products, items | price, product |
| **Video Collection** 🎬 | **Video content** | **Douyin/YouTube/TikTok** |
| **Video Tutorial** 🎓 | **Educational videos** | **tutorial, teaching** |
| **Video Entertainment** ✨ | **Fun content** | **funny, entertainment** |
| Inbox | Low confidence | (default) |

## Requirements

- iOS 17.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Documentation

- User Guide: `README_CN.md` (Chinese)
- Video Feature: `docs/VIDEO_SCREENSHOT_FEATURE.md`
- Technical Notes: `docs/TECHNICAL_NOTES.md`
- Shortcut Setup: `docs/SHORTCUT_SETUP.md`

## Known Limitations

### System Limitations
1. Cannot specify Notes folder (iOS API limitation)
2. Shortcuts "Ask Before Running" easy to miss
3. PhotoKit monitoring has 1-2 second delay

### App Limitations
1. Heuristic classification (not LLM-based)
2. OCR dependent on Vision Framework
3. Video recognition requires platform identifiers in screenshot

## Contributing

Issues and Pull Requests are welcome!

## License

MIT License

---

**Note**: This MVP implementation focuses on screenshot archiving. Voice control of native apps is not supported due to iOS system restrictions. All features use public APIs and are App Store friendly.
