import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../analyzer/session_store.dart';
import '../config/guardian_config.dart';
import '../models/events.dart';
import 'collector.dart';

Map<String, String> _headersToMap(HttpHeaders headers) {
  final out = <String, String>{};
  headers.forEach((name, values) {
    out[name] = values.join(', ');
  });
  return out;
}

/// Intercepts dart:io HTTP traffic via [HttpOverrides].
///
/// Records method, URL, status, duration, and truncated bodies.
class NetworkCollector implements GuardianCollector {
  HttpOverrides? _previous;

  @override
  void start(SessionStore store, GuardianConfig config) {
    _previous = HttpOverrides.current;
    HttpOverrides.global = _GuardianHttpOverrides(store, _previous);
  }

  @override
  void stop() {
    HttpOverrides.global = _previous;
  }
}

class _GuardianHttpOverrides extends HttpOverrides {
  _GuardianHttpOverrides(this.store, this.previous);

  final SessionStore store;
  final HttpOverrides? previous;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client =
        previous?.createHttpClient(context) ?? super.createHttpClient(context);
    return _TrackingHttpClient(client, store);
  }
}

/// Thin decorator around [HttpClient] that instruments request lifecycles.
class _TrackingHttpClient implements HttpClient {
  _TrackingHttpClient(this._client, this._store);

  final HttpClient _client;
  final SessionStore _store;

