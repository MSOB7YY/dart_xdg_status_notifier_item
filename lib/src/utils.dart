/// Utility functions for escaping and sanitizing data.

/// Escapes standard markup (e.g., &, <, >, ', ") so it is rendered literally by the desktop environment.
String escapeMarkup(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll("'", '&apos;')
      .replaceAll('"', '&quot;');
}

/// Sanitizes an icon name to ensure it's valid for D-Bus transmission.
String sanitizeIconName(String iconName) {
  // Typical icon names shouldn't have newlines or be extremely long.
  if (iconName.length > 255) {
    iconName = iconName.substring(0, 255);
  }
  return iconName.replaceAll(RegExp(r'[\r\n]'), '').trim();
}

/// Removes all XML-like tags from a string, keeping only the raw text.
String stripMarkup(String text) {
  return text.replaceAll(RegExp(r'<[^>]*>'), '');
}
