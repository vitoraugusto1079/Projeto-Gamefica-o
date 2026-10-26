import 'enemy_config.dart';

enum TowerKind { fortinet, cloudflare, crowdstrike, owasp, microsoft }

/// Atributos de um nível de torre.
class TowerLevel {
  const TowerLevel({
    required this.cost,
    required this.range,
    required this.summary,
    this.damage = 0,
    this.fireRate = 0,
    this.splashRadius = 0,
    this.slowFactor = 0,
    this.slowDuration = 0,
    this.revealDuration = 0,
    this.buffPercent = 0,
    this.patchVulnerability = 0,
  });

  /// Custo para comprar este nível (nível 1 = preço de construção).
  final int cost;
  final double range;

  /// Texto curto do efeito da melhoria, mostrado antes da compra.
  final String summary;
  final double damage;

  /// Disparos por segundo (0 = não ataca).
  final double fireRate;
  final double splashRadius;

  /// Redução de velocidade (0..1) aplicada pelo disparo.
  final double slowFactor;
  final double slowDuration;

  /// Duração (s) da revelação de ameaças ocultas.
  final double revealDuration;

  /// Bônus (0..1) de dano e cadência concedido a torres próximas.
  final double buffPercent;

  /// Multiplicador de dano recebido por Exploits sob correção.
  final double patchVulnerability;
}

/// Configuração de uma torre. Editável.
class TowerConfig {
  const TowerConfig({
    required this.kind,
    required this.name,
    required this.entityType,
    required this.role,
    required this.description,
    required this.disclaimer,
    required this.color,
    required this.symbol,
    required this.levels,
    this.detectsHidden = false,
    this.detectsKinds = const {},
    this.ignoresSqlShield = false,
    this.stripsSqlShield = false,
    this.stripsCamouflage = false,
    this.bonusVs = const {},
    this.projectileSpeed = 520,
    this.isSupport = false,
  });

  final TowerKind kind;
  final String name;

  /// "Empresa" ou "Organização".
  final String entityType;
  final String role;
  final String description;
  final String disclaimer;
  final int color;
  final String symbol;
  final List<TowerLevel> levels;

  /// Pode mirar em qualquer ameaça oculta.
  final bool detectsHidden;

  /// Pode mirar em ameaças ocultas destes tipos.
  final Set<EnemyKind> detectsKinds;
  final bool ignoresSqlShield;
  final bool stripsSqlShield;
  final bool stripsCamouflage;
  final Map<EnemyKind, double> bonusVs;
  final double projectileSpeed;

  /// Torre de suporte: não dispara; aplica efeitos em área.
  final bool isSupport;

  int get maxLevel => levels.length;
  int get buildCost => levels.first.cost;
  TowerLevel level(int lvl) => levels[lvl - 1];
}

const String _brandDisclaimer =
    'Nome usado apenas como inspiração temática. A função é uma abstração do '
    'jogo e não representa o produto real.';