  Future<HttpClientRequest> _track(
    String method,
    Uri url,
    Future<HttpClientRequest> future,
  ) async {
    final event = NetworkEvent(
      method: method.toUpperCase(),
      url: url.toString(),
      startTime: DateTime.now(),
    );
    _store.addNetwork(event);
    try {
      final request = await future;
      return _TrackingRequest(request, event);
    } catch (e) {
      event
        ..endTime = DateTime.now()
        ..error = e.toString();
      rethrow;
    }
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      _track(method, url, _client.openUrl(method, url));

  @override
  Future<HttpClientRequest> open(
    String method,
    String host,
    int port,
    String path,
  ) {
    final url = Uri(host: host, port: port, path: path);
    return _track(method, url, _client.open(method, host, port, path));
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('POST', url);

  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl('PUT', url);

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl('DELETE', url);

  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl('HEAD', url);

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl('PATCH', url);

  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      open('GET', host, port, path);

  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      open('POST', host, port, path);

  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      open('PUT', host, port, path);

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      open('DELETE', host, port, path);

  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      open('HEAD', host, port, path);

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      open('PATCH', host, port, path);

  @override
  bool get autoUncompress => _client.autoUncompress;
  @override
  set autoUncompress(bool v) => _client.autoUncompress = v;
  @override
  Duration? get connectionTimeout => _client.connectionTimeout;
  @override
  set connectionTimeout(Duration? v) => _client.connectionTimeout = v;
  @override
  Duration get idleTimeout => _client.idleTimeout;
  @override
  set idleTimeout(Duration v) => _client.idleTimeout = v;
  @override
  int? get maxConnectionsPerHost => _client.maxConnectionsPerHost;
  @override
  set maxConnectionsPerHost(int? v) => _client.maxConnectionsPerHost = v;
  @override
  String? get userAgent => _client.userAgent;
  @override
  set userAgent(String? v) => _client.userAgent = v;

  @override
  void addCredentials(
          Uri url, String realm, HttpClientCredentials credentials) =>
      _client.addCredentials(url, realm, credentials);

  @override
  void addProxyCredentials(String host, int port, String realm,
          HttpClientCredentials credentials) =>
      _client.addProxyCredentials(host, port, realm, credentials);

  @override
  set authenticate(
          Future<bool> Function(Uri url, String scheme, String? realm)? f) =>
      _client.authenticate = f;

  @override
  set authenticateProxy(
          Future<bool> Function(
                  String host, int port, String scheme, String? realm)?
              f) =>
      _client.authenticateProxy = f;

  @override
  set badCertificateCallback(
          bool Function(X509Certificate cert, String host, int port)?
              callback) =>
      _client.badCertificateCallback = callback;

  @override
  void close({bool force = false}) => _client.close(force: force);

  @override
  set connectionFactory(
          Future<ConnectionTask<Socket>> Function(
                  Uri url, String? proxyHost, int? proxyPort)?
              f) =>
      _client.connectionFactory = f;

  @override
  set findProxy(String Function(Uri url)? f) => _client.findProxy = f;

  @override
  set keyLog(Function(String line)? callback) => _client.keyLog = callback;
}

class _TrackingRequest implements HttpClientRequest {
  _TrackingRequest(this._request, this._event);

  final HttpClientRequest _request;
  final NetworkEvent _event;
  final BytesBuilder _sent = BytesBuilder(copy: false);

  @override
  Future<HttpClientResponse> close() async {
    final bytes = _sent.takeBytes();
    if (bytes.isNotEmpty) {
      _event.requestSizeBytes = bytes.length;
      _event.requestBody = _truncateUtf8(bytes);
    }
    _event.requestHeaders = _headersToMap(_request.headers);
    try {
      final response = await _request.close();
      return _TrackingResponse(response, _event);
    } catch (e) {
      _event
        ..endTime = DateTime.now()
        ..error = e.toString();
      rethrow;
    }
  }

  @override
  void add(List<int> data) {
    _sent.add(data);
    _request.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _request.addError(error, stackTrace);

  @override
  Future addStream(Stream<List<int>> stream) {
    final splitter = StreamTransformer<List<int>, List<int>>.fromHandlers(
      handleData: (data, sink) {
        _sent.add(data);
        sink.add(data);
      },
    );
    return _request.addStream(stream.transform(splitter));
  }

  @override
  void write(Object? obj) {
    final text = obj?.toString() ?? '';
    _sent.add(encoding.encode(text));
    _request.write(obj);
  }

  @override
  void writeAll(Iterable objects, [String separator = '']) =>
      write(objects.join(separator));

  @override
  void writeCharCode(int charCode) {
    _sent.add([charCode]);
    _request.writeCharCode(charCode);
  }

  @override
  void writeln([Object? obj = '']) => write('${obj ?? ''}\n');

  @override
  HttpHeaders get headers => _request.headers;
  @override
  Encoding get encoding => _request.encoding;
  @override
  set encoding(Encoding value) => _request.encoding = value;
  @override
  bool get bufferOutput => _request.bufferOutput;
  @override
  set bufferOutput(bool value) => _request.bufferOutput = value;
  @override
  int get contentLength => _request.contentLength;
  @override
  set contentLength(int value) => _request.contentLength = value;
  @override
  List<Cookie> get cookies => _request.cookies;
  @override
  Future<HttpClientResponse> get done => close();
  @override
  Future flush() => _request.flush();
  @override
  bool get followRedirects => _request.followRedirects;
  @override
  set followRedirects(bool value) => _request.followRedirects = value;
  @override
  int get maxRedirects => _request.maxRedirects;
  @override
  set maxRedirects(int value) => _request.maxRedirects = value;
  @override
  String get method => _request.method;
  @override
  bool get persistentConnection => _request.persistentConnection;
  @override
  set persistentConnection(bool value) =>
      _request.persistentConnection = value;
  @override
  Uri get uri => _request.uri;
  @override
  HttpConnectionInfo? get connectionInfo => _request.connectionInfo;
  @override
  abort([Object? exception, StackTrace? stackTrace]) =>
      _request.abort(exception, stackTrace);
}

class _TrackingResponse extends StreamView<List<int>>
    implements HttpClientResponse {
  _TrackingResponse(HttpClientResponse response, NetworkEvent event)
      : _response = response,
        super(_capture(response, event));

  final HttpClientResponse _response;

  static Stream<List<int>> _capture(
    HttpClientResponse response,
    NetworkEvent event,
  ) {
    final builder = BytesBuilder(copy: false);
    return response.transform(
      StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (data, sink) {
          builder.add(data);
          sink.add(data);
        },
        handleError: (e, st, sink) {
          event
            ..endTime = DateTime.now()
            ..error = e.toString();
          sink.addError(e, st);
        },
        handleDone: (sink) {
          final bytes = builder.takeBytes();
          event
            ..endTime = DateTime.now()
            ..statusCode = response.statusCode
            ..responseSizeBytes = bytes.length
            ..responseBody = _truncateUtf8(bytes, maxChars: 4000)
            ..responseHeaders = _headersToMap(response.headers);
          sink.close();
        },
      ),
    );
  }

  @override
  X509Certificate? get certificate => _response.certificate;
  @override
  HttpClientResponseCompressionState get compressionState =>
      _response.compressionState;
  @override
  HttpConnectionInfo? get connectionInfo => _response.connectionInfo;
  @override
  int get contentLength => _response.contentLength;
  @override
  List<Cookie> get cookies => _response.cookies;
  @override
  Future<Socket> detachSocket() => _response.detachSocket();
  @override
  HttpHeaders get headers => _response.headers;
  @override
  bool get isRedirect => _response.isRedirect;
  @override
  bool get persistentConnection => _response.persistentConnection;
  @override
  String get reasonPhrase => _response.reasonPhrase;
  @override
  Future<HttpClientResponse> redirect(
          [String? method, Uri? url, bool? followLoops]) =>
      _response.redirect(method, url, followLoops);
  @override
  List<RedirectInfo> get redirects => _response.redirects;
  @override
  int get statusCode => _response.statusCode;
}

String? _truncateUtf8(List<int> bytes, {int maxChars = 2000}) {
  if (bytes.isEmpty) return null;
  try {
    final text = utf8.decode(bytes, allowMalformed: true);
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars)}…';
  } catch (_) {
    return '<binary ${bytes.length} bytes>';
  }
}
