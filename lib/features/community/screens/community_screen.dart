import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';

// --------------- Providers ---------------

final communityPostsProvider =
    StateNotifierProvider<CommunityNotifier, List<CommunityPost>>(
        (ref) => CommunityNotifier());

class CommunityPost {
  final String id;
  final String userName;
  final String userInitial;
  final Color avatarColor;
  final String message;
  final String messageInTelugu;
  final String time;
  final String tag;
  int likes;
  bool likedByMe;

  CommunityPost({
    required this.id,
    required this.userName,
    required this.userInitial,
    required this.avatarColor,
    required this.message,
    required this.messageInTelugu,
    required this.time,
    required this.tag,
    this.likes = 0,
    this.likedByMe = false,
  });

  CommunityPost copyWith({int? likes, bool? likedByMe}) => CommunityPost(
        id: id,
        userName: userName,
        userInitial: userInitial,
        avatarColor: avatarColor,
        message: message,
        messageInTelugu: messageInTelugu,
        time: time,
        tag: tag,
        likes: likes ?? this.likes,
        likedByMe: likedByMe ?? this.likedByMe,
      );
}

class CommunityNotifier extends StateNotifier<List<CommunityPost>> {
  CommunityNotifier() : super(_initialPosts());

  void toggleLike(String postId) {
    state = state.map((post) {
      if (post.id != postId) return post;
      return post.copyWith(
        likes: post.likedByMe ? post.likes - 1 : post.likes + 1,
        likedByMe: !post.likedByMe,
      );
    }).toList();
  }

  void addPost(String message) {
    final newPost = CommunityPost(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userName: 'You',
      userInitial: 'Y',
      avatarColor: AppColors.primary,
      message: message,
      messageInTelugu: message,
      time: 'Just now',
      tag: 'General',
      likes: 0,
    );
    state = [newPost, ...state];
  }

  static List<CommunityPost> _initialPosts() => [
        CommunityPost(
          id: '1',
          userName: 'Anji Reddy',
          userInitial: 'A',
          avatarColor: const Color(0xFF1565C0),
          message:
              'Kurnool Sona Masuri variety is doing excellent with drip irrigation this season! Very low water consumption.',
          messageInTelugu:
              'Kurnool Sona Masuri variety is doing excellent with drip irrigation this season! Very low water consumption.',
          time: '2 hours ago',
          tag: '🌾 Crop Tips',
          likes: 24,
        ),
        CommunityPost(
          id: '2',
          userName: 'Suresh Garu',
          userInitial: 'S',
          avatarColor: const Color(0xFF6A1B9A),
          message:
              'Natural neem oil spray (5ml/litre) worked perfectly for tomato whitefly. No chemicals needed!',
          messageInTelugu:
              'Natural neem oil spray (5ml/litre) worked perfectly for tomato whitefly. No chemicals needed!',
          time: '5 hours ago',
          tag: '🌿 Natural Remedy',
          likes: 41,
        ),
        CommunityPost(
          id: '3',
          userName: 'Ramesh P',
          userInitial: 'R',
          avatarColor: const Color(0xFFE65100),
          message:
              'Does anyone know the best selling price for dry chilli in Adoni mandi this week?',
          messageInTelugu:
              'Does anyone know the best selling price for dry chilli in Adoni mandi this week?',
          time: 'Yesterday',
          tag: '💰 Market Query',
          likes: 8,
        ),
        CommunityPost(
          id: '4',
          userName: 'Lakshmi Devi',
          userInitial: 'L',
          avatarColor: const Color(0xFF00695C),
          message:
              'I switched to mulching for my Onion crop – saved almost 40% water! Highly recommend for Kurnool region.',
          messageInTelugu:
              'I switched to mulching for my Onion crop – saved almost 40% water! Highly recommend for Kurnool region.',
          time: '2 days ago',
          tag: '💧 Water Saving',
          likes: 57,
        ),
      ];
}

// --------------- Screen ---------------

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  String _selectedTag = 'All';

  final List<String> _tags = [
    'All',
    '🌾 Crop Tips',
    '🌿 Natural Remedy',
    '💰 Market Query',
    '💧 Water Saving',
  ];

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(communityPostsProvider);
    final filtered = _selectedTag == 'All'
        ? posts
        : posts.where((p) => p.tag == _selectedTag).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── App Bar ────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF6A1B9A),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
              title: const Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Farmer Community',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          fontWeight: FontWeight.normal)),
                  Text('Community Tips',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4A148C), Color(0xFF7B1FA2), Color(0xFFAB47BC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 20),
                    child: Opacity(
                        opacity: 0.15,
                        child: Text('👨‍🌾', style: TextStyle(fontSize: 90))),
                  ),
                ),
              ),
            ),
          ),

          // ─── Filter Tags ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: _tags
                    .map((tag) => _TagChip(
                          label: tag,
                          selected: _selectedTag == tag,
                          onTap: () => setState(() => _selectedTag = tag),
                        ))
                    .toList(),
              ),
            ),
          ),

          // ─── Post Count ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                '${filtered.length} posts',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ),

          // ─── Posts ───────────────────────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _PostCard(
                post: filtered[index],
                onLike: () {
                  HapticFeedback.lightImpact();
                  ref
                      .read(communityPostsProvider.notifier)
                      .toggleLike(filtered[index].id);
                },
              ),
              childCount: filtered.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // ─── FAB: Post ──────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPostDialog(context),
        backgroundColor: const Color(0xFF7B1FA2),
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: const Text('Post a Tip',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showPostDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share Experience',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark)),
            const Text('Share your farming tip',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share farming tips... (English)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0xFF7B1FA2), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B1FA2)),
                    onPressed: () {
                      if (ctrl.text.trim().isNotEmpty) {
                        ref
                            .read(communityPostsProvider.notifier)
                            .addPost(ctrl.text.trim());
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Post',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tag Chip ─────────────────────────────────────────────────────────────────
class _TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TagChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF7B1FA2) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? const Color(0xFF7B1FA2) : Colors.grey.shade300),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: const Color(0xFF7B1FA2).withValues(alpha: 0.3),
                      blurRadius: 6)
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Post Card ────────────────────────────────────────────────────────────────
class _PostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback onLike;

  const _PostCard({required this.post, required this.onLike});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: post.avatarColor,
                child: Text(post.userInitial,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.userName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary)),
                    Text(post.time,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: post.avatarColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(post.tag,
                    style: TextStyle(fontSize: 10, color: post.avatarColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Telugu content (hidden for english flow)
          Text(post.message,
              style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),

          // Footer
          Row(
            children: [
              GestureDetector(
                onTap: onLike,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Row(
                    key: ValueKey(post.likedByMe),
                    children: [
                      Icon(
                          post.likedByMe
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 18,
                          color: post.likedByMe ? Colors.red : Colors.grey),
                      const SizedBox(width: 4),
                      Text('${post.likes}',
                          style: TextStyle(
                              fontSize: 13,
                              color: post.likedByMe
                                  ? Colors.red
                                  : Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              const Icon(Icons.comment_outlined, size: 18, color: Colors.grey),
              const SizedBox(width: 4),
              const Text('Reply',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const Spacer(),
              Icon(Icons.share_outlined, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ],
      ),
    );
  }
}
