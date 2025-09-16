#!/usr/bin/env bash
# audio-diagnostic.sh — Universal Linux audio diagnostic (Ubuntu/Fedora/Debian)
# Works with PipeWire, PulseAudio, and mixed configurations
# Read-only: makes NO changes. Shows audio routing, profiles, and troubleshooting info.

set -uo pipefail

SINCE="${SINCE:-45 minutes ago}"
DO_TEST=0
VERBOSE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--test) DO_TEST=1; shift ;;
    --since)   SINCE="${2:-45m}"; shift 2 ;;
    -v|--verbose) VERBOSE=1; shift ;;
    -h|--help) cat <<EOF
Usage: $(basename "$0") [-t|--test] [--since WIN] [-v|--verbose]
  -t / --test        Play a short test tone via current default sink
  --since <window>   Journal window (e.g. '30 minutes ago', '2 hours ago', 'today')
  -v / --verbose     Extra detail
EOF
                 exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

# UI helpers
GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; DIM="\033[2m"; BOLD="\033[1m"; CLR="\033[0m"
ok()   { echo -e "✅ ${GREEN}$*${CLR}"; }
warn() { echo -e "⚠️  ${YELLOW}$*${CLR}"; }
bad()  { echo -e "❌ ${RED}$*${CLR}"; }
info() { echo -e "ℹ️  ${BOLD}$*${CLR}"; }
dim()  { echo -e "${DIM}$*${CLR}"; }
sep()  { echo -e "${DIM}-------------------------------------------------------------------------------${CLR}"; }

# Detect audio system and distro
AUDIO_SYSTEM=""
DISTRO_FAMILY=""
HAS_PIPEWIRE=0
HAS_PULSE=0
HAS_WIREPLUMBER=0

# Check for required commands and detect audio system
if command -v wpctl >/dev/null 2>&1 && command -v pw-cli >/dev/null 2>&1; then
  HAS_PIPEWIRE=1
  if command -v wireplumber >/dev/null 2>&1 || systemctl --user is-active wireplumber >/dev/null 2>&1; then
    HAS_WIREPLUMBER=1
  fi
fi

if command -v pactl >/dev/null 2>&1; then
  HAS_PULSE=1
fi

# Detect distro family
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  case "${ID:-}${ID_LIKE:-}" in
    *ubuntu*|*debian*) DISTRO_FAMILY="debian" ;;
    *fedora*|*rhel*|*centos*) DISTRO_FAMILY="fedora" ;;
    *arch*) DISTRO_FAMILY="arch" ;;
    *suse*) DISTRO_FAMILY="suse" ;;
    *) DISTRO_FAMILY="unknown" ;;
  esac
fi

# Determine primary audio system
if [[ $HAS_PIPEWIRE -eq 1 ]] && systemctl --user is-active pipewire >/dev/null 2>&1; then
  if [[ $HAS_WIREPLUMBER -eq 1 ]] && systemctl --user is-active wireplumber >/dev/null 2>&1; then
    AUDIO_SYSTEM="pipewire-wireplumber"
  else
    AUDIO_SYSTEM="pipewire-media-session"
  fi
elif [[ $HAS_PULSE -eq 1 ]] && (systemctl --user is-active pulseaudio >/dev/null 2>&1 || pgrep -x pulseaudio >/dev/null 2>&1); then
  AUDIO_SYSTEM="pulseaudio"
else
  AUDIO_SYSTEM="unknown"
fi

OS_NAME="$(. /etc/os-release 2>/dev/null && echo "${PRETTY_NAME:-unknown}")"
HOST="$(hostname 2>/dev/null || echo unknown)"
DATE="$(date)"

echo -e "${BOLD}Linux Audio Diagnostic (Universal • ${OS_NAME})${CLR}"
dim "Host: ${HOST} | Audio: ${AUDIO_SYSTEM} | When: ${DATE} | Journal: ${SINCE}"
sep

# Track detected issues for conditional output
ISSUE_COUNT=0
HAS_PROFILE_OFF=0
HAS_BT_ERRORS=0
HAS_DUMMY_OUTPUT=0

# 1) Core health (services)
echo -e "${BOLD}1) Core audio services health${CLR}"
ALL_OK=1

check_service() {
  local service="$1"
  local description="$2"
  local check_type="${3:-systemd}"  # systemd or process
  
  if [[ "$check_type" == "systemd" ]]; then
    if systemctl --user is-active "$service" >/dev/null 2>&1; then
      ok "$description: active (systemd)"
      return 0
    elif systemctl --user status "$service" >/dev/null 2>&1; then
      state="$(systemctl --user is-active "$service" 2>/dev/null || echo "inactive")"
      bad "$description: $state"
      return 1
    fi
  fi
  
  # Fall back to process check
  if pgrep -x "$service" >/dev/null 2>&1; then
    ok "$description: running (process)"
    return 0
  else
    # Check if service exists but isn't running
    if command -v "$service" >/dev/null 2>&1; then
      warn "$description: installed but not running"
    else
      bad "$description: not found"
    fi
    return 1
  fi
}

