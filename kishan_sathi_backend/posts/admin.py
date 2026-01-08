from django.contrib import admin
from .models import Post, Vote, Comment


@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    list_display = ['title', 'author', 'total_score', 'comments_count', 'created_at']
    list_filter = ['created_at', 'author']
    search_fields = ['title', 'content', 'author__full_name']
    readonly_fields = ['created_at', 'updated_at']


@admin.register(Vote)
class VoteAdmin(admin.ModelAdmin):
    list_display = ['user', 'post', 'vote_type', 'created_at']
    list_filter = ['vote_type', 'created_at']
    search_fields = ['user__full_name', 'post__title']


@admin.register(Comment)
class CommentAdmin(admin.ModelAdmin):
    list_display = ['author', 'post', 'content', 'created_at']
    list_filter = ['created_at']
    search_fields = ['author__full_name', 'post__title', 'content']
    readonly_fields = ['created_at', 'updated_at']
