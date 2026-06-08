/// Popular streaming apps a remote can launch directly.
enum AppShortcut { netflix, youtube, primeVideo, disneyPlus, spotify }

/// Capability interface for drivers that can launch apps on the TV.
/// Drivers that support it `implements RemoteDriver, AppLauncher`.
abstract interface class AppLauncher {
  /// Apps this device can launch.
  Set<AppShortcut> get apps;

  /// Launch [app] on the TV.
  Future<void> launchApp(AppShortcut app);
}