case "$AUDIO_SYSTEM" in
  pipewire-wireplumber)
    check_service pipewire "PipeWire core" || ALL_OK=0
    check_service wireplumber "WirePlumber session" || ALL_OK=0
    check_service pipewire-pulse "PulseAudio compatibility" || true  # Optional
    ;;
  pipewire-media-session)
    check_service pipewire "PipeWire core" || ALL_OK=0
    check_service pipewire-media-session "Media session manager" || ALL_OK=0
    check_service pipewire-pulse "PulseAudio compatibility" || true  # Optional
    ;;
  pulseaudio)
    # PulseAudio might run as systemd service or standalone
    if ! check_service pulseaudio "PulseAudio server"; then
      ALL_OK=0
    fi
    ;;
  *)
    bad "No recognized audio system detected"
    echo "Checking for any audio processes..."
    pgrep -la 'pipewire|pulse|jack' || echo "  No audio servers running"
    ALL_OK=0
    ;;
esac

[[ $ALL_OK -eq 1 ]] || warn "Inactive audio services can cause missing devices or dummy output."
sep

# 2) Default devices and routing
echo -e "${BOLD}2) Default devices & active routing${CLR}"

# Function to get defaults based on audio system
get_audio_defaults() {
  DEF_SINK_ID=""
  DEF_SINK_NAME=""
  DEF_SRC_ID=""
  DEF_SRC_NAME=""
  
  if [[ "$AUDIO_SYSTEM" == "pipewire-wireplumber" ]] && command -v wpctl >/dev/null 2>&1; then
    # Use wpctl for PipeWire with WirePlumber
    STATUS="$(wpctl status 2>/dev/null || true)"
    if [[ -n "$STATUS" ]]; then
      # Parse wpctl status (both old and new formats)
      # First try old format
      DEF_SINK_LINE="$(sed -n 's/^[[:space:]]*Default \(Audio \)\?Sink:[[:space:]]*\([0-9][0-9]*\)[[:space:]]*(\(.*\)).*/\2|\3/p' <<<"$STATUS" | head -n1)"
      DEF_SRC_LINE="$(sed -n 's/^[[:space:]]*Default \(Audio \)\?Source:[[:space:]]*\([0-9][0-9]*\)[[:space:]]*(\(.*\)).*/\2|\3/p' <<<"$STATUS" | head -n1)"
      
      # If old format not found, try new format (asterisk marking)
      if [[ -z "$DEF_SINK_LINE" ]]; then
        AUDIO_SECTION=$(echo "$STATUS" | sed -n '/^Audio/,/^Video/p')
        SINK_SECTION=$(echo "$AUDIO_SECTION" | sed -n '/├─ Sinks:/,/├─ Sources:/p')
        DEFAULT_SINK=$(echo "$SINK_SECTION" | grep '│.*\*' | head -n1)
        if [[ -n "$DEFAULT_SINK" ]]; then
          DEF_SINK_ID=$(echo "$DEFAULT_SINK" | sed -n 's/.*\*[[:space:]]*\([0-9][0-9]*\)\..*/\1/p')
          DEF_SINK_NAME=$(echo "$DEFAULT_SINK" | sed -n 's/.*\*[[:space:]]*[0-9][0-9]*\.[[:space:]]*\([^[]*\).*/\1/p' | xargs)
          DEF_SINK_LINE="${DEF_SINK_ID}|${DEF_SINK_NAME}"
        fi
      fi
      
      if [[ -z "$DEF_SRC_LINE" ]]; then
        AUDIO_SECTION=$(echo "$STATUS" | sed -n '/^Audio/,/^Video/p')
        SOURCE_SECTION=$(echo "$AUDIO_SECTION" | sed -n '/├─ Sources:/,/├─ Filters:/p')
        DEFAULT_SOURCE=$(echo "$SOURCE_SECTION" | grep '│.*\*' | head -n1)
        if [[ -z "$DEFAULT_SOURCE" ]]; then
          FILTER_SECTION=$(echo "$AUDIO_SECTION" | sed -n '/├─ Filters:/,/└─ Streams:/p')
          DEFAULT_SOURCE=$(echo "$FILTER_SECTION" | grep '│.*\*.*\[Audio/Source\]' | head -n1)
        fi
        if [[ -n "$DEFAULT_SOURCE" ]]; then
          DEF_SRC_ID=$(echo "$DEFAULT_SOURCE" | sed -n 's/.*\*[[:space:]]*\([0-9][0-9]*\)\..*/\1/p')
          DEF_SRC_NAME=$(echo "$DEFAULT_SOURCE" | sed -n 's/.*\*[[:space:]]*[0-9][0-9]*\.[[:space:]]*\([^[]*\).*/\1/p' | xargs)
          DEF_SRC_LINE="${DEF_SRC_ID}|${DEF_SRC_NAME}"
        fi
      fi
      
      # Parse the extracted lines
      DEF_SINK_ID="${DEF_SINK_LINE%%|*}"
      DEF_SINK_NAME="${DEF_SINK_LINE#*|}"
      DEF_SRC_ID="${DEF_SRC_LINE%%|*}"
      DEF_SRC_NAME="${DEF_SRC_LINE#*|}"
    fi
    
  elif command -v pactl >/dev/null 2>&1; then
    # Use pactl for PulseAudio or PipeWire without WirePlumber
    # Get default sink
    DEF_SINK_NAME="$(pactl info 2>/dev/null | grep "Default Sink:" | cut -d: -f2- | xargs || true)"
    if [[ -n "$DEF_SINK_NAME" ]]; then
      # Try to get the index
      DEF_SINK_ID="$(pactl list short sinks 2>/dev/null | grep -F "$DEF_SINK_NAME" | cut -f1 | head -n1 || true)"
    fi
    
    # Get default source
    DEF_SRC_NAME="$(pactl info 2>/dev/null | grep "Default Source:" | cut -d: -f2- | xargs || true)"
    if [[ -n "$DEF_SRC_NAME" ]]; then
      # Try to get the index
      DEF_SRC_ID="$(pactl list short sources 2>/dev/null | grep -F "$DEF_SRC_NAME" | cut -f1 | head -n1 || true)"
    fi
  fi
}

