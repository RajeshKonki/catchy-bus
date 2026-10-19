import 'package:dio/dio.dart';
void main() async {
  final dio = Dio();
  try {
    final response = await dio.get('https://backend-production-19db.up.railway.app/api/bus-tracking/routes/TS-JNTUH-01');
    print(response.data);
  } catch(e) {
    print(e);
  }
}
