/// Display helpers shared by the statistics widgets.
library;

/// `m:ss`, or `h:mm:ss` past the hour.
String formatDuration(int totalSeconds) {
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:$seconds';
  }
  return '$minutes:$seconds';
}

/// A 0–1 ratio as a whole percentage.
String formatPercent(double ratio) => '${(ratio * 100).round()}%';

/// Fills a translated template's `{n}` placeholder.
String fill(String template, Object value) =>
    template.replaceAll('{n}', '$value');
