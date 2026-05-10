import 'package:coexist_app_portal/core/constants/app_constants.dart';
import 'package:coexist_app_portal/core/theme/app_theme.dart';
import 'package:coexist_app_portal/core/utils/app_router.dart';
import 'package:coexist_app_portal/di/injection_container.dart' as di;
import 'package:coexist_app_portal/features/app_configs/presentation/bloc/app_config_bloc.dart';
import 'package:coexist_app_portal/features/app_configs/presentation/bloc/app_config_events.dart';
import 'package:coexist_app_portal/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:coexist_app_portal/features/auth/presentation/bloc/auth_event.dart';
import 'package:coexist_app_portal/features/events/presentation/bloc/event_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  usePathUrlStrategy();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final packageInfo = await PackageInfo.fromPlatform();
  AppConstants.appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

  if (AppConstants.env.isEmpty ||
      AppConstants.baseUrl.isEmpty ||
      AppConstants.apiKey.isEmpty) {
    throw StateError(
      'App config missing. Build with --dart-define-from-file=config/<env>.json '
      '(ENV, SUPABASE_URL and SUPABASE_ANON_KEY must be set).',
    );
  }

  await Supabase.initialize(
    url: AppConstants.baseUrl,
    anonKey: AppConstants.apiKey,
    debug: true,
  );

  // Initialize dependencies
  await di.init();

  // Listen for Supabase auth state changes, especially password recovery deep links
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final event = data.event;
    if (event == AuthChangeEvent.passwordRecovery) {
      appRouter.go('/set-new-password');
    }
  });

  runApp(const EcoFootprintPortal());
}

class EcoFootprintPortal extends StatelessWidget {
  const EcoFootprintPortal({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<AuthBloc>()..add(const CheckAuthEvent()),
        ),
        BlocProvider(
          create: (_) =>
              di.sl<AppConfigBloc>()..add(const CheckEnabledConfigsEvent()),
        ),
        BlocProvider(create: (_) => di.sl<EventBloc>()),
      ],
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: MaterialApp.router(
          title: AppConstants.appName,
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
