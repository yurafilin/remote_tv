/// Brand-independent remote keys.
///
/// Every [RemoteDriver] maps the subset it supports to its own wire format,
/// so the remote UI can be rendered from a driver's capabilities alone.
enum RemoteKey {
  power,
  home,
  back,
  up,
  down,
  left,
  right,
  ok,
  volumeUp,
  volumeDown,
  mute,
  playPause,
  rewind,
  fastForward,
  replay,
  info,
}
