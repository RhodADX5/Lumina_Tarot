import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// --- CONFIGURACIÓN ---
String getBaseUrl() {
  if (kIsWeb) return 'https://lumina-api.onrender.com'; // TU URL DE RENDER
  if (Platform.isAndroid) return 'http://10.0.2.2:8000';
  return 'http://127.0.0.1:8000';
}

final String currentDeviceId = const Uuid().v4();

void main() {
  runApp(const LuminaApp());
}

class LuminaApp extends StatelessWidget {
  const LuminaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lumina Tarot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37),
          secondary: Color(0xFFB900FF),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        ),
        textTheme: GoogleFonts.cinzelTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: const Color(0xFFD4AF37),
        ),
      ),
      home: const TarotScreen(),
    );
  }
}

class TarotScreen extends StatefulWidget {
  const TarotScreen({super.key});

  @override
  State<TarotScreen> createState() => _TarotScreenState();
}

class _TarotScreenState extends State<TarotScreen> {
  final TextEditingController _questionController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _readingResult;
  
  // --- ESTADO DE USUARIO ---
  Map<String, dynamic>? _user; // Si es null, es invitado. Si tiene datos, está logueado.

  final List<Map<String, String>> _deck = [
    {"name": "El Loco", "image": "https://upload.wikimedia.org/wikipedia/commons/9/90/RWS_Tarot_00_Fool.jpg"},
    {"name": "El Mago", "image": "https://upload.wikimedia.org/wikipedia/commons/d/de/RWS_Tarot_01_Magician.jpg"},
    {"name": "La Sacerdotisa", "image": "https://upload.wikimedia.org/wikipedia/commons/8/88/RWS_Tarot_02_High_Priestess.jpg"},
    {"name": "La Emperatriz", "image": "https://upload.wikimedia.org/wikipedia/commons/d/d2/RWS_Tarot_03_Empress.jpg"},
    {"name": "El Emperador", "image": "https://upload.wikimedia.org/wikipedia/commons/c/c3/RWS_Tarot_04_Emperor.jpg"},
    {"name": "El Hierofante", "image": "https://upload.wikimedia.org/wikipedia/commons/8/8d/RWS_Tarot_05_Hierophant.jpg"},
    {"name": "Los Enamorados", "image": "https://upload.wikimedia.org/wikipedia/commons/3/3a/TheLovers.jpg"},
    {"name": "El Carro", "image": "https://upload.wikimedia.org/wikipedia/commons/9/9b/RWS_Tarot_07_Chariot.jpg"},
    {"name": "La Fuerza", "image": "https://upload.wikimedia.org/wikipedia/commons/f/f5/RWS_Tarot_08_Strength.jpg"},
    {"name": "El Ermitaño", "image": "https://upload.wikimedia.org/wikipedia/commons/4/4d/RWS_Tarot_09_Hermit.jpg"},
    {"name": "La Rueda de la Fortuna", "image": "https://upload.wikimedia.org/wikipedia/commons/3/3c/RWS_Tarot_10_Wheel_of_Fortune.jpg"},
    {"name": "La Justicia", "image": "https://upload.wikimedia.org/wikipedia/commons/e/e0/RWS_Tarot_11_Justice.jpg"},
    {"name": "El Colgado", "image": "https://upload.wikimedia.org/wikipedia/commons/2/2b/RWS_Tarot_12_Hanged_Man.jpg"},
    {"name": "La Muerte", "image": "https://upload.wikimedia.org/wikipedia/commons/d/d7/RWS_Tarot_13_Death.jpg"},
    {"name": "La Templanza", "image": "https://upload.wikimedia.org/wikipedia/commons/f/f8/RWS_Tarot_14_Temperance.jpg"},
    {"name": "El Diablo", "image": "https://upload.wikimedia.org/wikipedia/commons/5/55/RWS_Tarot_15_Devil.jpg"},
    {"name": "La Torre", "image": "https://upload.wikimedia.org/wikipedia/commons/5/53/RWS_Tarot_16_Tower.jpg"},
    {"name": "La Estrella", "image": "https://upload.wikimedia.org/wikipedia/commons/d/db/RWS_Tarot_17_Star.jpg"},
    {"name": "La Luna", "image": "https://upload.wikimedia.org/wikipedia/commons/7/7f/RWS_Tarot_18_Moon.jpg"},
    {"name": "El Sol", "image": "https://upload.wikimedia.org/wikipedia/commons/1/17/RWS_Tarot_19_Sun.jpg"},
    {"name": "El Juicio", "image": "https://upload.wikimedia.org/wikipedia/commons/d/dd/RWS_Tarot_20_Judgement.jpg"},
    {"name": "El Mundo", "image": "https://upload.wikimedia.org/wikipedia/commons/f/ff/RWS_Tarot_21_World.jpg"},
  ];

