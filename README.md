# agenda

A simple command-line tool to fetch and display your calendar events. Perfect for quickly checking your schedule or integrating with other tools.

## What it does

`agenda` connects to your macOS Calendar app and lets you:

- **Fetch events** for today, tomorrow, or any specific date/date range
- **Filter by calendar** if you only want events from your work calendar, personal calendar, etc.
- **Extract meeting URLs** automatically from event notes, locations, or URL fields (supports Zoom, Google Meet, Microsoft Teams, and Webex)
- **Output in JSON format** with optional pretty-printing for readability

The tool is smart about finding meeting links in your events. It checks the event's URL field first, then falls back to scanning the notes and location for meeting links.

## Installation

### Option 1: Download from GitHub Releases (recommended)

1. Go to the [Releases page](https://github.com/thetinygoat/agenda/releases)
2. Download the latest `agenda` binary for your platform
3. (Optional but recommended) Verify the checksum:
   ```bash
   # Download both the binary and checksums.txt
   # Then verify with:
   shasum -a 256 -c checksums.txt
   ```
4. Make it executable and move it to your PATH:
   ```bash
   chmod +x agenda
   mv agenda /usr/local/bin/agenda
   ```

### Option 2: Build from source

1. Clone this repository
2. Navigate to the project directory
3. Build the release version:
   ```bash
   swift build -c release
   ```
4. Copy the binary to your PATH:
   ```bash
   cp .build/release/agenda /usr/local/bin/agenda
   ```

### Option 3: Run directly with Swift

If you don't want to install it system-wide, you can run it directly:
```bash
swift run agenda --date today
```

## Usage

### Basic usage

```bash
# Get today's events
agenda --date today

# Get tomorrow's events
agenda --date tomorrow

# Get events for a specific date
agenda --date 2023-12-25
```

### Date ranges

```bash
# Get events for a week
agenda --start-date 2023-12-20 --end-date 2023-12-26
```

### Filter by calendar

```bash
# Only show work calendar events
agenda --date today --calendar "Work"

# Case-insensitive matching
agenda --date today --calendar "personal"
```

### Output formats

```bash
# Pretty-printed JSON (great for debugging)
agenda --date today --pretty

# Compact JSON (default)
agenda --date today
```

## Shell Completions

Want tab completion for all the options? Here's how to set it up:

### Zsh (recommended for macOS)

```bash
# Create completions directory
mkdir -p ~/.zsh/completions

# Add to your ~/.zshrc if not already there:
# fpath=(~/.zsh/completions $fpath)

# Generate completion script
agenda __generate-completion-script zsh > ~/.zsh/completions/_agenda

# Reload your shell
exec zsh
```

### Fish

```bash
agenda __generate-completion-script fish > ~/.config/fish/completions/agenda.fish
```

### Bash

```bash
# Install bash-completion if you haven't already
brew install bash-completion

# Generate completion script
agenda __generate-completion-script bash > $(brew --prefix)/etc/bash_completion.d/agenda
```

After setting up completions, you can type `agenda --` and hit Tab to see all available options!

## Security & Verification

### Verifying Downloads

Each release includes SHA256 checksums to verify the integrity of the downloaded binaries. This ensures your download hasn't been tampered with.

**Step-by-step verification:**

1. Download both the binary and `checksums.txt` from the same release
2. Verify the checksum matches:
   ```bash
   # For a specific file
   shasum -a 256 agenda-v1.0.0-macos-universal
   
   # Compare the output with the hash in checksums.txt
   cat checksums.txt | grep universal
   ```
3. Or verify all files at once:
   ```bash
   shasum -a 256 -c checksums.txt
   ```

You should see output like:
```
agenda-v1.0.0-macos-universal: OK
```

If verification fails, **do not use the binary** and download it again.

## Privacy & Permissions

The first time you run `agenda`, macOS will ask for permission to access your calendar. This is required for the tool to work - it needs to read your calendar events to display them. The tool only reads your calendar data and never sends anything over the network.

## JSON Output Format

The default JSON output includes:
- `title` - Event title
- `startDate` - Start time in ISO 8601 format
- `endDate` - End time in ISO 8601 format
- `location` - Event location
- `notes` - Event notes
- `meetingURL` - Extracted meeting URL (if found)


## Requirements

- macOS (uses EventKit framework)
- Swift 5.7+ (for building from source)
