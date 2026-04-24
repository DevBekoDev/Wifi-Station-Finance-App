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

  final FocusNode centerNameFocus = FocusNode();
  final FocusNode locationFocus = FocusNode();
  final FocusNode managerNameFocus = FocusNode();
  final FocusNode managerEmailFocus = FocusNode();

  @override
  void dispose() {
    centerNameController.dispose();
    locationController.dispose();
    managerNameController.dispose();
    managerEmailController.dispose();

    centerNameFocus.dispose();
    locationFocus.dispose();
    managerNameFocus.dispose();
    managerEmailFocus.dispose();

    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    context.read<CreateCenterCubit>().createCenter(
      centerName: centerNameController.text.trim(),
      location: locationController.text.trim(),
      managerName: managerNameController.text.trim(),
      managerEmail: managerEmailController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0B7A75);
    const primaryDark = Color(0xFF075E59);
    const bg = Color(0xFFF4F7F9);
    const textDark = Color(0xFF0F172A);
    const textSoft = Color(0xFF64748B);
    const cardBorder = Color(0xFFE6ECF2);

    return BlocListener<CreateCenterCubit, CreateCenterState>(
      listener: (context, state) {
        if (state is CreateCenterSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }

        if (state is CreateCenterError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
          foregroundColor: textDark,
          title: const Text(
            'Create Center',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ),
        bottomNavigationBar: BlocBuilder<CreateCenterCubit, CreateCenterState>(
          builder: (context, state) {
            final isLoading = state is CreateCenterLoading;

            return SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 58,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryDark,
                      disabledBackgroundColor: primaryDark.withOpacity(0.75),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Create Center',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward_rounded, size: 22),
                            ],
                          ),
                  ),
                ),
              ),
            );
          },
        ),
        body: SafeArea(
          child: BlocBuilder<CreateCenterCubit, CreateCenterState>(
            builder: (context, state) {
              return Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            colors: [primaryDark, primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.22),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    color: Color(0xFFFFE8A3),
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Let's get you set up",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'New WiFi Center',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Add a new center and start tracking sales, expenses, and manager access with a cleaner setup flow.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.86),
                                fontSize: 14.5,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _TopBadge(
                                  icon: Icons.wifi_rounded,
                                  label: 'Center setup',
                                ),
                                _TopBadge(
                                  icon: Icons.person_add_alt_1_rounded,
                                  label: 'Manager assignment',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      _SectionCard(
                        icon: Icons.apartment_rounded,
                        title: 'Center Information',
                        subtitle: 'Basic details about your WiFi center',
                        child: Column(
                          children: [
                            _ModernField(
                              controller: centerNameController,
                              focusNode: centerNameFocus,
                              nextFocusNode: locationFocus,
                              label: 'Center Name',
                              hintText: 'Enter center name',
                              icon: Icons.storefront_outlined,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Center name is required.';
                                }
                                if (value.trim().length < 3) {
                                  return 'Center name must be at least 3 characters.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _ModernField(
                              controller: locationController,
                              focusNode: locationFocus,
                              nextFocusNode: managerNameFocus,
                              label: 'Location',
                              hintText: 'Enter center location',
                              icon: Icons.location_on_outlined,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Location is required.';
                                }
                                if (value.trim().length < 2) {
                                  return 'Location must be at least 2 characters.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F9F8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFD7EEEB),
                                ),
                              ),
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: primary,
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Choose a clear center name and location so it is easy to identify later in reports and dashboards.',
                                      style: TextStyle(
                                        color: textSoft,
                                        fontSize: 13,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SectionCard(
                        icon: Icons.person_outline_rounded,
                        title: 'Manager Information',
                        subtitle: 'Assign a manager to handle this center',
                        child: Column(
                          children: [
                            _ModernField(
                              controller: managerNameController,
                              focusNode: managerNameFocus,
                              nextFocusNode: managerEmailFocus,
                              label: 'Manager Name',
                              hintText: 'Enter manager name',
                              icon: Icons.badge_outlined,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Manager name is required.';
                                }
                                if (value.trim().length < 3) {
                                  return 'Manager name must be at least 3 characters.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _ModernField(
                              controller: managerEmailController,
                              focusNode: managerEmailFocus,
                              label: 'Manager Email',
                              hintText: 'Enter manager email',
                              icon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Manager email is required.';
                                }

                                final emailRegex = RegExp(
                                  r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$',
                                );

                                if (!emailRegex.hasMatch(value.trim())) {
                                  return 'Enter a valid email address.';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5FBFB),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFDCEEEE),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Color(0xFFE4F5F3),
                                    child: Icon(
                                      Icons.verified_user_outlined,
                                      color: primaryDark,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Manager account will be created automatically.',
                                          style: TextStyle(
                                            color: textDark,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Login details can be shared after the center is created.',
                                          style: TextStyle(
                                            color: textSoft,
                                            fontSize: 12.8,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        child: const Text(
                          'Review the details carefully before creating the center.',
                          style: TextStyle(
                            color: textSoft,
                            fontSize: 12.8,
                            height: 1.4,
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

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0B7A75);
    const textDark = Color(0xFF0F172A);
    const textSoft = Color(0xFF64748B);
    const cardBorder = Color(0xFFE6ECF2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
       Row(
  children: [
    Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE9F7F5),
        border: Border.all(
          color: const Color(0xFFD4EEEA),
        ),
      ),
      child: Icon(
        icon,
        color: primary,
        size: 26,
      ),
    ),
    const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: textSoft,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: cardBorder),
          ),
          child,
        ],
      ),
    );
  }
}

class _TopBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TopBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final String label;
  final String hintText;
  final IconData icon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const _ModernField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.focusNode,
    this.nextFocusNode,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0B7A75);
    const textDark = Color(0xFF0F172A);
    const borderColor = Color(0xFFD9E3EC);
    const fillColor = Color(0xFFFAFCFD);
    const hintColor = Color(0xFF94A3B8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: textDark,
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted ??
              (_) {
                if (nextFocusNode != null) {
                  FocusScope.of(context).requestFocus(nextFocusNode);
                } else {
                  FocusScope.of(context).unfocus();
                }
              },
          style: const TextStyle(
            color: textDark,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: hintColor,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: primary, size: 20),
            ),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: Colors.red.shade400,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: Colors.red.shade500,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}