  // --- LÓGICA DE NEGOCIO ---

  Future<void> _consultarOraculo() async {
    if (_questionController.text.isEmpty) return;

    setState(() { _isLoading = true; _readingResult = null; });

    _deck.shuffle();
    List<Map<String, String>> selectedCardsData = _deck.take(3).toList();
    List<String> cardNamesToSend = selectedCardsData.map((c) => c['name']!).toList();

    try {
      final baseUrl = getBaseUrl();
      
      // Preparamos los datos del usuario
      Map<String, dynamic> requestData = {
        "question": _questionController.text,
        "cards": cardNamesToSend,
        "spread_type": "simple"
      };

      // Si está logueado, mandamos su ID real. Si no, su Device ID.
      if (_user != null) {
        requestData["user_id"] = _user!['id'];
      } else {
        requestData["user_device_id"] = currentDeviceId;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/reading'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        setState(() {
          _readingResult = json.decode(utf8.decode(response.bodyBytes));
          // Si el usuario es invitado, restar crédito localmente (visual)
          if (_user != null) {
             _user!['credits'] = (_user!['credits'] as int) - 1;
          }
        });
      } else {
        _mostrarError("El oráculo calla (Error ${response.statusCode})");
      }
    } catch (e) {
      _mostrarError("Error de conexión");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- LÓGICA DE AUTENTICACIÓN ---

  void _showAuthDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AuthDialog(
        onLogin: (userData) {
          setState(() => _user = userData);
          Navigator.of(ctx).pop();
          _mostrarError("¡Bienvenido ${_user!['full_name']}!");
        },
      ),
    );
  }

  void _logout() {
    setState(() => _user = null);
    _mostrarError("Sesión cerrada");
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("✨ Lumina Tarot"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Botón de Perfil / Login
          IconButton(
            icon: Icon(_user == null ? Icons.login : Icons.person),
            color: const Color(0xFFD4AF37),
            onPressed: _user == null ? _showAuthDialog : () {
              // Menú simple de perfil
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF1A1A2E),
                builder: (ctx) => Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Hola, ${_user!['full_name']}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 10),
                      Text("Créditos: ${_user!['credits']}", style: const TextStyle(fontSize: 16, color: Color(0xFFD4AF37))),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {Navigator.pop(ctx); _logout();},
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text("Cerrar Sesión"),
                      )
                    ],
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_readingResult == null) ...[
              // Bienvenida
              if (_user == null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text("Modo Invitado", style: TextStyle(color: Colors.grey)),
                ),

              const Icon(Icons.auto_awesome, size: 60, color: Color(0xFFD4AF37))
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(duration: 2.seconds, begin: const Offset(0.8, 0.8)),
              const SizedBox(height: 20),
              TextField(
                controller: _questionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "¿Qué inquieta a tu alma hoy?",
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _consultarOraculo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text("CONSULTAR A LUMINA", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
            // --- RESULTADO ---
            if (_readingResult != null) ...[
              const SizedBox(height: 20),
              Text(
                "${_readingResult!['atmosfera_emoji']} ${_readingResult!['titulo_lectura']}",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                textAlign: TextAlign.center,
              ).animate().fadeIn().slideY(),
              const Divider(color: Colors.white24, height: 30),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFB900FF).withOpacity(0.3)),
                ),
                child: Text(
                  _readingResult!['sintesis_narrativa'],
                  style: const TextStyle(fontSize: 16, height: 1.5),
                  textAlign: TextAlign.justify,
                ),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 20),
              
              // Renderizado de cartas BONITO (El que arreglamos)
              ...(_readingResult!['analisis_cartas'] as List).map((carta) {
                String cardName = carta['carta'];
                String imageUrl = _deck.firstWhere(
                  (element) => element['name'] == cardName, 
                  orElse: () => {"image": "https://via.placeholder.com/150"}
                )['image']!;

                return Container(
                  margin: const EdgeInsets.only(bottom: 25),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 350,
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFF1A1A2E), const Color(0xFFB900FF).withOpacity(0.1)]),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Center(
                          child: Image.network(imageUrl, fit: BoxFit.contain),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(carta['carta'].toUpperCase(), style: GoogleFonts.cinzel(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFFD4AF37)), textAlign: TextAlign.center),
                            const SizedBox(height: 8),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(carta['mensaje_clave'], style: const TextStyle(fontSize: 12, color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, letterSpacing: 1.0), textAlign: TextAlign.center)),
                            const Divider(color: Colors.white12, height: 30),
                            Text(carta['interpretacion_directa'], style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.white70), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1);
              }),

              const SizedBox(height: 20),
              Text("\"${_readingResult!['frase_talisman']}\"", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.white70), textAlign: TextAlign.center).animate().fadeIn(delay: 800.ms),
              const SizedBox(height: 30),
              TextButton(onPressed: () => setState(() { _questionController.clear(); _readingResult = null; }), child: const Text("Hacer otra pregunta", style: TextStyle(color: Color(0xFFD4AF37)))),
            ]
          ],
        ),
      ),
    );
  }
}