get_audio_defaults

# Report defaults
if [[ -z "${DEF_SINK_ID:-}${DEF_SINK_NAME:-}" ]]; then 
  bad "No default audio output (sink) configured"
elif [[ "${DEF_SINK_NAME:-}" =~ (auto_null|dummy) ]]; then 
  bad "Default output is dummy device. Expect silence."
  HAS_DUMMY_OUTPUT=1
else 
  ok "Default Output: ${DEF_SINK_NAME}${DEF_SINK_ID:+ (ID: $DEF_SINK_ID)}"
fi

if [[ -z "${DEF_SRC_ID:-}${DEF_SRC_NAME:-}" ]]; then 
  warn "No default audio input (source) configured"
elif [[ "${DEF_SRC_NAME:-}" =~ (auto_null|dummy) ]]; then 
  bad "Default input is dummy device"
else 
  ok "Default Input: ${DEF_SRC_NAME}${DEF_SRC_ID:+ (ID: $DEF_SRC_ID)}"
fi

# Show additional routing info based on system
describe_device() {
  local name="$1"
  local type="$2"  # sink or source
  
  if [[ -z "$name" ]] || [[ "$name" =~ (auto_null|dummy) ]]; then
    return 0
  fi
  
  # Try to determine device type from name
  local NAME_UPPER="$(echo "$name" | tr '[:lower:]' '[:upper:]')"
  
  if [[ "$NAME_UPPER" =~ (BLUEZ|A2DP|HSP|HFP|BLUETOOTH) ]]; then
    info "Routed to Bluetooth device. If unintended, change in Settings → Sound"
  elif [[ "$NAME_UPPER" =~ (HDMI|DISPLAYPORT|DP) ]]; then
    warn "Routed to HDMI/DisplayPort. If you expected speakers/headphones, change in Settings → Sound"
  elif [[ "$NAME_UPPER" =~ (USB) ]]; then
    warn "Routed to USB device. If unintended, select built-in audio in Settings → Sound"
  elif [[ "$NAME_UPPER" =~ (EASY.?EFFECTS|EASYEFFECTS|VIRTUAL) ]]; then
    warn "Routed to virtual device (effects processor). Ensure the pipeline is active."
  else
    dim "  Appears to be built-in/analog audio device"
  fi
}

if [[ -n "${DEF_SINK_NAME:-}" ]]; then
  describe_device "$DEF_SINK_NAME" "sink"
fi

sep

# 3) Available devices - FIXED VERSION
echo -e "${BOLD}3) Available audio devices${CLR}"

