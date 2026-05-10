import '../widgets/login_page_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_router.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // Navigate to dashboard after successful login
          context.go(AppRoutes.dashboard);
        } else if (state is EmailVerificationRequired) {
          final email = Uri.encodeComponent(state.email);
          context.go('${AppRoutes.emailVerification}?email=$email');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(xxTinySpacing),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isWide ? 1000 : 600),
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWide ? 32 : 20,
                          vertical: isWide ? 24 : 16,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset(
                                    'assets/images/coexist-logo.png',
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.05,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Admin access to manage app configurations, users and updates.',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: AppColors.neutralTextGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'v${AppConstants.appVersion} • ${AppConstants.env}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.neutralDarkerGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 32),
                            // Right: login form
                            Expanded(
                              flex: 6,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  LoginPageForm(
                                    isLoading: isLoading,
                                    emailController: _emailController,
                                    passwordController: _passwordController,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Don\'t have an account?',
                                        style: AppTextStyles.bodyLarge,
                                      ),
                                      const SizedBox(width: tiniestSpacing),
                                      TextButton(
                                        onPressed: isLoading
                                            ? null
                                            : () => context.go(
                                                AppRoutes.register,
                                              ),
                                        child: Text(
                                          'Register Now',
                                          style: AppTextStyles.buttonLarge
                                              .copyWith(
                                                color: AppColors.primaryGreen,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