// --- WIDGET DIÁLOGO DE AUTENTICACIÓN ---
class AuthDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onLogin;
  const AuthDialog({super.key, required this.onLogin});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  bool _isLogin = true;
  bool _isLoading = false;
  
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController(); // Solo para registro

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final baseUrl = getBaseUrl();
    final endpoint = _isLogin ? '/api/login' : '/api/register';
    
    Map<String, dynamic> body = {
      "email": _emailCtrl.text,
      "password": _passCtrl.text,
    };

    if (!_isLogin) {
      body["full_name"] = _nameCtrl.text;
      body["device_id"] = currentDeviceId; // Vinculamos historial invitado
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        widget.onLogin(data); // Éxito
      } else {
        final errorMsg = json.decode(response.body)['detail'] ?? "Error desconocido";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error de conexión")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFD4AF37))),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_isLogin ? "Iniciar Sesión" : "Crear Cuenta", style: const TextStyle(fontSize: 24, color: Color(0xFFD4AF37), fontFamily: 'Cinzel')),
            const SizedBox(height: 20),
            if (!_isLogin)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(controller: _nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Nombre completo")),
              ),
            TextField(controller: _emailCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Correo electrónico")),
            const SizedBox(height: 10),
            TextField(controller: _passCtrl, obscureText: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Contraseña")),
            const SizedBox(height: 20),
            if (_isLoading) const CircularProgressIndicator(color: Color(0xFFD4AF37))
            else SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
                child: Text(_isLogin ? "ENTRAR" : "REGISTRARSE"),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(_isLogin ? "¿No tienes cuenta? Regístrate" : "¿Ya tienes cuenta? Inicia sesión", style: const TextStyle(color: Colors.white70)),
            )
          ],
        ),
      ),
    );
  }
}