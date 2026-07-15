int intValue(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) {
    return value.isFinite ? value.toInt() : fallback;
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double doubleValue(Object? value, {double fallback = 0}) {
  final double? parsed = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');
  return parsed != null && parsed.isFinite ? parsed : fallback;
}

String stringValue(Object? value, {String fallback = ''}) {
  final String? text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

Map<String, Object?> mapValue(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) {
    return value.map(
      (Object? key, Object? item) => MapEntry<String, Object?>(
        key.toString(),
        item,
      ),
    );
  }
  return <String, Object?>{};
}

List<Object?> listValue(Object? value) {
  return value is List<Object?> ? value : <Object?>[];
}
