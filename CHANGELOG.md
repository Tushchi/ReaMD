# Changelog

All notable changes to ReaMD will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.3] - 2026-01-11

### Fixed
- ImGui ID conflict when recent files have the same filename (from different folders)
- Settings (theme, scroll options) not persisting after restart - `Config.load()` was missing

### Changed
- Light theme redesigned for better contrast and professional appearance
  - Blue accent buttons instead of gray (matches dark theme style)
  - Alternating table row backgrounds for better readability
  - Cleaner off-white background with proper borders
  - Improved visual hierarchy

## [1.0.2] - 2026-01-11

### Changed
- Updated welcome message to reflect current features (Scenario linking, Teleprompter, AI Parse)

## [1.0.1] - 2026-01-10

### Fixed
- ReaPack installation now includes all required files
  - Added missing `ai_parser.lua` (AI Parse feature)
  - Added missing `teleprompter.lua` (Teleprompter mode)
  - Added missing `ai_format_prompt.txt` (AI prompt template)

## [1.0.0] - 2026-01-08

### Added

#### Core Features
- **Markdown Viewer** - Full markdown rendering with ReaImGui
  - Headers (H1-H6), paragraphs, bold, italic, strikethrough
  - Bullet lists, numbered lists, nested lists
  - Tables with proper column alignment
  - Code blocks with syntax highlighting style
  - Blockquotes and horizontal rules
  - Links (clickable, opens in browser)

- **Edit Mode** - Create and modify markdown directly in REAPER
  - Toggle between view and edit modes
  - Auto-save on mode switch
  - "New" menu for creating fresh documents

- **Themes** - Dark and Light themes
  - Matches common REAPER color schemes
  - Unified background colors for clean appearance
  - Full style customization (14 color variables)

#### Scenario Mode
- **Fragment-to-Item Linking** - Connect text to timeline
  - Link multiple items to a single text fragment
  - Click text to jump to linked items on timeline
  - Visual highlighting of linked fragments
  - Playback position tracking

- **Category System** - Organize linked items
  - V (Voiceover) - Blue
  - M (Music) - Green
  - F (FX/Sound Effects) - Orange
  - O (Other) - Gray

- **Group Support** - REAPER groups handled as units
  - Grouped items linked/selected together
  - Progress calculation spans entire group

#### Teleprompter Mode
- **VO-Focused Display** - Large, centered text
  - Shows only voiceover-linked fragments
  - 48px font size for readability
  - Semi-transparent background (50% opacity)

- **Auto-Scroll** - Follows playback
  - Smooth transitions between cues
  - 2-second hold prevents flashing
  - Progress bar indicator (orange→green)

#### AI Parse Feature
- **Claude Integration** - AI-powered text formatting
  - Paste unformatted text, get clean markdown
  - Async processing (non-blocking UI)
  - Uses Claude Haiku for speed and cost efficiency

- **Customizable Prompt** - Tailor AI behavior
  - Edit prompt template in `prompts/ai_format_prompt.txt`
  - Default prompt optimized for AV production scripts

- **Settings Panel** - API key management
  - Masked input for security
  - Show/Hide toggle
  - Edit Prompt button (opens in system editor)

### Technical
- ReaImGui 0.10+ compatibility
- Cross-platform support (Windows, macOS, Linux)
- Modular architecture (9 Lua modules)
- JSON-based scenario file format (.reamd)

---

## [Unreleased]

### Planned
- Model selector in settings (Haiku/Sonnet)
- Windows batch script support for AI Parse
- Enhanced error messages for API failures
- Rate limiting for API calls
- ReaPack distribution

[1.0.1]: https://github.com/b451c/ReaMD/releases/tag/v1.0.1
[1.0.0]: https://github.com/b451c/ReaMD/releases/tag/v1.0.0
[Unreleased]: https://github.com/b451c/ReaMD/compare/v1.0.1...HEAD
