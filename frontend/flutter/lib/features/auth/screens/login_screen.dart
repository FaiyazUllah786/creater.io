import 'package:creatorio/common/navigator_key.dart';
import 'package:creatorio/common/theme/colors.dart';
import 'package:creatorio/common/widgets/app_snackbar.dart';
import 'package:creatorio/features/auth/controller/auth_controller.dart';
import 'package:creatorio/core/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _SingUpState();
}

class _SingUpState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  String _email = "";
  String _password = "";

  bool _seePassword = false;

  void _visiblePassword() {
    setState(() {
      _seePassword = !_seePassword;
    });
  }

  late AuthController userController;

  void _login() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final userController = context.read<AuthController>();
      final success = await userController.loginUser(_email, _password);
      if (!mounted) return;

      if (success) {
        navigatorKey.currentState?.pushReplacementNamed('/home');
      } else {
        final message = userController.message;
        if (message != null) {
          AppSnackbar.show(
            context,
            message: message.message,
            type: message.messageType,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userController = context.watch<AuthController>();

    final textTheme = Theme.of(context).textTheme;

    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          "Creater.io",
        ),
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: userController.isLoading,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 500),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.disabled,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48.0,
                          vertical: 20,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: 80),
                            Text(
                              "Good to see you!",
                              style: textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Let's continue the journey.",
                              style: textTheme.bodyMedium,
                            ),
                            SizedBox(height: 80),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: AppValidators.validateEmail,
                              onSaved: (email) {
                                _email = email!;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: InkWell(
                                  splashFactory: NoSplash.splashFactory,
                                  onTap: _visiblePassword,
                                  child: Icon(_seePassword
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded),
                                ),
                              ),
                              obscureText: !_seePassword,
                              validator: AppValidators.validatePassword,
                              onSaved: (password) {
                                _password = password!;
                              },
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                                onPressed:
                                    userController.isLoading ? () {} : _login,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: userController.isLoading
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 28.0),
                                          child: LinearProgressIndicator(
                                            backgroundColor: whiteColor,
                                            color: blackColor,
                                          ),
                                        )
                                      : Text(
                                          'Login',
                                          style: textTheme.bodyMedium!
                                              .copyWith(color: whiteColor),
                                        ),
                                )),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text(
                                    "Didn't have an account? ",
                                  ),
                                  InkWell(
                                    onTap: () => Navigator.pushReplacementNamed(
                                        context, '/signup'),
                                    child: Text(
                                      "Signup",
                                      style: textTheme.bodyLarge,
                                    ),
                                  )
                                ],
                              ),
                            ),
                            // const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!isKeyboardOpen)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("Made with "),
                      Icon(
                        Icons.favorite,
                        color: Colors.red,
                      ),
                      Text(" India"),
                    ],
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
