import 'package:aquawatt/core/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('descrição da ocorrência', () {
    test('vazia é inválida', () {
      expect(Validators.description('  '), isNotNull);
    });

    test('curta demais é inválida', () {
      expect(Validators.description('vazou'), isNotNull);
    });

    test('longa demais é inválida', () {
      expect(Validators.description('a' * 281), isNotNull);
    });

    test('rejeita e-mail, telefone e CPF', () {
      expect(Validators.description('ligue para joao@email.com sobre o vazamento'), isNotNull);
      expect(Validators.description('me chame no (11) 91234-5678 por favor'), isNotNull);
      expect(Validators.description('meu cpf 123.456.789-09 para contato'), isNotNull);
    });

    test('texto válido passa', () {
      expect(Validators.description('Vazamento constante na calçada da rua'), isNull);
    });
  });

  group('número em intervalo', () {
    String? check(String? v) =>
        Validators.numberInRange(v, min: 5, max: 50, label: 'o percentual');

    test('vazio, texto e fora do intervalo são inválidos', () {
      expect(check(''), isNotNull);
      expect(check('abc'), isNotNull);
      expect(check('4'), isNotNull);
      expect(check('51'), isNotNull);
    });

    test('aceita vírgula decimal e limites', () {
      expect(check('12,5'), isNull);
      expect(check('5'), isNull);
      expect(check('50'), isNull);
      expect(Validators.parseNumber('12,5'), 12.5);
    });
  });

  test('escolha obrigatória', () {
    expect(Validators.requiredChoice(null), isNotNull);
    expect(Validators.requiredChoice('x'), isNull);
  });
}