if [[ "$AUDIO_SYSTEM" == "pipewire-wireplumber" ]] && command -v wpctl >/dev/null 2>&1; then
  # Get wpctl status and parse it properly
  WPCTL_STATUS="$(wpctl status 2>/dev/null || true)"
  
  echo "Output devices (Sinks):"
  # Extract just the Sinks section
  echo "$WPCTL_STATUS" | sed -n '/├─ Sinks:/,/├─ Sources:/p' | grep '│' | grep '[0-9]' | while IFS= read -r line; do
    # Clean up the line - remove tree characters and extra spaces
    clean_line=$(echo "$line" | sed 's/[│├└─]//g' | sed 's/^[[:space:]]*//')
    
    # Check if it's the default (has asterisk)
    if echo "$clean_line" | grep -q '\*'; then
      # Remove the asterisk and clean up
      clean_line=$(echo "$clean_line" | sed 's/\*//g' | sed 's/^[[:space:]]*//')
      echo "  • $clean_line ← DEFAULT"
    else
      echo "  • $clean_line"
    fi
    
    # Check for dummy devices
    if echo "$clean_line" | grep -qi 'dummy\|auto_null'; then
      echo "    ⚠️  Dummy output device"
    fi
  done || echo "  No output devices found"
  
  echo
  echo "Input devices (Sources):"
  # Extract Sources section (between Sources and either Filters or Devices)
  echo "$WPCTL_STATUS" | sed -n '/├─ Sources:/,/├─ \(Filters:\|Devices:\)/p' | grep '│' | grep '[0-9]' | while IFS= read -r line; do
    # Clean up the line - remove tree characters and extra spaces
    clean_line=$(echo "$line" | sed 's/[│├└─]//g' | sed 's/^[[:space:]]*//')
    
    # Check if it's the default (has asterisk)
    if echo "$clean_line" | grep -q '\*'; then
      # Remove the asterisk and clean up
      clean_line=$(echo "$clean_line" | sed 's/\*//g' | sed 's/^[[:space:]]*//')
      echo "  • $clean_line ← DEFAULT"
    else
      echo "  • $clean_line"
    fi
    
    # Check for dummy devices
    if echo "$clean_line" | grep -qi 'dummy\|auto_null'; then
      echo "    ⚠️  Dummy input device"
    fi
  done || echo "  No input devices found"
  
  echo
  echo "Audio Cards/Devices:"
  pw-cli ls Device 2>/dev/null | awk '
    /id [0-9]+/ {id=$2}
    /device.description/ {
      gsub(/.*= "/,""); gsub(/"$/,""); desc=$0
    }
    /device.profile.name/ {
      gsub(/.*= "/,""); gsub(/"$/,""); prof=$0
    }
    /^}$/ && id {
      printf("  • Card %s: %s\n", id, (desc!=""?desc:"unnamed"));
      if (prof != "") {
        printf("    Profile: %s\n", prof);
        if (prof == "off") print "    ⚠️  Profile is OFF - no inputs/outputs available from this card"
      }
      id=desc=prof="";
    }
  ' || echo "  Unable to list cards"
  
  # Check for profile off
  PW_DEV="$(pw-cli ls Device 2>/dev/null || true)"
  if grep -qiE 'device.profile.name.*"off"' <<<"$PW_DEV"; then
    HAS_PROFILE_OFF=1
  fi
  
elif command -v pactl >/dev/null 2>&1; then
  # PulseAudio device listing - improved version
  echo "Output devices (Sinks):"
  pactl list sinks 2>/dev/null | awk '
    /^Sink #/ {id=$2; gsub("#","",id)}
    /^\tName:/ {name=$2}
    /^\tDescription:/ {gsub(/^[[:space:]]*Description:[[:space:]]*/,""); desc=$0}
    /^\tState:/ {state=$2}
    /^\tVolume:/ {if (match($0, /[0-9]+%/)) vol=substr($0, RSTART, RLENGTH)}
    /^\tMute:/ {mute=$2}
    /^$/ && id {
      printf("  • [%s] %s\n", id, (desc!=""?desc:name));
      printf("    State: %s, Volume: %s, Mute: %s\n", state, vol, mute);
      if (name ~ /dummy/) print "    ⚠️  Dummy output device"
      id=name=desc=state=vol=mute=""
    }
  ' || echo "  No output devices found"
  
  echo
  echo "Input devices (Sources):"
  pactl list sources 2>/dev/null | grep -v '\.monitor' | awk '
    /^Source #/ {id=$2; gsub("#","",id)}
    /^\tName:/ {name=$2; if (name ~ /\.monitor$/) next}
    /^\tDescription:/ {gsub(/^[[:space:]]*Description:[[:space:]]*/,""); desc=$0}
    /^\tState:/ {state=$2}
    /^\tVolume:/ {if (match($0, /[0-9]+%/)) vol=substr($0, RSTART, RLENGTH)}
    /^\tMute:/ {mute=$2}
    /^$/ && id && name !~ /\.monitor/ {
      printf("  • [%s] %s\n", id, (desc!=""?desc:name));
      printf("    State: %s, Volume: %s, Mute: %s\n", state, vol, mute);
      if (name ~ /dummy/) print "    ⚠️  Dummy input device"
      id=name=desc=state=vol=mute=""
    }
  ' || echo "  No input devices found"
  
  echo
  echo "Sound Cards:"
  pactl list cards 2>/dev/null | awk '
    /^Card #/ {id=$2; gsub("#","",id)}
    /^\tName:/ {name=$2}
    /^\tDriver:/ {driver=$2}
    /^\tActive Profile:/ {gsub(/^[[:space:]]*Active Profile:[[:space:]]*/,""); prof=$0}
    /^$/ && id {
      printf("  • Card %s: %s [driver: %s]\n", id, name, driver);
      printf("    Active Profile: %s\n", prof);
      if (prof == "off") print "    ⚠️  Profile is OFF - no inputs/outputs available from this card"
      id=name=driver=prof=""
    }
  ' || echo "  Unable to list cards"
  
  # Check for cards with "off" profile
  CARDS="$(pactl list cards 2>/dev/null || true)"
  if [[ -n "$CARDS" ]] && grep -q "Active Profile: off" <<<"$CARDS"; then
    HAS_PROFILE_OFF=1
  fi
  
