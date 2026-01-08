from django.db import models
from Users.models import User


class Post(models.Model):
    """
    Represents a community post by farmers or buyers
    """
    CATEGORY_CHOICES = [
        ('General', 'General'),
        ('Questions', 'Questions'),
        ('Tips', 'Tips'),
        ('News', 'News'),
    ]
    
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='posts')
    title = models.CharField(max_length=200)
    content = models.TextField()
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES, default='General')
    image = models.ImageField(upload_to='posts/', null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.author.full_name}: {self.title}"
    
    @property
    def upvotes_count(self):
        return self.votes.filter(vote_type='upvote').count()
    @property
    def downvotes_count(self):
        return self.votes.filter(vote_type='downvote').count()
    @property
    def total_score(self):
        return self.upvotes_count - self.downvotes_count
    @property
    def comments_count(self):
        return self.comments.count()


class Vote(models.Model):
    """
    Represents an upvote or downvote on a post
    """
    VOTE_CHOICES = [
        ('upvote', 'Upvote'),
        ('downvote', 'Downvote'),
    ]
    
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='votes')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='votes')
    vote_type = models.CharField(max_length=10, choices=VOTE_CHOICES)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['post', 'user']  # One vote per user per post
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.user.full_name} {self.vote_type}d {self.post.title}"


class Comment(models.Model):
    """
    Represents a comment on a post
    """
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='comments')
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='comments')
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['created_at']
    
    def __str__(self):
        return f"{self.author.full_name} on {self.post.title}"
