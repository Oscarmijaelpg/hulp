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

import '/custom_code/widgets/index.dart';
import '/custom_code/actions/index.dart';
import '/flutter_flow/custom_functions.dart';

import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

class NequiVerificationButton extends StatefulWidget {
  const NequiVerificationButton({
    Key? key,
    this.width,
    this.height,
    required this.phoneNumber,
    required this.publicKey,
    required this.privateKey,
    required this.customerEmail,
    required this.acceptanceToken,
    required this.acceptPersonalAuth,
    this.onSuccess,
    this.onError,
    this.buttonText = 'Vincular Nequi',
    this.buttonColor,
    this.textColor,
  }) : super(key: key);

  final double? width;
  final double? height;
  final String phoneNumber;
  final String publicKey;
  final String privateKey;
  final String customerEmail;
  final String acceptanceToken;
  final String acceptPersonalAuth;
  final Future<dynamic> Function(int paymentSourceId)? onSuccess;
  final Future<dynamic> Function(String error)? onError;
  final String buttonText;
  final Color? buttonColor;
  final Color? textColor;

  @override
  _NequiVerificationButtonState createState() =>
      _NequiVerificationButtonState();
}

class _NequiVerificationButtonState extends State<NequiVerificationButton> {
  bool _isLoading = false;
  String _statusMessage = '';
  Timer? _pollingTimer;
  int _pollingAttempts = 0;
  static const int _maxPollingAttempts = 60;

  // Variable para guardar el número anterior y detectar cambios
  String _previousPhoneNumber = '';

  static String get baseUrl => FFDevEnvironmentValues().isProduction
      ? 'https://production.wompi.co/v1'
      : 'https://sandbox.wompi.co/v1';

  @override
  void initState() {
    super.initState();
    _previousPhoneNumber = widget.phoneNumber;
    print('Número inicial: ${widget.phoneNumber}');
  }

