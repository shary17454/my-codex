import 'dart:io';

Future<void> main(List<String> args) async {
  final root = args.isNotEmpty ? Directory(args[0]) : Directory.current;
  final port = args.length > 1 ? int.parse(args[1]) : 5005;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);

  print('Serving ${root.path} on http://0.0.0.0:$port');

  await for (final request in server) {
    final path = Uri.decodeComponent(request.uri.path);
    final relativePath = path == '/' ? 'index.html' : path.substring(1);
    var file = File('${root.path}${Platform.pathSeparator}$relativePath');

    if (!await file.exists()) {
      file = File('${root.path}${Platform.pathSeparator}index.html');
    }

    final contentType = _contentType(file.path);
    request.response.headers.contentType = contentType;
    request.response.headers.set('Cache-Control', 'no-cache');
    await file.openRead().pipe(request.response);
  }
}

ContentType _contentType(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.html')) return ContentType.html;
  if (lower.endsWith('.js')) {
    return ContentType('application', 'javascript', charset: 'utf-8');
  }
  if (lower.endsWith('.css'))
    return ContentType('text', 'css', charset: 'utf-8');
  if (lower.endsWith('.json')) return ContentType.json;
  if (lower.endsWith('.png')) return ContentType('image', 'png');
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return ContentType('image', 'jpeg');
  }
  if (lower.endsWith('.svg')) return ContentType('image', 'svg+xml');
  if (lower.endsWith('.wasm')) return ContentType('application', 'wasm');
  return ContentType.binary;
}
