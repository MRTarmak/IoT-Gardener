import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../domain/entities/wifi_provisioning_result.dart';

class WifiProvisioningDatasource {
  static const String _deviceApIp = '192.168.4.1';
  static const int _devicePort = 8888;

  Future<WifiProvisioningResult> sendWifiCredentials({
    required String ssid,
    required String password,
  }) async {
    RawDatagramSocket? socket;

    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

      final completer = Completer<WifiProvisioningResult>();

      socket.listen((RawSocketEvent event) {
        if (event != RawSocketEvent.read || completer.isCompleted) {
          return;
        }

        final packet = socket?.receive();
        if (packet == null) {
          return;
        }

        final isExpectedSender =
            packet.address.address == _deviceApIp && packet.port == _devicePort;
        if (!isExpectedSender) {
          return;
        }

        final response = utf8.decode(packet.data);

        if (response.trim() == "OK") {
          completer.complete(WifiProvisioningResult.success);
        } else {
          completer.complete(WifiProvisioningResult.deviceError);
        }
      });

      final message = '$ssid\r\n$password\r\n';
      final List<int> data = utf8.encode(message);

      final sentBytes = socket.send(
        data,
        InternetAddress(_deviceApIp),
        _devicePort,
      );
      if (sentBytes <= 0) {
        return WifiProvisioningResult.connectionFailed;
      }

      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => WifiProvisioningResult.connectionFailed,
      );
    } catch (_) {
      return WifiProvisioningResult.connectionFailed;
    } finally {
      socket?.close();
    }
  }

  Future<bool> isDeviceReachable() async {
    RawDatagramSocket? socket;

    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final completer = Completer<bool>();

      socket.listen(
        (RawSocketEvent event) {
          if (event != RawSocketEvent.read) {
            return;
          }

          final packet = socket?.receive();
          if (packet == null) {
            return;
          }

          final isExpectedSender =
              packet.address.address == _deviceApIp && packet.port == _devicePort;
          final payload = utf8.decode(packet.data).trim();
          final isExpectedPayload = payload.contains('PONG');

          if (isExpectedSender && isExpectedPayload && !completer.isCompleted) {
            completer.complete(true);
          }
        },
        onError: (_) {
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      );

      const message = 'PING';
      final sentBytes = socket.send(
        utf8.encode(message),
        InternetAddress(_deviceApIp),
        _devicePort,
      );
      if (sentBytes <= 0) {
        return false;
      }

      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
    } catch (_) {
      return false;
    } finally {
      socket?.close();
    }
  }
}
