import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

Future<void> storeTokens(
    {required String accessToken, required String refreshToken}) async {
  await storage.write(key: "refreshToken", value: refreshToken);
  await storage.write(key: "accessToken", value: accessToken);
  print('Tokens stored securely');
}

Future<Map<String, String>?> getTokens() async {
  final accessToken = await storage.read(key: "accessToken");
  final refreshToken = await storage.read(key: "refreshToken");
  if (accessToken == null && refreshToken == null) {
    return null;
  }
  return {
    "accessToken": accessToken ?? "",
    "refreshToken": refreshToken ?? "",
  };
}

Future<void> deleteToken() async {
  await storage.delete(key: "accessToken");
  await storage.delete(key: "refreshToken");
  print('Token deleted');
}
