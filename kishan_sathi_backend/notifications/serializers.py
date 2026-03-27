from rest_framework import serializers
from .models import Notification
from django.apps import apps


class NotificationSerializer(serializers.ModelSerializer):
    """Serializer for Notification model"""
    actor_name = serializers.SerializerMethodField()
    actor_profile_picture_url = serializers.SerializerMethodField()

    def _resolve_actor(self, obj):
        reference_type = (obj.reference_type or '').lower()
        reference_id = obj.reference_id

        if not reference_id or not reference_type:
            return None

        try:
            if reference_type == 'consultation_request':
                ConsultationRequest = apps.get_model('consultation', 'ConsultationRequest')
                request_obj = ConsultationRequest.objects.select_related('farmer', 'doctor').filter(id=reference_id).first()
                if not request_obj:
                    return None
                if obj.user_id == request_obj.farmer_id:
                    return request_obj.doctor
                return request_obj.farmer

            if reference_type == 'product':
                Product = apps.get_model('farmer', 'Product')
                product = Product.objects.select_related('farmer').filter(id=reference_id).first()
                return product.farmer if product else None

            if reference_type == 'cart_item':
                CartItem = apps.get_model('buyer', 'CartItem')
                cart_item = CartItem.objects.select_related('product__farmer').filter(id=reference_id).first()
                return cart_item.product.farmer if cart_item and cart_item.product else None

            if reference_type == 'post':
                Post = apps.get_model('posts', 'Post')
                post = Post.objects.select_related('author').filter(id=reference_id).first()
                return post.author if post else None
        except Exception:
            return None

        return None

    def _actor_profile_picture_url(self, actor):
        if not actor or not getattr(actor, 'profile_picture', None):
            return None
        request = self.context.get('request')
        if request:
            return request.build_absolute_uri(actor.profile_picture.url)
        return actor.profile_picture.url

    def _get_cached_actor(self, obj):
        cached = getattr(obj, '_resolved_actor', None)
        if cached is not None:
            return cached
        actor = self._resolve_actor(obj)
        setattr(obj, '_resolved_actor', actor)
        return actor

    def get_actor_name(self, obj):
        actor = self._get_cached_actor(obj)
        if actor and getattr(actor, 'full_name', None):
            return actor.full_name
        return None

    def get_actor_profile_picture_url(self, obj):
        actor = self._get_cached_actor(obj)
        return self._actor_profile_picture_url(actor)
    
    class Meta:
        model = Notification
        fields = [
            'id',
            'type',
            'title',
            'message',
            'is_read',
            'reference_id',
            'reference_type',
            'actor_name',
            'actor_profile_picture_url',
            'created_at',
            'read_at',
        ]
        read_only_fields = ['id', 'created_at', 'read_at']


class NotificationCountSerializer(serializers.Serializer):
    """Serializer for notification count"""
    unread_count = serializers.IntegerField()
    total_count = serializers.IntegerField()
