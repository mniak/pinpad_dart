import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:matcher/matcher.dart';
import 'package:pinpad/exceptions.dart';
import 'package:pinpad/receiver.dart';
import 'package:pinpad/utils/utils.dart';

class TextCRC {
  TextCRC(this.text, this.crc1, this.crc2);
  String text;
  int crc1;
  int crc2;
}

void main() {
  group('when bytes are well formatted message, should return string', () {
    final data = [
      TextCRC("OPN000", 0x77, 0x5e),
      TextCRC("AAAAAAAA", 0x9a, 0x63)
    ];
    data.forEach((d) {
      test(d.text, () {
        final streamController = StreamController<int>();
        final stream = streamController.stream.transform(ReaderTransformer());

        final bytes = BytesBuilder()
            .addByte(Byte.SYN.toInt())
            .addString(d.text)
            .addByte(Byte.ETB.toInt())
            .addBytes([d.crc1, d.crc2]).build();

        for (var b in bytes) {
          streamController.sink.add(b);
        }
        expectLater(
            stream,
            emitsInOrder([
              predicate((x) => x.isDataEvent && x.data == d.text),
            ]));

        streamController.close();
      });
    });
  });

  group('when bytes are CAN+well formatted message, should return string', () {
    final data = [
      TextCRC("OPN000", 0x77, 0x5e),
      TextCRC("AAAAAAAA", 0x9a, 0x63)
    ];
    data.forEach((d) {
      test(d.text, () {
        final streamController = StreamController<int>();
        final stream = streamController.stream.transform(ReaderTransformer());

        final bytes = BytesBuilder()
            .addByte(Byte.CAN.toInt())
            .addByte(Byte.SYN.toInt())
            .addString(d.text)
            .addByte(Byte.ETB.toInt())
            .addBytes([d.crc1, d.crc2]).build();

        for (var b in bytes) {
          streamController.sink.add(b);
        }
        expectLater(
            stream,
            emitsInOrder([
              predicate((x) => x.isDataEvent && x.data == d.text),
            ]));

        streamController.close();
      });
    });
  });

  test('when there is no bytes, should receive no string', () {
    final streamController = StreamController<int>();
    final stream = streamController.stream.transform(ReaderTransformer());
    stream.listen(expectAsync1((x) {}, count: 0));
    streamController.close();
  });

  test('when CRC is wrong, should raise error', () {
    final streamController = StreamController<int>();
    final stream = streamController.stream.transform(ReaderTransformer());

    final bytes = BytesBuilder()
        .addByte(Byte.SYN.toInt())
        .addString("ABCDEFG")
        .addByte(Byte.ETB.toInt())
        .addBytes([0x11, 0x22]).build();

    for (var b in bytes) {
      streamController.sink.add(b);
    }
    expectLater(stream, emitsError(TypeMatcher<ChecksumException>()));

    streamController.close();
  });

  group('when byte in payload section is out of range, should raise error', () {
    final data = [
      0x00,
      0x11,
      0x19,
      0x90,
      0xa0,
      0xf0,
    ];

    data.forEach((b) {
      test('0x${b.toRadixString(16)}', () {
        final streamController = StreamController<int>();
        final stream = streamController.stream.transform(ReaderTransformer());

        final bytes = BytesBuilder()
            .addByte(Byte.SYN.toInt())
            .addString("ABCD")
            .addByte(b)
            .addString("EFGH")
            .addByte(Byte.ETB.toInt())
            .addBytes([0x11, 0x22]).build();

        for (var b in bytes) {
          streamController.sink.add(b);
        }
        expectLater(stream, emitsError(TypeMatcher<ByteOutOfRangeException>()));

        streamController.close();
      });
    });
  });

  test('when payload length is 0, should raise error', () {
    final streamController = StreamController<int>();
    final stream = streamController.stream.transform(ReaderTransformer());

    final bytes = BytesBuilder()
        .addByte(Byte.SYN.toInt())
        .addByte(Byte.ETB.toInt())
        .addBytes([0x11, 0x22]).build();

    for (var b in bytes) {
      streamController.sink.add(b);
    }
    expectLater(stream, emitsError(TypeMatcher<PayloadTooShortException>()));

    streamController.close();
  });

  test('when payload length > 1024, should raise error', () {
    final streamController = StreamController<int>();
    final stream = streamController.stream.transform(ReaderTransformer());

    final bytes = BytesBuilder()
        .addByte(Byte.SYN.toInt())
        .addString('A' * 1025)
        .addByte(Byte.ETB.toInt())
        .addBytes([0x11, 0x22]).build();

    for (var b in bytes) {
      streamController.sink.add(b);
    }
    expectLater(stream, emitsError(TypeMatcher<PayloadTooLongException>()));

    streamController.close();
  });

  // test('TestReceiveACKorNAK_WhenReadByte_ShouldReturnAccordingly', () {
  //   // final data = [
  //   //   [Byte.ACK.toInt(), true, null],
  //   //   [Byte.NAK.toInt(), false, null],
  //   //   [Byte.ETB.toInt(), false, Exception()],
  //   //   ['X'.codeUnitAt(0), false, Exception()],
  //   //   [8, false, Exception()],
  //   // ];
  //   // data.forEach((d) {
  //   // int byte = d[0];
  //   // bool ack = d[1];
  //   // final error = d[2];
  //   // test('0x${byte.toRadixString(16)}', () {
  //   final streamController = StreamController<int>();
  //   final stream = streamController.stream.transform(ReaderTransformer());

  //   streamController.sink.add(byte);

  //   expectLater(stream, emitsError(error));

  //   streamController.close();
  //   //   });
  //   // });
  // });
}
