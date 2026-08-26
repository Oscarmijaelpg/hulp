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

class DaviplataVerificationWidget extends StatefulWidget {
  const DaviplataVerificationWidget({
    Key? key,
    this.width,
    this.height,
    required this.publicKey,
    required this.privateKey,
    required this.acceptanceToken,
    required this.acceptPersonalAuth,
    this.onSuccess,
    this.onError,
    this.primaryColor,
    this.backgroundColor,
  }) : super(key: key);

  final double? width;
  final double? height;
  final String publicKey;
  final String privateKey;
  final String acceptanceToken;
  final String acceptPersonalAuth;
  final Future<dynamic> Function(int paymentSourceId, String tokenId)?
      onSuccess;
  final Future<dynamic> Function(String error)? onError;
  final Color? primaryColor;
  final Color? backgroundColor;

  @override
  _DaviplataVerificationWidgetState createState() =>
      _DaviplataVerificationWidgetState();
}

class _DaviplataVerificationWidgetState
    extends State<DaviplataVerificationWidget> {
  // Controladores de texto
  final TextEditingController _documentNumberController =
      TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // Variables de estado
  bool _isLoading = false;
  String _statusMessage = '';
  String _currentStep = 'form'; // form, otp, success

  // Variables de tokens y URLs
  String? _daviplataTOKEN;
  String? _otpAuthToken;
  String? _otpSendUrl;
  String? _otpValidateUrl;
  String? _tokenStatus;
  int? _paymentSourceId;

  // Tipo de documento seleccionado
  String _selectedDocType = 'CC';
  final List<String> _docTypes = ['CC', 'CE', 'NIT', 'TI', 'PPN'];

  // Colores
  Color get _primaryColor => widget.primaryColor ?? Color(0xFF0033A0);
  Color get _bgColor => widget.backgroundColor ?? Colors.white;

  // URLs base
  static String get baseUrl => FFDevEnvironmentValues().isProduction
      ? 'https://production.wompi.co/v1'
      : 'https://sandbox.wompi.co/v1';

  @override
  void dispose() {
    _documentNumberController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ==================== PASO 1: CREAR TOKEN DAVIPLATA ====================
  Future<void> _createDaviToken() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Creando token Daviplata...';
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tokens/daviplata'),
        headers: {
          'Authorization': 'Bearer ${widget.publicKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'type_document': _selectedDocType,
          'number_document': _documentNumberController.text.trim(),
          'product_number': _phoneNumberController.text.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        setState(() {
          _daviplataTOKEN = data['data']['id'];
          _tokenStatus = data['data']['status'];
          _otpAuthToken = data['data']['url_services']['token'];
          _otpSendUrl = data['data']['url_services']['code_otp_send'];
          _otpValidateUrl = data['data']['url_services']['code_otp_validate'];
        });

        print('Token creado: $_daviplataTOKEN');
        print('Status: $_tokenStatus');

        // Automáticamente enviar OTP
        await _sendOTPCode();
      } else {
        _handleError(response, 'Error al crear token');
      }
    } catch (e) {
      _showError('Error de conexión: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ==================== PASO 2: ENVIAR CÓDIGO OTP ====================
  Future<void> _sendOTPCode() async {
    setState(() {
      _statusMessage = 'Enviando código OTP...';
    });

    try {
      final response = await http.post(
        Uri.parse(_otpSendUrl!),
        headers: {
          'Authorization': 'Bearer $_otpAuthToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Actualizar el token de autorización
        setState(() {
          _otpAuthToken = data['data']['authorization']['access_token'];
          _tokenStatus = data['data']['subscription']['status'];
          _currentStep = 'otp';
          _isLoading = false;
          _statusMessage = '';
        });

        print('OTP enviado. Nuevo auth token actualizado');
        _showSuccessSnackbar('Código OTP enviado a tu Daviplata');
      } else {
        _handleError(response, 'Error al enviar OTP');
      }
    } catch (e) {
      _showError('Error al enviar OTP: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ==================== PASO 3: VALIDAR CÓDIGO OTP ====================
  Future<void> _validateOTPCode() async {
    if (_otpController.text.trim().length != 6) {
      _showError('El código OTP debe tener 6 dígitos');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Validando código OTP...';
    });

    try {
      final response = await http.post(
        Uri.parse(_otpValidateUrl!),
        headers: {
          'Authorization': 'Bearer $_otpAuthToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'code': _otpController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['data']['subscription']['status'];

        if (status == 'APPROVED') {
          setState(() {
            _tokenStatus = 'APPROVED';
            _statusMessage = 'Token aprobado! Creando fuente de pago...';
          });

          print('Token APROBADO: $_daviplataTOKEN');

          // Crear fuente de pago automáticamente
          await _createPaymentSource();
        } else if (status == 'PENDING') {
          // Código incorrecto
          final faultstring = data['data']['subscription']['steps']
              ?['ConfirmIntention']?[0]?['faultstring'];

          setState(() {
            _isLoading = false;
            _statusMessage = '';
          });

          if (faultstring == 'OTP_INVALIDO') {
            _showError('Código OTP incorrecto. Intenta de nuevo.');
          } else {
            _showError(faultstring ?? 'Error al validar OTP');
          }
        }
      } else {
        _handleError(response, 'Error al validar OTP');
      }
    } catch (e) {
      _showError('Error al validar OTP: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ==================== PASO 4: CREAR FUENTE DE PAGO ====================
  Future<void> _createPaymentSource() async {
    setState(() {
      _statusMessage = 'Creando fuente de pago...';
    });

    try {
      // El registro lo hace la Edge Function `wompi`, que es la unica con la
      // clave privada. Los pasos previos —tokenizar y validar el OTP— se
      // quedan arriba: van con la clave publica y con el token que devuelve
      // el propio DaviPlata.
      //
      // El correo se manda tal cual lo escribe el usuario: su DaviPlata puede
      // estar a un correo distinto del de Hulp.
      final respuesta = await llamarWompi({
        'accion': 'registrar_metodo_pago',
        'tipo': 'DAVIPLATA',
        'token': _daviplataTOKEN,
        'acceptance_token': widget.acceptanceToken,
        'accept_personal_auth': widget.acceptPersonalAuth,
        'customer_email': _emailController.text.trim(),
      });

      if (respuesta['success'] == true) {
        setState(() {
          _paymentSourceId = respuesta['paymentSourceId'];
          _currentStep = 'success';
          _isLoading = false;
          _statusMessage = '';
        });

        print('Fuente de pago creada: $_paymentSourceId');

        // Llamar callback de éxito
        if (widget.onSuccess != null) {
          await widget.onSuccess!(_paymentSourceId!, _daviplataTOKEN!);
        }

        _showSuccessSnackbar('¡Daviplata vinculado exitosamente!');
      } else {
        _showError(respuesta['error']?.toString() ??
            'Error al crear fuente de pago');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showError('Error al crear fuente de pago: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ==================== FUNCIONES AUXILIARES ====================
  bool _validateForm() {
    if (_documentNumberController.text.trim().isEmpty) {
      _showError('Por favor ingresa tu número de documento');
      return false;
    }
    if (_phoneNumberController.text.trim().isEmpty) {
      _showError('Por favor ingresa tu número de Daviplata');
      return false;
    }
    if (_emailController.text.trim().isEmpty) {
      _showError('Por favor ingresa tu correo electrónico');
      return false;
    }
    if (!_emailController.text.contains('@')) {
      _showError('Por favor ingresa un correo válido');
      return false;
    }
    return true;
  }

  void _handleError(http.Response response, String defaultMessage) {
    try {
      final errorData = json.decode(response.body);
      String errorMessage = defaultMessage;

      if (errorData['error'] != null) {
        if (errorData['error']['messages'] != null) {
          errorMessage = errorData['error']['messages'].toString();
        } else if (errorData['error']['message'] != null) {
          errorMessage = errorData['error']['message'];
        }
      } else if (errorData['message'] != null) {
        errorMessage = errorData['message'];
      }

      _showError(errorMessage);
    } catch (e) {
      _showError(defaultMessage);
    }

    setState(() {
      _isLoading = false;
    });

    if (widget.onError != null) {
      widget.onError!(defaultMessage);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
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

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _currentStep = 'form';
      _daviplataTOKEN = null;
      _otpAuthToken = null;
      _tokenStatus = null;
      _paymentSourceId = null;
      _documentNumberController.clear();
      _phoneNumberController.clear();
      _emailController.clear();
      _otpController.clear();
      _isLoading = false;
      _statusMessage = '';
    });
  }

  // ==================== UI WIDGETS ====================
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 'otp':
        return _buildOTPStep();
      case 'success':
        return _buildSuccessStep();
      default:
        return _buildFormStep();
    }
  }

  // PASO 1: FORMULARIO DE DATOS
  Widget _buildFormStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vincular Daviplata',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Ingresa tus datos',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 32),

          // Tipo de documento
          Text(
            'Tipo de documento',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDocType,
                isExpanded: true,
                padding: EdgeInsets.symmetric(horizontal: 16),
                items: _docTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedDocType = newValue;
                    });
                  }
                },
              ),
            ),
          ),
          SizedBox(height: 20),

          // Número de documento
          Text(
            'Número de documento',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _documentNumberController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Ej: 1234567890',
              prefixIcon: Icon(Icons.badge_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor, width: 2),
              ),
            ),
          ),
          SizedBox(height: 20),

          // Número de Daviplata
          Text(
            'Número de Daviplata',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _phoneNumberController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: InputDecoration(
              hintText: 'Ej: 3001234567',
              prefixIcon: Icon(Icons.phone_android),
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor, width: 2),
              ),
            ),
          ),
          SizedBox(height: 20),

          // Email
          Text(
            'Correo electrónico',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'ejemplo@correo.com',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor, width: 2),
              ),
            ),
          ),
          SizedBox(height: 32),

          // Status message
          if (_statusMessage.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Botón continuar
          FFButtonWidget(
            onPressed: _isLoading ? null : _createDaviToken,
            text: 'Continuar',
            icon: Icon(Icons.arrow_forward, size: 20),
            options: FFButtonOptions(
              width: double.infinity,
              height: 54,
              color: _primaryColor,
              textStyle: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              borderRadius: BorderRadius.circular(27),
              disabledColor: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  // PASO 2: INGRESAR CÓDIGO OTP
  Widget _buildOTPStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.lock_outline,
            color: _primaryColor,
            size: 40,
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Código de verificación',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Ingresa el código OTP enviado a tu Daviplata',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 32),

        // Campo OTP
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '------',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primaryColor, width: 2),
            ),
          ),
        ),
        SizedBox(height: 24),

        // Status message
        if (_statusMessage.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

        // Botón validar
        FFButtonWidget(
          onPressed: _isLoading ? null : _validateOTPCode,
          text: 'Validar código',
          options: FFButtonOptions(
            width: double.infinity,
            height: 54,
            color: _primaryColor,
            textStyle: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            borderRadius: BorderRadius.circular(27),
            disabledColor: Colors.grey[400],
          ),
        ),
        SizedBox(height: 16),

        // Botón reenviar
        TextButton.icon(
          onPressed: _isLoading ? null : _sendOTPCode,
          icon: Icon(Icons.refresh),
          label: Text('Reenviar código'),
          style: TextButton.styleFrom(
            foregroundColor: _primaryColor,
          ),
        ),

        // Botón cancelar
        TextButton(
          onPressed: _isLoading ? null : _resetForm,
          child: Text(
            'Cancelar',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  // PASO 3: ÉXITO
  Widget _buildSuccessStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check,
            color: Colors.white,
            size: 60,
          ),
        ),
        SizedBox(height: 24),
        Text(
          '¡Daviplata vinculado!',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Tu cuenta Daviplata ha sido vinculada exitosamente.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 32),

        // Información del token y fuente de pago
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.credit_card, color: _primaryColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'ID de Fuente de Pago',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              SelectableText(
                _paymentSourceId?.toString() ?? 'N/A',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.vpn_key, color: _primaryColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Token ID',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              SelectableText(
                _daviplataTOKEN ?? 'N/A',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(height: 32),

        // Botón finalizar
        FFButtonWidget(
          onPressed: _resetForm,
          text: 'Vincular otra cuenta',
          icon: Icon(Icons.add, size: 20),
          options: FFButtonOptions(
            width: double.infinity,
            height: 54,
            color: _primaryColor,
            textStyle: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            borderRadius: BorderRadius.circular(27),
          ),
        ),
      ],
    );
  }
}
