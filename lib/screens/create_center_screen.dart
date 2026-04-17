import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wsfm/cubits/create_center/create_center_cubit.dart';
import 'package:wsfm/cubits/create_center/create_center_state.dart';

class CreateCenterScreen extends StatelessWidget {
  const CreateCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CreateCenterCubit(),
      child: const _CreateCenterView(),
    );
  }
}

class _CreateCenterView extends StatefulWidget {
  const _CreateCenterView();

  @override
  State<_CreateCenterView> createState() => _CreateCenterViewState();
}

class _CreateCenterViewState extends State<_CreateCenterView> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController centerNameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController managerNameController = TextEditingController();
  final TextEditingController managerEmailController = TextEditingController();

  @override
  void dispose() {
    centerNameController.dispose();
    locationController.dispose();
    managerNameController.dispose();
    managerEmailController.dispose();
    super.dispose();
  }

  void _submit() {
    final isValid = _formKey.currentState!.validate();

    if (!isValid) return;

    context.read<CreateCenterCubit>().createCenter(
      centerName: centerNameController.text,
      location: locationController.text,
      managerName: managerNameController.text,
      managerEmail: managerEmailController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateCenterCubit, CreateCenterState>(
      listener: (context, state) {
        if (state is CreateCenterSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          Navigator.pop(context);
        }

        if (state is CreateCenterError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF0F172A),
          title: const Text(
            "Create Center",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<CreateCenterCubit, CreateCenterState>(
            builder: (context, state) {
              final isLoading = state is CreateCenterLoading;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00695C), Color(0xFF00897B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "New WiFi Center",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Add a new center and save it directly to Firestore.",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        "Center Information",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 14),

                      _CustomField(
                        controller: centerNameController,
                        hintText: "Center Name",
                        icon: Icons.wifi_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Center name is required.";
                          }
                          if (value.trim().length < 3) {
                            return "Center name must be at least 3 characters.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      _CustomField(
                        controller: locationController,
                        hintText: "Location",
                        icon: Icons.location_on_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Location is required.";
                          }
                          if (value.trim().length < 2) {
                            return "Location must be at least 2 characters.";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        "Manager Information",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 14),

                      _CustomField(
                        controller: managerNameController,
                        hintText: "Manager Name",
                        icon: Icons.person_outline_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Manager name is required.";
                          }
                          if (value.trim().length < 3) {
                            return "Manager name must be at least 3 characters.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      _CustomField(
                        controller: managerEmailController,
                        hintText: "Manager Email",
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Manager email is required.";
                          }

                          final emailRegex = RegExp(
                            r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
                          );

                          if (!emailRegex.hasMatch(value.trim())) {
                            return "Enter a valid email address.";
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00695C),
                            disabledBackgroundColor: const Color(0xFF00695C),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Create Center",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CustomField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _CustomField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: const Color(0xFF00695C)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}