class MqttConnectionParams {
  final String host;
  final int port;
  final String clientId;
  final String topic;

  const MqttConnectionParams({
    required this.host,
    required this.port,
    required this.clientId,
    required this.topic,
  });
}
