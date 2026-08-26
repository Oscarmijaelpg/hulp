// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/backend/wompi_servidor.dart';

import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:webview_flutter/webview_flutter.dart';

class BancolombiaVerificationWidget extends StatefulWidget {
  const BancolombiaVerificationWidget({
    Key? key,
    this.width,
    this.height,
    required this.publicKey,
    required this.privateKey,
    required this.customerEmail,
    required this.acceptanceToken,
    required this.acceptPersonalAuth,
    this.onSuccess,
    this.onError,
    this.primaryColor,
    this.paymentDescription,
  }) : super(key: key);

  final double? width;
  final double? height;
  final String publicKey;
  final String privateKey;
  final String customerEmail;
  final String acceptanceToken;
  final String acceptPersonalAuth;
  final Future<dynamic> Function(
      int paymentSourceId, String bankAccountType, String lastFour)? onSuccess;
  final Future<dynamic> Function(String error)? onError;
  final Color? primaryColor;
  final String? paymentDescription;

  @override
  _BancolombiaVerificationWidgetState createState() =>
      _BancolombiaVerificationWidgetState();
}

class _BancolombiaVerificationWidgetState
    extends State<BancolombiaVerificationWidget> {
  // Estados del proceso
  bool _isLoading = false;
  String _statusMessage = '';
  String _currentStep = 'initial'; // initial, webview, polling, success
  String _debugLog = '';

  // Datos capturados
  String? _bancolombiaTokenId;
  String? _authorizationUrl;
  int? _paymentSourceId;
  String? _bankAccountType;
  String? _lastFour;

  // Polling
  Timer? _pollingTimer;
  int _pollingAttempts = 0;
  static const int _maxPollingAttempts = 60;

  // WebView
  late WebViewController _webViewController;

  static String get baseUrl => FFDevEnvironmentValues().isProduction
      ? 'https://production.wompi.co/v1'
      : 'https://sandbox.wompi.co/v1';

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Color get _primaryColor => widget.primaryColor ?? Color(0xFFFFDD00);

  void _addDebugLog(String message) {
    setState(() {
      _debugLog += '\n$message';
    });
    print(message);
  }

  // PASO 1: Crear token de Bancolombia
  Future<void> _startBancolombiaFlow() async {
    setState(() {
      _debugLog = '=== INICIANDO FLUJO BANCOLOMBIA ===';
    });

    try {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Iniciando conexión con Bancolombia...';
      });

      _addDebugLog('🚀 Creando token de Bancolombia...');
      _addDebugLog('📤 URL: $baseUrl/tokens/bancolombia_transfer');

      final publicKeyPreview = widget.publicKey.length > 30
          ? widget.publicKey.substring(0, 30)
          : widget.publicKey;
      _addDebugLog('🔑 Public Key: $publicKeyPreview...');

      final requestBody = {
        'redirect_url': 'https://hulp.com/success',
        'type_auth': 'TOKEN',
      };

      _addDebugLog('📦 Request Body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/tokens/bancolombia_transfer'),
        headers: {
          'Authorization': 'Bearer ${widget.publicKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      _addDebugLog('📡 Response Status: ${response.statusCode}');
      _addDebugLog('📡 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        _addDebugLog('✅ Parseo exitoso de respuesta');

        if (data['data'] == null) {
          throw Exception(
              'La respuesta no contiene el campo "data". Respuesta: $data');
        }

        final tokenData = data['data'] as Map<String, dynamic>;

        _bancolombiaTokenId = tokenData['id'] as String?;
        _authorizationUrl = tokenData['authorization_url'] as String?;

        _addDebugLog('✅ Token ID: $_bancolombiaTokenId');
        _addDebugLog('🔗 Authorization URL: $_authorizationUrl');

        if (_authorizationUrl != null && _authorizationUrl!.isNotEmpty) {
          _initializeWebView();
        } else {
          throw Exception('URL de autorización vacía o nula');
        }
      } else if (response.statusCode == 401) {
        throw Exception(
            '❌ ERROR 401 - Llave pública inválida\n\nVerifica:\n1. La llave pública sea correcta\n2. Empiece con "pub_test_" o "pub_prod_"\n3. Esté activa en Wompi');
      } else if (response.statusCode == 400) {
        String errorMsg = 'ERROR 400 - Solicitud inválida';

        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>;
          if (errorData.containsKey('error')) {
            errorMsg += ':\n${errorData['error']}';
          } else {
            errorMsg += ':\n${response.body}';
          }
        } catch (e) {
          errorMsg += ':\n${response.body}';
        }

        throw Exception(errorMsg);
      } else if (response.statusCode == 404) {
        throw Exception(
            'ERROR 404 - Endpoint no encontrado\n\n¿Bancolombia Transfer está habilitado en tu cuenta?');
      } else {
        // Otro error
        String errorMessage = 'Error ${response.statusCode}';

        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>;
          _addDebugLog('❌ Error Data: $errorData');

          if (errorData.containsKey('error')) {
            final error = errorData['error'];
            if (error is Map<String, dynamic>) {
              errorMessage = (error['message'] ??
                  error['reason'] ??
                  error.toString()) as String;
            } else {
              errorMessage = error.toString();
            }
          }
        } catch (e) {
          errorMessage += '\n${response.body}';
        }

        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      _addDebugLog('❌ ERROR: $e');
      _addDebugLog('❌ Stack: $stackTrace');
      _showError(e.toString());
    }
  }

  // PASO 2: Inicializar WebView
  void _initializeWebView() {
    setState(() {
      _currentStep = 'webview';
      _statusMessage = 'Cargando Bancolombia...';
      _isLoading = false;
    });

    _addDebugLog('📱 Inicializando WebView...');

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            _addDebugLog('📄 Cargando página: $url');
          },
          onPageFinished: (String url) {
            _addDebugLog('✅ Página cargada: $url');

            if (url.contains('success') ||
                url.contains('complete') ||
                url.contains('hulp.com')) {
              _addDebugLog('🎯 ¡Redirección detectada! Iniciando polling...');
              Future.delayed(Duration(seconds: 3), () {
                _startPolling();
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            _addDebugLog('❌ Error WebView: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(_authorizationUrl!));
  }

  // PASO 3: Polling
  void _startPolling() {
    if (_bancolombiaTokenId == null) {
      _showError('No hay token para verificar');
      return;
    }

    setState(() {
      _currentStep = 'polling';
      _statusMessage = 'Verificando autorización...';
      _isLoading = true;
    });

    _addDebugLog('🔄 Iniciando polling del token...');

    _pollingTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (_pollingAttempts >= _maxPollingAttempts) {
        timer.cancel();
        _showError('Tiempo de espera agotado (5 minutos)');
        return;
      }

      _pollingAttempts++;
      _addDebugLog('🔍 Polling $_pollingAttempts/$_maxPollingAttempts');

      try {
        final response = await http.get(
          Uri.parse(
              '$baseUrl/tokens/bancolombia_transfer/$_bancolombiaTokenId'),
          headers: {
            'Authorization': 'Bearer ${widget.publicKey}',
          },
        );

        _addDebugLog('📊 Polling response: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          final tokenData = data['data'] as Map<String, dynamic>;
          final status = tokenData['status'] as String;

          _addDebugLog('📊 Estado del token: $status');

          if (status == 'APPROVED') {
            timer.cancel();
            _bankAccountType = tokenData['bank_account_type'] as String? ?? '';
            _lastFour = tokenData['bank_account_last_four'] as String? ?? '';
            _addDebugLog('✅ Token APROBADO!');
            await _createPaymentSource();
          } else if (status == 'DECLINED' || status == 'VOIDED') {
            timer.cancel();
            throw Exception('Autorización rechazada o cancelada');
          } else {
            _addDebugLog('⏳ Estado: $status (esperando...)');
          }
        }
      } catch (e) {
        timer.cancel();
        _showError(e.toString());
      }
    });
  }

  // PASO 4: Crear fuente de pago
  Future<void> _createPaymentSource() async {
    try {
      setState(() {
        _statusMessage = 'Creando fuente de pago...';
      });

      _addDebugLog('💳 Creando payment source...');

      _addDebugLog('🔑 El registro lo hace la Edge Function wompi');

      // La clave privada ya no sale de la app: la tiene la Edge Function. La
      // tokenizacion previa se queda arriba, que va con la publica.
      final respuesta = await llamarWompi({
        'accion': 'registrar_metodo_pago',
        'tipo': 'BANCOLOMBIA_TRANSFER',
        'token': _bancolombiaTokenId,
        'payment_description':
            widget.paymentDescription ?? 'Pago con Bancolombia',
        'acceptance_token': widget.acceptanceToken,
        'accept_personal_auth': widget.acceptPersonalAuth,
        if (widget.customerEmail.trim().isNotEmpty)
          'customer_email': widget.customerEmail.trim(),
      });

      _addDebugLog('📡 Payment Source: ${respuesta['success']}');

      if (respuesta['success'] == true) {
        final paymentSource =
            (respuesta['fullData'] as Map?)?.cast<String, dynamic>() ?? {};

        if (respuesta['status'] == 'AVAILABLE') {
          _paymentSourceId = respuesta['paymentSourceId'] as int;
          final publicData =
              (paymentSource['public_data'] as Map?)?.cast<String, dynamic>() ??
                  {};
          _bankAccountType = publicData['bank_account_type'] as String? ?? '';
          _lastFour = publicData['bank_account_last_four'] as String? ?? '';
          _addDebugLog('✅ Payment Source creado! ID: $_paymentSourceId');
          _handleSuccess();
        } else {
          throw Exception('Payment Source status: ${respuesta['status']}');
        }
      } else {
        throw Exception(
            'Error creando payment source: ${respuesta['error']}');
      }
    } catch (e) {
      _addDebugLog('❌ Error: $e');
      _showError(e.toString());
    }
  }

  void _handleSuccess() {
    _addDebugLog('✅✅✅ ÉXITO COMPLETO!');
    _pollingTimer?.cancel();

    setState(() {
      _isLoading = false;
      _currentStep = 'success';
    });

    if (widget.onSuccess != null && _paymentSourceId != null) {
      widget.onSuccess!(
          _paymentSourceId!, _bankAccountType ?? '', _lastFour ?? '');
    }
  }

  void _showError(String error) {
    _addDebugLog('❌ MOSTRANDO ERROR: $error');
    _pollingTimer?.cancel();

    setState(() {
      _isLoading = false;
      _currentStep = 'initial';
    });

    if (widget.onError != null) {
      widget.onError!(error);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  error.replaceAll('Exception: ', ''),
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 6),
        ),
      );
    }
  }

  // UI WIDGETS
  Widget _buildInitialView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration:
                BoxDecoration(color: _primaryColor, shape: BoxShape.circle),
            child: Icon(Icons.account_balance, color: Colors.black, size: 40),
          ),
          SizedBox(height: 24),
          Text('Conectar Bancolombia',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text('Vincula tu cuenta para pagos rápidos y seguros',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          SizedBox(height: 32),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildInfoRow(Icons.lock, 'Conexión 100% segura'),
                SizedBox(height: 16),
                _buildInfoRow(Icons.flash_on, 'Pagos instantáneos'),
                SizedBox(height: 16),
                _buildInfoRow(Icons.credit_card, 'Sin comisiones'),
              ],
            ),
          ),
          SizedBox(height: 32),
          FFButtonWidget(
            onPressed: _isLoading ? null : _startBancolombiaFlow,
            text: 'Conectar con Bancolombia',
            icon: Icon(Icons.account_balance, size: 24),
            options: FFButtonOptions(
              width: double.infinity,
              height: 56,
              color: _primaryColor,
              textStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              elevation: 3,
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          SizedBox(height: 16),

          // BOTÓN DE DEBUG
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Debug Log'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _debugLog.isEmpty ? 'No hay logs todavía' : _debugLog,
                        style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cerrar'),
                    ),
                  ],
                ),
              );
            },
            child:
                Text('🐛 Ver Debug Log', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildWebView() {
    return Stack(
      children: [
        WebViewWidget(controller: _webViewController),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('✅ ¿Completaste la autorización?',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                FFButtonWidget(
                  onPressed: _isLoading ? null : _startPolling,
                  text: 'Verificar',
                  options: FFButtonOptions(
                    width: double.infinity,
                    height: 48,
                    color: Colors.green,
                    textStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 24),
          Text('Verificando...',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(_statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[600])),
          ),
          if (_currentStep == 'polling') ...[
            SizedBox(height: 20),
            Text('Intento $_pollingAttempts de $_maxPollingAttempts',
                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration:
                  BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              child: Icon(Icons.check, color: Colors.white, size: 60),
            ),
            SizedBox(height: 24),
            Text('¡Cuenta vinculada!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('Tu cuenta Bancolombia está lista',
                textAlign: TextAlign.center),
            SizedBox(height: 32),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildInfoRow(
                      Icons.account_balance, _bankAccountType ?? 'Bancolombia'),
                  if (_lastFour != null && _lastFour!.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 16),
                    _buildInfoRow(Icons.credit_card, _lastFour!),
                  ],
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 16),
                  _buildInfoRow(Icons.vpn_key, 'ID: $_paymentSourceId'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration:
              BoxDecoration(color: _primaryColor, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.black, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(fontSize: 15))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 600,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _currentStep == 'initial'
            ? _buildInitialView()
            : _currentStep == 'webview'
                ? _buildWebView()
                : _currentStep == 'polling' || _isLoading
                    ? _buildLoadingView()
                    : _currentStep == 'success'
                        ? _buildSuccessView()
                        : _buildInitialView(),
      ),
    );
  }
}
