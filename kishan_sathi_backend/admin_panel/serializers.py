from rest_framework import serializers
from Users.models import User
from farmer.models import Product, Category
from posts.models import Post
from consultation.models import ConsultationRequest


class AdminUserSerializer(serializers.ModelSerializer):
    """Serializer for user management in admin panel"""
    class Meta:
        model = User
        fields = [
            'id', 'email', 'full_name', 'phone_number', 'role',
            'specialization', 'experience_years', 'license_number',
            'certificate', 'is_doctor_verified', 'doctor_status',
            'is_active', 'created_at', 'updated_at', 'approved_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class AdminProductSerializer(serializers.ModelSerializer):
    """Serializer for product management in admin panel"""
    farmer_name = serializers.CharField(source='farmer.full_name', read_only=True)
    farmer_email = serializers.CharField(source='farmer.email', read_only=True)
    category_name = serializers.CharField(source='category.name', read_only=True)
    
    class Meta:
        model = Product
        fields = [
            'id', 'name', 'description', 'price', 'quantity',
            'farmer', 'farmer_name', 'farmer_email',
            'category', 'category_name', 'image',
            'created_at', 'updated_at'
        ]
    
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


class AdminPostSerializer(serializers.ModelSerializer):
    """Serializer for post management in admin panel"""
    author_name = serializers.CharField(source='author.full_name', read_only=True)
    author_role = serializers.CharField(source='author.role', read_only=True)
    likes_count = serializers.IntegerField(source='upvotes_count', read_only=True)
    
    class Meta:
        model = Post
        fields = [
            'id', 'author', 'author_name', 'author_role',
            'title', 'content', 'category', 'image', 'likes_count',
            'created_at', 'updated_at'
        ]
    
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


class DoctorVerificationSerializer(serializers.ModelSerializer):
    """Serializer for doctor verification"""
    class Meta:
        model = User
        fields = [
            'id', 'email', 'full_name', 'phone_number',
            'specialization', 'experience_years', 'license_number',
            'certificate', 'doctor_status', 'created_at'
        ]
        read_only_fields = ['id', 'email', 'full_name', 'phone_number',
                          'specialization', 'experience_years', 'license_number',
                          'certificate', 'created_at']
    
    def to_representation(self, instance):
        """Convert certificate to full URL in response"""
        representation = super().to_representation(instance)
        if instance.certificate:
            request = self.context.get('request')
            if request:
                representation['certificate'] = request.build_absolute_uri(instance.certificate.url)
            else:
                representation['certificate'] = instance.certificate.url
        else:
            representation['certificate'] = None
        return representation


class DashboardStatsSerializer(serializers.Serializer):
    """Serializer for dashboard statistics"""
    total_users = serializers.IntegerField()
    total_farmers = serializers.IntegerField()
    total_buyers = serializers.IntegerField()
    total_doctors = serializers.IntegerField()
    pending_doctors = serializers.IntegerField()
    total_products = serializers.IntegerField()
    total_posts = serializers.IntegerField()
    total_consultations = serializers.IntegerField()
    recent_users_growth = serializers.FloatField()
    recent_products_growth = serializers.FloatField()
