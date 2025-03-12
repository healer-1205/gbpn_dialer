import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gbpn_dealer/utils/extension.dart';
import '../../utils/constant.dart';
import '../../utils/style.dart';
import '../../utils/assets.dart';
import '../../services/auth_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // static bool _isNavigatingBack = false;

  void _validateAndLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    String? success = await _authService.login(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success == null) {
      await _hideKeyboard(context);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dialpad');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _hideKeyboard(context);
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: false,
        backgroundColor: Colors.white,
        // appBar: CustomAppBar.build(
        //   leading: IconButton(
        //     icon: const Icon(Icons.arrow_back, color: Colors.black),
        //     onPressed: () async {
        //       if (_isNavigatingBack) return;
        //       _isNavigatingBack = true;
        //       await _hideKeyboard(context);
        //       if (context.mounted) {
        //         Navigator.pop(context);
        //       }
        //       _isNavigatingBack = false;
        //     },
        //   ),
        // ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Image.asset(
                      ImageAssets.logo,
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      StringConstants.loginTitle,
                      style: AppStyles.textStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(36.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email is required';
                            }
                            if (!RegExp(
                                    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
                                .hasMatch(value)) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Handle forgot password
                            },
                            child: const Text('Forgot Password?'),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _isLoading
                                ? const CircularProgressIndicator()
                                : ElevatedButton(
                                    onPressed: _validateAndLogin,
                                    style: AppStyles.elevatedButtonStyle(
                                      backgroundColor: Colors.deepPurpleAccent,
                                      foregroundColor: Colors.white,
                                      borderRadius: 12.0,
                                      horizontalPadding:
                                          context.screenWidth / 3.8,
                                    ),
                                    child: const Text(
                                      "Login",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
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
      ),
    );
  }

  Future<void> _hideKeyboard(BuildContext context) async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 300));
    await SystemChannels.textInput.invokeMethod('TextInput.hide');
  }
}
