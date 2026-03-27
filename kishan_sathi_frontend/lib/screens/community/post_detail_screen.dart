import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/posts/presentation/bloc/post_bloc.dart';
import '../../features/posts/presentation/bloc/post_event.dart';
import '../../features/posts/presentation/bloc/post_state.dart';
import '../../features/posts/data/repositories/post_repository.dart';
import '../../features/posts/data/models/post_models.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  Post? _currentPost;
  List<Comment> _comments = [];

  String _initialFromName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, yyyy').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _submitComment(BuildContext context) {
    if (_commentController.text.trim().isEmpty) return;

    context.read<PostBloc>().add(
          CreateComment(
            postId: widget.postId,
            content: _commentController.text.trim(),
          ),
        );
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final token = authState is AuthSuccess ? authState.token : '';

    return BlocProvider(
      create: (context) => PostBloc(
        postRepository: PostRepository(),
        token: token,
      )..add(LoadPostDetail(postId: widget.postId)),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: const Color(0xFF4CAF50),
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          title: const Text(
            'Post',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: BlocConsumer<PostBloc, PostState>(
          listener: (context, state) {
            if (state is PostDetailLoaded) {
              setState(() {
                _currentPost = state.post;
                _comments = state.post.comments ?? [];
              });
            } else if (state is PostVoted) {
              if (_currentPost != null && _currentPost!.id == state.postId) {
                setState(() {
                  _currentPost = _currentPost!.copyWith(
                    upvotesCount: state.upvotes,
                    downvotesCount: state.downvotes,
                    totalScore: state.totalScore,
                    userVote: state.userVote,
                  );
                });
              }
            } else if (state is CommentCreated) {
              setState(() {
                _comments = [..._comments, state.comment];
                if (_currentPost != null) {
                  _currentPost = _currentPost!.copyWith(
                    commentsCount: _currentPost!.commentsCount + 1,
                  );
                }
              });
            } else if (state is PostError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            if (state is PostLoading && _currentPost == null) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF4CAF50),
                ),
              );
            }

            if (_currentPost == null) {
              return const Center(child: Text('Post not found'));
            }

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Post Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Author info
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: const Color(0xFF4CAF50),
                                    backgroundImage:
                                        (_currentPost!.author.profilePictureUrl !=
                                                    null &&
                                                _currentPost!
                                                    .author
                                                    .profilePictureUrl!
                                                    .isNotEmpty)
                                            ? NetworkImage(_currentPost!
                                                .author.profilePictureUrl!)
                                            : null,
                                    child: (_currentPost!
                                                    .author
                                                    .profilePictureUrl ==
                                                null ||
                                            _currentPost!
                                                .author
                                                .profilePictureUrl!
                                                .isEmpty)
                                        ? Text(
                                            _initialFromName(
                                                _currentPost!.author.fullName),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              _currentPost!.author.fullName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF4CAF50),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                _currentPost!.category,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '${_currentPost!.author.role} • ${_formatTime(_currentPost!.createdAt)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Title
                              Text(
                                _currentPost!.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Content
                              Text(
                                _currentPost!.content,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[800],
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Vote buttons
                              Row(
                                children: [
                                  _VoteButton(
                                    icon: Icons.arrow_upward,
                                    count: _currentPost!.upvotesCount,
                                    isActive:
                                        _currentPost!.userVote == 'upvote',
                                    onTap: () {
                                      context.read<PostBloc>().add(
                                            VotePost(
                                              postId: widget.postId,
                                              voteType: 'upvote',
                                            ),
                                          );
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  _VoteButton(
                                    icon: Icons.arrow_downward,
                                    count: _currentPost!.downvotesCount,
                                    isActive:
                                        _currentPost!.userVote == 'downvote',
                                    onTap: () {
                                      context.read<PostBloc>().add(
                                            VotePost(
                                              postId: widget.postId,
                                              voteType: 'downvote',
                                            ),
                                          );
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${_currentPost!.totalScore}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: _currentPost!.totalScore > 0
                                          ? Colors.green
                                          : _currentPost!.totalScore < 0
                                              ? Colors.red
                                              : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Comments section
                      Text(
                        'Comments (${_comments.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Comments list
                      if (_comments.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No comments yet',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._comments.map((comment) => _CommentCard(
                              comment: comment,
                              formatTime: _formatTime,
                            )),
                    ],
                  ),
                ),

                // Comment input
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            maxLines: null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _submitComment(context),
                          icon: const Icon(
                            Icons.send,
                            color: Color(0xFF4CAF50),
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.green[50],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _VoteButton({
    required this.icon,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF4CAF50).withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF4CAF50) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? const Color(0xFF4CAF50) : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              count.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isActive ? const Color(0xFF4CAF50) : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final Comment comment;
  final String Function(DateTime) formatTime;

  const _CommentCard({
    required this.comment,
    required this.formatTime,
  });

  String _initialFromName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF4CAF50),
                  backgroundImage: (comment.author.profilePictureUrl != null &&
                          comment.author.profilePictureUrl!.isNotEmpty)
                      ? NetworkImage(comment.author.profilePictureUrl!)
                      : null,
                  child: (comment.author.profilePictureUrl == null ||
                          comment.author.profilePictureUrl!.isEmpty)
                      ? Text(
                          _initialFromName(comment.author.fullName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.author.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${comment.author.role} • ${formatTime(comment.createdAt)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comment.content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
