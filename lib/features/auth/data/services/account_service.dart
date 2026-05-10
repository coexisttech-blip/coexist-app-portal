import 'package:coexist_app_portal/core/constants/app_constants.dart';
import 'package:dio/dio.dart';

class AccountService {
  static String get _deleteAccountUrl =>
      '${AppConstants.baseUrl.replaceFirst('.supabase.co', '.functions.supabase.co')}/delete_account';

  static Future<bool> deleteAccount(String userId) async {
    try {
      final dio = Dio();
      final response = await dio.post(
        _deleteAccountUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${AppConstants.apiKey}',
          },
        ),
        data: {'user_id': userId},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
