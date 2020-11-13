// import 'read/reader.dart';
// import 'utils/main.dart';
// import 'write/command.dart';

// class NonBlockingCommandResult {
//   int status;
//   Iterable<String> parameters;
// }

// class Operator {
//   final _receiveTimeout = Duration(seconds: 2);

//   Sink<int> _sink;
//   Stream<ReaderEvent> _stream;
//   Operator(this._sink, this._stream);

//   Future<NonBlockingCommandResult> executeNonBlocking(Command cmd) async {
//     final data = _buildCommand(cmd.code, cmd.parameters);
//     data.forEach((b) {
//       _sink.add(b);
//     });

//     final event = await _stream.first.timeout(_receiveTimeout);
//     if (event.ack) {}
//   }

//   Iterable<int> _buildCommand(String name, Iterable<String> parameters) {
//     final payloadBuilder = BytesBuilder().addString(name);

//     parameters.forEach((parameter) {
//       payloadBuilder
//           .addString(parameter.length.toString().padLeft(3, '0'))
//           .addString(parameter);
//     });

//     payloadBuilder.addByte2(Byte.ETB);

//     final payload = payloadBuilder.build();
//     final crc = _frameBuider.compute(payload);
//     final bytes = BytesBuilder()
//         .addByte2(Byte.SYN)
//         .addBytes(payload)
//         .addBytes(crc)
//         .build();

//     return bytes;
//   }
// }