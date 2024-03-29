import 'dart:async';

import 'package:chat/src/models/User.dart';
import 'package:chat/src/models/Receipt.dart';
import 'package:chat/src/services/receipt/receipt_service_contract.dart';
import 'package:rethinkdb_dart/rethinkdb_dart.dart';

class ReceiptService implements IReceiptService {
  final Connection _connection;
  final Rethinkdb r;
  final _controller = StreamController<Receipt>.broadcast();
  StreamSubscription _changefeed;

  ReceiptService(this._connection, this.r);
  @override
  dispose() {
    _changefeed?.cancel();
    _controller?.close();
  }

  @override
  Stream<Receipt> receipts(User user) {
    _startRecevingReceipts(user);
    return _controller.stream;
  }

  @override
  Future<bool> send(Receipt receipt) async {
    var data = receipt.toJson();
    Map record = await r.table('receipts').insert(data).run(_connection);
    return record['inserted'] == 1;
  }

  _startRecevingReceipts(User user) {
    _changefeed = r
        .table('receipts')
        .filter({'recipient': user.id})
        .changes({'include_initial': true})
        .run(_connection)
        .asStream()
        .cast<Feed>()
        .listen((event) {
          event
              .forEach((feedData) {
                if (feedData['new_val'] == null) return;
                final receipt = _receiptFromFeed(feedData);
                _controller.sink.add(receipt);
              })
              .catchError((err) => print(err))
              .onError((error, stackTrace) => print(error));
        });
  }

  Receipt _receiptFromFeed(feedData) {
    var data = feedData['new_val'];
    return Receipt.fromJson(data);
  }
}
