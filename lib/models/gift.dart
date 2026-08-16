/// Gift e carrossel "coletar" com timer (igual print do Kwai).
class Gift {
  final String id;
  final String name;
  final String emoji;
  final int price; // em moedas do app
  final int multiplier; // ex.: x3
  final Duration remaining; // timer do carrossel

  const Gift({
    required this.id,
    required this.name,
    this.emoji = '🎁',
    this.price = 0,
    this.multiplier = 1,
    this.remaining = const Duration(minutes: 1),
  });
}

/// Itens do carrossel "Aquecimento grátis para o streamer!" com timers
/// 00:47, 02:48, 07:48, 27:48 conforme o print de referencia.
const List<Gift> kGiftCarousel = [
  Gift(id: 'g1', name: 'Gift Básico', emoji: '❤️', price: 1, multiplier: 3,
      remaining: Duration(minutes: 0, seconds: 47)),
  Gift(id: 'g2', name: 'Gift Média', emoji: '😍', price: 5, multiplier: 3,
      remaining: Duration(minutes: 2, seconds: 48)),
  Gift(id: 'g3', name: 'Gift Grande', emoji: '🎉', price: 10, multiplier: 3,
      remaining: Duration(minutes: 7, seconds: 48)),
  Gift(id: 'g4', name: 'Gift Supremo', emoji: '👑', price: 50, multiplier: 3,
      remaining: Duration(minutes: 27, seconds: 48)),
];

String formatGiftTimer(Duration d) {
  final m = d.inMinutes.toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// Timer de live "03:14" + viewers "K 98" + valor "R$15" (overlay do print).
String formatLiveClock(Duration d) {
  final h = d.inHours;
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  if (h > 0) {
    return '${h.toString().padLeft(2, '0')}:$m:$s';
  }
  return '$m:$s';
}
