import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';
import 'package:frontend/src/l10n/app_localizations.dart';
import 'config/app_theme.dart';
import 'routing/app_router.dart';
import 'features/auth/application/locale_bloc.dart';
import 'features/auth/application/auth_bloc.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create the router once or use a builder to handle refresh
    final router = createRouter(context.read<AuthBloc>());

    return BlocBuilder<LocaleBloc, LocaleState>(
      builder: (context, state) {
        return ToastificationWrapper(
          child: MaterialApp.router(
            title: 'Local Eats',
            locale: state.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            routerConfig: router,
          ),
        );
      },
    );
  }
}