else
  # Fallback to ALSA if no PipeWire/PulseAudio
  echo "Using ALSA to list devices:"
  if command -v aplay >/dev/null 2>&1; then
    echo "Playback devices:"
    aplay -l 2>/dev/null | while IFS= read -r line; do
      echo "  $line"
    done || echo "  No playback devices found"
    
    echo
    echo "Capture devices:"
    arecord -l 2>/dev/null | while IFS= read -r line; do
      echo "  $line"
    done || echo "  No capture devices found"
  else
    bad "Cannot list devices - no audio tools available"
    echo "  Install alsa-utils, pulseaudio-utils, or pipewire-utils"
  fi
fi

sep

# 3b) Check for common issues based on distro
echo -e "${BOLD}3b) System-specific checks${CLR}"

# Check for suspended nodes (PipeWire)
if [[ "$AUDIO_SYSTEM" == pipewire* ]] && command -v wpctl >/dev/null 2>&1; then
  SUSPENDED_COUNT=0
  ALL_NODES=$(wpctl status 2>/dev/null | grep -E '^\s*[0-9]+\.' | sed -n 's/.*\[\?\([0-9][0-9]*\)\].*/\1/p')
  for NODE_ID in $ALL_NODES; do
    NODE_INFO=$(wpctl inspect "$NODE_ID" 2>/dev/null || true)
    if grep -q 'node.state = "suspended"' <<<"$NODE_INFO"; then
      NODE_DESC=$(sed -n 's/.*node.description = "\(.*\)".*/\1/p' <<<"$NODE_INFO" | head -n1)
      bad "Node $NODE_ID suspended: ${NODE_DESC:-unknown}"
      SUSPENDED_COUNT=$((SUSPENDED_COUNT + 1))
    fi
  done
  
  if [[ $SUSPENDED_COUNT -eq 0 ]]; then
    ok "No suspended audio nodes detected"
  else
    warn "Found $SUSPENDED_COUNT suspended node(s)"
    dim "Fix: systemctl --user restart ${AUDIO_SYSTEM##*-}"
  fi
else
  # Check for common Ubuntu/PulseAudio issues
  if [[ "$DISTRO_FAMILY" == "debian" ]]; then
    # Check if user is in audio group
    if ! groups | grep -q audio; then
      warn "User not in 'audio' group - may cause permission issues"
      dim "Fix: sudo usermod -a -G audio $USER (then logout/login)"
    else
      ok "User is in audio group"
    fi
    
    # Check for timidity blocking audio (common Ubuntu issue)
    if pgrep -x timidity >/dev/null 2>&1; then
      warn "TiMidity++ is running - may block audio devices"
      dim "Fix: sudo systemctl stop timidity && sudo systemctl disable timidity"
    fi
  fi
  
  # Check ALSA state
  if command -v aplay >/dev/null 2>&1; then
    ALSA_CARDS="$(aplay -l 2>&1 || true)"
    if [[ "$ALSA_CARDS" =~ "no soundcards found" ]]; then
      bad "ALSA reports no sound cards found"
      dim "Check: lspci -v | grep -i audio"
      dim "Check: dmesg | grep -Ei 'snd|hda|audio|firmware'"
    else
      CARD_COUNT="$(echo "$ALSA_CARDS" | grep -c "^card " || true)"
      ok "ALSA detected $CARD_COUNT sound card(s)"
    fi
  fi
fi

sep

# 4) Recent logs
echo -e "${BOLD}4) Recent audio system logs${CLR}"

