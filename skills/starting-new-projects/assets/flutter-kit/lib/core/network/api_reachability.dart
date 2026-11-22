import 'package:dio/dio.dart';

const probeTimeout = Duration(seconds: 5);

/// A plain client for the probe: no auth, no retry, 5 s timeouts.
Dio createProbeDio() => Dio(
  BaseOptions(
    connectTimeout: probeTimeout,
    receiveTimeout: probeTimeout,
    sendTimeout: probeTimeout,
  ),
);

/// True when our own API answers at all. A HEAD on the base URL is enough:
/// any status, 404 included, proves the backend is reachable, not only the
/// internet.
Future<bool> apiReachable(Dio dio, String url) async {
  try {
    await dio.head<void>(url, options: Options(validateStatus: (_) => true));
    return true;
  } on DioException {
    return false;
  }
}
