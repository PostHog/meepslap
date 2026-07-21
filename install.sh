#!/bin/bash
set -e

# Installs a pre-built MeepSlap binary (for the no-Xcode release path).
# For building from source, use `make install` instead.

INSTALL_DIR="$HOME/Desktop/meepslap/bin"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.posthog.meepslap.plist"
BINARY="$INSTALL_DIR/MeepSlap"

echo "Installing MeepSlap..."

# Copy binary
mkdir -p "$INSTALL_DIR"
cp "$(dirname "$0")/MeepSlap" "$BINARY"
chmod +x "$BINARY"
codesign --force --sign - "$BINARY" 2>/dev/null || true

# Create LaunchAgent
cat > "$LAUNCH_AGENT" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.posthog.meepslap</string>
  <key>ProgramArguments</key><array><string>$BINARY</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><false/>
  <key>StandardErrorPath</key><string>/tmp/meepslap.log</string>
</dict></plist>
EOF

# Load and launch
launchctl load "$LAUNCH_AGENT" 2>/dev/null || true

echo ""
echo "MeepSlap installed!"
echo "  Binary: $BINARY"
echo "  Launches at login: Yes"
echo "  Logs: tail -f /tmp/meepslap.log"
echo ""
echo "To uninstall: launchctl unload $LAUNCH_AGENT && rm -rf $INSTALL_DIR $LAUNCH_AGENT"
