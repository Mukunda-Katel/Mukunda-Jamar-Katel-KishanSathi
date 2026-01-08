import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';
import '../models/post_models.dart';

class PostRemoteDataSource {
  final http.Client client;

  PostRemoteDataSource({required this.client});

  Future<List<Post>> getPosts(
    String token, {
    int? authorId,
    bool myPosts = false,
    String? search,
  }) async {
    var uri = Uri.parse('${ApiConfig.baseUrl}/posts/');
    
    final queryParams = <String, String>{};
    if (authorId != null) queryParams['author_id'] = authorId.toString();
    if (myPosts) queryParams['my_posts'] = 'true';
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    
    if (queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final response = await client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((post) => Post.fromJson(post)).toList();
    } else {
      throw Exception('Failed to load posts: ${response.body}');
    }
  }

  Future<Post> getPostDetail(String token, int postId) async {
    final response = await client.get(
      Uri.parse('${ApiConfig.baseUrl}/posts/$postId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      return Post.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load post details: ${response.body}');
    }
  }

  Future<Post> createPost(
    String token,
    CreatePostRequest request,
    {File? imageFile}
  ) async {
    var uri = Uri.parse('${ApiConfig.baseUrl}/posts/');
    
    print('=== CREATE POST DEBUG ===');
    print('Image file provided: ${imageFile != null}');
    if (imageFile != null) {
      print('Image file path: ${imageFile.path}');
      print('Image file exists: ${await imageFile.exists()}');
      print('Image file size: ${await imageFile.length()} bytes');
    }
    
    if (imageFile != null) {
      // Use multipart for image upload
      var multipartRequest = http.MultipartRequest('POST', uri);
      multipartRequest.headers['Authorization'] = 'Token $token';
      
      multipartRequest.fields['title'] = request.title;
      multipartRequest.fields['content'] = request.content;
      multipartRequest.fields['category'] = request.category;
      
      print('Multipart fields: ${multipartRequest.fields}');
      
      // Add image file
      var imageStream = http.ByteStream(imageFile.openRead());
      var imageLength = await imageFile.length();
      var multipartFile = http.MultipartFile(
        'image',
        imageStream,
        imageLength,
        filename: imageFile.path.split('/').last,
      );
      multipartRequest.files.add(multipartFile);
      
      print('Multipart file added: ${multipartFile.filename}, ${multipartFile.length} bytes');
      print('Sending request to: $uri');
      
      var streamedResponse = await multipartRequest.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 201) {
        var post = Post.fromJson(json.decode(response.body));
        print('Post created with image URL: ${post.image}');
        return post;
      } else {
        throw Exception('Failed to create post: ${response.body}');
      }
    } else {
      // Use JSON for text-only posts
      final response = await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 201) {
        return Post.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create post: ${response.body}');
      }
    }
  }

  Future<void> deletePost(String token, int postId) async {
    final response = await client.delete(
      Uri.parse('${ApiConfig.baseUrl}/posts/$postId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete post: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> votePost(
    String token,
    int postId,
    String voteType,
  ) async {
    final response = await client.post(
      Uri.parse('${ApiConfig.baseUrl}/posts/$postId/vote/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: json.encode(VoteRequest(voteType: voteType).toJson()),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to vote: ${response.body}');
    }
  }

  Future<List<Comment>> getComments(String token, int postId) async {
    final response = await client.get(
      Uri.parse('${ApiConfig.baseUrl}/posts/$postId/comments/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((comment) => Comment.fromJson(comment)).toList();
    } else {
      throw Exception('Failed to load comments: ${response.body}');
    }
  }

  Future<Comment> createComment(
    String token,
    CreateCommentRequest request,
  ) async {
    final response = await client.post(
      Uri.parse('${ApiConfig.baseUrl}/comments/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 201) {
      return Comment.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create comment: ${response.body}');
    }
  }
}
