from rest_framework import serializers
from .models import Category, Product, ProductImage
from Users.models import User


def _file_exists(field_file):
    if not field_file:
        return False
    name = getattr(field_file, 'name', None)
    storage = getattr(field_file, 'storage', None)
    if not name or storage is None:
        return False
    try:
        return storage.exists(name)
    except Exception:
        return False


def _build_file_url(serializer, field_file):
    url = field_file.url
    request = serializer.context.get('request')
    if request and not (url.startswith('http://') or url.startswith('https://')):
        return request.build_absolute_uri(url)
    return url


class CategorySerializer(serializers.ModelSerializer):
    product_count = serializers.IntegerField(source='products.count', read_only=True)
    
    class Meta:
        model = Category
        fields = ['id', 'name', 'description', 'icon', 'product_count', 'created_at']
        read_only_fields = ['created_at']


class ProductImageSerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()

    class Meta:
        model = ProductImage
        fields = ['id', 'image', 'caption', 'uploaded_at']
        read_only_fields = ['uploaded_at']

    def get_image(self, obj):
        if obj.image and _file_exists(obj.image):
            return _build_file_url(self, obj.image)
        return None


class FarmerBasicSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'full_name', 'phone_number', 'email']


class ProductListSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source='category.name', read_only=True)
    farmer_name = serializers.CharField(source='farmer.full_name', read_only=True)
    farmer_id = serializers.IntegerField(source='farmer.id', read_only=True)
    unit_display = serializers.CharField(source='get_unit_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    
    class Meta:
        model = Product
        fields = [
            'id', 'name', 'description', 'price', 'quantity', 'unit', 'unit_display',
            'status', 'status_display', 'is_organic', 'location', 'district',
            'image', 'category_name', 'farmer_name', 'farmer_id', 'created_at', 'is_available'
        ]

    def to_representation(self, instance):
        representation = super().to_representation(instance)
        if instance.image and _file_exists(instance.image):
            representation['image'] = _build_file_url(self, instance.image)
        else:
            representation['image'] = None
        return representation


class ProductDetailSerializer(serializers.ModelSerializer):
    category = CategorySerializer(read_only=True)
    category_id = serializers.PrimaryKeyRelatedField(
        queryset=Category.objects.all(),
        source='category',
        write_only=True,
        required=False
    )
    farmer = FarmerBasicSerializer(read_only=True)
    additional_images = ProductImageSerializer(many=True, read_only=True)
    unit_display = serializers.CharField(source='get_unit_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    
    class Meta:
        model = Product
        fields = [
            'id', 'farmer', 'category', 'category_id', 'name', 'description',
            'price', 'quantity', 'unit', 'unit_display', 'status', 'status_display',
            'is_organic', 'harvest_date', 'location', 'district',
            'image', 'additional_images', 'is_active', 'views_count',
            'created_at', 'updated_at', 'is_available'
        ]
        read_only_fields = ['farmer', 'views_count', 'created_at', 'updated_at']

    def to_representation(self, instance):
        representation = super().to_representation(instance)
        if instance.image and _file_exists(instance.image):
            representation['image'] = _build_file_url(self, instance.image)
        else:
            representation['image'] = None
        return representation
    
    def create(self, validated_data):
        # Set farmer from request user
        validated_data['farmer'] = self.context['request'].user
        return super().create(validated_data)


class ProductCreateUpdateSerializer(serializers.ModelSerializer):
    
    
    class Meta:
        model = Product
        fields = [
            'category', 'name', 'description', 'price', 'quantity', 'unit',
            'status', 'is_organic', 'harvest_date', 'location', 'district', 'image'
        ]
    
    def validate_price(self, value):
        if value <= 0:
            raise serializers.ValidationError("Price must be greater than 0")
        return value
    
    def validate_quantity(self, value):
        if value < 0:
            raise serializers.ValidationError("Quantity cannot be negative")
        return value
    
    def validate(self, data):
        # Ensure farmer is set from request
        request = self.context.get('request')
        if request and request.user:
            if request.user.role != 'farmer':
                raise serializers.ValidationError("Only farmers can create products")
        return data
    
    def create(self, validated_data):
        validated_data['farmer'] = self.context['request'].user
        return super().create(validated_data)