  @override
  void didUpdateWidget(NequiVerificationButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Detectar si el número cambió
    if (oldWidget.phoneNumber != widget.phoneNumber) {
      setState(() {
        _previousPhoneNumber = widget.phoneNumber;
      });
      print('Número actualizado: ${widget.phoneNumber}');
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleNequiFlow() async {
    // Validar que haya un número de teléfono
    if (widget.phoneNumber.isEmpty) {
      _showErrorSnackbar('Por favor ingresa un número de teléfono');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Iniciando tokenización...';
      _pollingAttempts = 0;
    });

    try {
      final tokenId = await _tokenizeNequi();

      if (tokenId == null) {
        throw Exception('No se pudo obtener el token de Nequi');
      }

      _showVerificationModal();
      await _startPolling(tokenId);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '';
      });

      // Extraer el mensaje del error
      String errorMessage = e.toString().replaceAll('Exception: ', '');

      if (widget.onError != null) {
        await widget.onError!(errorMessage);
      }

      if (mounted) {
        Navigator.of(context).pop();
        _showErrorSnackbar(errorMessage);
      }
    }
  }

  Future<String?> _tokenizeNequi() async {
    try {
      print('Tokenizando con número: ${widget.phoneNumber}');

      final response = await http.post(
        Uri.parse('$baseUrl/tokens/nequi'),
        headers: {
          'Authorization': 'Bearer ${widget.publicKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'phone_number': widget.phoneNumber,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data']['id'];
      } else {
        // Parsear el error de la API
        final errorData = json.decode(response.body);
        String errorMessage = 'Error al tokenizar';

        if (errorData['error'] != null) {
          if (errorData['error']['messages'] != null) {
            errorMessage = errorData['error']['messages'].toString();
          } else if (errorData['error']['message'] != null) {
            errorMessage = errorData['error']['message'];
          } else {
            errorMessage = errorData['error'].toString();
          }
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('Exception:')) {
        // Si ya es una excepción formateada, la relanzamos
        rethrow;
      }
      throw Exception('Error de conexión: Verifica tu internet');
    }
  }

  Future<String> _checkTokenStatus(String tokenId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tokens/nequi/$tokenId'),
        headers: {
          'Authorization': 'Bearer ${widget.publicKey}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['status'];
      } else {
        // Parsear el error de la API
        final errorData = json.decode(response.body);
        String errorMessage = 'Error al verificar estado';

        if (errorData['error'] != null) {
          if (errorData['error']['messages'] != null) {
            errorMessage = errorData['error']['messages'].toString();
          } else if (errorData['error']['message'] != null) {
            errorMessage = errorData['error']['message'];
          } else {
            errorMessage = errorData['error'].toString();
          }
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Error de conexión: Verifica tu internet');
    }
  }

  Future<void> _startPolling(String tokenId) async {
    _pollingTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (_pollingAttempts >= _maxPollingAttempts) {
        timer.cancel();
        setState(() {
          _isLoading = false;
          _statusMessage = '';
        });

        if (mounted) {
          Navigator.of(context).pop();
        }

        if (widget.onError != null) {
          await widget.onError!(
              'Tiempo de espera agotado. Por favor intenta de nuevo.');
        }

        _showErrorSnackbar('Tiempo de espera agotado');
        return;
      }

      _pollingAttempts++;

      try {
        final status = await _checkTokenStatus(tokenId);

        if (status == 'APPROVED') {
          timer.cancel();

          setState(() {
            _statusMessage = 'Token aprobado! Creando fuente de pago...';
          });

          final paymentSourceId = await _createPaymentSource(tokenId);

          setState(() {
            _isLoading = false;
            _statusMessage = '';
          });

          if (mounted) {
            Navigator.of(context).pop();
          }

          if (widget.onSuccess != null) {
            await widget.onSuccess!(paymentSourceId);
          }

          _showSuccessDialog(paymentSourceId);
        } else if (status == 'DECLINED' || status == 'REJECTED') {
          timer.cancel();

          setState(() {
            _isLoading = false;
            _statusMessage = '';
          });

          if (mounted) {
            Navigator.of(context).pop();
          }

          if (widget.onError != null) {
            await widget.onError!('La suscripción fue rechazada en Nequi');
          }

          _showErrorSnackbar('La suscripción fue rechazada');
        }
      } catch (e) {
        print('Error en polling: $e');
      }
    });
  }

  /// Registra la cuenta Nequi como fuente de pago.
  ///
  /// Lo hace la Edge Function `wompi`, que es la unica con la clave privada.
  /// La tokenizacion previa —los pasos `/tokens/nequi`— se queda arriba con la
  /// clave publica, que es la que corresponde.
  Future<int> _createPaymentSource(String tokenId) async {
    final respuesta = await llamarWompi({
      'accion': 'registrar_metodo_pago',
      'tipo': 'NEQUI',
      'token': tokenId,
      'acceptance_token': widget.acceptanceToken,
      'accept_personal_auth': widget.acceptPersonalAuth,
      if (widget.customerEmail.trim().isNotEmpty)
        'customer_email': widget.customerEmail.trim(),
    });

    if (respuesta['success'] == true && respuesta['paymentSourceId'] != null) {
      return respuesta['paymentSourceId'] as int;
    }

    // El resto del widget espera una excepcion con el motivo dentro.
    throw Exception(respuesta['error'] ?? 'Error al crear fuente de pago');
  }

  void _showVerificationModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Color(0xFFFF006E),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.phone_android,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Esperando verificación',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Por favor, abre tu app de Nequi y aprueba la suscripción.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 24),
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFFF006E),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    SizedBox(height: 24),
                    TextButton(
                      onPressed: () {
                        _pollingTimer?.cancel();
                        setState(() {
                          _isLoading = false;
                          _statusMessage = '';
                        });
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSuccessDialog(int paymentSourceId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  '¡Nequi vinculado!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Tu cuenta Nequi ha sido vinculada exitosamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'ID de Fuente de Pago',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      SelectableText(
                        paymentSourceId.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF006E),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                FFButtonWidget(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  text: 'Continuar',
                  options: FFButtonOptions(
                    width: double.infinity,
                    height: 50,
                    color: Color(0xFFFF006E),
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FFButtonWidget(
      onPressed: _isLoading ? null : _handleNequiFlow,
      text: widget.buttonText,
      icon: Icon(
        Icons.phone_android,
        size: 20,
      ),
      options: FFButtonOptions(
        width: widget.width ?? double.infinity,
        height: widget.height ?? 50,
        color: widget.buttonColor ?? Color(0xFFFF006E),
        textStyle: TextStyle(
          color: widget.textColor ?? Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        borderRadius: BorderRadius.circular(25),
        disabledColor: Colors.grey[400],
      ),
    );
  }
}
