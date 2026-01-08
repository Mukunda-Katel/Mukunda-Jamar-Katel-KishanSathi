from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAuthenticatedOrReadOnly
from django.db.models import Q
from .models import Post, Vote, Comment
from .serializers import PostSerializer, PostDetailSerializer, VoteSerializer, CommentSerializer


class PostViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing posts
    """
    permission_classes = [IsAuthenticatedOrReadOnly]
    
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return PostDetailSerializer
        return PostSerializer
    
    def get_queryset(self):
        """Get all posts or filter by query params"""
        queryset = Post.objects.all()
        
        # Filter by author
        author_id = self.request.query_params.get('author_id')
        if author_id:
            queryset = queryset.filter(author_id=author_id)
        
        # Filter by current user's posts
        my_posts = self.request.query_params.get('my_posts')
        if my_posts and self.request.user.is_authenticated:
            queryset = queryset.filter(author=self.request.user)
        
        # Search by title or content
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(
                Q(title__icontains=search) | Q(content__icontains=search)
            )
        
        return queryset
    
    def perform_create(self, serializer):
        print(f"Creating post with data: {self.request.data}")
        print(f"Files in request: {self.request.FILES}")
        if 'image' in self.request.FILES:
            print(f"Image file: {self.request.FILES['image']}")
        post = serializer.save(author=self.request.user)
        print(f"Post created with image: {post.image}")
        if post.image:
            print(f"Image URL: {post.image.url}")
        return post
    
    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def vote(self, request, pk=None):
        """
        Upvote or downvote a post
        Expects: { "vote_type": "upvote" or "downvote" }
        """
        post = self.get_object()
        vote_type = request.data.get('vote_type')
        
        if vote_type not in ['upvote', 'downvote']:
            return Response(
                {'error': 'vote_type must be "upvote" or "downvote"'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check if user already voted
        existing_vote = Vote.objects.filter(post=post, user=request.user).first()
        
        if existing_vote:
            if existing_vote.vote_type == vote_type:
                # Remove vote if clicking same vote type
                existing_vote.delete()
                return Response({
                    'message': 'Vote removed',
                    'upvotes': post.upvotes_count,
                    'downvotes': post.downvotes_count,
                    'total_score': post.total_score,
                    'user_vote': None
                })
            else:
                # Change vote type
                existing_vote.vote_type = vote_type
                existing_vote.save()
                return Response({
                    'message': 'Vote changed',
                    'upvotes': post.upvotes_count,
                    'downvotes': post.downvotes_count,
                    'total_score': post.total_score,
                    'user_vote': vote_type
                })
        else:
            # Create new vote
            Vote.objects.create(post=post, user=request.user, vote_type=vote_type)
            return Response({
                'message': 'Vote recorded',
                'upvotes': post.upvotes_count,
                'downvotes': post.downvotes_count,
                'total_score': post.total_score,
                'user_vote': vote_type
            })
    
    @action(detail=True, methods=['get'])
    def comments(self, request, pk=None):
        """Get all comments for a post"""
        post = self.get_object()
        comments = post.comments.all()
        serializer = CommentSerializer(comments, many=True)
        return Response(serializer.data)


class CommentViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing comments
    """
    serializer_class = CommentSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]
    
    def get_queryset(self):
        """Get comments, optionally filtered by post"""
        queryset = Comment.objects.all()
        
        post_id = self.request.query_params.get('post_id')
        if post_id:
            queryset = queryset.filter(post_id=post_id)
        
        return queryset
    
    def perform_create(self, serializer):
        serializer.save(author=self.request.user)
