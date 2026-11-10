import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';

import '/backend/schema/structs/index.dart';
import '/backend/transiciones_solicitud.dart';

import '/backend/supabase/supabase.dart';

import '/auth/base_auth_user_provider.dart';

import '/main.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/lat_lng.dart';
import '/flutter_flow/place.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'serialization_util.dart';

import '/index.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  BaseAuthUser? initialUser;
  BaseAuthUser? user;
  bool showSplashImage = true;
  String? _redirectLocation;

  /// Determines whether the app will refresh and build again when a sign
  /// in or sign out happens. This is useful when the app is launched or
  /// on an unexpected logout. However, this must be turned off when we
  /// intend to sign in/out and then navigate or perform any actions after.
  /// Otherwise, this will trigger a refresh and interrupt the action(s).
  bool notifyOnAuthChange = true;

  bool get loading => user == null || showSplashImage;
  bool get loggedIn => user?.loggedIn ?? false;
  bool get initiallyLoggedIn => initialUser?.loggedIn ?? false;
  bool get shouldRedirect => loggedIn && _redirectLocation != null;

  String getRedirectLocation() => _redirectLocation!;
  bool hasRedirect() => _redirectLocation != null;
  void setRedirectLocationIfUnset(String loc) => _redirectLocation ??= loc;
  void clearRedirectLocation() => _redirectLocation = null;

  /// Mark as not needing to notify on a sign in / out when we intend
  /// to perform subsequent actions (such as navigation) afterwards.
  void updateNotifyOnAuthChange(bool notify) => notifyOnAuthChange = notify;

  void update(BaseAuthUser newUser) {
    final shouldUpdate =
        user?.uid == null || newUser.uid == null || user?.uid != newUser.uid;
    initialUser ??= newUser;
    user = newUser;
    // Refresh the app on auth change unless explicitly marked otherwise.
    // No need to update unless the user has changed.
    if (notifyOnAuthChange && shouldUpdate) {
      notifyListeners();
    }
    // Once again mark the notifier as needing to update on auth change
    // (in order to catch sign in / out events).
    updateNotifyOnAuthChange(true);
  }

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      errorBuilder: (context, state) =>
          appStateNotifier.loggedIn ? SplashLoginWidget() : LoginWidget(),
      routes: [
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) =>
              appStateNotifier.loggedIn ? SplashLoginWidget() : LoginWidget(),
        ),
        FFRoute(
          name: MiperfilWidget.routeName,
          path: MiperfilWidget.routePath,
          builder: (context, params) => MiperfilWidget(),
        ),
        FFRoute(
          name: RegistrodsdsWidget.routeName,
          path: RegistrodsdsWidget.routePath,
          builder: (context, params) => RegistrodsdsWidget(),
        ),
        FFRoute(
          name: DatospersonalesWidget.routeName,
          path: DatospersonalesWidget.routePath,
          builder: (context, params) => DatospersonalesWidget(),
        ),
        FFRoute(
          name: Registro1Widget.routeName,
          path: Registro1Widget.routePath,
          builder: (context, params) => Registro1Widget(),
        ),
        FFRoute(
          name: BienvenidoWidget.routeName,
          path: BienvenidoWidget.routePath,
          builder: (context, params) => BienvenidoWidget(),
        ),
        FFRoute(
          name: Restablecercontrasea2Widget.routeName,
          path: Restablecercontrasea2Widget.routePath,
          builder: (context, params) => Restablecercontrasea2Widget(),
        ),
        FFRoute(
          name: RestablecercontraseaWidget.routeName,
          path: RestablecercontraseaWidget.routePath,
          builder: (context, params) => RestablecercontraseaWidget(),
        ),
        FFRoute(
          name: RecuperarcontraseaWidget.routeName,
          path: RecuperarcontraseaWidget.routePath,
          builder: (context, params) => RecuperarcontraseaWidget(),
        ),
        FFRoute(
          name: Restablecercontrasea3Widget.routeName,
          path: Restablecercontrasea3Widget.routePath,
          builder: (context, params) => Restablecercontrasea3Widget(
            email: params.getParam('email', ParamType.String),
          ),
        ),
        FFRoute(
          name: RestablecerConCodigoWidget.routeName,
          path: RestablecerConCodigoWidget.routePath,
          builder: (context, params) => RestablecerConCodigoWidget(
            email: params.getParam('email', ParamType.String),
          ),
        ),
        FFRoute(
          name: LoginWidget.routeName,
          path: LoginWidget.routePath,
          builder: (context, params) => LoginWidget(),
        ),
        FFRoute(
          name: SolicitudesWidget.routeName,
          path: SolicitudesWidget.routePath,
          builder: (context, params) => SolicitudesWidget(),
        ),
        FFRoute(
          name: TerminosycondicionesWidget.routeName,
          path: TerminosycondicionesWidget.routePath,
          builder: (context, params) => TerminosycondicionesWidget(),
        ),
        FFRoute(
          name: PoliticasDePrivacidadWidget.routeName,
          path: PoliticasDePrivacidadWidget.routePath,
          builder: (context, params) => PoliticasDePrivacidadWidget(),
        ),
        FFRoute(
          name: SoporteWidget.routeName,
          path: SoporteWidget.routePath,
          builder: (context, params) => SoporteWidget(),
        ),
        FFRoute(
          name: Registro2Widget.routeName,
          path: Registro2Widget.routePath,
          builder: (context, params) => Registro2Widget(),
        ),
        FFRoute(
          name: Registro3Widget.routeName,
          path: Registro3Widget.routePath,
          builder: (context, params) => Registro3Widget(),
        ),
        FFRoute(
          name: TerminosycondicionesCopyCopyWidget.routeName,
          path: TerminosycondicionesCopyCopyWidget.routePath,
          builder: (context, params) => TerminosycondicionesCopyCopyWidget(),
        ),
        FFRoute(
          name: ContratoBaseWidget.routeName,
          path: ContratoBaseWidget.routePath,
          builder: (context, params) => ContratoBaseWidget(),
        ),
        FFRoute(
          name: Registro6Widget.routeName,
          path: Registro6Widget.routePath,
          builder: (context, params) => Registro6Widget(),
        ),
        FFRoute(
          name: Registro4Widget.routeName,
          path: Registro4Widget.routePath,
          builder: (context, params) => Registro4Widget(),
        ),
        FFRoute(
          name: Registro5Widget.routeName,
          path: Registro5Widget.routePath,
          builder: (context, params) => Registro5Widget(),
        ),
        FFRoute(
          name: VerificacionPageWidget.routeName,
          path: VerificacionPageWidget.routePath,
          builder: (context, params) => VerificacionPageWidget(
            estado: params.getParam(
              'estado',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: DesempenioPageWidget.routeName,
          path: DesempenioPageWidget.routePath,
          builder: (context, params) => DesempenioPageWidget(),
        ),
        FFRoute(
          name: SplashLoginWidget.routeName,
          path: SplashLoginWidget.routePath,
          builder: (context, params) => SplashLoginWidget(),
        ),
        FFRoute(
          name: DesactivarCuentaWidget.routeName,
          path: DesactivarCuentaWidget.routePath,
          builder: (context, params) => DesactivarCuentaWidget(),
        ),
        FFRoute(
          name: SolicitudesCopyWidget.routeName,
          path: SolicitudesCopyWidget.routePath,
          builder: (context, params) => usaTransicionesSprint3
              ? SolicitudesWidget()
              : SolicitudesCopyWidget(),
        ),
        FFRoute(
          name: ChatWidget.routeName,
          path: ChatWidget.routePath,
          builder: (context, params) => ChatWidget(
            servicio: params.getParam<VwSolicitudesServiciosCompletaRow>(
              'servicio',
              ParamType.SupabaseRow,
            ),
          ),
        ),
        FFRoute(
          name: CambiarContrasenaWidget.routeName,
          path: CambiarContrasenaWidget.routePath,
          requireAuth: true,
          builder: (context, params) => CambiarContrasenaWidget(),
        ),
        FFRoute(
          name: Registro1EditWidget.routeName,
          path: Registro1EditWidget.routePath,
          builder: (context, params) => Registro1EditWidget(),
        ),
        FFRoute(
          name: Registro2EditWidget.routeName,
          path: Registro2EditWidget.routePath,
          builder: (context, params) => Registro2EditWidget(),
        ),
        FFRoute(
          name: Registro3EditWidget.routeName,
          path: Registro3EditWidget.routePath,
          builder: (context, params) => Registro3EditWidget(),
        )
      ].map((r) => r.toRoute(appStateNotifier)).toList(),
      observers: [routeObserver],
    );

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
  void goNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : goNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void pushNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : pushNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void safePop() {
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}

