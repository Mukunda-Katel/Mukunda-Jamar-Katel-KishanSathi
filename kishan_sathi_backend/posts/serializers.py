from rest_framework import serializers
from .models import Post, Vote, Comment
from Users.models import User


class AuthorSerializer(serializers.ModelSerializer):
    """Serializer for post author information"""
    class Meta:
        model = User
        fields = ['id', 'full_name', 'email', 'role']


class CommentSerializer(serializers.ModelSerializer):
    """Serializer for comments"""
    author = AuthorSerializer(read_only=True)
    author_id = serializers.IntegerField(write_only=True, required=False)
    
    class Meta:
        model = Comment
        fields = ['id', 'post', 'author', 'author_id', 'content', 'created_at', 'updated_at']
        read_only_fields = ['created_at', 'updated_at']
    
    def create(self, validated_data):
        # Set author from request user
        validated_data['author'] = self.context['request'].user
        validated_data.pop('author_id', None)
        return super().create(validated_data)


class VoteSerializer(serializers.ModelSerializer):
    """Serializer for votes"""
    user = AuthorSerializer(read_only=True)
    
    class Meta:
        model = Vote
        fields = ['id', 'post', 'user', 'vote_type', 'created_at']
        read_only_fields = ['created_at']


class PostSerializer(serializers.ModelSerializer):
    """Serializer for posts"""
    author = AuthorSerializer(read_only=True)
    author_name = serializers.SerializerMethodField()
    author_is_doctor = serializers.SerializerMethodField()
    upvotes_count = serializers.IntegerField(read_only=True)
    downvotes_count = serializers.IntegerField(read_only=True)
    total_score = serializers.IntegerField(read_only=True)
    comments_count = serializers.IntegerField(read_only=True)
    user_vote = serializers.SerializerMethodField()
    
    class Meta:
        model = Post
        fields = [
            'id', 'author', 'author_name', 'author_is_doctor',
            'title', 'content', 'category', 'image',
            'upvotes_count', 'downvotes_count', 'total_score',
            'comments_count', 'user_vote', 'created_at', 'updated_at'
        ]
        read_only_fields = ['created_at', 'updated_at']
    
    def get_author_name(self, obj):
        """Get author's full name"""
        return obj.author.full_name if obj.author else 'Unknown'
    
    def get_author_is_doctor(self, obj):
        """Check if author is a verified doctor"""
        if obj.author and obj.author.role == 'doctor':
            # Check if doctor is approved
            from Users.models import Doctor
            try:
                doctor = Doctor.objects.get(user=obj.author)
                return doctor.doctor_status == 'approved'
            except Doctor.DoesNotExist:
                return False
        return False
        return False
    
    def to_representation(self, instance):
        """Convert image to full URL in response"""
        representation = super().to_representation(instance)
        if instance.image:
            request = self.context.get('request')
            if request:
                representation['image'] = request.build_absolute_uri(instance.image.url)
            else:
                representation['image'] = instance.image.url
        else:
            representation['image'] = None
        return representation
    
    def get_user_vote(self, obj):
        """Get the current user's vote on this post"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            vote = obj.votes.filter(user=request.user).first()
            return vote.vote_type if vote else None
        return None
    
    def create(self, validated_data):
        # Set author from request user
        validated_data['author'] = self.context['request'].user
        return super().create(validated_data)


class PostDetailSerializer(PostSerializer):
    """Detailed serializer for posts including comments"""
    comments = CommentSerializer(many=True, read_only=True)
    
    class Meta(PostSerializer.Meta):
        fields = PostSerializer.Meta.fields + ['comments']
