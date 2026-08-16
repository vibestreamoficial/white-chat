/// Converte valores de tempo salvos no Firestore/RTDB para [DateTime].
///
/// Firestore devolve `Timestamp` (nao `DateTime`) ao ler documentos e o
/// Realtime Database devolve string ISO-8601. Este helper aceita ambos,
/// alem de `DateTime` puro.
DateTime? tsToDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  try {
    final dt = value.toDate();
    if (dt is DateTime) return dt;
  } catch (_) {}
  return null;
}