check_logs() {
  local service="$1"
  local error_keywords="error|fail|warn|timeout|dummy|auto_null|suspend"
  local lifecycle_keywords="Started|Stopped|Starting|Stopping|Reloading|Reloaded|Activating|Deactivating"
  
  LOG="$(journalctl --user -u "$service" --since "$SINCE" --no-pager 2>/dev/null || true)"
  if [[ -z "$LOG" ]]; then
    LOG="$(journalctl -u "$service" --since "$SINCE" --no-pager 2>/dev/null || true)"
  fi
  
  if [[ -n "$LOG" ]]; then
    # Check for service lifecycle events
    LIFECYCLE_HITS=$(grep -Ei "$lifecycle_keywords" <<<"$LOG" | wc -l | tr -d ' ')
    if [[ "$LIFECYCLE_HITS" -gt 0 ]]; then
      echo "Service $service lifecycle events:"
      echo "$LOG" | grep -Ei "$lifecycle_keywords" | tail -n 5 | while IFS= read -r line; do
        # Extract timestamp and event
        timestamp=$(echo "$line" | awk '{print $1, $2, $3}')
        event=$(echo "$line" | grep -oE "(Started|Stopped|Starting|Stopping|Reloading|Reloaded|Activating|Deactivating).*" | head -n1)
        if [[ -n "$event" ]]; then
          if [[ "$event" =~ (Stopped|Stopping|fail) ]]; then
            warn "  $timestamp: $event"
          else
            dim "  $timestamp: $event"
          fi
        fi
      done
      echo
    fi
    
    # Check for errors/warnings
    ERROR_HITS=$(grep -Ei "$error_keywords" <<<"$LOG" | wc -l | tr -d ' ')
    if [[ "$ERROR_HITS" -gt 0 ]]; then
      echo "Found $ERROR_HITS concerning entries in $service logs:"
      echo "$LOG" | grep -Ei "$error_keywords" | tail -n 5 | while IFS= read -r line; do
        # Highlight critical keywords
        if echo "$line" | grep -qi "error\|fail\|timeout\|dummy\|auto_null"; then
          bad "  ${line:0:120}..."
        else
          warn "  ${line:0:120}..."
        fi
      done
      
      # Check for specific issues
      grep -qi 'bluetooth.*error\|bluez.*fail' <<<"$LOG" && HAS_BT_ERRORS=1
      grep -qi 'auto_null\|dummy' <<<"$LOG" && HAS_DUMMY_OUTPUT=1
    fi
    
    # Show full logs in verbose mode
    if [[ $VERBOSE -eq 1 ]] && [[ "$LIFECYCLE_HITS" -gt 0 || "$ERROR_HITS" -gt 0 ]]; then
      echo
      echo -e "${DIM}Full recent log entries (verbose mode):${CLR}"
      echo "$LOG" | tail -n 30 | while IFS= read -r line; do
        dim "  $line"
      done
    fi
    
    # Return success if we found anything interesting
    [[ "$LIFECYCLE_HITS" -gt 0 || "$ERROR_HITS" -gt 0 ]] && return 0
  fi
  return 1
}

# Track if we found any logs
FOUND_LOGS=0

case "$AUDIO_SYSTEM" in
  pipewire-wireplumber)
    check_logs wireplumber && FOUND_LOGS=1
    check_logs pipewire && FOUND_LOGS=1
    check_logs pipewire-pulse && FOUND_LOGS=1
    ;;
  pipewire-media-session)
    check_logs pipewire-media-session && FOUND_LOGS=1
    check_logs pipewire && FOUND_LOGS=1
    check_logs pipewire-pulse && FOUND_LOGS=1
    ;;
  pulseaudio)
    check_logs pulseaudio && FOUND_LOGS=1
    ;;
esac

# Also check for bluetooth service events if relevant
if [[ "${DEF_SINK_NAME:-}" =~ (bluetooth|bluez) ]] || [[ "${DEF_SRC_NAME:-}" =~ (bluetooth|bluez) ]]; then
  check_logs bluetooth && FOUND_LOGS=1
fi

if [[ $FOUND_LOGS -eq 0 ]]; then
  ok "No service events or errors in recent logs (last $SINCE)"
  dim "  To see all logs: journalctl --user -u ${AUDIO_SYSTEM##*-} --since '$SINCE'"
fi

sep

