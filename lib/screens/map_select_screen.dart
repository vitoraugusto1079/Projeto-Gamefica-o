import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../game/config/map_config.dart';
import '../widgets/cyber_widgets.dart';

class MapSelectScreen extends StatelessWidget {
  const MapSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const map = circuitAlpha;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SELEÇÃO DE MAPA'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/menu'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: CyberCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cyan),
                        ),
                        child: const Icon(Icons.developer_board, color: AppColors.cyan, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              map.name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Mapa Oficial · Primeira Versão',
                              style: TextStyle(fontSize: 12, color: AppColors.cyan),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Text(
                    map.description,
                    style: const TextStyle(fontSize: 13, color: AppColors.textDim, height: 1.4),
                  ),
                  const SizedBox(height: 20),

                  // Especificações da partida
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      children: [
                        _StatRow(label: 'Ondas de invasão', value: '15 ondas progressivas'),
                        Divider(color: AppColors.border, height: 16),
                        _StatRow(label: 'Integridade do Servidor', value: '100 HP'),
                        Divider(color: AppColors.border, height: 16),
                        _StatRow(label: 'Créditos iniciais', value: '400 créditos'),
                        Divider(color: AppColors.border, height: 16),
                        _StatRow(label: 'Ameaça final', value: 'HYDRA AI (Onda 15)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  FilledButton.icon(
                    icon: const Icon(Icons.shield_outlined),
                    label: const Text('INICIAR PARTIDA'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    onPressed: () => context.go('/match'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

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
                fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.cyan)),
      ],
    );
  }
}
