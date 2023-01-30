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

/// Class for making between-isolate communication easier.
class SRPWrapper {
  /// Internal constructor.
  SRPWrapper.raw(this.sp, this.name, [ReceivePort? _rp]) {
    if (_rp != null) rp = _rp;
  }

  /// For creator of isolate. Make a recieve port, give the isolate the send port, and give this constructor the recieve port. This class is expecting a send port to be sent to the receive port.
  factory SRPWrapper(ReceivePort rp, String name) {
    return SRPWrapper.raw(null, name, rp);
  }

  /// For created isolate. Pass this constructor the send port you were given at the start. This class will send the creator a send port.
  factory SRPWrapper.fromSendPort(SendPort sp, String name) {
    ReceivePort rp = ReceivePort();
    SRPWrapper result = SRPWrapper.raw(sp, name, rp);
    result.send(rp.sendPort);
    return result;
  }

  SendPort? sp;
  final String name;
  Completer<void> moreItems = Completer();
  List<MapEntry> items = [];
  List<Object?> sent = [];
  set rp(ReceivePort x) {
    x.listen((x) {
      if (x.value is SendPort && sp == null) {
        sp = x.value;
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

  /// Sends [thingToSend] to the connected isolate, if there is one.
  void send(Object? thingToSend) {
    log("SRPW-$name", "Sending $thingToSend");
    sent.add(thingToSend);
    if (sp != null) {
      sp!.send(MapEntry(name, thingToSend));
    }
  }

  // Waits for an item to be recieved, makes sure it's of type T, and returns it.
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
