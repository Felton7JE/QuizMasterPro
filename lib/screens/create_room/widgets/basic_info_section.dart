import 'package:flutter/material.dart';

class BasicInfoSection extends StatelessWidget {
  final TextEditingController roomNameController;
  final TextEditingController passwordController;
  final int maxPlayers;
  final String selectedMode;
  final ValueChanged<int?> onMaxPlayersChanged;

  const BasicInfoSection({
    super.key,
    required this.roomNameController,
    required this.passwordController,
    required this.maxPlayers,
    required this.selectedMode,
    required this.onMaxPlayersChanged,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: roomNameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Nome da Sala',
            labelStyle: TextStyle(color: Colors.grey),
            hintText: 'Ex: Sala dos Amigos',
            hintStyle: TextStyle(color: Colors.grey),
            helperText: 'Escolha um nome único e fácil de lembrar',
            helperStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF334155)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF6366F1)),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, digite um nome para a sala';
            }
            if (value.length < 3) {
              return 'O nome deve ter pelo menos 3 caracteres';
            }
            return null;
          },
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        if (isSmallScreen) ...[
          // Em telas pequenas, empilha verticalmente
          TextFormField(
            controller: passwordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Senha (Opcional)',
              labelStyle: TextStyle(color: Colors.grey),
              hintText: 'Deixe vazio para sala pública',
              hintStyle: TextStyle(color: Colors.grey),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF6366F1)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (selectedMode != 'duel')
            DropdownButtonFormField<int>(
              initialValue: maxPlayers,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Máximo de Jogadores',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6366F1)),
                ),
              ),
              dropdownColor: const Color(0xFF1E293B),
              items: [2, 4, 6, 8, 12, 20].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value jogadores'),
                );
              }).toList(),
              onChanged: onMaxPlayersChanged,
            ),
        ] else ...[
          // Em telas maiores, mantém lado a lado
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Senha (Opcional)',
                    labelStyle: TextStyle(color: Colors.grey),
                    hintText: 'Deixe vazio para sala pública',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF334155)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF6366F1)),
                    ),
                  ),
                ),
              ),
              if (selectedMode != 'duel') ...[
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: maxPlayers,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Máximo de Jogadores',
                      labelStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF334155)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF6366F1)),
                      ),
                    ),
                    dropdownColor: const Color(0xFF1E293B),
                    items: [2, 4, 6, 8, 12, 20].map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value jogadores'),
                      );
                    }).toList(),
                    onChanged: onMaxPlayersChanged,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
