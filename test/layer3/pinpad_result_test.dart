import 'package:bc108/src/layer2/exports.dart';
import 'package:bc108/src/layer3/pinpad_result.dart';
import 'package:faker/faker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class CommandResultMock extends Mock implements CommandResult {}

void main() {
  test('happy scenario', () {
    final status = faker.randomGenerator.integer(100).toStatus();
    final data = faker.lorem.sentence();

    final ppResult = PinpadResult(status, data);

    expect(ppResult.status, equals(status));
    expect(ppResult.data, equals(data));
  });
}
