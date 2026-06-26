import 'package:creatorio/common/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SignupSuccessDialog extends StatelessWidget {
  const SignupSuccessDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 200,
              child: Lottie.asset(
                "assets/anim/success_celebration.json",
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Account created successfully!",
              style: textTheme.labelMedium,
            ),
            const SizedBox(height: 16),
            Text(
              "Congratulations! Your account has been created. Please log in with your credentials to get started.",
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: whiteColor,
                  backgroundColor: blackColor,
                ),
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text("Login to get started")),
          ],
        ),
      ),
    );
  }
}
