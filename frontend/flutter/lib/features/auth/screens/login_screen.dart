import 'package:creatorio/common/theme/colors.dart';
import 'package:creatorio/features/auth/controller/user_controller.dart';
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

  late UserController userController;

  void _login() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      debugPrint("email: $_email");
      debugPrint("password: $_password");
      final userController = context.read<UserController>();
      final success = await userController.loginUser(_email, _password);
      if (!mounted) return;
      final msg = userController.message;
      if (msg != null) {
        msg.show(context);
        userController.clearMessage(); // VERY IMPORTANT
      }
      if (success) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          "/home",
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userController = context.watch<UserController>();

    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Creater.io"),
      ),
      body: AbsorbPointer(
        absorbing: userController.isLoading,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Container(
                height:
                    size.height - kToolbarHeight - kBottomNavigationBarHeight,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.disabled,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Spacer(flex: 1),
                        const Text(
                          "Good to see you!",
                          style: TextStyle(
                              fontSize: 36, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Let's continue the journey.",
                          style: TextStyle(fontSize: 14),
                        ),
                        const Spacer(flex: 1),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (email) {
                            if (email == null ||
                                email.toString().trim().isEmpty) {
                              return 'Email is required';
                            } else if (!RegExp(
                                    r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$')
                                .hasMatch(email)) {
                              return 'Not a valid email';
                            }
                            return null;
                          },
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
                          validator: (password) {
                            if (password == null ||
                                password.toString().trim().isEmpty) {
                              return 'Password is required';
                            } else if (password.length < 6) {
                              return 'Password must contain 6 or more characters';
                            }
                            return null;
                          },
                          onSaved: (password) {
                            _password = password!;
                          },
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: whiteColor,
                              backgroundColor: blackColor,
                              minimumSize: Size(size.width, 50),
                              shape: ContinuousRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
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
                                  : const Text(
                                      'Login',
                                      style: TextStyle(color: whiteColor),
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
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w100),
                              ),
                              InkWell(
                                onTap: () => Navigator.pushReplacementNamed(
                                    context, '/signup'),
                                child: const Text(
                                  "Signup",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: blackColor,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        // const SizedBox(height: 20),
                        const Spacer(flex: 2),
                        const Row(
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
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
