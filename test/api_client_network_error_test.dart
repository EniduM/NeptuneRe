import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:neptune_recyclers/services/api_client.dart';

void main() {
  test('ApiClient surfaces the underlying SocketException message', () {
    final socketException = SocketException(
      'Connection refused',
      address: InternetAddress.loopbackIPv4,
      port: 3000,
    );

    final message = ApiClient.formatNetworkError(socketException);

    expect(message, contains('Connection refused'));
    expect(message, contains('port=3000'));
  });
}
