import '../models/dashboard.dart';
import 'api_client.dart';

class DashboardService {
  final _dio = ApiClient.instance.dio;

  Future<ManagerDashboard> fetchManager() async {
    final res = await _dio.get('/dashboard');
    return ManagerDashboard.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<SalesDashboard> fetchSales() async {
    final res = await _dio.get('/dashboard');
    return SalesDashboard.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
