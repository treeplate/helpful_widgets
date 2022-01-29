import 'dart:async';
import 'dart:io';

import 'dart:isolate';

List<String> logs = [];
void log(String name, String msg) {
  if (logs.contains(name)) {
    File("$name.log").writeAsStringSync(msg + "\n", mode: FileMode.append);
  } else {
    logs.add(name);
    File("$name.log").writeAsStringSync(msg + "\n", mode: FileMode.write);
  }
}

class SRPWrapper {
  SRPWrapper.raw(this.sps, this.name, [ReceivePort? _rp]) {
    if (_rp != null) rp = _rp;
  }
  factory SRPWrapper(ReceivePort rp, String name) {
    return SRPWrapper.raw([], name, rp);
  }
  factory SRPWrapper.fromSendPort(SendPort sp, String name) {
    ReceivePort rp = ReceivePort();
    SRPWrapper result = SRPWrapper.raw([sp], name, rp);
    result.send(rp.sendPort);
    return result;
  }
  List<SendPort> sps = [];
  final String name;
  Completer<void> moreItems = Completer();
  List<MapEntry> items = [];
  List<Object?> sent = [];
  set rp(ReceivePort x) {
    x.listen((x) {
      if (x.value is SendPort) {
        sps.add(x.value);
        for (Object? thingToSend in sent) {
          x.value.send(MapEntry(name, thingToSend));
        }
        return;
      }
      log("SRPW-$name", "${x.key} sent ${x.value}");
      items.add(x);
      moreItems.complete();
      moreItems = Completer();
    });
  }

  void send(Object? thingToSend) {
    log("SRPW-$name", "Sending $thingToSend");
    sent.add(thingToSend);
    for (SendPort sp in sps) {
      sp.send(MapEntry(name, thingToSend));
    }
  }

  Future<T> readItem<T>() async {
    if (items.isEmpty) await moreItems.future;
    MapEntry result = items.first;
    items.removeAt(0);
    if (result.value is T) {
      return result.value;
    } else {
      throw FormatException(
          "SRPW-$name: Expected a $T, got $result (which is a ${result.runtimeType})");
    }
  }
}