# 5) Optional test tone
if [[ $DO_TEST -eq 1 ]]; then
  echo -e "${BOLD}5) Audio test${CLR}"
  
  # Find a test sound
  TEST_SOUND=""
  for sound in \
    /usr/share/sounds/freedesktop/stereo/complete.oga \
    /usr/share/sounds/freedesktop/stereo/bell.oga \
    /usr/share/sounds/ubuntu/stereo/bell.ogg \
    /usr/share/sounds/alsa/Front_Center.wav \
    /usr/share/sounds/sound-icons/piano-3.wav; do
    if [[ -f "$sound" ]]; then
      TEST_SOUND="$sound"
      break
    fi
  done
  
  if [[ -z "$TEST_SOUND" ]]; then
    warn "No test sound file found"
  else
    echo "Playing test sound: $(basename "$TEST_SOUND")"
    
    # Try different players based on what's available
    if command -v pw-play >/dev/null 2>&1; then
      pw-play "$TEST_SOUND" 2>/dev/null && ok "Test completed via PipeWire" || bad "Test failed"
    elif command -v paplay >/dev/null 2>&1; then
      paplay "$TEST_SOUND" 2>/dev/null && ok "Test completed via PulseAudio" || bad "Test failed"
    elif command -v aplay >/dev/null 2>&1; then
      aplay "$TEST_SOUND" 2>/dev/null && ok "Test completed via ALSA" || bad "Test failed"
    else
      warn "No audio player found (pw-play, paplay, or aplay)"
    fi
  fi
  sep
fi

# 6) Conditional conclusions
echo -e "${BOLD}Conclusions / Next steps${CLR}"

SHOWED_ISSUES=0

# Critical service issues
if [[ $ALL_OK -ne 1 ]]; then
  bad "Critical: Audio service(s) not running properly"
  
  case "$AUDIO_SYSTEM" in
    pipewire*)
      echo "  Fix: systemctl --user restart pipewire pipewire-pulse wireplumber"
      ;;
    pulseaudio)
      echo "  Fix: systemctl --user restart pulseaudio"
      echo "  Or:  pulseaudio --kill && pulseaudio --start"
      ;;
    *)
      echo "  Ubuntu: sudo apt install pulseaudio && systemctl --user start pulseaudio"
      echo "  Fedora: sudo dnf install pipewire wireplumber && systemctl --user start pipewire"
      ;;
  esac
  echo
  SHOWED_ISSUES=1
fi

# No audio output
if [[ -z "${DEF_SINK_ID:-}${DEF_SINK_NAME:-}" ]]; then
  bad "No audio output configured"
  echo "  Fix 1: Open Settings → Sound → Output Device"
  if command -v pactl >/dev/null 2>&1; then
    echo "  Fix 2: List devices:  pactl list short sinks"
    echo "         Set default:   pactl set-default-sink SINK_NAME"
  elif command -v wpctl >/dev/null 2>&1; then
    echo "  Fix 2: List devices:  wpctl status"
    echo "         Set default:   wpctl set-default SINK_ID"
  fi
  echo
  SHOWED_ISSUES=1
fi

# Dummy output
if [[ $HAS_DUMMY_OUTPUT -eq 1 ]]; then
  bad "Audio has fallen back to dummy output"
  echo "  Fix 1: Restart audio service:"
  case "$AUDIO_SYSTEM" in
    pipewire*) echo "         systemctl --user restart pipewire wireplumber" ;;
    pulseaudio) echo "         systemctl --user restart pulseaudio" ;;
  esac
  echo "  Fix 2: Check if sound card detected: aplay -l"
  echo "  Fix 3: Check for missing firmware: dmesg | grep -i firmware"
  echo "  Fix 4: Ubuntu: sudo apt install linux-modules-extra-\$(uname -r)"
  echo
  SHOWED_ISSUES=1
fi

# Profile off
if [[ $HAS_PROFILE_OFF -eq 1 ]]; then
  bad "One or more audio devices have profile OFF"
  echo "  Fix: Settings → Sound → Device Configuration"
  echo "       Select 'Analog Stereo Duplex' or appropriate profile"
  if command -v pactl >/dev/null 2>&1; then
    echo "  Or:  pactl list cards | grep -E 'Name:|Profiles:|Active Profile:'"
    echo "       pactl set-card-profile CARD_NAME PROFILE_NAME"
  fi
  echo
  SHOWED_ISSUES=1
fi

# Bluetooth issues
if [[ $HAS_BT_ERRORS -eq 1 ]]; then
  warn "Bluetooth audio errors detected"
  echo "  Fix 1: Toggle Bluetooth off/on in Settings"
  echo "  Fix 2: Remove and re-pair the device"
  echo "  Fix 3: sudo systemctl restart bluetooth"
  if [[ "$DISTRO_FAMILY" == "debian" ]]; then
    echo "  Fix 4: Install codecs: sudo apt install pulseaudio-module-bluetooth"
  fi
  echo
  SHOWED_ISSUES=1
fi

# Suspended nodes (PipeWire)
if [[ ${SUSPENDED_COUNT:-0} -gt 0 ]]; then
  bad "Suspended audio nodes detected"
  echo "  Quick fix: systemctl --user restart wireplumber"
  echo "  For Framework laptops: Check for firmware updates"
  echo
  SHOWED_ISSUES=1
