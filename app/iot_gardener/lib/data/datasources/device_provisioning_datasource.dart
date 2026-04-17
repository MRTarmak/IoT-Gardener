import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../domain/entities/provisioning_result.dart';

class DeviceProvisioningDatasource {
  static const String deviceApIp = '192.168.4.1';
  static const int devicePort = 8888;

  Future<ProvisioningResult> sendWifiCredentials({
    required String ssid,
    required String password,
  }) async {
    RawDatagramSocket? socket;

    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

      final completer = Completer<ProvisioningResult>();

      socket.listen((RawSocketEvent event) {
        if (event != RawSocketEvent.read || completer.isCompleted) {
          return;
        }

        final packet = socket?.receive();
        if (packet == null) {
          return;
        }

        final isExpectedSender =
            packet.address.address == deviceApIp && packet.port == devicePort;
        if (!isExpectedSender) {
          return;
        }

        final response = utf8.decode(packet.data);

        if (response.trim() == "OK") {
          completer.complete(ProvisioningResult.success);
        } else {
          completer.complete(ProvisioningResult.deviceError);
        }
      });

      final message = "WIFI_PROVISION\r\nSSID=$ssid\r\nPASS=$password\r\n";
      final List<int> data = utf8.encode(message);

      final sentBytes = socket.send(
        data,
        InternetAddress(deviceApIp),
        devicePort,
      );
      if (sentBytes <= 0) {
        return ProvisioningResult.connectionFailed;
      }

      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => ProvisioningResult.connectionFailed,
      );
    } catch (_) {
      return ProvisioningResult.connectionFailed;
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
              packet.address.address == deviceApIp && packet.port == devicePort;
          final payload = utf8.decode(packet.data).trim();
          final isExpectedPayload = payload == 'PONG';

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

      const probeMessage = 'PING\r\n';
      final sentBytes = socket.send(
        utf8.encode(probeMessage),
        InternetAddress(deviceApIp),
        devicePort,
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
