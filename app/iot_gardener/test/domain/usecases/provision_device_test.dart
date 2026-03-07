import 'package:flutter_test/flutter_test.dart';
import 'package:iot_gardener/domain/entities/provisioning_result.dart';
import 'package:iot_gardener/domain/repositories/device_provisioning_repository.dart';
import 'package:iot_gardener/domain/usecases/provision_device.dart';

class MockDeviceProvisioningRepository implements DeviceProvisioningRepository {
  ProvisioningResult result;
  MockDeviceProvisioningRepository(this.result);

  @override
  Future<ProvisioningResult> sendWifiCredentials({required String ssid, required String password}) async {
    return result;
  }

  @override
  Future<bool> isDeviceReachable() async => true;
}

void main() {
  group('ProvisionDevice usecase', () {
    test('returns success when repository returns success', () async {
      final repo = MockDeviceProvisioningRepository(ProvisioningResult.success);
      final usecase = ProvisionDevice(repo);
      final res = await usecase(ssid: 'test', password: '1234');
      expect(res, ProvisioningResult.success);
    });

    test('returns deviceError when repository returns deviceError', () async {
      final repo = MockDeviceProvisioningRepository(ProvisioningResult.deviceError);
      final usecase = ProvisionDevice(repo);
      final res = await usecase(ssid: 'test', password: '1234');
      expect(res, ProvisioningResult.deviceError);
    });

    test('returns connectionFailed when repository returns connectionFailed', () async {
      final repo = MockDeviceProvisioningRepository(ProvisioningResult.connectionFailed);
      final usecase = ProvisionDevice(repo);
      final res = await usecase(ssid: 'test', password: '1234');
      expect(res, ProvisioningResult.connectionFailed);
    });
  });
}
