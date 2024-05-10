import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<String> connect(
    String hostname, String uri, String method, String? body) async {
  Socket socket = await Socket.connect(hostname, 80);
  Completer<String> completer = Completer();
  StringBuffer? responseBodyBuffer;
  late int contentlength;
  socket.listen((data) {
    String rresponse = utf8.decode(data);
    String responseBody;
    if (responseBodyBuffer == null) {
      String response = rresponse.replaceAll('\r\n', '\n');
      List<String> parts = response.split('\n\n');
      List<String> headerLines = parts[0].split('\n');
      responseBody = parts.skip(1).join('\n\n');
      String statusLine = headerLines.first;
      List<String> statusParts = statusLine.split(' ');
      Map<String, String> headers =
          Map.fromEntries(headerLines.skip(1).map((e) {
        List<String> parts = e.split(': ');
        return MapEntry(parts[0].toLowerCase(), parts.skip(1).join(' '));
      }));
      contentlength = int.parse(headers['content-length']!);
      // statusParts[0]: http version
      int statusCode = int.parse(statusParts[1]);
      switch (statusCode) {
        success:
        case 200:
        case 404:
          break;
        case 301:
        case 302:
          if (headers['location'] == null) {
            print('no location to redirect to');
            print(headers);
            exit(1);
          }
          String rawlocation = headers['location']!;
          String location = rawlocation.split('//').last.split('/').first;
          print('redirecting to $rawlocation ($location)');
          if (rawlocation.contains('https')) {
            print('https not supported');
            exit(1);
          }
          completer.complete(connect(location, rawlocation, method, body));
          return;
        case 999:
          print('error code 999: linked-in');
          continue success;
        default:
          print(statusParts.skip(1).join(' '));
          exit(1);
      }
    } else {
      responseBody = rresponse;
    }
    (responseBodyBuffer ??= StringBuffer()).write(responseBody);
    if (utf8.encode(responseBodyBuffer.toString()).length <
        contentlength) {
      return;
    }
    completer.complete(responseBodyBuffer.toString());
  });
  StringBuffer buffer = StringBuffer();
  buffer.writeln('$method $uri HTTP/1.1\r');
  buffer.writeln('Host: $hostname\r');
  buffer.writeln('User-Agent: Tree-Http (github.com/treeplate/helpful_widgets/blob/main/http.dart)\r');
  buffer.writeln('\r');
  if (responseBodyBuffer != null) {
    buffer.writeln('$responseBodyBuffer\r');
    buffer.writeln('\r');
  }
  socket.add(utf8.encode(buffer.toString()));
  return await completer.future;
}
