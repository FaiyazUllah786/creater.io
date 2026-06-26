import 'package:creatorio/common/theme/colors.dart';
import 'package:creatorio/common/utils.dart';
import 'package:creatorio/features/auth/controller/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final TextEditingController _confirmEditingController =
      TextEditingController();

  @override
  void dispose() {
    _confirmEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileController>(
      builder: (context, userController, _) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 150,
                child: Lottie.asset('assets/anim/error.json'),
              ),
              const Text(
                "Are you sure you want to delete your account?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "The account will no longer be available and all data will be permanently deleted.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Enter the word Confirm below to perform this action.",
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _confirmEditingController,
                onChanged: (value) => setState(() {}),
                textCapitalization: TextCapitalization.characters,
                maxLength: 7,
                decoration: const InputDecoration(
                    labelText: 'CONFIRM',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30))),
                    prefixIcon: Icon(Icons.key_rounded),
                    counterText: ''),
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
                        child: const Text(
                          "Cancel",
                          style: TextStyle(fontSize: 14),
                        )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: whiteColor,
                        backgroundColor: redColor,
                      ),
                      onPressed: _confirmEditingController.text
                                  .trim()
                                  .toLowerCase() !=
                              'confirm'
                          ? null
                          : userController.isLoading
                              ? () {}
                              : () async {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  await Future.delayed(
                                      const Duration(milliseconds: 100));
                                  final success =
                                      await userController.deleteAccount();
                                  if (!mounted) return;
                                  handleMessage(context, userController);
                                  if (success) {
                                    _confirmEditingController.clear();
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
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: LinearProgressIndicator(
                                  backgroundColor: whiteColor,
                                  color: redColor,
                                ),
                              )
                            : const Text(
                                "Delete account",
                                style: TextStyle(fontSize: 14),
                              ),
                      ),
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
