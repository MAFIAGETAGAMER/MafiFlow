/// Category IDs remain language independent; labels are translated in the UI.
const otherCategory = 'Otro';

List<String> otherLast(Iterable<String> categories) {
  final unique = categories.toSet();
  return [
    ...unique.where((value) => value != otherCategory),
    if (unique.contains(otherCategory)) otherCategory,
  ];
}

int compareCategoryEntries(MapEntry<String, double> a, MapEntry<String, double> b) {
  if (a.key == otherCategory && b.key != otherCategory) return 1;
  if (b.key == otherCategory && a.key != otherCategory) return -1;
  return b.value.compareTo(a.value);
}
