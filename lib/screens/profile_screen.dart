import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../data/supabase_backend.dart';
import '../models/profile.dart';
import '../state/app_providers.dart';
import '../widgets/cyber_widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<void> _editNickname(String currentNickname) async {
    final controller = TextEditingController(text: currentNickname);
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('ALTERAR APELIDO', style: TextStyle(fontSize: 15, color: AppColors.cyan)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Novo Apelido'),
            validator: (v) {
              if (v == null || v.trim().length < 3) return 'Mínimo de 3 caracteres.';
              if (v.trim().length > 20) return 'Máximo de 20 caracteres.';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('SALVAR'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final backend = ref.read(backendProvider);
      if (backend != null) {
        try {
          await backend.updateNickname(controller.text);
          ref.invalidate(profileProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Apelido atualizado com sucesso!')),
            );
          }
        } on BackendException catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.message), backgroundColor: AppColors.red),
            );
          }
        }
      }
    }
  }

  Future<void> _logout() async {
    final backend = ref.read(backendProvider);
    if (backend != null) {
      await backend.signOut();
    }
    if (mounted) context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final isDemo = ref.watch(isDemoProvider);
    final user = ref.watch(authUserProvider).value;
    final profileAsync = ref.watch(profileProvider);
    final demoStats = ref.watch(demoProgressProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PERFIL DO DEFENSOR'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/menu'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isDemo || user == null) ...[
                  CyberCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(Icons.account_circle_outlined, size: 48, color: AppColors.amber),
                        const SizedBox(height: 12),
                        const Text(
                          'MODO DEMONSTRAÇÃO LOCAL',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.amber,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Você está jogando localmente sem persistência no banco de dados. '
                          'Crie ou conecte uma conta para competir no ranking e salvar seu progresso.',
                          style: TextStyle(fontSize: 12, color: AppColors.textDim),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          icon: const Icon(Icons.login),
                          label: const Text('CONECTAR CONTA'),
                          onPressed: () => context.go('/auth'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _StatsCard(stats: demoStats, title: 'Estatísticas da Sessão Atual'),
                ] else ...[
                  profileAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: AppColors.cyan),
                      ),
                    ),
                    error: (e, st) => Center(child: Text('Erro: $e')),
                    data: (profile) {
                      if (profile == null) return const SizedBox.shrink();

                      return Column(
                        children: [
                          CyberCard(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceHigh,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.cyan, width: 2),
                                  ),
                                  child: const Icon(Icons.shield, color: AppColors.cyan, size: 28),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              profile.nickname,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.text,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 16, color: AppColors.cyan),
                                            onPressed: () => _editNickname(profile.nickname),
                                            tooltip: 'Editar apelido',
                                          ),
                                        ],
                                      ),
                                      if (profile.email != null)
                                        Text(
                                          '${profile.email} (privado)',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textDim),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          _StatsCard(stats: profile.stats, title: 'Histórico de Defesa'),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.logout, color: AppColors.red),
                            label: const Text('ENCERRAR SESSÃO', style: TextStyle(color: AppColors.red)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.red),
                              minimumSize: const Size.fromHeight(48),
                            ),
                            onPressed: _logout,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats, required this.title});

  final PlayerStats stats;
  final String title;

  @override
  Widget build(BuildContext context) {
    return CyberCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: AppColors.cyan,
            ),
          ),
          const SizedBox(height: 14),
          _StatTile(label: 'Partidas jogadas', value: '${stats.matchesPlayed}'),
          const Divider(color: AppColors.border, height: 12),
          _StatTile(label: 'Vitórias', value: '${stats.wins}'),
          const Divider(color: AppColors.border, height: 12),
          _StatTile(label: 'Melhor pontuação', value: '${stats.bestScore}'),
          const Divider(color: AppColors.border, height: 12),
          _StatTile(label: 'Maior onda alcançada', value: '${stats.bestWave}/15'),
          const Divider(color: AppColors.border, height: 12),
          _StatTile(label: 'Total de invasores eliminados', value: '${stats.totalKills}'),
          const Divider(color: AppColors.border, height: 12),
          _StatTile(label: 'Vitórias impecáveis (100 HP)', value: '${stats.flawlessWins}'),
          const Divider(color: AppColors.border, height: 12),
          _StatTile(label: 'Chefes HYDRA AI destruídos', value: '${stats.bossesDefeated}'),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
        Text(value,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text)),
      ],
    );
  }
}
