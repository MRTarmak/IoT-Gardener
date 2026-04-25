import 'package:flutter_test/flutter_test.dart';
import 'package:iot_gardener/domain/entities/wifi_provisioning_result.dart';
import 'package:iot_gardener/domain/repositories/wifi_provisioning_repository.dart';
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
  Future<List<String>?> checkConnection() async => reachable ? ['device1', 'device2'] : null;

  @override
  List<String>? parsePongPacket(String payload) => null;
}

void main() {
  group('WifiProvisioningRepositoryImpl', () {
    test('sendWifiCredentials returns correct result', () async {
      final datasource = MockWifiProvisioningDatasource(result: WifiProvisioningResult.success);
      final WifiProvisioningRepository repo = WifiProvisioningRepositoryImpl(datasource);
      final res = await repo.sendWifiCredentials(ssid: 'test', password: '1234');
      expect(res, WifiProvisioningResult.success);
    });

    test('checkConnection returns ssids when device is reachable', () async {
      final datasource = MockWifiProvisioningDatasource(result: WifiProvisioningResult.success, reachable: true);
      final WifiProvisioningRepository repo = WifiProvisioningRepositoryImpl(datasource);
      final res = await repo.checkConnection();
      expect(res, ['device1', 'device2']);
    });

    test('checkConnection returns null when device is unreachable', () async {
      final datasource = MockWifiProvisioningDatasource(result: WifiProvisioningResult.success, reachable: false);
      final WifiProvisioningRepository repo = WifiProvisioningRepositoryImpl(datasource);
      final res = await repo.checkConnection();
      expect(res, isNull);
    });
  });
}
