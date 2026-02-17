# Solo Shuffle Whisperer (SSW)

A World of Warcraft addon for The War Within (11.0+) that helps you send friendly, low-drama thank-you messages to teammates after Solo Shuffle matches.

**PVP Philosophy**: In PVP, less talk is better... but many times you want to praise rather than flame. This addon keeps messages short, neutral, and positive.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Settings](#settings)
- [How It Works](#how-it-works)
- [Customization & Lua Modifications](#customization--lua-modifications)
- [File Structure](#file-structure)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [Version](#version)

## Features

- **Automatic Detection**: Automatically opens after Solo Shuffle matches
- **Smart Roster Tracking**: Tracks all teammates, even those who leave early
- **Customizable Messages**: Choose from friendly presets or add your own custom lines
- **PVP-Friendly Messages**: Short, neutral, positive - avoid sarcasm and drama
- **PVP Profile Integration**: Quick access to player PvP rankings via check-pvp.fr
  - Click player names to open their check-pvp.fr profile URL
  - Hover over the PvP icon to see key information (CR, performance, alts, achievements)
  - Easily check teammate rankings and alt character information
- **Safety Modes**: 
  - SAFE mode (preview only, no messages sent)
  - LIVE mode (actually sends whispers)
  - TEST mode (for testing with dummy data)
- **Accessibility Features**:
  - One-Tap mode for quick "thanks all" with a single button
  - Visual countdown before sending
  - Auto-greeting when joining groups (optional)
  - Blame checkbox for quick dismissal of toxic players (sends "..." and adds to ignore list)
- **Anti-Spam Protection**: Prevents duplicate messages and respects cooldowns
- **Minimap Button**: Easy access with left-click (open), right-click (settings), Shift+click (toggle mode)
- **Custom Message Lines**: Add up to 10 custom messages that persist across sessions

## Installation

### Standard Installation

1. Download the latest release from the repository
2. Extract the archive to your WoW addons directory:
   - **Windows**: `C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\`
   - **Mac**: `/Applications/World of Warcraft/_retail_/Interface/AddOns/`
3. You should see a `SoloShuffleWhisperer` folder inside the `AddOns` directory
4. Launch World of Warcraft or reload the UI with `/reload` if already in-game
5. Verify installation by typing `/ssw` in chat

### Verify Installation

After installation, you should see:
- A minimap button (cyan/red icon depending on mode)
- The addon listed in the AddOns menu at character select
- Response to `/ssw` command in chat

## Usage

### Commands
- `/ssw` - Open settings
- `/ssw show` - Open the whisper window manually
- `/ssw test` - Test mode with dummy party data
- `/ssw arm` - Toggle between SAFE and LIVE modes

### Whisper Window Interface

The whisper window allows you to select which players to message and how:

- **Send**: Check to send a whisper to this player
- **Name**: Include the player's name in the message using {name} placeholder
- **BNet**: Send a second message with your Battle.net tag invitation
- **Blame**: Send "..." to the player and add them to your ignore list
  - When Blame is checked, Name and BNet are automatically unchecked
  - When Name or BNet is checked, Blame is automatically unchecked
  - This is useful for quickly dismissing toxic players

### Minimap Button
- **Left Click**: Open whisper window
- **Right Click**: Open settings
- **Shift + Left Click**: Toggle SAFE/LIVE mode
- **Drag**: Reposition the button around the minimap

### Modes

**SAFE Mode** (Cyan icon): Preview messages without sending. Great for testing.

**LIVE Mode** (Red icon): Actually sends whispers to selected players. Includes a countdown delay before sending.

**TEST Mode**: Opens the UI with dummy test data for configuration testing.

## Settings

- **Custom Message Lines**: Write up to 10 personalized messages in the settings window. These appear in message dropdowns but are never selected by "Random".
- **Message 1**: Primary thank-you message (always sent)
- **Message 2**: Optional Battle.net tag invitation
- **Delay**: Countdown time before sending in LIVE mode
- **Auto Greeting**: Automatically greet party members when joining a group

### Custom Messages

The addon now includes a **Custom Message Lines** section in settings where you can write your own personalized messages:

1. Open settings with `/ssw`
2. Scroll to the "CUSTOM MESSAGE LINES" section at the top
3. Type your custom messages in any of the 10 available text boxes
4. Your custom messages will appear in the message dropdown when selecting players
5. Custom messages support all placeholders: `{name}`, `{praise}`, `{role}`, `{spec}`, `{btag}`
6. Custom messages are automatically saved and excluded from "Random" selection

**Example custom messages:**
- `great plays {name}!`
- `fun shuffle! {name}`
- `{praise} lets queue again sometime`

### Message Placeholders

Use these in your custom messages:
- `{name}` - Player name (without realm)
- `{praise}` - Random friendly phrase (gg!, ty!, wp!, good games!, cheers!)
- `{role}` - Tank/Healer/DPS
- `{spec}` - Player's specialization
- `{btag}` - Your Battle.net tag

### Message Philosophy for PVP

Following the core principle: **"In PVP less talk is better... but many times you want to praise rather than flame"**

- Messages are intentionally short and neutral
- Focus on "gg" and "thanks" rather than performance commentary
- Avoid role-specific praise that could be misread as sarcasm
- Keep it simple, positive, and drama-free
- Use the "Random" option to vary messages naturally

### PVP Profile Integration

The addon integrates with [check-pvp.fr](https://check-pvp.fr) to provide quick access to player PvP rankings:

- **Clickable Player Names**: Click on any player name to open a dialog with their check-pvp.fr profile URL for easy copying
- **PVP Icon Tooltip**: Hover over the PvP icon next to player names to see key information available on check-pvp.fr:
  - Current & Best CR (Combat Rating)
  - Season Performance
  - Alt Characters
  - Achievement History
- **Quick Lookup**: Use this to quickly assess teammate skill levels or find players for future matches
- **Automatic Region Detection**: The addon automatically detects your region (US, EU, KR, TW, CN) and generates the correct check-pvp.fr URL

**Note**: The check-pvp.fr URL is automatically generated based on the player's name, realm, and your detected region. WoW addons cannot directly open external URLs or fetch external data, so the URL must be copied and pasted into a browser.

## How It Works

### Solo Shuffle
1. Starts tracking when a match begins
2. Takes a snapshot of all teammates at completion
3. Locks the roster (so late leavers don't affect the list)
4. Opens the UI automatically
5. Allows you to select which players to message

---

## Customization & Lua Modifications

The addon is highly customizable through Lua file modifications. All Lua files are located in:
```
World of Warcraft\_retail_\Interface\AddOns\SoloShuffleWhisperer\
```

**Important**: Always make a backup of the original file before modifying!

### 📝 Presets.lua - Customize Messages

This file contains all message templates and presets.

#### Modify Message 1 Presets (Thank You Messages)

**Location**: `Presets.lua`, lines 14-21

```lua
SSW.MSG1_PRESETS = {
    "gg {name}",
    "ty {name}!",
    "good games {name}!",
    "Random",
    "{praise} {name}",
    "gg {name} :)",
    "nice games!",
}
```

**How to customize**:
```lua
-- Add your own messages to the list
SSW.MSG1_PRESETS = {
    "gg {name}",
    "ty {name}!",
    "good games {name}!",
    "Random",
    "{praise} {name}",
    "gg {name} :)",
    "nice games!",
    "wp {name}!",              -- NEW
    "fun matches {name}",      -- NEW
}
```

#### Modify Message 2 Presets (Battle.net Tag Invites)

**Location**: `Presets.lua`, lines 24-30

```lua
SSW.MSG2_PRESETS = {
    "if you wanna queue again: {btag}",
    "feel free to add me: {btag}",
    "up for more games? {btag}",
    "Random",
    "if you want to queue more: {btag}",
}
```

**How to customize**:
```lua
-- Customize BTag invitation messages
SSW.MSG2_PRESETS = {
    "if you wanna queue again: {btag}",
    "feel free to add me: {btag}",
    "up for more games? {btag}",
    "Random",
    "if you want to queue more: {btag}",
    "let's queue together: {btag}",        -- NEW
    "add me for future games: {btag}",     -- NEW
}
```

#### Customize Praise Phrases

**Location**: `Presets.lua`, line 166

```lua
local function PraiseForRole(role)
    local pool = {
        "gg!",
        "ty!",
        "wp!",
        "good games!",
        "cheers!",
    }
    if type(math.random) == "function" then
        return pool[math.random(1, #pool)]
    end
    return pool[1]
end
```

**How to customize**:
```lua
-- Add more praise variations (keep them short and neutral for PVP!)
local pool = {
    "gg!",
    "ty!",
    "wp!",
    "good games!",
    "cheers!",
    "nice!",          -- NEW
    "well played!",   -- NEW
}
```

#### Available Placeholders

You can use these placeholders in your custom messages:
- `{name}` - Player name (without realm)
- `{praise}` - Random friendly phrase from the praise pool
- `{role}` - Tank/Healer/DPS
- `{spec}` - Player's specialization (e.g., "Holy", "Arms")
- `{btag}` - Your Battle.net tag (Message 2 only)

**Example Custom Message**:
```lua
"{spec} {name}, gg!"         -- Uses spec and name
"wp {name}!"                  -- Simple well played
```

#### Automatic PVP Profile Region Detection

**Location**: `Core.lua`, in the `SSW.GetRegionCode` and `SSW.GetCheckPvpUrl` functions

The addon now automatically detects your region using the WoW API:
- Uses `GetCurrentRegion()` to detect if you're on US (1), Korea (2), EU (3), Taiwan (4), or China (5) servers
- Falls back to `GetCVar("portal")` if the primary method fails
- Defaults to EU if both detection methods fail

**No manual configuration needed!** The addon will automatically use the correct region for check-pvp.fr URLs.

**How it works**:
```lua
-- Auto-detect region (no user modification needed)
local region = SSW.GetRegionCode()  -- Returns "us", "eu", "kr", "tw", or "cn"
return ("https://check-pvp.fr/%s/%s/%s"):format(region, realm, name)
```

### ⚙️ Core.lua - Adjust Core Settings

This file contains core addon constants and utilities.

#### Change Maximum Message Length

**Location**: `Core.lua`, line 11

```lua
SSW.MAX_LEN = 140
```

**How to customize**:
```lua
SSW.MAX_LEN = 200  -- Allow longer messages (max 255)
```

#### Adjust Send Delay Between Messages

**Location**: `Core.lua`, line 9

```lua
SSW.SEND_DELAY = 0.35
```

**How to customize**:
```lua
SSW.SEND_DELAY = 0.5  -- Slower, safer (0.5 seconds between messages)
SSW.SEND_DELAY = 0.2  -- Faster (may trigger spam protection)
```

#### Change Default Pre-Send Countdown

**Location**: `Core.lua`, line 10

```lua
SSW.DEFAULT_PRE_SEND_DELAY = 3.5
```

**How to customize**:
```lua
SSW.DEFAULT_PRE_SEND_DELAY = 5.0  -- Longer countdown (5 seconds)
SSW.DEFAULT_PRE_SEND_DELAY = 2.0  -- Shorter countdown (2 seconds)
```

#### Adjust Maximum Player Rows Displayed

**Location**: `Core.lua`, line 8

```lua
SSW.MAX_ROWS = 5
```

**How to customize**:
```lua
SSW.MAX_ROWS = 6  -- Show more players (Solo Shuffle is 6 players)
```

#### Change Maximum Custom Lines

**Location**: `Core.lua`, line 12

```lua
SSW.MAX_CUSTOM_LINES = 10
```

**How to customize**:
```lua
SSW.MAX_CUSTOM_LINES = 20  -- Allow more custom message slots
```

### 🎯 Triggers.lua - Modify Auto-Open Behavior

Control when the addon window automatically opens.

#### Disable Auto-Open for Solo Shuffle

**Location**: `Triggers.lua`, search for match completion event

**How to customize**:
```lua
-- Comment out or remove the auto-open line
-- SSW.UI.ShowWhisperWindow()
```

### 🔘 MinimapButton.lua - Customize Minimap Button

#### Change Button Position

**Location**: `MinimapButton.lua`, search for default position settings

```lua
-- The button position is saved in SavedVariables
-- To change default position, modify:
local angle = SSW_CharConfig.minimap.angle or 220  -- Degrees around minimap
```

**How to customize**:
```lua
local angle = SSW_CharConfig.minimap.angle or 180  -- Different starting position
```

#### Hide Minimap Button

**Location**: `MinimapButton.lua`

**How to customize**:
```lua
-- Add at the end of CreateMinimapButton function:
button:Hide()  -- Completely hide minimap button
```

### 🤝 AutoGreet.lua - Customize Auto-Greeting

Modify the automatic greeting sent when joining groups.

**Location**: `AutoGreet.lua`, search for greeting message

**How to customize**:
```lua
-- Find the greeting message string and modify it
SendChatMessage("gl hf!", "PARTY")  -- Change greeting text
```

### 📊 AntiSpam.lua - Adjust Anti-Spam Settings

Control spam protection and cooldowns.

#### Modify Cooldown Timers

**Location**: `AntiSpam.lua`, search for cooldown values

**How to customize**:
```lua
-- Typical pattern:
local COOLDOWN = 300  -- Change from 5 minutes to your preferred value
```

### Testing Your Changes

After modifying any Lua files:

1. **Save the file**
2. **Reload the UI** in WoW with `/reload`
3. **Test in SAFE mode first**: Use `/ssw test` to see preview with dummy data
4. **Verify messages**: Check that your changes appear in the dropdown menus
5. **Test actual sending**: Switch to LIVE mode only after confirming everything looks correct

### Troubleshooting Lua Modifications

**Problem**: UI errors or addon doesn't load after modification

**Solution**:
1. Check for Lua syntax errors (missing commas, quotes, brackets)
2. Restore from your backup
3. Use `/console scriptErrors 1` to see detailed error messages
4. Common mistakes:
   - Missing comma between list items
   - Unmatched quotes: `"message` (missing closing quote)
   - Unmatched brackets: `{ item1, item2` (missing closing `}`)

**Problem**: Changes don't appear

**Solution**:
1. Ensure you saved the file
2. Completely exit WoW and restart (not just `/reload`)
3. Clear WoW cache if needed: Delete `WoW/_retail_/Cache` folder

---

## File Structure

Overview of all addon files and their purposes:

| File | Purpose | Common Modifications |
|------|---------|---------------------|
| **Core.lua** | Core utilities, constants, SavedVariables initialization | Delays, limits, max length |
| **Presets.lua** | Message templates and preset lists | Add/edit message presets, praise phrases |
| **Snapshot.lua** | Party roster tracking and snapshots | Modify tracking behavior |
| **Send.lua** | Message sending logic and queue management | Sending behavior, delays |
| **UI.lua** | Main UI window, settings panel, player rows | UI layout, button behavior |
| **Accessibility.lua** | One-tap mode and accessibility features | Quick-send behavior |
| **AutoGreet.lua** | Automatic greeting when joining groups | Greeting message, timing |
| **MinimapButton.lua** | Minimap button creation and behavior | Button position, tooltips |
| **AntiSpam.lua** | Spam protection and cooldown tracking | Cooldown times, limits |
| **Triggers.lua** | Event handlers for Solo Shuffle completion | Auto-open behavior |
| **SoloShuffleWhisperer.toc** | Addon metadata and file load order | Version, dependencies |

---

## Troubleshooting

### Addon Not Loading

**Symptoms**: No minimap button, `/ssw` command doesn't work

**Solutions**:
1. Verify the folder structure:
   ```
   AddOns/
   └── SoloShuffleWhisperer/
       ├── SoloShuffleWhisperer.toc
       ├── Core.lua
       ├── Presets.lua
       └── ... (other .lua files)
   ```
2. Enable the addon in the AddOns menu at character selection
3. Check for Lua errors: `/console scriptErrors 1`
4. Disable conflicting addons temporarily

### Window Not Opening Automatically

**Symptoms**: Window doesn't open after completing Solo Shuffle

**Solutions**:
1. Check if you're in TEST mode (`/ssw test` - exit test mode)
2. Verify trigger events in `Triggers.lua` are enabled
3. Manually open with `/ssw show`
4. Check that the match actually completed

### Messages Not Sending (LIVE Mode)

**Symptoms**: Countdown completes but no whispers sent

**Solutions**:
1. Verify you're in LIVE mode (red icon), not SAFE mode (cyan icon)
2. Check anti-spam cooldowns (wait a few minutes between matches)
3. Verify player names are correct (not offline/cross-realm issues)
4. Check that Battle.net is connected for BTag messages

### Error Messages After Modifying Lua

**Symptoms**: Red error text, addon breaks after editing

**Solutions**:
1. Restore from backup immediately
2. Common syntax errors to check:
   - Missing commas: `{"item1" "item2"}` → `{"item1", "item2"}`
   - Unclosed strings: `"message` → `"message"`
   - Unclosed brackets: `{item1, item2` → `{item1, item2}`
3. Use a Lua-aware text editor with syntax checking (VS Code, Sublime Text, Notepad++)

---

## FAQ

### Q: Is this addon safe to use?

**A**: Yes! The addon includes SAFE mode (default) that only previews messages without sending them. You control when messages are actually sent, and built-in anti-spam protection prevents abuse.

### Q: Will I get banned for using this?

**A**: No. This addon uses standard Blizzard APIs and doesn't automate gameplay or violate ToS. It's a convenience tool that still requires your input to send messages.

### Q: How do I add my Battle.net tag?

**A**: The addon automatically detects your BattleTag from your Battle.net connection. Just ensure you're logged into Battle.net when playing WoW.

### Q: Can I change messages in-game?

**A**: Yes! The settings panel allows you to select from presets. For adding new presets or custom messages, you can edit them in the addon settings or modify `Presets.lua`.

### Q: Does this work with other languages?

**A**: Yes, you can customize all messages in `Presets.lua` to any language. The addon code is in English, but all player-facing messages are customizable.

### Q: How do I disable auto-greeting?

**A**: Open settings with `/ssw` and uncheck "Auto Greeting" option.

### Q: What's the difference between Message 1 and Message 2?

**A**: 
- **Message 1**: Primary thank-you message (always available)
- **Message 2**: Optional BattleTag invitation

### Q: How does "Random" work in presets?

**A**: When you select "Random", the addon randomly picks from all non-custom presets in the list (excluding other "Random" entries and custom messages).

### Q: Why are the messages so short?

**A**: Following PVP etiquette: "In PVP less talk is better... but many times you want to praise rather than flame." Short messages are less likely to be misread as sarcastic and keep interactions positive.

### Q: What region does the check-pvp.fr link use?

**A**: The addon automatically detects your region (US, EU, Korea, Taiwan, or China) using the WoW API and generates the correct check-pvp.fr URL. No manual configuration is needed!

### Q: Can I disable the PvP ranking icons?

**A**: The PvP icons appear automatically next to all player names. If you prefer not to see them, you can comment out or modify the PvP button creation code in `UI.lua`.

---

## Version

- **Current Version**: 2.0
- **Interface**: 120001 (The War Within)
- **Repository**: https://github.com/ThePipSpi/SSW

---

## Contributing

### Reporting Issues

If you encounter bugs or have feature requests:
1. Check existing issues on GitHub
2. Provide detailed information:
   - WoW version
   - Addon version
   - Steps to reproduce
   - Error messages (enable with `/console scriptErrors 1`)
3. Include your Lua modifications if you've made any

### Submitting Custom Presets

Have great message presets to share?
1. Fork the repository
2. Add your presets to `Presets.lua`
3. Submit a pull request with a description
4. Keep messages friendly, short, and drama-free!

---

## License

This addon is provided as-is for World of Warcraft players. Feel free to modify for personal use.

### Permissions

✅ **Allowed**:
- Personal modifications
- Sharing with friends
- Creating custom presets
- Using in-game and sharing experiences

⚠️ **Please Don't**:
- Redistribute modified versions without credit
- Use for commercial purposes
- Remove author attribution
- Bundle with malware or unauthorized software

---

## Credits

**Inspired by**: Mythic Plus Whisperer (MPW)
**Contributors**: Community feedback and suggestions welcome!

### Special Thanks

- World of Warcraft PVP community for feedback
- Solo Shuffle players for inspiration
- All players who use this addon to spread positivity in the game

---

## Support

- **Issues**: https://github.com/ThePipSpi/SSW/issues

### Quick Help

- Need help? Type `/ssw` in game for settings
- Want to test? Use `/ssw test` for dummy data
- Toggle modes? Shift + click minimap button
- Stuck? Use `/reload` to restart the UI

---

**Good luck in the arena! May your queues be fast and your games be gg! ⚔️✨**
