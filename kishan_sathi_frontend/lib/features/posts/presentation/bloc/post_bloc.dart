import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/models/post_models.dart';
import 'post_event.dart';
import 'post_state.dart';

class PostBloc extends Bloc<PostEvent, PostState> {
  final PostRepository postRepository;
  final String token;

  PostBloc({
    required this.postRepository,
    required this.token,
  }) : super(PostInitial()) {
    on<LoadPosts>(_onLoadPosts);
    on<LoadPostDetail>(_onLoadPostDetail);
    on<CreatePost>(_onCreatePost);
    on<DeletePost>(_onDeletePost);
    on<VotePost>(_onVotePost);
    on<LoadComments>(_onLoadComments);
    on<CreateComment>(_onCreateComment);
  }

  Future<void> _onLoadPosts(LoadPosts event, Emitter<PostState> emit) async {
    emit(PostLoading());
    try {
      final posts = await postRepository.getPosts(
        token,
        authorId: event.authorId,
        myPosts: event.myPosts,
        search: event.search,
      );
      emit(PostsLoaded(posts: posts));
    } catch (e) {
      emit(PostError(message: e.toString()));
    }
  }

  Future<void> _onLoadPostDetail(
    LoadPostDetail event,
    Emitter<PostState> emit,
  ) async {
    emit(PostLoading());
    try {
      final post = await postRepository.getPostDetail(token, event.postId);
      emit(PostDetailLoaded(post: post));
    } catch (e) {
      emit(PostError(message: e.toString()));
    }
  }

  Future<void> _onCreatePost(CreatePost event, Emitter<PostState> emit) async {
    emit(PostLoading());
    try {
      final post = await postRepository.createPost(
        token,
        CreatePostRequest(
          title: event.title,
          content: event.content,
          category: event.category,
        ),
        imageFile: event.imageFile,
      );
      emit(PostCreated(post: post));
    } catch (e) {
      emit(PostError(message: e.toString()));
    }
  }

  Future<void> _onDeletePost(DeletePost event, Emitter<PostState> emit) async {
    emit(PostLoading());
    try {
      await postRepository.deletePost(token, event.postId);
      emit(PostDeleted());
    } catch (e) {
      emit(PostError(message: e.toString()));
    }
  }

  Future<void> _onVotePost(VotePost event, Emitter<PostState> emit) async {
    try {
      final result = await postRepository.votePost(
        token,
        event.postId,
        event.voteType,
      );
      emit(PostVoted(
        postId: event.postId,
        upvotes: result['upvotes'] as int,
        downvotes: result['downvotes'] as int,
        totalScore: result['total_score'] as int,
        userVote: result['user_vote'] as String?,
      ));
    } catch (e) {
      emit(PostError(message: e.toString()));
    }
  }

  Future<void> _onLoadComments(
    LoadComments event,
    Emitter<PostState> emit,
  ) async {
    emit(PostLoading());
    try {
      final comments = await postRepository.getComments(token, event.postId);
      emit(CommentsLoaded(comments: comments));
    } catch (e) {
      emit(PostError(message: e.toString()));
    }
  }

  Future<void> _onCreateComment(
    CreateComment event,
    Emitter<PostState> emit,
  ) async {
    try {
      final comment = await postRepository.createComment(
        token,
        CreateCommentRequest(
          post: event.postId,
          content: event.content,
        ),
      );
      emit(CommentCreated(comment: comment));
    } catch (e) {
      emit(PostError(message: e.toString()));
    }
  }
}
