/// Funções puras de formatação (pt-BR) e de data, sem dependência de `intl`.

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String _two(int n) => n.toString().padLeft(2, '0');

/// Número com vírgula decimal. Ex.: `fmt(3.14159, 2)` -> `3,14`.
String fmt(double v, [int decimals = 1]) =>
    v.toStringAsFixed(decimals).replaceAll('.', ',');

/// Fração como porcentagem. Ex.: `fmtPct(0.153)` -> `+15%`.
String fmtPct(double fraction, {bool signed = true, int decimals = 0}) {
  final v = fraction * 100;
  final s = v.toStringAsFixed(decimals).replaceAll('.', ',');
  return signed && v > 0 ? '+$s%' : '$s%';
}

/// Inteiro com separador de milhar. Ex.: `fmtInt(65000)` -> `65.000`.
String fmtInt(num n) => n
    .round()
    .toString()
    .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');

String fmtDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}';

String fmtDateTime(DateTime d) => '${fmtDate(d)} ${_two(d.hour)}:${_two(d.minute)}';
