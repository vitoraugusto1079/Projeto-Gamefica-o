import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../data/supabase_backend.dart';
import '../state/app_providers.dart';
import '../widgets/cyber_widgets.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSignUp = false;
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();

  bool _loading = false;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    final backend = ref.read(backendProvider);
    if (backend == null) {
      // Sem credenciais: navega diretamente para o menu em modo demonstração
      context.go('/menu');
      return;
    }

    try {
      if (_isSignUp) {
        final res = await backend.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          nickname: _nicknameController.text,
        );
        if (res == SignUpResult.signedIn) {
          if (mounted) context.go('/menu');
        } else {
          setState(() {
            _infoMessage = 'Cadastro realizado! Verifique seu e-mail para confirmar a conta antes de entrar.';
            _isSignUp = false;
          });
        }
      } else {
        await backend.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (mounted) context.go('/menu');
      }
    } on BackendException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDemo = ref.watch(isDemoProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: CyberCard(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cabeçalho
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.5)),
                        ),
                        child: const Text(
                          'PHP DEFENSE',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: AppColors.cyan,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Alternador Login / Cadastro
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('ENTRAR')),
                            selected: !_isSignUp,
                            onSelected: (s) => setState(() {
                              _isSignUp = false;
                              _errorMessage = null;
                            }),
                            selectedColor: AppColors.cyan,
                            labelStyle: TextStyle(
                              color: !_isSignUp ? AppColors.background : AppColors.textDim,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('CADASTRAR')),
                            selected: _isSignUp,
                            onSelected: (s) => setState(() {
                              _isSignUp = true;
                              _errorMessage = null;
                            }),
                            selectedColor: AppColors.cyan,
                            labelStyle: TextStyle(
                              color: _isSignUp ? AppColors.background : AppColors.textDim,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (_isSignUp) ...[
                      TextFormField(
                        controller: _nicknameController,
                        decoration: const InputDecoration(
                          labelText: 'Apelido (exibido no ranking)',
                          prefixIcon: Icon(Icons.person_outline, color: AppColors.cyan),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().length < 3) {
                            return 'O apelido deve ter pelo menos 3 caracteres.';
                          }
                          if (v.trim().length > 20) {
                            return 'O apelido deve ter no máximo 20 caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                    ],

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.email_outlined, color: AppColors.cyan),
                      ),
                      validator: (v) {
                        if (v == null || !v.contains('@') || !v.contains('.')) {
                          return 'Informe um e-mail válido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: Icon(Icons.lock_outline, color: AppColors.cyan),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 6) {
                          return 'A senha deve ter pelo menos 6 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.red),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: AppColors.red, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_infoMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.green),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: AppColors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _infoMessage!,
                                style: const TextStyle(color: AppColors.green, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                            )
                          : Text(_isSignUp ? 'CRIAR CONTA' : 'ACESSAR SERVIDOR'),
                    ),
                    const SizedBox(height: 14),

                    // Opção de modo de demonstração local
                    OutlinedButton.icon(
                      icon: const Icon(Icons.play_arrow_outlined),
                      label: Text(isDemo
                          ? 'JOGAR EM MODO DEMONSTRAÇÃO'
                          : 'JOGAR SEM CONTA (DEMO LOCAL)'),
                      onPressed: () => context.go('/menu'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
