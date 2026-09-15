import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friendship_provider.dart';
import '../../theme/app_colors.dart';
import 'widgets/friend_card.dart';
import 'widgets/friend_request_card.dart';
import 'package:quizmaster_pro/widgets/loading_logo.dart';
import '../../widgets/cosmetic_avatar.dart';

class SocialScreen extends StatefulWidget {
  final int initialTabIndex;
  const SocialScreen({super.key, this.initialTabIndex = 0});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      final int parsedId = int.tryParse(userId) ?? 0;
      if (parsedId > 0) {
        final prov = context.read<FriendshipProvider>();
        prov.initPresence(parsedId);
        prov.fetchFriends(parsedId);
        prov.fetchPendingRequests(parsedId);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addFriend() async {
    final username = _searchController.text.trim();
    if (username.isEmpty) return;
    
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    try {
      await context.read<FriendshipProvider>().sendFriendRequest(int.parse(userId), username);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido enviado com sucesso!'), backgroundColor: Colors.green),
        );
        _searchController.clear();
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Social', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Amigos'),
            Tab(text: 'Pedidos'),
            Tab(text: 'Notificações'),
            Tab(text: 'Adicionar'),
          ],
        ),
      ),
      body: Consumer<FriendshipProvider>(
        builder: (context, provider, child) {
          final userIdStr = context.read<AuthProvider>().currentUser?.id ?? '0';
          final userId = int.tryParse(userIdStr) ?? 0;

          return TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Amigos
              provider.isLoadingFriends
                  ? const Center(child: LoadingLogo(size: 60))
                  : provider.friends.isEmpty
                      ? const Center(child: Text('Ainda não tens amigos. Vai à aba "Adicionar"!', style: TextStyle(color: Colors.white70)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.friends.length,
                          itemBuilder: (context, index) {
                            final friend = provider.friends[index];
                            return FriendCard(
                              friend: friend,
                              onRemove: () => provider.removeFriend(userId, friend.id),
                            );
                          },
                        ),
              
              // Tab 2: Pedidos
              provider.isLoadingRequests
                  ? const Center(child: LoadingLogo(size: 60))
                  : DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          const TabBar(
                            indicatorColor: AppColors.primary,
                            labelColor: AppColors.primary,
                            unselectedLabelColor: Colors.white54,
                            tabs: [
                              Tab(text: 'Recebidos'),
                              Tab(text: 'Enviados'),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                // Recebidos
                                provider.pendingRequests.isEmpty
                                    ? const Center(child: Text('Não tens pedidos pendentes.', style: TextStyle(color: Colors.white70)))
                                    : ListView.builder(
                                        padding: const EdgeInsets.all(16),
                                        itemCount: provider.pendingRequests.length,
                                        itemBuilder: (context, index) {
                                          final request = provider.pendingRequests[index];
                                          return FriendRequestCard(
                                            request: request,
                                            onAccept: () => provider.acceptRequest(userId, request.friendshipId!),
                                            onReject: () => provider.rejectRequest(userId, request.friendshipId!),
                                          );
                                        },
                                      ),
                                // Enviados
                                provider.sentRequests.isEmpty
                                    ? const Center(child: Text('Não tens pedidos enviados.', style: TextStyle(color: Colors.white70)))
                                    : ListView.builder(
                                        padding: const EdgeInsets.all(16),
                                        itemCount: provider.sentRequests.length,
                                        itemBuilder: (context, index) {
                                          final request = provider.sentRequests[index];
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 12),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppColors.surface,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: AppColors.border),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    request.username,
                                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () => provider.cancelSentRequest(userId, request.friendshipId!),
                                                  child: const Text('Cancelar', style: TextStyle(color: Colors.redAccent)),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
              
              // Tab 3: Notificações
              const Center(
                child: Text('Nenhuma notificação.', style: TextStyle(color: Colors.white70)),
              ),

              // Tab 4: Adicionar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: (value) => context.read<FriendshipProvider>().searchUsers(value),
                      decoration: InputDecoration(
                        hintText: 'Pesquisar utilizador...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.search, color: Colors.white54),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward, color: AppColors.primary),
                          onPressed: () => context.read<FriendshipProvider>().searchUsers(_searchController.text),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: provider.isLoadingSearch
                          ? const Center(child: LoadingLogo(size: 60))
                          : provider.searchResults.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Usa a barra de pesquisa para encontrar amigos.',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: provider.searchResults.length,
                                  itemBuilder: (context, index) {
                                    final user = provider.searchResults[index];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Row(
                                        children: [
                                          CosmeticAvatar(
                                            radius: 24,
                                            avatarUrl: user.avatar,
                                            username: user.username,
                                            isVip: false,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  user.username,
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Nível ${user.level} • ${user.currentLeague}',
                                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              try {
                                                await provider.sendFriendRequest(userId, user.username);
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Pedido enviado com sucesso!'), backgroundColor: Colors.green),
                                                  );
                                                }
                                              } catch (e) {
                                                if (mounted) {
                                                  String errorMsg = e.toString().replaceAll('Exception: ', '');
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
                                                  );
                                                }
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            child: const Text('Adicionar', style: TextStyle(color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
