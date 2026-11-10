// Compile-time switches set with `--dart-define` (see codemagic.yaml at the repo root).

/// True for App Store / Google Play builds (`--dart-define=RATTIL_STORE=true`).
/// Hides features that need a hosted server which is not live yet (account sync).
const bool kStoreBuild = bool.fromEnvironment('RATTIL_STORE');
