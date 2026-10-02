import 'package:easy_localization/easy_localization.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_text_field.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import '../../../../core/di/service_locator.dart';
import '../../business_logic/auth_cubit.dart';
import '../../business_logic/auth_state.dart';
import '../widgets/auth_layout.dart';

@RoutePage()
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().login(
        _identifierController.text.trim(),
        _passwordController.text,
      );
    }
  }

  static String? _required(String? value) =>
      value == null || value.trim().isEmpty
      ? 'common.field_required'.tr()
      : null;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthCubit>(),
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            context.router.replaceAll([
              if (state.auth.isNewUser)
                PropertyManagerProfileRoute(isOnboarding: true)
              else
                const HomeRoute(),
            ]);
          }
          if (state is AuthError) {
            AppToast.error(state.message, context: context);
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          return AuthLayout(
            title: 'auth.login_title'.tr(),
            description: 'auth.login_description'.tr(),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'auth.phone'.tr(),
                    hint: '07 00 00 00 00',
                    controller: _identifierController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(LucideIcons.phone, size: 16),
                    validator: _required,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'auth.password'.tr(),
                    hint: '••••••••',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: const Icon(LucideIcons.lock, size: 16),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'auth.show_password'.tr()
                          : 'auth.hide_password'.tr(),
                      icon: Icon(
                        _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                        size: 16,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty
                        ? 'common.field_required'.tr()
                        : null,
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'auth.sign_in'.tr(),
                    isLoading: loading,
                    expand: true,
                    onPressed: () => _submit(context),
                  ),
                  const SizedBox(height: 20),
                  const OrDivider(),
                  const SizedBox(height: 20),
                  GoogleSignInButton(
                    label: 'auth.continue_google'.tr(),
                    onPressed: loading
                        ? null
                        : () => context.read<AuthCubit>().loginWithGoogle(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('auth.no_account'.tr(), style: context.mutedText),
                      TextButton(
                        onPressed: () =>
                            context.router.push(const RegisterRoute()),
                        child: Text('auth.sign_up'.tr()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
