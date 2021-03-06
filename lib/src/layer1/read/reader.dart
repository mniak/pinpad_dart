library pinpad;

import 'dart:async';
import 'dart:convert';

import '../utils/checksum.dart';
import '../utils/bytes.dart';
import 'exceptions.dart';
import 'reader_event.dart';

enum _ReaderStage {
  Initial,
  Payload,
  CRC1,
  CRC2,
}

class ReaderState {
  final List<int> payload = [];
  _ReaderStage stage;
  int crc1;

  ReaderState() {
    this.reset();
  }

  void reset() {
    this.payload.clear();
    this.stage = _ReaderStage.Initial;
  }
}

class ReaderTransformer implements StreamTransformer<int, ReaderEvent> {
  ChecksumAlgorithm _checksumAlgorithm;
  ReaderTransformer({ChecksumAlgorithm checksumAlgorithm}) {
    this._checksumAlgorithm = checksumAlgorithm ?? CRC16();
  }

  @override
  Stream<ReaderEvent> bind(Stream<int> stream) {
    final state = ReaderState();
    // ignore: close_sinks
    final controller = StreamController<ReaderEvent>();
    stream.listen(
      (data) => _processBytes(data, controller.sink, state),
      onError: (error) {
        controller.sink.addError(error);
      },
      onDone: () {
        controller.sink.close();
      },
    );
    return controller.stream;
  }

  void _processBytes(int b, StreamSink<ReaderEvent> sink, ReaderState state) {
    final byte = b.toByte();
    if (byte == Byte.EOT) {
      sink.add(ReaderEvent.aborted());
      state.reset();
      return;
    }
    switch (state.stage) {
      case _ReaderStage.Initial:
        switch (byte) {
          case Byte.ACK:
            sink.add(ReaderEvent.ack());
            break;
          case Byte.NAK:
            sink.add(ReaderEvent.nak());
            break;
          case Byte.SYN:
            state.stage = _ReaderStage.Payload;
            break;
          default:
            sink.addError(ExpectedSynException(b));
            break;
        }
        break;

      case _ReaderStage.Payload:
        if (b == Byte.ETB.toInt()) {
          if (state.payload.length == 0) {
            sink.addError(PayloadTooShortException());
            state.reset();
            break;
          }

          for (var b in state.payload) {
            if (b < 0x20 || b > 0x7f) {
              sink.addError(ByteOutOfRangeException(b));
              state.reset();
              break;
            }
          }

          state.stage = _ReaderStage.CRC1;
          break;
        }

        state.payload.add(b);
        if (state.payload.length > 1024) {
          sink.addError(PayloadTooLongException(state.payload.length));
          state.reset();
          break;
        }
        break;
      case _ReaderStage.CRC1:
        state.crc1 = b;
        state.stage = _ReaderStage.CRC2;
        break;
      case _ReaderStage.CRC2:
        final payloadWithETB = state.payload + [Byte.ETB.toInt()];
        final crcInMessage = [state.crc1, b];
        final crcIsValid =
            _checksumAlgorithm.validate(payloadWithETB, crcInMessage);
        if (!crcIsValid) {
          sink.add(ReaderEvent.badCRC());
        } else {
          final text = ascii.decode(state.payload);
          sink.add(ReaderEvent.data(text));
        }
        state.reset();
        break;
    }
  }

  @override
  StreamTransformer<RS, RT> cast<RS, RT>() {
    return StreamTransformer.castFrom(this);
  }
}

extension EventReaderExtension on Stream<int> {
  Stream<ReaderEvent> asEventReader({ChecksumAlgorithm checksumAlgorithm}) {
    return transform(ReaderTransformer(checksumAlgorithm: checksumAlgorithm));
  }
}
