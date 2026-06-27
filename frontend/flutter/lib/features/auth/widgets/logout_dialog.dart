import 'package:creatorio/common/theme/colors.dart';
import 'package:creatorio/common/utils.dart';
import 'package:creatorio/features/auth/controller/auth_controller.dart';
import 'package:creatorio/features/auth/controller/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LogoutDialog extends StatefulWidget {
  const LogoutDialog({super.key});

  @override
  State<LogoutDialog> createState() => _LogoutDialogState();
}

class _LogoutDialogState extends State<LogoutDialog> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, userController, _) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Are you sure you want to logout?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: whiteColor,
                          backgroundColor: blackColor,
                        ),
                        onPressed: userController.isLoading
                            ? () {}
                            : () => Navigator.pop(context),
                        child: const Text("Cancel")),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: whiteColor,
                        backgroundColor: redColor,
                      ),
                      onPressed: userController.isLoading
                          ? () {}
                          : () async {
                              final success = await userController.logout();
                              if (!context.mounted) return;
                              context.read<ProfileController>().clearProfile();
                              handleMessage(context, userController);
                              if (success) {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  "/login",
                                  (_) => false,
                                );
                              }
                            },
                      child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: userController.isLoading
                              ? const Padding(
                                  key: ValueKey('loader'),
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 8.0),
                                  child: LinearProgressIndicator(
                                    backgroundColor: whiteColor,
                                    color: redColor,
                                  ),
                                )
                              : const Text("Log out")),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
