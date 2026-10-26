# PHP Defense — Cybersecurity Tower Defense

**PHP Defense** é um jogo de tower defense com temática de cibersegurança inspirado nas mecânicas de ondas e inimigos com camadas (estilo Bloons TD6), desenvolvido em **Flutter**, **Flame**, **Riverpod**, **GoRouter** e **Supabase**.

O jogador assume o papel de administrador de segurança encarregado de proteger um servidor que executa uma aplicação PHP. Ataques cibernéticos percorrem trilhas de dados em uma placa de circuito impresso em direção ao servidor. O jogador posiciona, melhora e vende torres defensivas inspiradas em entidades do ecossistema de cibersegurança para neutralizar as invasões.

---

## 1. Visão Geral da Arquitetura

O projeto foi organizado separando rigorosamente a simulação do jogo da interface e do acesso a dados:

```
lib/
├── core/                        # Configurações centrais, tema e rotas
│   ├── env.dart                 # Leitura de variáveis via --dart-define
│   ├── router.dart              # Rotas declarativas do GoRouter
│   └── theme.dart               # Paleta cibersegurança (dark blue, ciano, roxo, alertas)
├── data/
│   └── supabase_backend.dart    # Cliente de autenticação, RPCs transacionais e RLS
├── game/
│   ├── config/                  # Definições centrais e editáveis de conteúdo
│   │   ├── boss_config.dart     # Configuração do chefe HYDRA AI e inimigos liberados
│   │   ├── enemy_config.dart    # 5 inimigos com atributos, blindagens e formatos
│   │   ├── game_rules.dart      # Regras globais (integridade, créditos, passos fixos)
│   │   ├── map_config.dart      # Grade lógica, caminho e validação de mapa
│   │   ├── tower_config.dart    # 5 torres, níveis 1-3, custos e multiplicadores
│   │   └── wave_config.dart     # 15 ondas progressivas com introdução gradual
│   ├── flame/
│   │   └── php_defense_game.dart# Câmera com resolução fixa e gerenciamento de ciclo de vida
│   ├── render/
│   │   ├── circuit_components.dart # Renderização da placa de circuito, trilhas e servidor
│   │   ├── entity_renderer_component.dart # Torres, inimigos, projéteis e efeitos
│   │   └── glyph_painter.dart   # Desenho vetorial compartilhado (sem imagens externas)
│   └── sim/                     # Simulação pura em Dart (independente de renderização)
│       ├── entities.dart        # Torres, inimigos, projéteis com estados de blindagem
│       ├── game_simulation.dart # Laço de simulação com delta time fixo (1/60s)
│       ├── path_track.dart      # Parametrização por distância do caminho percorrido
│       ├── score_rules.dart     # Fórmula determinística de cálculo de pontuação
│       ├── sim_events.dart      # Eventos desacoplados para renderização
│       └── vec.dart             # Estruturas vetoriais imutáveis
├── models/                      # Modelos de domínio (perfil, conquistas, ranking, resultado)
├── screens/                     # Telas completas da aplicação
│   ├── achievements_screen.dart # Conquistas desbloqueadas e progresso
│   ├── auth_screen.dart         # Login e cadastro com validações e tradução PT-BR
│   ├── main_menu_screen.dart    # Menu principal com identificação de modo
│   ├── map_select_screen.dart   # Seleção e especificações do mapa
│   ├── match_screen.dart        # Partida interativa com HUD e controles
│   ├── profile_screen.dart      # Perfil, edição de apelido e estatísticas de carreira
│   ├── ranking_screen.dart      # Ranking global sem exposição de e-mail
│   ├── result_screen.dart       # Relatório pós-partida e sincronização
│   ├── splash_screen.dart       # Splash animado e roteamento automático
│   └── tutorial_screen.dart     # Manual didático de regras, defesas e ameaças
├── state/                       # Gerenciamento de estado com Riverpod
│   ├── app_providers.dart       # Provedores de autenticação, ranking e conquistas
│   └── match_controller.dart   # Controlador da partida e comunicação com HUD
└── widgets/                     # Componentes visuais reutilizáveis
    └── cyber_widgets.dart       # Ícones de torres via Canvas e cartões estilizados
```

---

## 2. Conteúdo e Mecânicas

### Torres de Defesa (Abstrações Didáticas)
Cada torre possui 3 níveis de evolução editáveis:
1. **Fortinet (Firewall)**: Disparos equilibrados e cadenciados. Ideal para ameaças comuns.
2. **Cloudflare (Filtragem de Tráfego)**: Disparos de dano em área com bônus de 2,5x contra grupos e bots DDoS; adiciona lentidão nos níveis 2 e 3.
3. **CrowdStrike (Detecção)**: Revela ameaças ocultas no raio de ação para que as demais torres possam atingi-las.
4. **OWASP (Defesa da Aplicação)**: Representa consultas parametrizadas e codificação segura; quebra a blindagem de SQL Injection e a camuflagem de scripts XSS.
5. **Microsoft (Correção e Suporte)**: Aplica patches de segurança que deixam Exploits vulneráveis e concede bônus de dano e cadência para torres vizinhas (bônus não-cumulativo entre torres de suporte).

