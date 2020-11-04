library pinpad;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:pinpad/utils/utils.dart';

enum ReaderState {
  Initial,
  Payload,
  CRC1,
  CRC2,
}

class ReaderTransformer implements StreamTransformer<Uint8List, String> {
  final _controller = StreamController<String>();
  final _payload = List<int>();
  var _state = ReaderState.Initial;
  int _crc1;

  @override
  Stream<String> bind(Stream<Uint8List> stream) {
    stream.listen((bytes) {
      while (bytes.isNotEmpty) {
        var b = bytes[0];
        switch (this._state) {
          case ReaderState.Initial:
            if (b == Byte.CAN.toInt()) {
              // Do nothing. Just skip the byte.
            } else if (b != Byte.SYN.toInt()) {
              _controller.sink.addError(
                  "Protocol violation. Expecting byte SYN (0x16), ACK (0x06) or NAK (0x15");
            } else {
              this._state = ReaderState.Payload;
            }
            bytes = bytes.sublist(1);
            break;
          case ReaderState.Payload:
            var index = bytes.indexOf(Byte.ETB.toInt());
            if (index >= 0) {
              _payload.addAll(bytes.sublist(0, index));
              bytes = bytes.sublist(index + 1);
              _state = ReaderState.CRC1;
            } else {
              _payload.addAll(bytes);
              bytes = bytes.sublist(bytes.length);
            }
            break;
          case ReaderState.CRC1:
            _crc1 = b;
            bytes = bytes.sublist(1);
            _state = ReaderState.CRC2;
            break;
          case ReaderState.CRC2:
            bytes = bytes.sublist(1);

            final crc =
                crc16(Uint8List.fromList(_payload + [Byte.ETB.toInt()]));
            if (crc[0] != _crc1 || crc[1] != b) {
              _controller.sink.addError('Invalid checksum');
            } else {
              final text = ascii.decode(_payload);
              _controller.sink.add(text);
            }

            _payload.clear();
            _state = ReaderState.Initial;
            break;
        }
      }
    });
    return _controller.stream;
  }

  @override
  StreamTransformer<RS, RT> cast<RS, RT>() {
    return StreamTransformer.castFrom(this);
  }
}

Stream<String> readMessage(Stream<Uint8List> stream) {
  // final sc = StreamController<String>();
  // stream.listen((event) {
  //   sc.sink.add("event");
  // });
  // return sc.stream;

  // StreamTransformer<Uint8List, String>()
  return null;
}
