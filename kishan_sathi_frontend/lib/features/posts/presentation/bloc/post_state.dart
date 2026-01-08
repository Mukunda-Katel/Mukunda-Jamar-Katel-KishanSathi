import '../../data/models/post_models.dart';

abstract class PostState {}

class PostInitial extends PostState {}

class PostLoading extends PostState {}

class PostsLoaded extends PostState {
  final List<Post> posts;

  PostsLoaded({required this.posts});
}

class PostDetailLoaded extends PostState {
  final Post post;

  PostDetailLoaded({required this.post});
}

class PostCreated extends PostState {
  final Post post;

  PostCreated({required this.post});
}

class PostDeleted extends PostState {}

class PostVoted extends PostState {
  final int postId;
  final int upvotes;
  final int downvotes;
  final int totalScore;
  final String? userVote;

  PostVoted({
    required this.postId,
    required this.upvotes,
    required this.downvotes,
    required this.totalScore,
    this.userVote,
  });
}

class CommentsLoaded extends PostState {
  final List<Comment> comments;

  CommentsLoaded({required this.comments});
}

class CommentCreated extends PostState {
  final Comment comment;

  CommentCreated({required this.comment});
}

class PostError extends PostState {
  final String message;

  PostError({required this.message});
}
