@echo off
echo 🧪 QuizMaster Pro - Testes de Integração
echo ========================================

REM Verificar se as dependências estão instaladas
echo 📦 Verificando dependências...
flutter pub get

REM Executar testes de integração
echo.
echo 🔬 Executando testes de integração com backend...
echo ⚠️  IMPORTANTE: Certifique-se de que o backend esteja rodando em http://localhost:8080
echo.

set /p backend="Backend está rodando? (y/n): "
if /i "%backend%" neq "y" (
    echo ❌ Inicie o backend primeiro e execute este script novamente.
    pause
    exit /b 1
)

echo 🚀 Executando testes...
flutter test test/integration_test.dart

echo.
echo 📱 Para testar manualmente:
echo 1. Execute: flutter run
echo 2. Navegue para: /test
echo 3. Use a tela de teste para verificar a integração
echo.
echo ✅ Concluído!
pause
