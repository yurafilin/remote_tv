/// Capability interface for drivers that can type into the TV's focused text
/// field. Drivers that support it `implements RemoteDriver, TextInput`; the UI
/// shows a keyboard affordance only when the connected driver `is TextInput`.
abstract interface class TextInput {
  /// Push [text] into the focused field on the TV.
  Future<void> sendText(String text);

  /// Confirm / submit the field (Enter / Done / Search).
  Future<void> submit();
}
