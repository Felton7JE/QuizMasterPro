# QuizMaster Pro - Aplicativo de Quiz Multiplayer

Um protótipo HTML/CSS completo e moderno para um aplicativo de quiz multiplayer com diferentes modos de jogo, sistema de ranking e funcionalidades online/offline.

## 🎯 Visão Geral

O QuizMaster Pro é um aplicativo de quiz interativo que permite aos usuários:

- **Jogar em equipes** de até 4 jogadores cada, com especialização por categoria
- **Duelos 1v1** para confrontos diretos
- **Quiz clássico** individual para treino
- **Modo Kahoot** com perguntas simultâneas para grupos grandes
- **Sistema de ranking** global e por categoria
- **Funcionalidade online e offline** via hotspot Wi-Fi

## 🚀 Funcionalidades Principais

### Modos de Jogo
- **Modo Equipe (4x4)**: Duas equipes de até 4 jogadores, cada um especialista em uma categoria
- **Duelo 1v1**: Confronto direto entre dois jogadores
- **Quiz Clássico**: Modo individual para treino e aprendizado
- **Estilo Kahoot**: Todos respondem simultaneamente com ranking ao vivo

### Sistema de Pontuação
- Pontuação baseada em precisão e velocidade
- Sistema de sequências (streaks) para respostas consecutivas corretas
- Ranking global e por categoria
- Conquistas e medalhas

### Personalização
- Configuração de tempo por pergunta
- Seleção de dificuldade (Fácil, Médio, Difícil)
- Escolha de categorias (Matemática, Português, História, Geografia, Ciências)
- Número personalizável de perguntas

## 📁 Estrutura do Projeto

```
quiz-app/
├── index.html              # Página inicial
├── menu.html               # Menu principal
├── create-room.html         # Criação de salas
├── quiz-game.html          # Interface de jogo
├── ranking.html            # Sistema de ranking
├── README.md               # Documentação
├── todo.md                 # Lista de tarefas do projeto
├── assets/
│   ├── css/
│   │   ├── style.css       # CSS principal com design system
│   │   ├── home.css        # Estilos da página inicial
│   │   ├── menu.css        # Estilos do menu
│   │   ├── create-room.css # Estilos da criação de sala
│   │   ├── quiz-game.css   # Estilos da interface de jogo
│   │   └── ranking.css     # Estilos do ranking
│   ├── js/
│   │   └── main.js         # JavaScript principal
│   └── images/             # Imagens e assets
```

## 🎨 Design System

### Cores Principais
- **Primary**: `#6366f1` (Índigo vibrante)
- **Secondary**: `#f59e0b` (Âmbar)
- **Success**: `#10b981` (Verde esmeralda)
- **Error**: `#ef4444` (Vermelho)
- **Background**: `#0f172a` (Azul escuro)

### Tipografia
- **Display**: Poppins (títulos e destaques)
- **Body**: Inter (texto geral)

### Componentes
- Sistema de grid responsivo
- Cards interativos com hover effects
- Botões com gradientes e animações
- Formulários estilizados
- Sistema de badges e indicadores

## 📱 Responsividade

O projeto foi desenvolvido com abordagem mobile-first e inclui:

- **Desktop**: Layout completo com sidebar e múltiplas colunas
- **Tablet**: Adaptação para telas médias com reorganização de elementos
- **Mobile**: Interface otimizada para dispositivos móveis

### Breakpoints
- **Desktop**: > 1024px
- **Tablet**: 768px - 1024px
- **Mobile**: < 768px

## 🛠️ Tecnologias Utilizadas

- **HTML5**: Estrutura semântica e acessível
- **CSS3**: Estilos modernos com Flexbox, Grid e animações
- **JavaScript**: Interatividade e funcionalidades dinâmicas
- **SVG Icons**: Ícones vetoriais para melhor qualidade
- **Google Fonts**: Tipografia profissional (Inter e Poppins)

## 🎯 Páginas Implementadas

### 1. Página Inicial (`index.html`)
- Hero section com animações
- Apresentação dos recursos
- Modos de jogo detalhados
- Call-to-action e estatísticas

