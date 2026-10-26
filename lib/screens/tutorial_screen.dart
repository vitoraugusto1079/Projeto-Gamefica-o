import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../game/config/enemy_config.dart';
import '../game/config/tower_config.dart';
import '../widgets/cyber_widgets.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('MANUAL DE CIBERSEGURANÇA'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/menu'),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.cyan,
          labelColor: AppColors.cyan,
          unselectedLabelColor: AppColors.textDim,
          tabs: const [
            Tab(text: 'REGRAS'),
            Tab(text: 'DEFESAS (TORRES)'),
            Tab(text: 'AMEAÇAS (INIMIGOS)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _RulesTab(),
          _TowersTab(),
          _EnemiesTab(),
        ],
      ),
    );
  }
}

class _RulesTab extends StatelessWidget {
  const _RulesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        _InfoCard(
          title: 'Objetivo do Jogo',
          content:
              'Você é o administrador de segurança responsável por proteger um servidor '
              'que hospeda uma aplicação PHP. Ataques cibernéticos percorrem a placa de circuito '
              'em direção ao servidor. Se alcançarem o final da trilha, a integridade do sistema '
              'será reduzida até o colapso total (0 HP).',
        ),
        SizedBox(height: 12),
        _InfoCard(
          title: 'Economia e Posicionamento',
          content:
              '• Cada partida começa com 100 de Integridade e 400 Créditos.\n'
              '• Construa torres clicando no catálogo e posicionando-as na grade lógica.\n'
              '• As torres não podem sobrepor a trilha de dados nem o rack do servidor.\n'
              '• Vender uma torre instalada reembolsa 70% de todo o valor investido.',
        ),
        SizedBox(height: 12),
        _InfoCard(
          title: 'Ondas e Velocidade',
          content:
              '• São 15 ondas progressivas. A próxima onda só inicia quando acionada pelo jogador.\n'
              '• Alterne entre as velocidades 1x e 2x a qualquer momento (sem alterar sua pontuação).\n'
              '• A pausa interrompe imediatamente a movimentação, projéteis e temporizadores.',
        ),
      ],
    );
  }
}

class _TowersTab extends StatelessWidget {
  const _TowersTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: towerConfigs.values.map((cfg) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: CyberCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TowerIconWidget(kind: cfg.kind, size: 44),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cfg.name.toUpperCase()} — ${cfg.role}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.cyan,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${cfg.entityType} · Custo inicial: ${cfg.buildCost} créditos',
                            style: const TextStyle(fontSize: 12, color: AppColors.textDim),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  cfg.description,
                  style: const TextStyle(fontSize: 13, color: AppColors.text, height: 1.3),
                ),
                const SizedBox(height: 8),
                Text(
                  cfg.disclaimer,
                  style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textDim,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EnemiesTab extends StatelessWidget {
  const _EnemiesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: enemyConfigs.values.map((cfg) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: CyberCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Color(cfg.color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(cfg.color)),
                      ),
                      child: Center(
                        child: Text(
                          cfg.symbol,
                          style: TextStyle(
                            color: Color(cfg.color),
                            fontWeight: FontWeight.bold,
                            fontSize: cfg.symbol.length > 2 ? 10 : 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cfg.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(cfg.color),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Vida: ${cfg.maxHp.toInt()} · Velocidade: ${cfg.speed.toInt()} · Recompensa: ${cfg.reward} cr',
                            style: const TextStyle(fontSize: 12, color: AppColors.textDim),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  cfg.shortDescription,
                  style: const TextStyle(fontSize: 13, color: AppColors.text, height: 1.3),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, size: 14, color: AppColors.cyan),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Contramedida: ${cfg.counterHint}',
                          style: const TextStyle(fontSize: 11, color: AppColors.cyan),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return CyberCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.cyan,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 13, color: AppColors.text, height: 1.4),
          ),
        ],
      ),
    );
  }
}
