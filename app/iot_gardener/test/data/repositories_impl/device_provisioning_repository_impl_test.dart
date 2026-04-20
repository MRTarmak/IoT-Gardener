import 'package:flutter_test/flutter_test.dart';
import 'package:iot_gardener/domain/entities/wifi_provisioning_result.dart';
import 'package:iot_gardener/data/repositories_impl/wifi_provisioning_repository_impl.dart';
import 'package:iot_gardener/data/datasources/wifi_provisioning_datasource.dart';

class MockWifiProvisioningDatasource implements WifiProvisioningDatasource {
  WifiProvisioningResult result;
  bool reachable;
  MockWifiProvisioningDatasource({required this.result, this.reachable = true});

  @override
  Future<WifiProvisioningResult> sendWifiCredentials({required String ssid, required String password}) async {
    return result;
  }

  @override
  Future<bool> isDeviceReachable() async => reachable;
}

void main() {
  group('WifiProvisioningRepositoryImpl', () {
    test('sendWifiCredentials returns correct result', () async {
      final datasource = MockWifiProvisioningDatasource(result: WifiProvisioningResult.success);
      final repo = WifiProvisioningRepositoryImpl(datasource);
      final res = await repo.sendWifiCredentials(ssid: 'test', password: '1234');
      expect(res, WifiProvisioningResult.success);
    });

    test('isDeviceReachable returns true', () async {
      final datasource = MockWifiProvisioningDatasource(result: WifiProvisioningResult.success, reachable: true);
      final repo = WifiProvisioningRepositoryImpl(datasource);
      final res = await repo.isDeviceReachable();
      expect(res, true);
    });

    test('isDeviceReachable returns false', () async {
      final datasource = MockWifiProvisioningDatasource(result: WifiProvisioningResult.success, reachable: false);
      final repo = WifiProvisioningRepositoryImpl(datasource);
      final res = await repo.isDeviceReachable();
      expect(res, false);
    });
  });
}