### 2. Menu Principal (`menu.html`)
- Dashboard do usuário
- Seleção de modos de jogo
- Estatísticas pessoais
- Atividade recente

### 3. Criação de Sala (`create-room.html`)
- Formulário completo de configuração
- Seleção de modo de jogo
- Configurações avançadas
- Prévia da sala em tempo real

### 4. Interface de Jogo (`quiz-game.html`)
- Tela de perguntas interativa
- Timer visual animado
- Sistema de equipes
- Chat em tempo real
- Overlay de resultados

### 5. Sistema de Ranking (`ranking.html`)
- Pódio dos top 3 jogadores
- Tabela de classificação completa
- Filtros por período e categoria
- Rankings específicos por matéria

## ⚡ Funcionalidades JavaScript

### Interatividade
- Menu mobile responsivo
- Animações de scroll
- Efeitos de hover e transições
- Formulários dinâmicos
- Timer de jogo animado

### Componentes Dinâmicos
- Seleção de modos de jogo
- Configuração de salas
- Sistema de chat
- Atualização de pontuação em tempo real

## 🎮 Como Usar

### Navegação Básica
1. Abra `index.html` em um navegador moderno
2. Clique em "Jogar Agora" para acessar o menu principal
3. Escolha um modo de jogo ou explore outras funcionalidades

### Criação de Sala
1. No menu principal, clique em "Criar Sala"
2. Configure o nome da sala e parâmetros do jogo
3. Escolha o modo de jogo e categorias
4. Ajuste configurações avançadas se necessário
5. Clique em "Criar Sala" para finalizar

### Visualização do Ranking
1. Acesse "Ranking" no menu principal
2. Use os filtros para ver rankings específicos
3. Explore os rankings por categoria

## 🏆 Destaques do Design

### Visual
- **Gradientes modernos** em botões e elementos de destaque
- **Animações suaves** para melhor experiência do usuário
- **Cards interativos** com efeitos de hover
- **Tipografia hierárquica** para melhor legibilidade

### UX/UI
- **Navegação intuitiva** entre páginas
- **Feedback visual** para todas as interações
- **Estados de loading** e transições
- **Indicadores visuais** de progresso e status

### Acessibilidade
- **Contraste adequado** para legibilidade
- **Elementos focáveis** para navegação por teclado
- **Estrutura semântica** HTML
- **Textos alternativos** para elementos visuais

## 🔧 Personalização

### Cores
Edite as variáveis CSS em `assets/css/style.css`:
```css
:root {
    --primary-color: #6366f1;
    --secondary-color: #f59e0b;
    /* ... outras variáveis */
}
```

### Fontes
Altere as importações no início dos arquivos CSS:
```css
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Poppins:wght@400;500;600;700;800&display=swap');
```

### Layout
Ajuste os breakpoints responsivos conforme necessário:
```css
@media (max-width: 768px) {
    /* Estilos mobile */
}
```

## 📈 Próximos Passos

Para transformar este protótipo em uma aplicação funcional:

1. **Backend**: Implementar servidor com Node.js/Express ou Python/Flask
2. **Banco de Dados**: Adicionar MongoDB ou PostgreSQL para persistência
3. **WebSockets**: Implementar comunicação em tempo real
4. **Autenticação**: Sistema de login e registro de usuários
5. **API**: Endpoints para gerenciar perguntas, salas e rankings
6. **PWA**: Transformar em Progressive Web App
7. **Deploy**: Hospedar em plataformas como Vercel, Netlify ou Heroku

## 🤝 Contribuição

Este é um protótipo desenvolvido para demonstrar as funcionalidades e design do aplicativo QuizMaster Pro. O código está organizado e documentado para facilitar futuras implementações e melhorias.

## 📄 Licença

Este projeto é um protótipo desenvolvido para fins demonstrativos e educacionais.

---

**Desenvolvido com 💜 para o concurso**

*QuizMaster Pro - Onde o conhecimento encontra a diversão!*

