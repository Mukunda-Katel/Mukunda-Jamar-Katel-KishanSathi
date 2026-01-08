import 'dart:io';
import '../../data/models/post_models.dart';

abstract class PostEvent {}

class LoadPosts extends PostEvent {
  final int? authorId;
  final bool myPosts;
  final String? search;

  LoadPosts({this.authorId, this.myPosts = false, this.search});
}

class LoadPostDetail extends PostEvent {
  final int postId;

  LoadPostDetail({required this.postId});
}

class CreatePost extends PostEvent {
  final String title;
  final String content;
  final String category;
  final File? imageFile;

  CreatePost({
    required this.title,
    required this.content,
    required this.category,
    this.imageFile,
  });
}

class DeletePost extends PostEvent {
  final int postId;

  DeletePost({required this.postId});
}

class VotePost extends PostEvent {
  final int postId;
  final String voteType;

  VotePost({required this.postId, required this.voteType});
}

class LoadComments extends PostEvent {
  final int postId;

  LoadComments({required this.postId});
}

class CreateComment extends PostEvent {
  final int postId;
  final String content;

  CreateComment({required this.postId, required this.content});
}
