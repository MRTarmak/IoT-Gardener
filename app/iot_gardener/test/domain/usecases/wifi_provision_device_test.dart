import 'package:flutter_test/flutter_test.dart';
import 'package:iot_gardener/domain/entities/wifi_provisioning_result.dart';
import 'package:iot_gardener/domain/repositories/wifi_provisioning_repository.dart';
import 'package:iot_gardener/domain/usecases/wifi_provision_device.dart';

class MockWifiProvisioningRepository implements WifiProvisioningRepository {
  WifiProvisioningResult result;
  MockWifiProvisioningRepository(this.result);

  @override
  Future<WifiProvisioningResult> sendWifiCredentials({required String ssid, required String password}) async {
    return result;
  }

  @override
  Future<bool> isDeviceReachable() async => true;
}

void main() {
  group('WifiProvisionDevice usecase', () {
    test('returns success when repository returns success', () async {
      final repo = MockWifiProvisioningRepository(WifiProvisioningResult.success);
      final usecase = WifiProvisionDevice(repo);
      final res = await usecase(ssid: 'test', password: '1234');
      expect(res, WifiProvisioningResult.success);
    });

    test('returns deviceError when repository returns deviceError', () async {
      final repo = MockWifiProvisioningRepository(WifiProvisioningResult.deviceError);
      final usecase = WifiProvisionDevice(repo);
      final res = await usecase(ssid: 'test', password: '1234');
      expect(res, WifiProvisioningResult.deviceError);
    });

    test('returns connectionFailed when repository returns connectionFailed', () async {
      final repo = MockWifiProvisioningRepository(WifiProvisioningResult.connectionFailed);
      final usecase = WifiProvisionDevice(repo);
      final res = await usecase(ssid: 'test', password: '1234');
      expect(res, WifiProvisioningResult.connectionFailed);
    });
  });
}
