import 'package:flutter/material.dart';
import 'package:libris/common/localization/app_localization.dart';
import 'package:libris/common/models/member.dart';
import 'package:libris/common/providers/database_provider.dart';
import 'package:provider/provider.dart';

class MemberFormScreen extends StatefulWidget {
  final Member? member;

  const MemberFormScreen({super.key, this.member});

  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  bool _isSaving = false;

  bool get isEdit => widget.member != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member?.name ?? '');
    _emailController = TextEditingController(text: widget.member?.email ?? '');
    _phoneController = TextEditingController(text: widget.member?.phone ?? '');
    _addressController = TextEditingController(
      text: widget.member?.address ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveMember() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final member = isEdit
          ? widget.member!.copyWith(
              name: _nameController.text.trim(),
              email: _nullableText(_emailController),
              phone: _nullableText(_phoneController),
              address: _nullableText(_addressController),
            )
          : Member(
              name: _nameController.text.trim(),
              email: _nullableText(_emailController),
              phone: _nullableText(_phoneController),
              address: _nullableText(_addressController),
            );

      final provider = context.read<DatabaseProvider>();

      if (isEdit) {
        await provider.updateMember(member);
      } else {
        await provider.addMember(member);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _nullableText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? l10n('Üyeyi Düzenle', 'Edit Member') : l10n('Yeni Üye', 'New Member'),
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isEdit
                              ? Icons.manage_accounts_rounded
                              : Icons.person_add_alt_1_rounded,
                          size: 30,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEdit
                                    ? l10n('Üye bilgilerini güncelleyin', 'Update member information')
                                    : l10n('Yeni bir üye kaydı oluşturun', 'Create a new member record'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                l10n(
                                  'İletişim bilgileri isteğe bağlıdır; ad soyad alanı zorunludur.',
                                  'Contact information is optional; the full name field is required.',
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final twoColumns = constraints.maxWidth >= 640;
                        final fieldWidth = twoColumns
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth;

                        return Wrap(
                          spacing: 12,
                          runSpacing: 14,
                          children: [
                            SizedBox(
                              width: constraints.maxWidth,
                              child: TextFormField(
                                controller: _nameController,
                                autofocus: !isEdit,
                                decoration: InputDecoration(
                                  labelText: l10n('Ad Soyad', 'Full Name'),
                                  prefixIcon: const Icon(Icons.person_outline_rounded),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return l10n('Ad soyad zorunlu', 'Full name is required');
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: l10n('E-posta', 'Email'),
                                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  final email = value?.trim() ?? '';
                                  if (email.isEmpty) return null;
                                  if (!email.contains('@') ||
                                      !email.contains('.')) {
                                    return l10n(
                                      'Geçerli bir e-posta girin',
                                      'Enter a valid email address',
                                    );
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: TextFormField(
                                controller: _phoneController,
                                decoration: InputDecoration(
                                  labelText: l10n('Telefon', 'Phone'),
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                            SizedBox(
                              width: constraints.maxWidth,
                              child: TextFormField(
                                controller: _addressController,
                                decoration: InputDecoration(
                                  labelText: l10n('Adres', 'Address'),
                                  prefixIcon: const Icon(Icons.location_on_outlined),
                                  alignLabelWithHint: true,
                                ),
                                maxLines: 4,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSaving ? null : () => Navigator.pop(context),
                child: Text(l10n('Vazgeç', 'Cancel')),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveMember,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(
                  isEdit ? l10n('Güncelle', 'Update') : l10n('Üyeyi Kaydet', 'Save Member'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
