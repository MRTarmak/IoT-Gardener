import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/provisioning_result.dart';
import 'device_provisioning_datasource.dart';

class DeviceProvisioningDatasourceImpl implements DeviceProvisioningDatasource {
  static const String deviceApIp = '192.168.4.1';
  static const int devicePort = 80;

  @override
  Future<ProvisioningResult> sendWifiCredentials({
    required String ssid,
    required String password,
  }) async {
    final uri = Uri.http('$deviceApIp:$devicePort', '/configure');
    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'ssid': ssid, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return ProvisioningResult.success;
      } else {
        return ProvisioningResult.deviceError;
      }
    } catch (_) {
      return ProvisioningResult.connectionFailed;
    }
  }

  @override
  Future<bool> isDeviceReachable() async {
    final uri = Uri.http('$deviceApIp:$devicePort', '/ping');
    try {
      final response =
          await http.get(uri).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
