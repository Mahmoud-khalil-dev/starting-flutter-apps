import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// An in-test Dio transport. [respond] decides every answer; nothing goes
/// to the network.
class StubAdapter implements HttpClientAdapter {
  StubAdapter(this.respond);

  final Future<ResponseBody> Function(RequestOptions options) respond;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(Object? data, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

Future<ResponseBody> Function(RequestOptions) failWith(DioExceptionType type) =>
    (options) => Future<ResponseBody>.error(
      DioException(requestOptions: options, type: type),
    );
