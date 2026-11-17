# Updates

Headroom updates itself with [Sparkle](https://sparkle-project.org). It verifies every update before
installing it.

- **Automatic checks.** About once a day. A found update shows an **Update Available** banner at the
  top of the panel. Click **Install Update** to open the update window, which lists what's new in that
  version. Closing the banner hides it and the menu bar's update dot. Until Headroom restarts, or you
  answer the update in the window **Check for Updates…** opens, no automatic check runs. After a
  restart, the next check that finds the update shows the banner again.
- **Manual check.** **Check for Updates…** in the dashboard's **⋯** menu or in **Settings → General → Updates**.
- **Turn it off.** **Settings → General → Updates → Check Automatically** stops the background checks.
  Manual checks still work.
- Headroom shows a Dock icon while the update window is open, then hides it again.

## Where updates come from

- Builds come from Headroom's [GitHub releases](https://github.com/EvenDog/headroom/releases). The
  appcast is `https://github.com/EvenDog/headroom/releases/latest/download/appcast.xml`, attached to
  the newest release.
- Each download is notarized by Apple and signed with Headroom's update key. The app refuses anything
  that doesn't match.
- Only release builds update. Local developer builds don't. Headroom 1.0.0 and 1.0.1 had no updater;
  install 1.0.2 or later by hand once.

## Publishing a release

1. Build: `CODESIGN_IDENTITY=… OPENUSAGE_VERSION=<version> NOTARY_KEYCHAIN_PROFILE=headroom-notary script/release.sh`
   writes `dist/Headroom-<version>.dmg` and `dist/appcast.xml`, signed with the `headroom` Sparkle key
   in your login Keychain.
2. Publish: `script/publish_release.sh <version> <notes-file>` creates the GitHub Release with both files.
