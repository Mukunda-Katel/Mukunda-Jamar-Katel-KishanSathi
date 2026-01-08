import 'dart:io';
import 'package:http/http.dart' as http;
import '../datasources/post_remote_datasource.dart';
import '../models/post_models.dart';

class PostRepository {
  final PostRemoteDataSource? remoteDataSource;

  PostRepository({PostRemoteDataSource? remoteDataSource})
      : remoteDataSource =
            remoteDataSource ?? PostRemoteDataSource(client: http.Client());

  Future<List<Post>> getPosts(
    String token, {
    int? authorId,
    bool myPosts = false,
    String? search,
  }) async {
    return await remoteDataSource!.getPosts(
      token,
      authorId: authorId,
      myPosts: myPosts,
      search: search,
    );
  }

  Future<Post> getPostDetail(String token, int postId) async {
    return await remoteDataSource!.getPostDetail(token, postId);
  }

  Future<Post> createPost(String token, CreatePostRequest request, {File? imageFile}) async {
    return await remoteDataSource!.createPost(token, request, imageFile: imageFile);
  }

  Future<void> deletePost(String token, int postId) async {
    return await remoteDataSource!.deletePost(token, postId);
  }

  Future<Map<String, dynamic>> votePost(
    String token,
    int postId,
    String voteType,
  ) async {
    return await remoteDataSource!.votePost(token, postId, voteType);
  }

  Future<List<Comment>> getComments(String token, int postId) async {
    return await remoteDataSource!.getComments(token, postId);
  }

  Future<Comment> createComment(
    String token,
    CreateCommentRequest request,
  ) async {
    return await remoteDataSource!.createComment(token, request);
  }
}
