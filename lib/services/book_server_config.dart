/// Public book-server base URL — the ONE place the server address lives.
///
/// All book content (book JSONs, covers, page images) is downloaded from
/// this server over HTTPS; nothing is bundled in the app any more.
/// Change this single constant to point the app at a different server.
/// A trailing slash is fine; [BookSyncService] builds
/// `{baseUrl}/manifest.json` and `{baseUrl}/<relative-path>` from it.
///
/// NOTE: the value below is the PUBLIC URL, served over HTTPS via
/// Tailscale Funnel (tailnet taildb6449.ts.net, node ckss-mac-mini,
/// path /books). It is set but PENDING the user enabling Tailscale
/// Serve/Funnel on the tailnet — until Serve is enabled the app cannot
/// reach this URL, the sync fails silently (logged, no crash), and the
/// library shows whatever is already cached, or the empty-library message
/// on a fresh install. The local test server
/// (http://127.0.0.1:8084, loopback only) can be put back here temporarily
/// for simulator testing.
class BookServerConfig {
  static const String baseUrl = 'https://ckss-mac-mini.taildb6449.ts.net/books/';
}
