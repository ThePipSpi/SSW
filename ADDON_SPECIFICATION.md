# Solo Shuffle Whisperer - Addon Specification

## Purpose
A World of Warcraft addon for The War Within (11.0+) that helps players send friendly, positive thank-you messages to teammates after Solo Shuffle PvP matches.

## Core Philosophy
**"In PVP, less talk is better... but many times you want to praise rather than flame."**

Messages should be:
- Short and neutral
- Positive and friendly
- Non-sarcastic
- Drama-free

## Main Features

### 1. Automatic Match Detection
- **Trigger**: Automatically detects when a Solo Shuffle match completes
- **Event**: Listens to `PVP_MATCH_COMPLETE` and `ARENA_PREP_OPPONENT_SPECIALIZATIONS`
- **Snapshot**: Captures all player data from the scoreboard
- **Auto-open**: Opens the whisper window automatically after match completion
- **Implementation**: `Triggers.lua`

### 2. Player Roster Management
- **Snapshot System**: Takes a snapshot of all 5 teammates (excluding yourself)
- **Data Captured**: 
  - Player full name (including realm)
  - Class (Warrior, Paladin, etc.)
  - Specialization (Holy, Arms, etc.)
  - Role (Tank, Healer, DPS)
  - GUID (unique identifier)
- **Locking**: Locks the roster once captured to prevent changes if players leave
- **Implementation**: `Snapshot.lua`

### 3. Whisper Window Interface
- **Window Size**: 720px × 580px
- **Max Rows**: 5 (one for each teammate)
- **Per-Row Controls**:
  - **Send checkbox**: Select to send whisper to this player
  - **Name checkbox**: Include player's name in message using {name} placeholder
  - **BNet checkbox**: Send second message with BattleTag invitation
  - **Blame checkbox**: Send "..." and add player to ignore list (mutually exclusive with Name/BNet)
  - **Message dropdown**: Select message preset (includes custom messages)
  - **Preview area**: Shows what will be sent before sending
- **Implementation**: `UI.lua`

### 4. Message System

#### Message Types
- **Message 1**: Primary thank-you message (always sent if Send is checked)
- **Message 2**: Optional BattleTag invitation (sent if BNet is checked)

#### Presets (MSG1_PRESETS)
```
- "gg {name}"
- "ty {name}!"
- "good games {name}!"
- "Random" (picks random preset)
- "{praise} {name}"
- "gg {name} :)"
- "nice games!"
```

#### Presets (MSG2_PRESETS)
```
- "if you wanna queue again: {btag}"
- "feel free to add me: {btag}"
- "up for more games? {btag}"
- "Random" (picks random preset)
- "if you want to queue more: {btag}"
```

#### Placeholders
- `{name}` - Player name without realm (e.g., "Arthas")
- `{praise}` - Random praise phrase (gg!, ty!, wp!, good games!, cheers!)
- `{role}` - Player role (Tank, Healer, DPS)
- `{spec}` - Player specialization (Holy, Arms, etc.)
- `{btag}` - Your BattleTag (e.g., "PlayerName#1234")

#### Custom Messages
- Players can define up to 10 custom messages in settings
- Custom messages appear in dropdown but are excluded from "Random" selection
- Stored in `SSW_Config.customLines`
- Tagged with "[Custom] " prefix in UI
- Implementation: `Presets.lua`

### 5. Operating Modes

#### SAFE Mode (Default)
- **Icon Color**: Cyan
- **Behavior**: Preview only, no whispers sent
- **Purpose**: Test messages before sending
- **Visual**: Messages shown in chat with "[SAFE -> PlayerName]" prefix

#### LIVE Mode
- **Icon Color**: Red
- **Behavior**: Actually sends whispers
- **Countdown**: Configurable delay before sending (default 3.5 seconds)
- **Visual**: Shows countdown and confirmation
- **Toggle**: Shift + Left Click minimap button, or `/ssw arm`

#### TEST Mode
- **Icon Color**: Yellow
- **Behavior**: Dummy data for testing UI
- **Purpose**: Configure addon without real match data
- **Activation**: `/ssw test`

