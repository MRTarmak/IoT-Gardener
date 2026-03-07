import 'package:flutter_test/flutter_test.dart';
import 'package:iot_gardener/domain/entities/provisioning_result.dart';
import 'package:iot_gardener/data/repositories_impl/device_provisioning_repository_impl.dart';
import 'package:iot_gardener/data/datasources/device_provisioning_datasource.dart';

class MockDeviceProvisioningDatasource implements DeviceProvisioningDatasource {
  ProvisioningResult result;
  bool reachable;
  MockDeviceProvisioningDatasource({required this.result, this.reachable = true});

  @override
  Future<ProvisioningResult> sendWifiCredentials({required String ssid, required String password}) async {
    return result;
  }

  @override
  Future<bool> isDeviceReachable() async => reachable;
}

void main() {
  group('DeviceProvisioningRepositoryImpl', () {
    test('sendWifiCredentials returns correct result', () async {
      final datasource = MockDeviceProvisioningDatasource(result: ProvisioningResult.success);
      final repo = DeviceProvisioningRepositoryImpl(datasource);
      final res = await repo.sendWifiCredentials(ssid: 'test', password: '1234');
      expect(res, ProvisioningResult.success);
    });

    test('isDeviceReachable returns true', () async {
      final datasource = MockDeviceProvisioningDatasource(result: ProvisioningResult.success, reachable: true);
      final repo = DeviceProvisioningRepositoryImpl(datasource);
      final res = await repo.isDeviceReachable();
      expect(res, true);
    });

    test('isDeviceReachable returns false', () async {
      final datasource = MockDeviceProvisioningDatasource(result: ProvisioningResult.success, reachable: false);
      final repo = DeviceProvisioningRepositoryImpl(datasource);
      final res = await repo.isDeviceReachable();
      expect(res, false);
    });
  });
}
