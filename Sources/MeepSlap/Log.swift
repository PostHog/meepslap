import Foundation

/// Unbuffered logging to stderr so output is visible from GUI apps
/// (and captured by the LaunchAgent's StandardErrorPath → /tmp/meepslap.log).
func log(_ message: String) {
    fputs("[MeepSlap] \(message)\n", stderr)
}
