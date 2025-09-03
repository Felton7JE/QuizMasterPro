#!/bin/bash

echo "🧪 QuizMaster Pro - Testes de Integração"
echo "========================================"

# Verificar se o Flutter está instalado
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter não encontrado. Instale o Flutter primeiro."
    exit 1
fi

# Verificar se as dependências estão instaladas
echo "📦 Verificando dependências..."
flutter pub get

# Executar testes de integração
echo ""
echo "🔬 Executando testes de integração com backend..."
echo "⚠️  IMPORTANTE: Certifique-se de que o backend esteja rodando em http://localhost:8080"
echo ""

read -p "Backend está rodando? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Inicie o backend primeiro e execute este script novamente."
    exit 1
fi

echo "🚀 Executando testes..."
flutter test test/integration_test.dart

echo ""
echo "📱 Para testar manualmente:"
echo "1. Execute: flutter run"
echo "2. Navegue para: /test"
echo "3. Use a tela de teste para verificar a integração"
echo ""
echo "✅ Concluído!"