extension GoRouterExtensions on GoRouter {
  AppStateNotifier get appState => AppStateNotifier.instance;
  void prepareAuthEvent([bool ignoreRedirect = false]) =>
      appState.hasRedirect() && !ignoreRedirect
          ? null
          : appState.updateNotifyOnAuthChange(false);
  bool shouldRedirect(bool ignoreRedirect) =>
      !ignoreRedirect && appState.hasRedirect();
  void clearRedirectLocation() => appState.clearRedirectLocation();
  void setRedirectLocationIfUnset(String location) =>
      appState.updateNotifyOnAuthChange(false);
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
    StructBuilder<T>? structBuilder,
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
      structBuilder: structBuilder,
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
        name: name,
        path: path,
        redirect: (context, state) {
          if (appStateNotifier.shouldRedirect) {
            final redirectLocation = appStateNotifier.getRedirectLocation();
            appStateNotifier.clearRedirectLocation();
            return redirectLocation;
          }

          if (requireAuth && !appStateNotifier.loggedIn) {
            appStateNotifier.setRedirectLocationIfUnset(state.uri.toString());
            return '/login';
          }
          return null;
        },
        pageBuilder: (context, state) {
          fixStatusBarOniOS16AndBelow(context);
          final ffParams = FFParameters(state, asyncParams);
          final page = ffParams.hasFutures
              ? FutureBuilder(
                  future: ffParams.completeFutures(),
                  builder: (context, _) => builder(context, ffParams),
                )
              : builder(context, ffParams);
          final child = appStateNotifier.loading
              ? Container(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  child: Center(
                    child: Image.asset(
                      'assets/images/Hulp_(Facebook_Post_(Square))_(1).png',
                      width: 250.0,
                      height: 250.0,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : page;

          final transitionInfo = state.transitionInfo;
          return transitionInfo.hasTransition
              ? CustomTransitionPage(
                  key: state.pageKey,
                  name: state.name,
                  child: child,
                  transitionDuration: transitionInfo.duration,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          PageTransition(
                    type: transitionInfo.transitionType,
                    duration: transitionInfo.duration,
                    reverseDuration: transitionInfo.duration,
                    alignment: transitionInfo.alignment,
                    child: child,
                  ).buildTransitions(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ),
                )
              : MaterialPage(
                  key: state.pageKey, name: state.name, child: child);
        },
        routes: routes,
      );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() => TransitionInfo(hasTransition: false);
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}
