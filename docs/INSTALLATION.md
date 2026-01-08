# Installation Guide

This guide covers all installation methods for ReaMD.

## Requirements

### Required

| Component | Minimum Version | Download |
|-----------|-----------------|----------|
| REAPER | 7.0 | [reaper.fm](https://www.reaper.fm/download.php) |
| ReaImGui | 0.10 | Via ReaPack (see below) |

### Recommended

| Component | Purpose | Download |
|-----------|---------|----------|
| js_ReaScriptAPI | Save dialogs, advanced features | [Forum thread](https://forum.cockos.com/showthread.php?t=212174) |
| SWS Extension | Edit prompt in external editor | [sws-extension.org](https://www.sws-extension.org/) |

---

## Method 1: Manual Installation (Recommended)

### Step 1: Install Dependencies

#### Install ReaImGui

1. Open REAPER
2. Go to **Extensions → ReaPack → Browse packages**
3. Search for **"ReaImGui"**
4. Right-click → **Install**
5. Click **Apply** and restart REAPER

#### Install js_ReaScriptAPI (Optional but Recommended)

1. In ReaPack Browser, search for **"js_ReaScriptAPI"**
2. Right-click → **Install**
3. Apply and restart REAPER

#### Install SWS Extension (Optional)

1. Download from [sws-extension.org](https://www.sws-extension.org/)
2. Run the installer
3. Restart REAPER

### Step 2: Download ReaMD

**Option A: Download Release**
1. Go to [Releases](https://github.com/b451c/ReaMD/releases/latest)
2. Download `ReaMD-v1.x.x.zip`
3. Extract the archive

**Option B: Clone Repository**
```bash
git clone https://github.com/b451c/ReaMD.git
```

### Step 3: Copy to REAPER Scripts

Copy the entire `ReaMD` folder to your REAPER Scripts directory:

**Windows:**
```
%APPDATA%\REAPER\Scripts\
```
Full path: `C:\Users\<YourName>\AppData\Roaming\REAPER\Scripts\ReaMD\`

**macOS:**
```
~/Library/Application Support/REAPER/Scripts/
```
Full path: `/Users/<YourName>/Library/Application Support/REAPER/Scripts/ReaMD/`

**Linux:**
```
~/.config/REAPER/Scripts/
```
Full path: `/home/<YourName>/.config/REAPER/Scripts/ReaMD/`

### Step 4: Load the Script

1. Open REAPER
2. Go to **Actions → Show action list**
3. Click **Load ReaScript...**
4. Navigate to `ReaMD/Main/ReaMD.lua`
5. Select and click **Open**

### Step 5: Assign Shortcut (Optional)

1. In the Actions list, find "Script: ReaMD.lua"
2. Click **Add shortcut...**
3. Press your desired key combination
4. Click **OK**

---

## Method 2: ReaPack (Coming Soon)

ReaPack distribution is planned for a future release.

---

## Verifying Installation

1. Run the ReaMD action
2. You should see the ReaMD window appear
3. Try opening a `.md` file to verify markdown rendering
4. Check Settings (gear icon) to confirm all options are accessible

### Troubleshooting

**"ReaImGui not found" error:**
- Ensure ReaImGui is installed via ReaPack
- Restart REAPER after installation

**Window doesn't appear:**
- Check REAPER's console for error messages (View → Show console)
- Verify all files are in the correct location

**"Cannot find module" errors:**
- Ensure the folder structure is preserved:
  ```
  ReaMD/
  ├── Main/
  │   └── ReaMD.lua
  └── Libs/
      └── (all .lua files)
  ```

---

## Updating

### Manual Update

1. Download the new release
2. Replace the `ReaMD` folder (backup your `prompts/ai_format_prompt.txt` if customized)
3. Restart REAPER

### Settings Preservation

Your settings (theme, API key, etc.) are stored in REAPER's ExtState, not in files. They will persist across updates.

---

## Uninstalling

1. Delete the `ReaMD` folder from your Scripts directory
2. (Optional) Clear ExtState: Run this in REAPER's ReaScript console:
   ```lua
   reaper.DeleteExtState("ReaMD", "theme", true)
   reaper.DeleteExtState("ReaMD", "ai_api_key", true)
   -- etc. for other settings
   ```

---

## Platform-Specific Notes

### Windows

- AI Parse requires `curl.exe` (included in Windows 10 build 17063+)
- For older Windows, install curl manually or use WSL

### macOS

- All features work out of the box
- Grant REAPER permission to access files if prompted

### Linux

- Ensure `curl` is installed: `sudo apt install curl`
- ReaImGui may require additional dependencies on some distros