fi

# Ubuntu-specific issues
if [[ "$DISTRO_FAMILY" == "debian" ]] && [[ $SHOWED_ISSUES -eq 1 ]]; then
  echo "Ubuntu-specific fixes to try:"
  echo "  • Remove speech-dispatcher if not needed:"
  echo "    sudo apt remove speech-dispatcher"
  echo "  • Reinstall audio packages:"
  echo "    sudo apt install --reinstall alsa-base alsa-utils pulseaudio"
  echo "  • Reset PulseAudio config:"
  echo "    rm -rf ~/.config/pulse && pulseaudio --kill"
  echo
fi

# No issues found
if [[ $SHOWED_ISSUES -eq 0 ]]; then
  ok "No critical issues detected - audio system appears healthy"
  echo
  echo "Useful commands for managing audio:"
  
  # GUI Settings
  echo "• Open audio settings:"
  echo "  - GNOME: Settings → Sound"
  echo "  - KDE: System Settings → Audio"
  echo "  - Or run: pavucontrol (if installed)"
  
  # Volume control tools
  if ! command -v pavucontrol >/dev/null 2>&1 && command -v alsamixer >/dev/null 2>&1; then
    echo
    echo "• For easier volume control, consider installing pavucontrol:"
    case "$DISTRO_FAMILY" in
      debian)  echo "  sudo apt install pavucontrol" ;;
      fedora)  echo "  sudo dnf install pavucontrol" ;;
      arch)    echo "  sudo pacman -S pavucontrol" ;;
      suse)    echo "  sudo zypper install pavucontrol" ;;
      *)       echo "  Install 'pavucontrol' using your package manager" ;;
    esac
    echo "  Currently available: alsamixer (terminal-based)"
  fi
  
  # Command line controls based on active audio system
  echo
  echo "• Command-line volume control:"
  case "$AUDIO_SYSTEM" in
    pipewire-wireplumber)
      if command -v wpctl >/dev/null 2>&1; then
        echo "  wpctl status                            # Show devices"
        echo "  wpctl set-volume @DEFAULT_SINK@ 50%     # Set to 50%"
        echo "  wpctl set-volume @DEFAULT_SINK@ 5%+     # Increase 5%"
        echo "  wpctl set-mute @DEFAULT_SINK@ toggle    # Mute/unmute"
      elif command -v pactl >/dev/null 2>&1; then
        echo "  pactl info                               # Show info"
        echo "  pactl set-sink-volume @DEFAULT_SINK@ 50% # Set to 50%"
        echo "  pactl set-sink-mute @DEFAULT_SINK@ toggle # Mute/unmute"
      fi
      ;;
    pipewire-media-session|pulseaudio)
      if command -v pactl >/dev/null 2>&1; then
        echo "  pactl info                               # Show info"
        echo "  pactl set-sink-volume @DEFAULT_SINK@ 50% # Set to 50%"
        echo "  pactl set-sink-volume @DEFAULT_SINK@ +5% # Increase 5%"
        echo "  pactl set-sink-mute @DEFAULT_SINK@ toggle # Mute/unmute"
      fi
      ;;
    *)
      if command -v amixer >/dev/null 2>&1; then
        echo "  alsamixer                                # Interactive TUI"
        echo "  amixer set Master 50%                    # Set to 50%"
        echo "  amixer set Master 5%+                    # Increase 5%"
        echo "  amixer set Master toggle                  # Mute/unmute"
      fi
      ;;
  esac
  
  # View logs based on actual audio system
  echo
  echo "• View recent audio logs:"
  case "$AUDIO_SYSTEM" in
    pipewire-wireplumber)
      echo "  journalctl --user -u wireplumber -u pipewire --since '5 min ago'"
      ;;
    pipewire-media-session)
      echo "  journalctl --user -u pipewire-media-session -u pipewire --since '5 min ago'"
      ;;
    pulseaudio)
      echo "  journalctl --user -u pulseaudio --since '5 min ago'"
      if [[ -d ~/.config/pulse ]]; then
        echo "  tail -f ~/.config/pulse/*.log"
      fi
      ;;
    *)
      echo "  dmesg | grep -i audio    # Kernel audio messages"
      ;;
  esac
  
  # Test audio
  echo
  echo "• Test audio output:"
  if command -v speaker-test >/dev/null 2>&1; then
    echo "  speaker-test -t wav -c 2 -l 1    # Play test sound once"
    echo "  speaker-test -t sine -f 440 -l 1 # Play 440Hz tone once"
  else
    echo "  Install 'alsa-utils' package for speaker-test command"
  fi
fi

echo
ok "Diagnostic complete — no changes were made."
