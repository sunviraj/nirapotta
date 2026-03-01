import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../widgets/glass_container.dart';

class PinSetupScreen extends StatefulWidget {
  final bool isFromUpdate;
  const PinSetupScreen({super.key, this.isFromUpdate = false});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final pinController = TextEditingController();
  final focusNode = FocusNode();

  String? firstPin;
  bool isConfirming = false;
  String errorMessage = '';

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _onCompleted(String pin) async {
    if (!isConfirming) {
      setState(() {
        firstPin = pin;
        isConfirming = true;
        errorMessage = '';
      });
      pinController.clear();
      focusNode.requestFocus();
    } else {
      if (pin == firstPin) {
        // Save PIN
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('gallery_pin', pin);

        if (!widget.isFromUpdate) {
          await prefs.setBool('has_onboarded', true);
        }

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        setState(() {
          errorMessage = 'PINs do not match. Try again.';
          isConfirming = false;
          firstPin = null;
        });
        pinController.clear();
        focusNode.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const defaultPinTheme = PinTheme(
      width: 60,
      height: 64,
      textStyle: TextStyle(
          fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.all(Radius.circular(12)),
        border: Border.fromBorderSide(BorderSide(color: Colors.white24)),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: Colors.amber.shade400),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: Colors.redAccent),
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          isConfirming ? 'Confirm PIN' : 'Set Security PIN',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E1E1E), Color(0xFF2D1B2E)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: GlassContainer(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isConfirming
                          ? Icons.lock_clock_outlined
                          : Icons.lock_outline,
                      size: 64,
                      color: Colors.amber.shade400,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isConfirming
                          ? 'Please re-enter your 4-digit PIN'
                          : 'Set a 4-digit PIN to secure your evidence gallery.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    Pinput(
                      length: 4,
                      controller: pinController,
                      focusNode: focusNode,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: focusedPinTheme,
                      errorPinTheme: errorPinTheme,
                      obscureText: true,
                      autofocus: true,
                      onCompleted: _onCompleted,
                    ),
                    if (errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        errorMessage,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
