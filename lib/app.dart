import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/presentation/blocs/spots/spots_bloc.dart';
import 'package:spots/presentation/blocs/lists/lists_bloc.dart';
import 'package:spots/presentation/routes/app_router.dart';
import 'package:spots/injection_container.dart' as di;

class SpotsApp extends StatelessWidget {
  const SpotsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => di.sl<AuthBloc>(),
        ),
        BlocProvider<SpotsBloc>(
          create: (context) => di.sl<SpotsBloc>(),
        ),
        BlocProvider<ListsBloc>(
          create: (context) => di.sl<ListsBloc>(),
        ),
      ],
      // Use a Builder to obtain a context that is below the BlocProviders
      child: Builder(
        builder: (innerContext) {
          // If DI failed to register AuthBloc (e.g., backend init failed),
          // lazily register a fallback AuthBloc to keep the app running.
          AuthBloc? authBloc;
          try {
            authBloc = BlocProvider.of<AuthBloc>(innerContext);
          } catch (_) {
            // no-op; will create a fallback below
          }
          if (authBloc == null) {
            try {
              authBloc = di.sl<AuthBloc>();
            } catch (_) {}
          }
          return MaterialApp.router(
            title: 'SPOTS',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            debugShowCheckedModeBanner: false,
            routerConfig: AppRouter.build(authBloc: authBloc ?? di.sl<AuthBloc>()),
          );
        },
      ),
    );
  }
}