### 6. Buttons and Actions

#### Bottom Bar Buttons (Left to Right)
- **All** (90px): Check all Send checkboxes
- **None** (90px): Uncheck all Send checkboxes
- **Send Whispers** (160px): Process selected whispers according to current mode
- **Ty All** (100px): Immediately send random message to all players and add to ignore
- **Blame All** (100px): Immediately send "..." to all players and add to ignore
- **Settings** (120px): Open settings panel
- **Close** (100px): Close whisper window

#### Special Buttons
- **PvP Icon Button**: Opens check-pvp.fr URL for player rankings
- **Player Name Button**: Clickable player name to copy check-pvp.fr URL
- **Minimap Button**: 
  - Left Click: Open whisper window
  - Right Click: Open settings
  - Shift + Left Click: Toggle SAFE/LIVE mode
  - Drag: Reposition around minimap

### 7. Anti-Spam Protection
- **Per-Target Cooldown**: 20 minutes per player (won't whisper same person twice in 20 min)
- **Per-Run Cap**: Maximum 12 whispers per match
- **Burst Throttle**: Minimum 3 seconds between "Send" button clicks
- **Message Delay**: 0.35 seconds between each whisper in a batch
- **Duplicate Prevention**: Tracks by snapshot timestamp to avoid re-sending
- **Implementation**: `AntiSpam.lua`

### 8. Settings Panel
- **Pre-Send Delay**: Countdown time before sending in LIVE mode (default 3.5s)
- **Auto Greeting**: Enable/disable automatic party greeting
- **Custom Message Lines**: 10 text boxes for custom messages
- **Mode Indicator**: Shows current mode (SAFE/LIVE/TEST)
- **Implementation**: `UI.lua` (settings section)

### 9. PvP Profile Integration
- **Provider**: check-pvp.fr
- **Region Detection**: Auto-detects region (US, EU, KR, TW, CN)
- **URL Format**: `https://check-pvp.fr/{region}/{realm}/{name}`
- **Features**:
  - Click player name to open dialog with copyable URL
  - Hover PvP icon for tooltip about rankings
  - Shows CR (Combat Rating), performance, alts, achievements
- **Implementation**: `Core.lua` (GetCheckPvpUrl, GetRegionCode)

### 10. Auto-Greeting
- **When**: Automatically when joining a group
- **Delay**: 1.5 seconds after GROUP_JOINED event
- **Cooldown**: 120 seconds (won't spam if joining multiple groups quickly)
- **Messages**: Random from ["hi", "yo", "o/", "hey", "gl"]
- **Target**: PARTY chat channel
- **Implementation**: `AutoGreet.lua`

### 11. Accessibility Features
- **One-Tap Mode**: "Ty All" and "Blame All" for quick actions
- **Visual Countdown**: Shows countdown before sending
- **Tooltips**: Detailed tooltips on all interactive elements
- **Screen Reader**: Labels for accessibility addons
- **Implementation**: `Accessibility.lua`

### 12. Data Storage

#### Account-Wide (SSW_Config)
```lua
{
    msg1Index = 1,              -- Selected Message 1 preset
    msg2Index = 1,              -- Selected Message 2 preset
    preSendDelay = 3.5,         -- Countdown delay
    autoPartyThanksOnReward = false,
    autoGreetEnabled = false,
    customLines = {}            -- Array of custom messages
}
```

#### Per-Character (SSW_CharConfig)
```lua
{
    isArmed = true,             -- LIVE mode enabled by default
    minimap = { angle = 220 },  -- Minimap button position
    access = {},
    antispam = {
        whisperCooldown = 1200,       -- 20 minutes
        maxWhispersPerRun = 12,
        minSecondsBetweenBursts = 3
    }
}
```

#### Session (SSW_AntiSpamState)
```lua
{
    lastWhisperAt = {},         -- fullName -> timestamp
    lastBurstAt = 0,
    runKey = "",                -- Unique key per match
    runCount = 0                -- Whispers sent this run
}
```

### 13. Slash Commands
- `/ssw` - Open settings panel
- `/ssw show` - Open whisper window manually
- `/ssw test` - Open in TEST mode with dummy data
- `/ssw arm` - Toggle between SAFE and LIVE modes

### 14. Technical Constants
- `MAX_ROWS`: 5 (max players per row)
- `SEND_DELAY`: 0.35 seconds (between whispers)
- `DEFAULT_PRE_SEND_DELAY`: 3.5 seconds (countdown)
- `MAX_LEN`: 140 characters (message length limit)
- `MAX_CUSTOM_LINES`: 10 (custom message slots)

## File Structure and Responsibilities

| File | Purpose |
|------|---------|
| **Core.lua** | Core utilities, SavedVariables init, slash commands, region detection |
| **Presets.lua** | Message templates, placeholder replacement, random selection |
| **Snapshot.lua** | Party roster tracking, scoreboard capture |
| **Send.lua** | Message sending logic, queue management, whisper dispatch |
| **UI.lua** | Main UI window, settings panel, player rows, buttons |
| **Accessibility.lua** | One-tap mode, accessibility features |
| **AutoGreet.lua** | Automatic party greeting |
| **MinimapButton.lua** | Minimap icon, tooltips, quick controls |
| **AntiSpam.lua** | Spam protection, cooldown tracking |
| **Triggers.lua** | Match completion detection, auto-open |
| **SoloShuffleWhisperer.toc** | Addon metadata, file load order |

## UI Layout Specifications

### Whisper Window
- **Width**: 720px
- **Height**: 580px
- **Position**: Center of screen, offset Y+60
- **Movable**: Yes (drag title bar)
- **Backdrop**: Standard Blizzard frame with inset

### Header Row
- **Height**: 28px
- **Background**: Dark semi-transparent
- **Columns**: Player (28px), Send (280px), Name (340px), BNet (400px), Blame (460px)

### Player Rows
- **Height**: 72px each
- **Spacing**: 2px gap between rows
- **Total for 5 rows**: 370px
- **Background**: Alternating opacity (0.05 / 0.15)
- **Layout**: 
  - Player name + icons: 0-250px
  - Send checkbox: 280px
  - Name checkbox: 340px
  - BNet checkbox: 400px
  - Blame checkbox: 460px
  - Message dropdown: Full width, second row
  - Preview text: Full width, third row

### Bottom Bar
- **Height**: 60px
- **Separator**: Tooltip divider texture
- **Button positions**:
  - All: BOTTOMLEFT +18, +15 (90×36)
  - None: LEFT of All +8 gap (90×36)
  - Send: LEFT of None +8 gap (160×36)
  - Ty All: LEFT of Send +8 gap (100×36)
  - Blame All: LEFT of Ty All +8 gap (100×36)
  - Settings: BOTTOMRIGHT -238, +15 (120×36)
  - Close: BOTTOMRIGHT -18, +15 (100×36)

## Logic Flow

### Match Completion → Whisper Window
1. `PVP_MATCH_COMPLETE` event fires
2. `Triggers.lua` calls `SSW.SnapshotScoreboard()`
3. `Snapshot.lua` captures scoreboard data
4. Snapshot is locked to prevent changes
5. After 1.5s delay, `SSW.ShowWhisperWindow(false)` called
6. `UI.lua` populates rows from snapshot
7. Window opens in center of screen

### Sending Whispers
1. User selects players and options
2. User clicks "Send Whispers" button
3. `Send.lua` checks anti-spam (`CanStartBurst()`)
4. For each selected row:
   - Check `CanWhisperTarget()`
   - Build messages with `BuildMessagesForTarget()`
   - Add to queue
5. If LIVE mode:
   - Show countdown (default 3.5s)
   - After countdown, send whispers sequentially
   - 0.35s delay between each
   - Mark each target in anti-spam
   - Add to ignore if Blame checked
6. Window closes after sending

### Message Building
1. Get template from preset index
2. If "Random", pick random non-custom preset
3. Replace placeholders:
   - {name} → Clean player name
   - {praise} → Random praise phrase
   - {role} → Tank/Healer/DPS
   - {spec} → Specialization name
   - {btag} → Your BattleTag
4. Clean up artifacts (extra spaces, dashes, punctuation)
5. Trim to MAX_LEN (140 chars)

### Checkbox Logic
- **Send checkbox**: Master control, enables other checkboxes
- **Name checkbox**: When checked, unchecks Blame
- **BNet checkbox**: When checked, unchecks Blame  
- **Blame checkbox**: When checked, unchecks Name and BNet (mutually exclusive)

## Error Handling

### Scoreboard Capture Failure
- Retry up to 10 times with 1s delay
- If all retries fail, show message: "Could not capture scoreboard. Use /ssw show to open manually."

### Anti-Spam Blocks
- Show reason in chat (e.g., "Cooldown for PlayerName", "Run cap reached")
- Skip player but continue with others
- Don't close window or reset state

### BattleTag Not Found
- If {btag} placeholder used but no BattleTag available
- Message 2 is set to empty string (not sent)
- No error shown to user

### Invalid Player Names
- Skip invalid targets silently
- Log to chat if in debug mode
- Continue processing other players

## Best Practices for AI Development

### When Adding Features
1. Maintain the "less talk is better" philosophy
2. Keep messages short (< 140 chars)
3. Always use anti-spam protection
4. Test in SAFE mode first
5. Respect user privacy (no data collection)

### Code Style
- Use SSW namespace for all globals
- Comment intent, not implementation
- Prefer clarity over cleverness
- Use descriptive variable names
- Follow existing patterns

### UI Principles
- Mobile-first: Large, clear buttons
- Tooltips for all interactive elements
- Visual feedback for all actions
- Consistent spacing and alignment
- Respect Blizzard UI conventions

### Performance
- Minimize frame updates
- Use C_Timer for delays
- Avoid polling, use events
- Cache expensive lookups
- Clean up unused data

## Known Limitations

1. **Cross-Realm**: Can only whisper players on same realm or connected realms
2. **Offline Players**: Cannot whisper offline players
3. **Ignore List**: WoW ignore list has a cap (~50 players), Blame All might fail if full
4. **URL Opening**: WoW addons cannot open URLs automatically (security restriction)
5. **BattleTag Detection**: Requires Battle.net login, might fail if disconnected
6. **Region Detection**: Falls back to EU if detection fails
7. **Scoreboard Timing**: Sometimes scoreboard isn't ready immediately after match

## Future Enhancement Ideas

1. **Multi-Language Support**: Templates in other languages
2. **Statistics Dashboard**: Track messages sent, players thanked
3. **Friend Recommendations**: Suggest adding frequently matched good players
4. **Template Variables**: More placeholders (class, rating, performance)
5. **Macro Integration**: Create macros for common actions
6. **Guild Sync**: Share custom messages with guildmates
7. **Rating Threshold**: Only whisper players above certain CR
8. **Win/Loss Context**: Different messages for wins vs losses

## Testing Checklist

- [ ] Test mode opens with dummy data
- [ ] Safe mode shows previews without sending
- [ ] Live mode sends actual whispers
- [ ] Checkboxes enable/disable correctly
- [ ] Blame checkbox is mutually exclusive
- [ ] All/None buttons work
- [ ] Ty All sends random messages
- [ ] Blame All sends "..." and ignores
- [ ] Custom messages appear in dropdown
- [ ] Custom messages excluded from Random
- [ ] Placeholders replaced correctly
- [ ] Anti-spam prevents duplicates
- [ ] Minimap button toggles mode
- [ ] Settings persist across sessions
- [ ] Window position saves
- [ ] Messages truncated at 140 chars
- [ ] Check-pvp.fr URLs generate correctly
- [ ] Region auto-detection works
- [ ] Auto-greeting fires on group join
- [ ] Scoreboard snapshot captures all players
- [ ] Window auto-opens after match

## Version History

- **v2.0**: Current version
  - Added PvP profile integration
  - Added custom message lines
  - Added Ty All/Blame All buttons
  - Auto-region detection
  - Improved UI layout

- **v1.x**: Initial releases
  - Basic whisper functionality
  - SAFE/LIVE modes
  - Anti-spam protection
  - Minimap button
