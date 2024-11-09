import 'package:creatorio/common/widgets/unsplash_screen.dart';
import 'package:creatorio/features/auth/screens/update_profile_screen.dart';
import 'package:creatorio/splash_screen.dart';
import 'package:flutter/material.dart';

import 'features/auth/screens/account_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'home_screen.dart';

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case SplashScreen.routeName:
      return MaterialPageRoute(builder: (context) => const SplashScreen());
    case HomeScreen.routeName:
      return MaterialPageRoute(builder: (context) => const HomeScreen());
    case SignupScreen.routeName:
      return MaterialPageRoute(builder: (context) => const SignupScreen());
    case LoginScreen.routeName:
      return MaterialPageRoute(builder: (context) => const LoginScreen());
    case AccountScreen.routeName:
      return MaterialPageRoute(builder: (context) => const AccountScreen());
    case UpdateProfileScreen.routeName:
      return MaterialPageRoute(
          builder: (context) => const UpdateProfileScreen());
    case UnsplashScreen.routeName:
      Function pickImageFromUnsplash = settings.arguments as Function;
      return MaterialPageRoute(
          builder: (context) => UnsplashScreen(
                pickImageFromUnsplash: pickImageFromUnsplash,
              ));
    default:
      return MaterialPageRoute(
          builder: (context) =>
              ErrorWidget('Something went Wrong\nThis route does not exists'));
  }
}
