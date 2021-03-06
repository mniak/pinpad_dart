import 'package:bc108/src/layer2/command_request.dart';
import 'package:bc108/src/layer2/exceptions.dart';
import 'package:faker/faker.dart';
import 'package:test/test.dart';

void main() {
  test('format payload using random data', () {
    final code =
        faker.lorem.word().padRight(3, ' ').substring(0, 3).toUpperCase();
    final paramCount = faker.randomGenerator.integer(200);
    final params = faker.lorem.sentences(paramCount);

    final sut = CommandRequest(code, params);

    expect(sut.code, equals(code));
    expect(sut.parameters, equals(params));

    final expected = code +
        params
            .map((p) => (p.length % 999).toString().padLeft(3, '0') + p)
            .join();
    expect(sut.payload, equals(expected));
  });

  group('empty parameters:', () {
    test('when there are no parameters, should format as CMD', () {
      final cmd = CommandRequest("AAA", []);
      final payload = cmd.payload;
      expect("AAA", payload);
    });

    test('when there is one empty parameter, should format as CMD 000', () {
      final cmd = CommandRequest("BBB", ['']);
      expect("BBB000", cmd.payload);
    });

    test('when there are two empty parameters, should format as CMD 000 000',
        () {
      final cmd = CommandRequest("CCC", ['', '']);
      expect("CCC000000", cmd.payload);
    });
  });

  group('payload examples:', () {
    final data = [
      [
        ['1234567890'],
        '010' + '1234567890'
      ],
      [
        ['123', '456', '7890'],
        '003' + '123' + '003' + '456' + '004' + '7890'
      ],
      [
        ['1234567890', '', '12345678901234567890123456789012345'],
        '010' +
            '1234567890' +
            '000' +
            '' +
            '035' +
            '12345678901234567890123456789012345'
      ],
    ];

    data.forEach((d) {
      final parameters = d[0] as Iterable<String>;
      final expected = d[1] as String;

      test('when there is one parameter, should format accordingly', () {
        final cmd = CommandRequest("CMD", parameters);
        expect("CMD" + expected, cmd.payload);
      });
    });
  });

  group('when command has length different than 3, should throw exception', () {
    final data = [1, 2, 4, 5];
    data.forEach((length) {
      test(length, () {
        expect(() => CommandRequest("X" * length, []),
            throwsA(isA<InvalidCommandLengthException>()));
      });
    });
  });

  test('when parameter is lengthier than 999, should throw exception', () {
    expect(() => CommandRequest("CMD", ['x' * 1000]),
        throwsA(isA<ParameterTooLongException>()));
  });
}
