import 'package:bc108/src/layer2/exports.dart';

import '../fields/numeric.dart';
import '../fields/composite.dart';
import '../mapper.dart';
import '../handler.dart';

class TableLoadInitRequest {
  int network;
  int timestamp;
}

class Mapper extends RequestResponseMapper<TableLoadInitRequest, void> {
  static final _requestField = new CompositeField([
    NumericField(2),
    NumericField(10),
  ]);

  @override
  Command mapRequest(TableLoadInitRequest request) {
    return Command("TLI", [
      _requestField.serialize([
        request.network,
        request.timestamp,
      ])
    ]);
  }

  @override
  void mapResponse(CommandResult result) {}
}

class TableLoadInitFactory {
  RequestHandler<TableLoadInitRequest, void> tableLoadInit(Operator o) =>
      RequestHandler.fromMapper(o, Mapper());
}