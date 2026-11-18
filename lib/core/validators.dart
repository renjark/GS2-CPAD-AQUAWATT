/// Validadores de formulário (funções puras, testáveis).
class Validators {
  const Validators._();

  static final RegExp _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+');
  static final RegExp _phone = RegExp(r'\(?\d{2}\)?\s?9?\d{4}[-\s]?\d{4}');
  static final RegExp _cpf = RegExp(r'\d{3}\.?\d{3}\.?\d{3}-?\d{2}');

  /// Detecta e-mail, telefone ou CPF digitados em texto livre.
  static bool containsPersonalData(String text) =>
      _email.hasMatch(text) || _phone.hasMatch(text) || _cpf.hasMatch(text);

  static String? requiredChoice(Object? value, {String message = 'Selecione uma opção.'}) =>
      value == null ? message : null;

  static String? description(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Descreva a ocorrência.';
    if (text.length < 10) {
      return 'Use ao menos 10 caracteres para a equipe entender o problema.';
    }
    if (text.length > 280) return 'Máximo de 280 caracteres.';
    if (containsPersonalData(text)) {
      return 'Não inclua dados pessoais (e-mail, telefone ou CPF).';
    }
    return null;
  }

  /// Nota opcional da decisão humana.
  static String? optionalNote(String? value) {
    final text = (value ?? '').trim();
    if (text.length > 200) return 'Máximo de 200 caracteres.';
    if (containsPersonalData(text)) {
      return 'Não inclua dados pessoais (e-mail, telefone ou CPF).';
    }
    return null;
  }

  static String? numberInRange(
    String? value, {
    required double min,
    required double max,
    required String label,
  }) {
    final text = (value ?? '').trim().replaceAll(',', '.');
    if (text.isEmpty) return 'Informe $label.';
    final number = double.tryParse(text);
    if (number == null) return 'Digite um número válido.';
    if (number < min || number > max) {
      return '$label deve estar entre ${min.toStringAsFixed(0)} e ${max.toStringAsFixed(0)}.';
    }
    return null;
  }

  static double parseNumber(String value) =>
      double.parse(value.trim().replaceAll(',', '.'));
}
