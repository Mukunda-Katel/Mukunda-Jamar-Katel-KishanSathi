class PostAuthor {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final String? profilePictureUrl;

  PostAuthor({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.profilePictureUrl,
  });

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      id: json['id'] as int? ?? 0,
      fullName: json['full_name'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'unknown',
      profilePictureUrl: json['profile_picture_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'role': role,
      'profile_picture_url': profilePictureUrl,
    };
  }
}

class Post {
  final int id;
  final PostAuthor author;
  final String title;
  final String content;
  final String category;
  final String? image;
  final int upvotesCount;
  final int downvotesCount;
  final int totalScore;
  final int commentsCount;
  final String? userVote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Comment>? comments;

  Post({
    required this.id,
    required this.author,
    required this.title,
    required this.content,
    required this.category,
    this.image,
    required this.upvotesCount,
    required this.downvotesCount,
    required this.totalScore,
    required this.commentsCount,
    this.userVote,
    required this.createdAt,
    required this.updatedAt,
    this.comments,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int? ?? 0,
      author: PostAuthor.fromJson(json['author'] as Map<String, dynamic>),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      image: json['image'] as String?,
      upvotesCount: json['upvotes_count'] as int? ?? 0,
      downvotesCount: json['downvotes_count'] as int? ?? 0,
      totalScore: json['total_score'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      userVote: json['user_vote'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      comments: json['comments'] != null
          ? (json['comments'] as List)
              .map((c) => Comment.fromJson(c as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author.toJson(),
      'title': title,
      'content': content,
      'category': category,
      'image': image,
      'upvotes_count': upvotesCount,
      'downvotes_count': downvotesCount,
      'total_score': totalScore,
      'comments_count': commentsCount,
      'user_vote': userVote,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (comments != null) 'comments': comments!.map((c) => c.toJson()).toList(),
    };
  }

  Post copyWith({
    int? upvotesCount,
    int? downvotesCount,
    int? totalScore,
    String? userVote,
    int? commentsCount,
    List<Comment>? comments,
  }) {
    return Post(
      id: id,
      author: author,
      title: title,
      content: content,
      category: category,
      image: image,
      upvotesCount: upvotesCount ?? this.upvotesCount,
      downvotesCount: downvotesCount ?? this.downvotesCount,
      totalScore: totalScore ?? this.totalScore,
      commentsCount: commentsCount ?? this.commentsCount,
      userVote: userVote ?? this.userVote,
      createdAt: createdAt,
      updatedAt: updatedAt,
      comments: comments ?? this.comments,
    );
  }
}

class Comment {
  final int id;
  final int post;
  final PostAuthor author;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Comment({
    required this.id,
    required this.post,
    required this.author,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int? ?? 0,
      post: json['post'] as int? ?? 0,
      author: PostAuthor.fromJson(json['author'] as Map<String, dynamic>),
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post': post,
      'author': author.toJson(),
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class CreatePostRequest {
  final String title;
  final String content;
  final String category;

  CreatePostRequest({
    required this.title,
    required this.content,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'category': category,
    };
  }
}

class CreateCommentRequest {
  final int post;
  final String content;

  CreateCommentRequest({
    required this.post,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'post': post,
      'content': content,
    };
  }
}

class VoteRequest {
  final String voteType;

  VoteRequest({required this.voteType});

  Map<String, dynamic> toJson() {
    return {
      'vote_type': voteType,
    };
  }
}
