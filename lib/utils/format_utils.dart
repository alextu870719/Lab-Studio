String formatVolume(double volume) {
  String formatted = volume.toStringAsFixed(3);
  if (formatted.endsWith('.000')) {
    return formatted.substring(0, formatted.length - 4);
  }
  while (formatted.endsWith('0') && formatted.contains('.')) {
    formatted = formatted.substring(0, formatted.length - 1);
  }
  if (formatted.endsWith('.')) {
    formatted = formatted.substring(0, formatted.length - 1);
  }
  return formatted;
}