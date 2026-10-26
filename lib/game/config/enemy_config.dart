/// Tipos de inimigos.
enum EnemyKind { bruteForce, sqlInjection, xss, ddos, exploit, hydra }

/// Formatos usados para diferenciar inimigos além da cor.
enum EnemyShape { circle, hexagon, diamond, triangle, square, boss }

/// Configuração de um tipo de inimigo. Editável.
class EnemyConfig {
  const EnemyConfig({
    required this.kind,
    required this.name,
    required this.shortDescription,
    required this.counterHint,
    required this.maxHp,
    required this.speed,
    required this.reward,
    required this.baseDamage,
    required this.radius,
    required this.color,
    required this.symbol,
    required this.shape,
    this.sqlShield = false,
    this.hidden = false,
    this.exploitArmor = 0,
    this.isBoss = false,
  });

  final EnemyKind kind;
  final String name;
  final String shortDescription;

  /// Dica exibida quando a ameaça aparece pela primeira vez.
  final String counterHint;
  final double maxHp;

  /// Unidades lógicas por segundo.
  final double speed;
  final int reward;

  /// Dano causado à integridade do servidor ao alcançá-lo.
  final int baseDamage;
  final double radius;
  final int color;
  final String symbol;
  final EnemyShape shape;

  /// Proteção contra dano comum (removida pela defesa OWASP).
  final bool sqlShield;

  /// Começa oculto (precisa ser revelado ou detectado).
  final bool hidden;

  /// Redução de dano (0..1) enquanto não estiver sob efeito de correção.
  final double exploitArmor;
  final bool isBoss;
}

/// Fração do dano comum que atravessa a proteção de SQL Injection.
const double sqlShieldDamageFactor = 0.15;

const Map<EnemyKind, EnemyConfig> enemyConfigs = {
  EnemyKind.bruteForce: EnemyConfig(
    kind: EnemyKind.bruteForce,
    name: 'Força Bruta',
    shortDescription: 'Tentativas repetidas de senha. Pouca vida, aparece em grande número.',
    counterHint: 'Qualquer torre de ataque resolve. Fortinet é eficiente.',
    maxHp: 4,
    speed: 80,
    reward: 4,
    baseDamage: 1,
    radius: 14,
    color: 0xFF4FC3F7,
    symbol: '#',
    shape: EnemyShape.circle,
  ),
  EnemyKind.sqlInjection: EnemyConfig(
    kind: EnemyKind.sqlInjection,
    name: 'SQL Injection',
    shortDescription: "Consulta maliciosa (' OR 1=1). Blindada contra dano comum.",
    counterHint: 'OWASP remove a blindagem com consultas parametrizadas.',
    maxHp: 12,
    speed: 70,
    reward: 9,
    baseDamage: 3,
    radius: 16,
    color: 0xFFFFB300,
    symbol: 'SQL',
    shape: EnemyShape.hexagon,
    sqlShield: true,
  ),
  EnemyKind.xss: EnemyConfig(
    kind: EnemyKind.xss,
    name: 'XSS',
    shortDescription: 'Script injetado que se esconde no conteúdo. Fica oculto.',
    counterHint: 'CrowdStrike revela; OWASP detecta e remove a camuflagem.',
    maxHp: 9,
    speed: 95,
    reward: 9,
    baseDamage: 3,
    radius: 15,
    color: 0xFFE040FB,
    symbol: '</>',
    shape: EnemyShape.diamond,
    hidden: true,
  ),
  EnemyKind.ddos: EnemyConfig(
    kind: EnemyKind.ddos,
    name: 'Bot DDoS',
    shortDescription: 'Enxame de bots rápidos e frágeis que inundam o servidor.',
    counterHint: 'Cloudflare filtra grupos inteiros com dano em área.',
    maxHp: 1.5,
    speed: 140,
    reward: 2,
    baseDamage: 1,
    radius: 10,
    color: 0xFF69F0AE,
    symbol: 'b',
    shape: EnemyShape.triangle,
  ),
  EnemyKind.exploit: EnemyConfig(
    kind: EnemyKind.exploit,
    name: 'Exploit',
    shortDescription: 'Explora falhas sem correção. Muito resistente e causa dano alto.',
    counterHint: 'Microsoft aplica correções que deixam o Exploit vulnerável.',
    maxHp: 40,
    speed: 50,
    reward: 25,
    baseDamage: 10,
    radius: 20,
    color: 0xFFFF5252,
    symbol: '0day',
    shape: EnemyShape.square,
    exploitArmor: 0.5,
  ),
  EnemyKind.hydra: EnemyConfig(
    kind: EnemyKind.hydra,
    name: 'HYDRA AI',
    shortDescription: 'IA invasora fictícia. Ao ser destruída, libera várias ameaças.',
    counterHint: 'Concentre o fogo e prepare-se para os fragmentos liberados.',
    maxHp: 1100,
    speed: 26,
    reward: 250,
    baseDamage: 100,
    radius: 38,
    color: 0xFFB388FF,
    symbol: 'AI',
    shape: EnemyShape.boss,
    isBoss: true,
  ),
};

EnemyConfig enemyConfig(EnemyKind kind) => enemyConfigs[kind]!;