### Ameaças Cibernéticas
- **Força Bruta**: Ataque frequente, pouca vida e rápida aparição.
- **SQL Injection**: Possui blindagem contra dano convencional; dano normal é reduzido a 15% até que a defesa OWASP quebre a proteção.
- **XSS**: Surge camuflado; precisa ser detectado pela CrowdStrike ou neutralizado pela OWASP.
- **Bot DDoS**: Enxames rápidos e frágeis; favorece torres de filtragem em área.
- **Exploit**: Muito resistente, com alta absorção de dano e alto impacto no servidor; fica vulnerável sob efeito da torre Microsoft.
- **HYDRA AI (Chefe Final - Onda 15)**: IA invasora fictícia lenta com alta resistência. Ao ser destruída, **se fragmenta em um grupo de ameaças menores** que continuam a avançar a partir do ponto onde a Hydra foi derrotada.

### Economia e Regras
- **Integridade Inicial**: 100 HP.
- **Créditos Iniciais**: 400 créditos.
- **Venda de Torres**: Reembolsa exatamente **70%** do valor total investido (construção + melhorias).
- **Velocidades**: 1x e 2x (a simulação avança em passos fixos de `1/60` de segundo, garantindo que o resultado e a pontuação sejam idênticos independente da taxa de quadros e velocidade).
- **Pausa**: Congela completamente temporizadores, projéteis, deslocamentos e geração de inimigos.

---

## 3. Persistência e Supabase

### Migrations SQL
As migrations estão localizadas em `supabase/migrations/20261026_init_cybersecurity.sql` e definem:
- `profiles`: Armazena dados de carreira, apelido único (3-20 caracteres) e estatísticas agregadas.
- `matches`: Registra o histórico de partidas com `start_match` e `finish_match`.
- `achievements` e `user_achievements`: Definição e concessão transacional das 6 conquistas.
- **Políticas de RLS**:
  - Usuários só alteram seu próprio perfil.
  - Resultados de partidas só podem ser consultados pelo dono e não podem ser editados livremente pelo client.
  - O ranking é obtido pela RPC `get_leaderboard(p_limit)`, expondo apenas apelido, pontuação e estatísticas públicas (**nunca e-mails**).
  - A função transacional `finish_match` impede gravações duplicadas (idempotência) e calcula a pontuação oficial no PostgreSQL:
    $$\text{Pontos} = (\text{Ondas} \times 1000) + (\text{Abates} \times 10) + (\text{Integridade} \times 25) + (\text{Vitória} ? 5000 : 0)$$

### Modo de Demonstração Local
Caso as variáveis de ambiente do Supabase não sejam fornecidas, o jogo ativa automaticamente o **Modo Demonstração Local**. O jogador pode jogar a partida completa, ver tutoriais, regras e estatísticas da sessão sem travas e sem falsificar autenticação ou poluir o ranking global.

---

## 4. Instruções de Instalação e Execução

### Pré-requisitos
- Flutter 3.24+ (ou superior) com suporte a Dart 3.5+.
- Dispositivo Android conectado ou Google Chrome instalado.

### Executar no Navegador (Chrome)
```bash
# Modo demonstração local (sem necessidade de backend):
flutter run -d chrome

# Conectado a um projeto Supabase configurado:
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://SEU_PROJETO.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_SUA_CHAVE
```

### Executar no Celular (Android)
```bash
# Modo demonstração local:
flutter run -d android

# Conectado ao Supabase:
flutter run -d android \
  --dart-define=SUPABASE_URL=https://SEU_PROJETO.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_SUA_CHAVE
```

*(Nota: a chave legada `--dart-define=SUPABASE_ANON_KEY=...` também é aceita caso você utilize uma versão anterior do painel Supabase).*

---

## 5. Testes e Validação Automatizada

Para executar a suíte completa de testes automatizados:

```bash
flutter test
```

### Cobertura dos Testes:
- **Economia e Posicionamento**: Saldo inicial, bloqueio de sobreposição de caminho/servidor/outras torres, devolução de 70% na venda, proibição de créditos negativos.
- **Mecânicas Especializadas**:
  - Blindagem do SQL Injection e anulação pela defesa OWASP.
  - Camuflagem do XSS e revelação pela CrowdStrike.
  - Bônus de suporte não-cumulativo e vulnerabilização de Exploits pela Microsoft.
- **Comportamento do Chefe**: Divisão da HYDRA AI ao ser eliminada, surgimento de inimigos menores a partir da coordenada do chefe e conclusão da partida apenas após a limpeza total.
- **Ciclo de Vida e Pontuação**: Projétil teleguiado dissipado ao perder o alvo, cálculo estrito de pontuação e consistência transacional.
- **Equilíbrio das 15 Ondas**: Jogador automatizado demonstrando viabilidade de vitória das 15 ondas com a economia calibrada.