const Map<TowerKind, TowerConfig> towerConfigs = {
  TowerKind.fortinet: TowerConfig(
    kind: TowerKind.fortinet,
    name: 'Fortinet',
    entityType: 'Empresa',
    role: 'Firewall',
    description: 'Torre equilibrada com disparos regulares. Ótima contra ameaças básicas.',
    disclaimer: _brandDisclaimer,
    color: 0xFFFF6E40,
    symbol: 'FW',
    levels: [
      TowerLevel(cost: 150, range: 165, damage: 2, fireRate: 1.6, summary: 'Firewall básico'),
      TowerLevel(
          cost: 130, range: 175, damage: 3, fireRate: 2.2, summary: '+50% dano, +37% cadência'),
      TowerLevel(
          cost: 280, range: 190, damage: 5, fireRate: 3.2, summary: '+67% dano, +45% cadência'),
    ],
  ),
  TowerKind.cloudflare: TowerConfig(
    kind: TowerKind.cloudflare,
    name: 'Cloudflare',
    entityType: 'Empresa',
    role: 'Filtragem de tráfego',
    description: 'Disparos com dano em área. Especialista contra enxames de bots e DDoS.',
    disclaimer: _brandDisclaimer,
    color: 0xFFFFA726,
    symbol: 'CF',
    bonusVs: {EnemyKind.ddos: 2.5},
    projectileSpeed: 420,
    levels: [
      TowerLevel(
          cost: 200,
          range: 150,
          damage: 1.5,
          fireRate: 0.8,
          splashRadius: 60,
          summary: 'Filtro em área (x2,5 contra DDoS)'),
      TowerLevel(
          cost: 160,
          range: 180,
          damage: 1.5,
          fireRate: 0.9,
          splashRadius: 85,
          slowFactor: 0.3,
          slowDuration: 1.5,
          summary: '+alcance, +área, lentidão de 30%'),
      TowerLevel(
          cost: 300,
          range: 205,
          damage: 2.5,
          fireRate: 1.0,
          splashRadius: 110,
          slowFactor: 0.45,
          slowDuration: 2,
          summary: '+alcance, +área, +dano, lentidão de 45%'),
    ],
  ),
  TowerKind.crowdstrike: TowerConfig(
    kind: TowerKind.crowdstrike,
    name: 'CrowdStrike',
    entityType: 'Empresa',
    role: 'Detecção',
    description:
        'Revela ameaças ocultas no alcance para que as outras torres possam atingi-las. '
        'Dispara pulsos fracos.',
    disclaimer: _brandDisclaimer,
    color: 0xFFEF5350,
    symbol: 'EDR',
    detectsHidden: true,
    levels: [
      TowerLevel(
          cost: 170,
          range: 160,
          damage: 1,
          fireRate: 1,
          revealDuration: 2,
          summary: 'Revela ocultos por 2 s'),
      TowerLevel(
          cost: 120,
          range: 205,
          damage: 1.5,
          fireRate: 1.2,
          revealDuration: 3.5,
          summary: '+alcance, revelação 3,5 s'),
      TowerLevel(
          cost: 220,
          range: 250,
          damage: 2.5,
          fireRate: 1.5,
          revealDuration: 5,
          summary: '+alcance, revelação 5 s, +dano'),
    ],
  ),
  TowerKind.owasp: TowerConfig(
    kind: TowerKind.owasp,
    name: 'OWASP',
    entityType: 'Organização',
    role: 'Defesa da aplicação',
    description:
        'Consultas parametrizadas e codificação de saída: remove a blindagem de SQL '
        'Injection e a camuflagem de XSS. Detecta XSS.',
    disclaimer:
        'OWASP é uma organização aberta e sem fins lucrativos; aqui representa boas '
        'práticas de desenvolvimento seguro.',
    color: 0xFF7C4DFF,
    symbol: '{ }',
    detectsKinds: {EnemyKind.xss},
    ignoresSqlShield: true,
    stripsSqlShield: true,
    stripsCamouflage: true,
    bonusVs: {EnemyKind.sqlInjection: 2, EnemyKind.xss: 2},
    levels: [
      TowerLevel(cost: 180, range: 160, damage: 2, fireRate: 1, summary: 'Remove blindagem SQL/XSS'),
      TowerLevel(cost: 150, range: 180, damage: 3, fireRate: 1.4, summary: '+alcance, +dano, +cadência'),
      TowerLevel(cost: 280, range: 200, damage: 5, fireRate: 2, summary: '+alcance, +dano, +cadência'),
    ],
  ),
  TowerKind.microsoft: TowerConfig(
    kind: TowerKind.microsoft,
    name: 'Microsoft',
    entityType: 'Empresa',
    role: 'Correção e suporte',
    description:
        'Atualizações de segurança: deixa Exploits vulneráveis e dá bônus de dano e '
        'cadência às torres próximas (o bônus não acumula entre torres de suporte).',
    disclaimer: _brandDisclaimer,
    color: 0xFF29B6F6,
    symbol: 'KB',
    isSupport: true,
    levels: [
      TowerLevel(
          cost: 220,
          range: 150,
          buffPercent: 0.10,
          patchVulnerability: 1.25,
          summary: 'Bônus 10%, Exploit recebe +25% dano'),
      TowerLevel(
          cost: 180,
          range: 180,
          buffPercent: 0.15,
          patchVulnerability: 1.5,
          summary: '+alcance, bônus 15%, Exploit +50% dano'),
      TowerLevel(
          cost: 300,
          range: 210,
          buffPercent: 0.20,
          patchVulnerability: 1.75,
          summary: '+alcance, bônus 20%, Exploit +75% dano'),
    ],
  ),
};

TowerConfig towerConfig(TowerKind kind) => towerConfigs[kind]!;
