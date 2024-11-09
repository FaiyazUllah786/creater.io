import 'package:creatorio/common/theme/colors.dart';
import 'package:creatorio/features/auth/controller/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
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

  bool _isLoading = false;

  late final UserController userController;

  void _login() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      print("email: $_email");
      print("password: $_password");
      setState(() {
        _isLoading = true;
      });
      final res = await userController.loginUser(context, _email, _password);
      print(res);
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    userController = Provider.of<UserController>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      // resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Creater.io"),
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Container(
              height: size.height - kToolbarHeight - kBottomNavigationBarHeight,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
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
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(30))),
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
                          border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(30))),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffix: InkWell(
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
                        onPressed: !_isLoading ? _login : () {},
                        child: _isLoading
                            ? const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 28.0),
                                child: LinearProgressIndicator(
                                  backgroundColor: whiteColor,
                                  color: blackColor,
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(color: whiteColor),
                              ),
                      ),
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
    );
  }
}
